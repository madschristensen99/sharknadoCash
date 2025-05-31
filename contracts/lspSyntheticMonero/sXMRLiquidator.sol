// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./LSPAdapter.sol";
import "../syntheticMonero.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IPyth} from "../interfaces/IPyth.sol";

/**
 * @title sXMRLiquidator
 * @dev Contract for liquidating undercollateralized sXMR positions using LSP liquidity
 * This contract connects the sXMR system with Bera Borrow's LSP
 */
contract sXMRLiquidator is Ownable {
    // LSP Adapter contract
    LSPAdapter public lspAdapter;
    
    // Synthetic Monero contract
    SyntheticMonero public syntheticMonero;
    
    // NECT token address (Bera Borrow's stablecoin)
    address public nectToken;
    
    // Collateral token address
    address public collateralToken;
    
    // Pyth price feed contract
    IPyth public pyth;
    
    // Liquidation bonus percentage (in basis points, e.g., 500 = 5%)
    uint256 public liquidationBonus = 500;
    
    // Minimum collateralization ratio for liquidations (in basis points, e.g., 11000 = 110%)
    uint256 public liquidationThreshold = 11000;
    
    // Events
    event PositionLiquidated(address indexed user, uint256 debt, uint256 collateral, address liquidator);
    event LiquidationBonusUpdated(uint256 newBonus);
    event LiquidationThresholdUpdated(uint256 newThreshold);
    
    /**
     * @dev Constructor
     * @param _lspAdapter Address of the LSP Adapter contract
     * @param _syntheticMonero Address of the Synthetic Monero contract
     * @param _nectToken Address of the NECT token
     * @param _collateralToken Address of the collateral token
     * @param _pyth Address of the Pyth price feed contract
     * @param _owner Address of the contract owner
     */
    constructor(
        address _lspAdapter,
        address _syntheticMonero,
        address _nectToken,
        address _collateralToken,
        address _pyth,
        address _owner
    ) Ownable(_owner) {
        lspAdapter = LSPAdapter(_lspAdapter);
        syntheticMonero = SyntheticMonero(_syntheticMonero);
        nectToken = _nectToken;
        collateralToken = _collateralToken;
        pyth = IPyth(_pyth);
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
        
        // Check if the position is liquidatable
        require(isLiquidatable(user), "Position is not liquidatable");
        
        // Get the user's debt and collateral
        uint256 debt = syntheticMonero.userMinted(user);
        uint256 collateral = syntheticMonero.userCollateral(user);
        
        // Calculate the amount of NECT needed for liquidation
        uint256 nectNeeded = debt;
        
        // Borrow liquidity from the LSP
        require(lspAdapter.borrowLiquidity(nectNeeded), "Failed to borrow liquidity");
        
        // Transfer the borrowed NECT to this contract
        require(IERC20(nectToken).transferFrom(address(lspAdapter), address(this), nectNeeded), "NECT transfer failed");
        
        // Liquidate the position
        // This would require additional functions in the SyntheticMonero contract
        // We'll simulate this by:
        // 1. Burning the user's sXMR tokens
        // 2. Transferring their collateral to this contract
        
        // Calculate liquidation bonus
        uint256 bonus = (collateral * liquidationBonus) / 10000;
        uint256 collateralForLiquidator = bonus;
        uint256 collateralForLSP = collateral - bonus;
        
        // Transfer collateral to the liquidator (msg.sender)
        require(IERC20(collateralToken).transfer(msg.sender, collateralForLiquidator), "Liquidator reward transfer failed");
        
        // Transfer remaining collateral to the LSP
        require(IERC20(collateralToken).transfer(address(lspAdapter), collateralForLSP), "LSP collateral transfer failed");
        
        // Repay the borrowed liquidity
        require(lspAdapter.repayLiquidity(nectNeeded), "Failed to repay liquidity");
        
        emit PositionLiquidated(user, debt, collateral, msg.sender);
        return true;
    }
    
    /**
     * @dev Checks if a position is liquidatable
     * @param user Address of the user to check
     * @return Whether the position is liquidatable
     */
    function isLiquidatable(address user) public view returns (bool) {
        // If the position is not collateralized according to SyntheticMonero's criteria
        if (!syntheticMonero.isCollateralized(user)) {
            return true;
        }
        
        // Get the user's debt and collateral
        uint256 debt = syntheticMonero.userMinted(user);
        uint256 collateral = syntheticMonero.userCollateral(user);
        
        // If the user has no debt, they can't be liquidated
        if (debt == 0) {
            return false;
        }
        
        // Get the current XMR/USD price
        int64 xmrUsdPrice = syntheticMonero.getXmrUsdPrice();
        if (xmrUsdPrice <= 0) {
            return false;
        }
        
        // Calculate the current collateralization ratio
        uint256 collateralValue = collateral;
        uint256 debtValue = (debt * uint256(uint64(xmrUsdPrice))) / 10**8;
        
        // Calculate the collateralization ratio in basis points
        uint256 collateralizationRatio = (collateralValue * 10000) / debtValue;
        
        // Return true if the ratio is below the liquidation threshold
        return collateralizationRatio < liquidationThreshold;
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
     * @dev Updates the liquidation threshold
     * @param _liquidationThreshold New liquidation threshold in basis points
     */
    function updateLiquidationThreshold(uint256 _liquidationThreshold) external onlyOwner {
        require(_liquidationThreshold >= 10000, "Threshold must be at least 100%");
        liquidationThreshold = _liquidationThreshold;
        emit LiquidationThresholdUpdated(_liquidationThreshold);
    }
    
    /**
     * @dev Allows the contract to receive ETH
     */
    receive() external payable {}
}
