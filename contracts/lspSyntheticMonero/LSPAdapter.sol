// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ILiquidStabilityPool.sol";
import "../syntheticMonero.sol";
import "./CrossChainSXMR.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {DeployedContracts} from "../DeployedContracts.sol";

/**
 * @title LSPAdapter
 * @dev Adapter contract to connect Bera Borrow's Liquid Stability Pool with the sXMR system
 * This contract allows the sXMR system to use LSP liquidity for liquidations
 */
/**
 * @title LSPAdapter
 * @dev Adapter contract to connect Bera Borrow's Liquid Stability Pool with the sXMR system
 * This contract allows the sXMR system to use LSP liquidity for liquidations
 * Integrates with LayerZero for cross-chain functionality between Sepolia and Berachain
 */
contract LSPAdapter is Ownable {
    // Bera Borrow's Liquid Stability Pool (0x8343a45D793688410A60d67eA17E8ce0ab3C2c24 on Berachain)
    ILiquidStabilityPool public liquidStabilityPool;
    
    // Synthetic Monero contract
    CrossChainSXMR public syntheticMonero;
    
    // NECT token address (Bera Borrow's stablecoin)
    address public nectToken;
    
    // LayerZero chain IDs
    uint16 public constant SEPOLIA_CHAIN_ID = 10161; // LayerZero Sepolia chain ID
    uint16 public constant BERACHAIN_CHAIN_ID = 40875; // LayerZero Berachain chain ID
    
    // Current chain ID
    uint16 public currentChainId;
    
    // Fee percentage for LSP depositors (in basis points, e.g., 500 = 5%)
    uint256 public feePercentage = 500;
    
    // Minimum collateralization ratio for liquidations (in basis points, e.g., 11000 = 110%)
    uint256 public liquidationThreshold = 11000;
    
    // Mapping to track borrowed liquidity per protocol
    mapping(address => uint256) public protocolBorrowedLiquidity;
    
    // Total borrowed liquidity
    uint256 public totalBorrowedLiquidity;
    
    // Maximum liquidity that can be borrowed (as a percentage of total LSP deposits)
    uint256 public maxLiquidityPercentage = 3000; // 30% by default
    
    // Events
    event LiquidityBorrowed(address indexed protocol, uint256 amount);
    event LiquidityRepaid(address indexed protocol, uint256 amount, uint256 fee);
    event LiquidationExecuted(address indexed user, uint256 debt, uint256 collateral);
    event CrossChainLiquidationInitiated(address indexed user, uint256 debt, uint256 collateral);
    event CrossChainLiquidationExecuted(address indexed user, uint256 debt, uint256 collateral);
    event FeePercentageUpdated(uint256 newPercentage);
    event LiquidationThresholdUpdated(uint256 newThreshold);
    event MaxLiquidityPercentageUpdated(uint256 newPercentage);
    
    /**
     * @dev Constructor
     * @param _liquidStabilityPool Address of Bera Borrow's Liquid Stability Pool (defaults to DeployedContracts.LSP_PROXY if not provided)
     * @param _syntheticMonero Address of the Synthetic Monero contract
     * @param _nectToken Address of the NECT token (defaults to DeployedContracts.NECT if not provided)
     * @param _owner Address of the contract owner
     * @param _chainId Current chain ID (SEPOLIA_CHAIN_ID or BERACHAIN_CHAIN_ID)
     */
    constructor(
        address _liquidStabilityPool,
        address _syntheticMonero,
        address _nectToken,
        address _owner,
        uint16 _chainId
    ) Ownable(_owner) {
        currentChainId = _chainId;
        
        // Use provided addresses or default to the deployed contract addresses
        if (_chainId == BERACHAIN_CHAIN_ID) {
            // On Berachain, use the deployed addresses if not provided
            address lspAddress = _liquidStabilityPool != address(0) ? _liquidStabilityPool : DeployedContracts.LSP_PROXY;
            require(
                lspAddress == DeployedContracts.LSP_IMPLEMENTATION || 
                lspAddress == DeployedContracts.LSP_PROXY, 
                "Invalid LSP address for Berachain"
            );
            liquidStabilityPool = ILiquidStabilityPool(lspAddress);
            nectToken = _nectToken != address(0) ? _nectToken : DeployedContracts.NECT;
        } else {
            // On other chains, use the provided addresses
            liquidStabilityPool = ILiquidStabilityPool(_liquidStabilityPool);
            nectToken = _nectToken;
        }
        
        syntheticMonero = CrossChainSXMR(_syntheticMonero);
    }
    
    /**
     * @dev Allows a protocol to borrow liquidity from the LSP
     * @param amount Amount of NECT to borrow
     * @return success Whether the borrowing was successful
     */
    function borrowLiquidity(uint256 amount) external returns (bool) {
        // Check available liquidity
        uint256 availableLiquidity = getAvailableLiquidity();
        require(amount <= availableLiquidity, "Insufficient available liquidity");
        
        // Update borrowed liquidity
        protocolBorrowedLiquidity[msg.sender] += amount;
        totalBorrowedLiquidity += amount;
        
        // Transfer NECT to the borrowing protocol
        require(IERC20(nectToken).transfer(msg.sender, amount), "NECT transfer failed");
        
        emit LiquidityBorrowed(msg.sender, amount);
        return true;
    }
    
    /**
     * @dev Allows a protocol to repay borrowed liquidity with fees
     * @param amount Amount of NECT to repay
     * @return success Whether the repayment was successful
     */
    function repayLiquidity(uint256 amount) external returns (bool) {
        require(protocolBorrowedLiquidity[msg.sender] >= amount, "Repayment exceeds borrowed amount");
        
        // Calculate fee
        uint256 fee = (amount * feePercentage) / 10000;
        uint256 totalRepayment = amount + fee;
        
        // Transfer NECT from the protocol to this contract
        require(IERC20(nectToken).transferFrom(msg.sender, address(this), totalRepayment), "NECT transfer failed");
        
        // Update borrowed liquidity
        protocolBorrowedLiquidity[msg.sender] -= amount;
        totalBorrowedLiquidity -= amount;
        
        // Transfer the repaid amount back to the LSP
        require(IERC20(nectToken).transfer(address(liquidStabilityPool), amount), "LSP transfer failed");
        
        // Keep the fee in this contract for later distribution
        
        emit LiquidityRepaid(msg.sender, amount, fee);
        return true;
    }
    
    /**
     * @dev Executes a liquidation using the LSP
     * @param user Address of the user to liquidate
     * @return success Whether the liquidation was successful
     */
    function executeLiquidation(address user) external returns (bool) {
        // Check if we're on the correct chain (Berachain)
        require(currentChainId == BERACHAIN_CHAIN_ID, "Must be on Berachain for liquidations");
        
        // Check if the user's position is undercollateralized
        require(!syntheticMonero.isCollateralized(user), "Position is properly collateralized");
        
        // Get the user's debt and collateral
        uint256 debt = syntheticMonero.userMinted(user);
        uint256 collateral = syntheticMonero.userCollateral(user);
        
        // Execute the liquidation through the LSP's offset function
        uint256 nectUsed = liquidStabilityPool.offset(debt, collateral);
        
        // Update the user's position in the sXMR system
        // This would require additional functions in the SyntheticMonero contract
        // to handle liquidations, which we'll implement separately
        
        emit LiquidationExecuted(user, debt, collateral);
        return true;
    }
    
    /**
     * @dev Initiates a cross-chain liquidation (from Sepolia to Berachain)
     * @param user Address of the user to liquidate
     * @param debt Amount of debt to liquidate
     * @param collateral Amount of collateral to liquidate
     * @return success Whether the cross-chain liquidation request was successful
     */
    function initiateCrossChainLiquidation(address user, uint256 debt, uint256 collateral) external payable returns (bool) {
        // Check if we're on the correct chain (Sepolia)
        require(currentChainId == SEPOLIA_CHAIN_ID, "Must be on Sepolia to initiate cross-chain liquidation");
        
        // Check if the user's position is undercollateralized
        require(!syntheticMonero.isCollateralized(user), "Position is properly collateralized");
        
        // Prepare the payload for the cross-chain message
        bytes memory payload = abi.encode(user, debt, collateral);
        
        // In a real implementation, this would call the LayerZero endpoint to send the message to Berachain
        // lzEndpoint.send{value: msg.value}(
        //     BERACHAIN_CHAIN_ID,
        //     trustedRemoteLookup[BERACHAIN_CHAIN_ID],
        //     payload,
        //     payable(msg.sender),
        //     address(0),
        //     bytes("")
        // );
        
        // For now, emit an event to indicate the cross-chain liquidation request
        emit CrossChainLiquidationInitiated(user, debt, collateral);
        
        return true;
    }
    
    /**
     * @dev Distributes accumulated fees to LSP depositors
     * @return success Whether the distribution was successful
     */
    function distributeFees() external returns (bool) {
        uint256 feeBalance = IERC20(nectToken).balanceOf(address(this));
        require(feeBalance > 0, "No fees to distribute");
        
        // Transfer fees to the LSP
        require(IERC20(nectToken).transfer(address(liquidStabilityPool), feeBalance), "Fee transfer failed");
        
        return true;
    }
    
    /**
     * @dev Returns the available liquidity that can be borrowed
     * @return The amount of NECT that can be borrowed
     */
    function getAvailableLiquidity() public view returns (uint256) {
        uint256 totalDeposits = liquidStabilityPool.getTotalNECTDeposits();
        uint256 maxBorrowable = (totalDeposits * maxLiquidityPercentage) / 10000;
        
        if (totalBorrowedLiquidity >= maxBorrowable) {
            return 0;
        }
        
        return maxBorrowable - totalBorrowedLiquidity;
    }
    
    /**
     * @dev Updates the fee percentage
     * @param _feePercentage New fee percentage in basis points
     */
    function updateFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 2000, "Fee cannot exceed 20%");
        feePercentage = _feePercentage;
        emit FeePercentageUpdated(_feePercentage);
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
     * @dev Updates the maximum liquidity percentage
     * @param _maxLiquidityPercentage New maximum liquidity percentage in basis points
     */
    function updateMaxLiquidityPercentage(uint256 _maxLiquidityPercentage) external onlyOwner {
        require(_maxLiquidityPercentage <= 5000, "Cannot exceed 50% of total deposits");
        maxLiquidityPercentage = _maxLiquidityPercentage;
        emit MaxLiquidityPercentageUpdated(_maxLiquidityPercentage);
    }
}
