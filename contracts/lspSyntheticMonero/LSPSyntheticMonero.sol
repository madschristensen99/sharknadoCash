// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../syntheticMonero.sol";
import "./LSPAdapter.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IPyth} from "../interfaces/IPyth.sol";

/**
 * @title LSPSyntheticMonero
 * @dev Enhanced version of SyntheticMonero with LSP integration for liquidations
 * This contract extends the original SyntheticMonero with additional liquidation functionality
 */
contract LSPSyntheticMonero is SyntheticMonero {
    // LSP Adapter contract
    LSPAdapter public lspAdapter;
    
    // Liquidation threshold (in basis points, e.g., 12000 = 120%)
    uint256 public liquidationThreshold = 12000;
    
    // Liquidation bonus (in basis points, e.g., 500 = 5%)
    uint256 public liquidationBonus = 500;
    
    // Liquidation enabled flag
    bool public liquidationsEnabled = true;
    
    // Mapping to track if a user's position has been liquidated
    mapping(address => bool) public liquidated;
    
    // Events
    event LiquidationExecuted(address indexed user, uint256 debt, uint256 collateral, address liquidator);
    event LiquidationThresholdUpdated(uint256 newThreshold);
    event LiquidationBonusUpdated(uint256 newBonus);
    event LiquidationsToggled(bool enabled);
    event LSPAdapterUpdated(address newAdapter);
    
    /**
     * @dev Constructor
     * @param _collateralToken Address of the collateral token
     * @param _pythAddress Address of the Pyth price feed contract
     * @param _priceId Pyth price feed ID for XMR/USD
     * @param _lspAdapter Address of the LSP Adapter contract
     */
    constructor(
        address _collateralToken,
        address _pythAddress,
        bytes32 _priceId,
        address _lspAdapter
    ) SyntheticMonero(_collateralToken, _pythAddress, _priceId) {
        lspAdapter = LSPAdapter(_lspAdapter);
    }
    
    /**
     * @dev Liquidates an undercollateralized position
     * @param user Address of the user to liquidate
     * @param priceUpdateData Pyth price update data
     * @return success Whether the liquidation was successful
     */
    function liquidatePosition(address user, bytes[] calldata priceUpdateData) external payable returns (bool) {
        // Update price feed if data is provided
        if (priceUpdateData.length > 0) {
            uint256 fee = pyth.getUpdateFee(priceUpdateData);
            require(msg.value >= fee, "Insufficient ETH for price update");
            pyth.updatePriceFeeds{value: fee}(priceUpdateData);
        }
        
        // Check liquidation requirements
        require(liquidationsEnabled, "Liquidations are disabled");
        require(!liquidated[user], "Position already liquidated");
        require(isLiquidatable(user), "Position is not liquidatable");
        
        // Get the user's debt and collateral
        uint256 debt = userMinted[user];
        uint256 collateral = userCollateral[user];
        
        // Mark the position as liquidated
        liquidated[user] = true;
        
        // Calculate liquidation bonus
        uint256 bonus = (collateral * liquidationBonus) / 10000;
        uint256 collateralForLiquidator = bonus;
        uint256 collateralForLSP = collateral - bonus;
        
        // Reset the user's position
        userMinted[user] = 0;
        userCollateral[user] = 0;
        
        // Burn the sXMR tokens
        _burn(address(this), debt);
        
        // Transfer collateral to the liquidator (msg.sender)
        require(IERC20(collateralToken).transfer(msg.sender, collateralForLiquidator), "Liquidator reward transfer failed");
        
        // Transfer remaining collateral to the LSP
        require(IERC20(collateralToken).transfer(address(lspAdapter), collateralForLSP), "LSP collateral transfer failed");
        
        emit LiquidationExecuted(user, debt, collateral, msg.sender);
        return true;
    }
    
    /**
     * @dev Checks if a position is liquidatable
     * @param user Address of the user to check
     * @return Whether the position is liquidatable
     */
    function isLiquidatable(address user) public view returns (bool) {
        // If the user has already been liquidated, they can't be liquidated again
        if (liquidated[user]) {
            return false;
        }
        
        // Get the user's debt and collateral
        uint256 debt = userMinted[user];
        uint256 collateral = userCollateral[user];
        
        // If the user has no debt, they can't be liquidated
        if (debt == 0) {
            return false;
        }
        
        // Get the current XMR/USD price
        int64 xmrUsdPrice = getXmrUsdPrice();
        if (xmrUsdPrice <= 0) {
            return false;
        }
        
        // Calculate the current collateralization ratio
        uint256 xmrValue = (debt * uint256(uint64(xmrUsdPrice))) / 10**8;
        uint256 collateralValue = collateral;
        
        // Calculate the collateralization ratio in basis points
        uint256 collateralizationRatio = (collateralValue * 10000) / xmrValue;
        
        // Return true if the ratio is below the liquidation threshold
        return collateralizationRatio < liquidationThreshold;
    }
    
    /**
     * @dev Updates the liquidation threshold
     * @param _liquidationThreshold New liquidation threshold in basis points
     */
    function updateLiquidationThreshold(uint256 _liquidationThreshold) external onlyOwner {
        require(_liquidationThreshold >= 10000, "Threshold must be at least 100%");
        liquidationThreshold = _liquidationThreshold;
        emit LiquidationThresholdUpdated(_liquidationThreshold);
    }
    
    /**
     * @dev Updates the liquidation bonus percentage
     * @param _liquidationBonus New liquidation bonus in basis points
     */
    function updateLiquidationBonus(uint256 _liquidationBonus) external onlyOwner {
        require(_liquidationBonus <= 1000, "Bonus cannot exceed 10%");
        liquidationBonus = _liquidationBonus;
        emit LiquidationBonusUpdated(_liquidationBonus);
    }
    
    /**
     * @dev Toggles liquidations on or off
     * @param _enabled Whether liquidations should be enabled
     */
    function toggleLiquidations(bool _enabled) external onlyOwner {
        liquidationsEnabled = _enabled;
        emit LiquidationsToggled(_enabled);
    }
    
    /**
     * @dev Updates the LSP Adapter contract
     * @param _lspAdapter Address of the new LSP Adapter contract
     */
    function updateLSPAdapter(address _lspAdapter) external onlyOwner {
        require(_lspAdapter != address(0), "Invalid adapter address");
        lspAdapter = LSPAdapter(_lspAdapter);
        emit LSPAdapterUpdated(_lspAdapter);
    }
    
    /**
     * @dev Resets a user's liquidation status
     * @param user Address of the user
     */
    function resetLiquidationStatus(address user) external onlyOwner {
        liquidated[user] = false;
    }
    
    /**
     * @dev Allows the contract to receive ETH
     */
    receive() external payable {}
}
