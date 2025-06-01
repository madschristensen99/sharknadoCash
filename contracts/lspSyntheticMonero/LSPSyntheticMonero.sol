// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IPyth} from "../interfaces/IPyth.sol";
import {PythStructs} from "../interfaces/PythStructs.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DeployedContracts} from "../DeployedContracts.sol";
import {IRewardVault} from "../interfaces/IRewardVault.sol";
import {IRewardVaultFactory} from "../interfaces/IRewardVaultFactory.sol";
import {ILSP} from "../interfaces/ILSP.sol";
import {IBorrowerOperations} from "../interfaces/IBorrowerOperations.sol";

/**
 * @title LSPSyntheticMonero
 * @dev Implementation of a synthetic Monero (sXMR) token backed by NECT collateral with BeraBorrow integration.
 * 
 * This contract allows users to mint sXMR tokens by depositing NECT (a USD stablecoin) as collateral,
 * with the amount of sXMR minted based on the current XMR/USD price from the Pyth oracle.
 * Users can also burn sXMR tokens to redeem their NECT collateral.
 * 
 * The contract maintains a collateralization ratio (default 150%) to ensure the system
 * remains solvent even during price volatility.
 * 
 * Price data is obtained from the Pyth Network oracle, which provides reliable and
 * up-to-date XMR/USD price feeds.
 * 
 * BeraBorrow Integration Features:
 * 1. Proof of Liquidity (PoL) - Users can stake their sXMR tokens in a RewardVault to earn BGT rewards
 * 2. Liquid Stability Pool (LSP) - Integration with BeraBorrow's LSP for stability
 * 3. BeraBorrow Core - Integration with BeraBorrow's borrowing operations
 */
contract LSPSyntheticMonero is ERC20, Ownable {
    // Pyth price feed contract
    IPyth public pyth;
    
    // Pyth price feed ID for XMR/USD
    bytes32 public xmrUsdPriceId;
    
    // Minimum collateralization ratio (150% = 15000)
    uint256 public collateralRatio = 15000; // 150% in basis points
    
    // NECT token as collateral (USD stablecoin)
    address public collateralToken;
    
    // Mapping of user addresses to their collateral amounts
    mapping(address => uint256) public userCollateral;
    
    // Mapping of user addresses to their minted sXMR amounts
    mapping(address => uint256) public userMinted;
    
    // Price update fee for Pyth
    uint256 public pythUpdateFee;
    
    // BeraBorrow Integration - Proof of Liquidity (PoL)
    address public rewardVault;
    IRewardVaultFactory public rewardVaultFactory;
    
    // BeraBorrow Integration - Liquid Stability Pool (LSP)
    ILSP public liquidityStabilityPool;
    
    // BeraBorrow Integration - BeraBorrow Core
    IBorrowerOperations public borrowerOperations;
    
    // Events
    event Minted(address indexed user, uint256 nectAmount, uint256 sxmrAmount);
    event Burned(address indexed user, uint256 sxmrAmount, uint256 nectAmount);
    event CollateralAdded(address indexed user, uint256 amount);
    event CollateralRemoved(address indexed user, uint256 amount);
    event CollateralRatioUpdated(uint256 newRatio);
    event TokensStaked(address indexed user, uint256 amount);
    event TokensUnstaked(address indexed user, uint256 amount);
    event RewardsHarvested(address indexed user, uint256 amount);
    event ProvidedToStabilityPool(address indexed user, uint256 amount);
    event WithdrawnFromStabilityPool(address indexed user, uint256 amount);
    
    /**
     * @dev Constructor to initialize the LSPSyntheticMonero contract with BeraBorrow integration
     * 
     * The constructor sets up the initial state of the contract using the deployed contract addresses
     * from DeployedContracts library. It initializes the Pyth oracle connection, XMR/USD price feed,
     * NECT token address, and BeraBorrow integration components. The deployer automatically becomes 
     * the contract owner. It also initializes the ERC20 token with the name "Synthetic Monero" and 
     * symbol "sXMR".
     */
    constructor() ERC20("Synthetic Monero", "sXMR") Ownable(msg.sender) {
        // Use the deployed contract addresses from DeployedContracts library
        pyth = IPyth(DeployedContracts.BERACHAIN_PYTH_ORACLE);
        xmrUsdPriceId = DeployedContracts.XMR_USD_PYTH_PRICE_ID;
        collateralToken = DeployedContracts.NECT;
        
        // Initialize BeraBorrow integration components
        rewardVaultFactory = IRewardVaultFactory(DeployedContracts.FACTORY);
        liquidityStabilityPool = ILSP(DeployedContracts.LSP_PROXY);
        borrowerOperations = IBorrowerOperations(DeployedContracts.BORROWER_OPERATIONS);
        
        // Note: Removed pyth.getUpdateFee() call from constructor to avoid deployment issues
        // Fee will be calculated when needed in actual function calls
    }
    
    /**
     * @dev Updates the Pyth price feed
     * @param priceUpdateData The price update data from Pyth
     */
    function updatePrice(bytes[] calldata priceUpdateData) public payable {
        // Calculate the fee required to update the price feed
        uint256 fee = pyth.getUpdateFee(priceUpdateData);
        // Update the price feed with the provided data
        pyth.updatePriceFeeds{value: fee}(priceUpdateData);
    }
    
    /**
     * @dev Gets the current XMR/USD price from Pyth
     * @return price The current price of XMR in USD (scaled by 10^8)
     */
    function getXmrUsdPrice() public view returns (int64) {
        PythStructs.Price memory priceData = pyth.getPrice(xmrUsdPriceId);
        return priceData.price;
    }
    
    /**
     * @dev Mint sXMR tokens by depositing NECT collateral
     * @param nectAmount Amount of NECT to deposit (in NECT's smallest units, typically 18 decimals)
     * @param priceUpdateData The price update data from Pyth (can be empty if no update is needed)
     * 
     * This function allows users to mint sXMR tokens by depositing NECT collateral. The amount of sXMR
     * minted is calculated based on the current XMR/USD price from the Pyth oracle and the
     * collateralization ratio. If price update data is provided, the function will update the
     * price feed before minting.
     * 
     * Since NECT is a USD stablecoin (1 NECT ≈ 1 USD), the calculation is:
     * sxmrAmount = (nectAmount * 10^8 * 10000) / (xmrUsdPrice * collateralRatio)
     * 
     * This ensures that the USD value of the NECT collateral is at least collateralRatio% 
     * of the USD value of the minted sXMR tokens.
     * 
     * Requirements:
     * - The XMR/USD price must be greater than 0
     * - The user must have approved the contract to spend their NECT tokens
     */
    function mintWithCollateral(uint256 nectAmount, bytes[] calldata priceUpdateData) external payable {
        // Update price feed if data is provided
        if (priceUpdateData.length > 0) {
            uint256 fee = pyth.getUpdateFee(priceUpdateData);
            pyth.updatePriceFeeds{value: fee}(priceUpdateData);
        }
        
        // Get the current XMR/USD price
        int64 xmrUsdPrice = getXmrUsdPrice();
        require(xmrUsdPrice > 0, "Invalid XMR price");
        
        // Transfer NECT collateral from user to contract
        require(
            IERC20(collateralToken).transferFrom(msg.sender, address(this), nectAmount),
            "NECT transfer failed"
        );
        
        // Calculate how much sXMR can be minted based on NECT collateral and XMR price
        // Since NECT is a USD stablecoin, we use it directly as USD value
        // Formula: sxmrAmount = (nectAmount * 10^8 * 10000) / (xmrUsdPrice * collateralRatio)
        uint256 sxmrAmount = (nectAmount * 10**8 * 10000) / (uint256(uint64(xmrUsdPrice)) * collateralRatio);
        
        // Update user's collateral and minted amounts
        userCollateral[msg.sender] += nectAmount;
        userMinted[msg.sender] += sxmrAmount;
        
        // Mint sXMR tokens to the user
        _mint(msg.sender, sxmrAmount);
        
        emit Minted(msg.sender, nectAmount, sxmrAmount);
    }
    
    /**
     * @dev Burns sXMR tokens and redeems NECT collateral
     * @param sxmrAmount Amount of sXMR to burn (in sXMR's smallest units)
     * @param priceUpdateData The price update data from Pyth (can be empty if no update is needed)
     * 
     * This function allows users to burn their sXMR tokens and redeem the corresponding amount of
     * NECT collateral. The amount of NECT redeemed is calculated based on the current XMR/USD price
     * from the Pyth oracle and the collateralization ratio. If price update data is provided, the
     * function will update the price feed before burning.
     * 
     * The formula used to calculate the amount of NECT redeemed is:
     * nectAmount = (sxmrAmount * uint256(uint64(xmrUsdPrice)) * collateralRatio) / (10^8 * 10000)
     * 
     * Requirements:
     * - The user must have previously minted at least sxmrAmount of sXMR tokens
     * - The user must have at least sxmrAmount of sXMR tokens in their balance
     * - The XMR/USD price must be greater than 0
     */
    function burnAndRedeemCollateral(uint256 sxmrAmount, bytes[] calldata priceUpdateData) external payable {
        require(userMinted[msg.sender] >= sxmrAmount, "Insufficient minted balance");
        require(balanceOf(msg.sender) >= sxmrAmount, "Insufficient sXMR balance");
        
        // Update price feed if data is provided
        if (priceUpdateData.length > 0) {
            uint256 fee = pyth.getUpdateFee(priceUpdateData);
            pyth.updatePriceFeeds{value: fee}(priceUpdateData);
        }
        
        // Get the current XMR/USD price
        int64 xmrUsdPrice = getXmrUsdPrice();
        require(xmrUsdPrice > 0, "Invalid XMR price");
        
        // Calculate NECT amount to return based on sXMR amount and current XMR price
        uint256 nectToReturn = (sxmrAmount * uint256(uint64(xmrUsdPrice)) * collateralRatio) / (10**8 * 10000);
        
        // Ensure user has enough collateral
        require(userCollateral[msg.sender] >= nectToReturn, "Insufficient collateral");
        
        // Update user's collateral and minted amounts
        userCollateral[msg.sender] -= nectToReturn;
        userMinted[msg.sender] -= sxmrAmount;
        
        // Burn sXMR tokens from the user
        _burn(msg.sender, sxmrAmount);
        
        // Return NECT collateral to the user
        require(
            IERC20(collateralToken).transfer(msg.sender, nectToReturn),
            "NECT transfer failed"
        );
        
        emit Burned(msg.sender, sxmrAmount, nectToReturn);
    }
    
    /**
     * @dev Adds additional NECT collateral without minting new tokens
     * @param nectAmount Amount of NECT collateral to add
     */
    function addCollateral(uint256 nectAmount) external {
        // Transfer NECT collateral from user to contract
        require(
            IERC20(collateralToken).transferFrom(msg.sender, address(this), nectAmount),
            "NECT transfer failed"
        );
        
        // Update user's collateral amount
        userCollateral[msg.sender] += nectAmount;
        
        emit CollateralAdded(msg.sender, nectAmount);
    }
    
    /**
     * @dev Removes excess NECT collateral without burning tokens
     * @param nectAmount Amount of NECT collateral to remove
     * @param priceUpdateData The price update data from Pyth
     */
    function removeExcessCollateral(uint256 nectAmount, bytes[] calldata priceUpdateData) external payable {
        // Update price feed if data is provided
        if (priceUpdateData.length > 0) {
            uint256 fee = pyth.getUpdateFee(priceUpdateData);
            pyth.updatePriceFeeds{value: fee}(priceUpdateData);
        }
        
        // Get the current XMR/USD price
        int64 xmrUsdPrice = getXmrUsdPrice();
        require(xmrUsdPrice > 0, "Invalid XMR price");
        
        // Calculate minimum required NECT collateral based on minted sXMR and current price
        uint256 requiredCollateral = (userMinted[msg.sender] * uint256(uint64(xmrUsdPrice)) * collateralRatio) / (10**8 * 10000);
        
        // Ensure user has enough excess collateral to remove
        require(userCollateral[msg.sender] >= requiredCollateral + nectAmount, "Insufficient excess collateral");
        
        // Update user's collateral amount
        userCollateral[msg.sender] -= nectAmount;
        
        // Return NECT collateral to the user
        require(
            IERC20(collateralToken).transfer(msg.sender, nectAmount),
            "NECT transfer failed"
        );
        
        emit CollateralRemoved(msg.sender, nectAmount);
    }
    
    /**
     * @dev Updates the collateralization ratio
     * @param newRatio New collateralization ratio in basis points (e.g., 15000 for 150%)
     */
    function updateCollateralRatio(uint256 newRatio) external onlyOwner {
        require(newRatio >= 10000, "Ratio must be at least 100%");
        collateralRatio = newRatio;
        emit CollateralRatioUpdated(newRatio);
    }
    
    /**
     * @dev Checks if a user's position is properly collateralized
     * @param user Address of the user to check
     * @return isCollateralized Whether the user's position is properly collateralized
     */
    function isCollateralized(address user) public view returns (bool) {
        if (userMinted[user] == 0) return true;
        
        // Get the current XMR/USD price
        int64 xmrUsdPrice = getXmrUsdPrice();
        if (xmrUsdPrice <= 0) return false;
        
        // Calculate required NECT collateral based on minted sXMR and current price
        uint256 requiredCollateral = (userMinted[user] * uint256(uint64(xmrUsdPrice)) * collateralRatio) / (10**8 * 10000);
        
        return userCollateral[user] >= requiredCollateral;
    }
    
    /**
     * @dev Updates the Pyth update fee
     * Note: Pyth price feeds do require fees for updates in most networks to compensate
     * the oracle providers for gas costs and to prevent spam attacks.
     */
    function updatePythFee() external {
        // Initialize with empty update data to get a base fee
        bytes[] memory emptyUpdateData = new bytes[](0);
        pythUpdateFee = pyth.getUpdateFee(emptyUpdateData);
    }
    
    /**
     * @dev Get the current collateral token address (NECT)
     * @return The address of the NECT token used as collateral
     */
    function getCollateralToken() external view returns (address) {
        return collateralToken;
    }
    
    /**
     * @dev Get user's collateralization ratio in basis points
     * @param user Address of the user to check
     * @return ratio Current collateralization ratio for the user (0 if no position)
     */
    function getUserCollateralizationRatio(address user) external view returns (uint256 ratio) {
        if (userMinted[user] == 0) return 0;
        
        // Get the current XMR/USD price
        int64 xmrUsdPrice = getXmrUsdPrice();
        if (xmrUsdPrice <= 0) return 0;
        
        // Calculate the USD value of minted sXMR
        uint256 mintedValueUsd = (userMinted[user] * uint256(uint64(xmrUsdPrice))) / 10**8;
        
        // Calculate current ratio: (collateral * 10000) / mintedValueUsd
        ratio = (userCollateral[user] * 10000) / mintedValueUsd;
    }
    
    /**
     * @dev Initialize or get the RewardVault for sXMR tokens (PoL integration)
     * This allows users to stake their sXMR tokens and earn BGT rewards through BeraBorrow's PoL system
     * @return Address of the RewardVault for sXMR tokens
     */
    function initializeRewardVault() public returns (address) {
        // If the RewardVault is already initialized, return its address
        if (rewardVault != address(0)) {
            return rewardVault;
        }
        
        // Check if a RewardVault already exists for this token
        address existingVault = rewardVaultFactory.getVault(address(this));
        
        // If a RewardVault already exists, use it
        if (existingVault != address(0)) {
            rewardVault = existingVault;
            return rewardVault;
        }
        
        // Otherwise, create a new RewardVault
        rewardVault = rewardVaultFactory.createRewardVault(address(this));
        
        return rewardVault;
    }
    
    /**
     * @dev Stake sXMR tokens in the RewardVault to earn BGT rewards (PoL integration)
     * @param amount Amount of sXMR tokens to stake
     */
    function stakeSXMR(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient sXMR balance");
        
        // Ensure the RewardVault is initialized
        address vault = initializeRewardVault();
        
        // Transfer sXMR tokens to this contract
        _transfer(msg.sender, address(this), amount);
        
        // Approve the RewardVault to spend the tokens
        _approve(address(this), vault, amount);
        
        // Stake the tokens in the RewardVault on behalf of the user
        IRewardVault(vault).delegateStake(msg.sender, amount);
        
        emit TokensStaked(msg.sender, amount);
    }
    
    /**
     * @dev Unstake sXMR tokens from the RewardVault
     * @param amount Amount of sXMR tokens to unstake
     */
    function unstakeSXMR(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(rewardVault != address(0), "RewardVault not initialized");
        
        // Get the amount staked by this contract on behalf of the user
        uint256 stakedAmount = IRewardVault(rewardVault).getDelegateStake(msg.sender, address(this));
        require(stakedAmount >= amount, "Insufficient staked balance");
        
        // Withdraw the tokens from the RewardVault
        IRewardVault(rewardVault).delegateWithdraw(msg.sender, amount);
        
        // Transfer the tokens back to the user
        _transfer(address(this), msg.sender, amount);
        
        emit TokensUnstaked(msg.sender, amount);
    }
    
    /**
     * @dev Harvest BGT rewards from the RewardVault
     * @param recipient Address to receive the rewards
     * @return Amount of rewards harvested
     */
    function harvestRewards(address recipient) external returns (uint256) {
        require(rewardVault != address(0), "RewardVault not initialized");
        require(recipient != address(0), "Invalid recipient");
        
        // Claim rewards from the RewardVault
        uint256 rewards = IRewardVault(rewardVault).getReward(msg.sender, recipient);
        
        emit RewardsHarvested(msg.sender, rewards);
        
        return rewards;
    }
    
    /**
     * @dev Get the amount of sXMR tokens staked by a user in the RewardVault
     * @param user Address of the user
     * @return Amount of sXMR tokens staked
     */
    function getStakedSXMR(address user) external view returns (uint256) {
        if (rewardVault == address(0)) return 0;
        
        return IRewardVault(rewardVault).getDelegateStake(user, address(this));
    }
    
    // ==================== Liquid Stability Pool (LSP) Integration ====================
    
    /**
     * @dev Provide NECT to the Stability Pool
     * This allows users to provide NECT to BeraBorrow's Stability Pool directly through this contract
     * @param amount Amount of NECT to provide
     */
    function provideToStabilityPool(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        
        // Transfer NECT from the user to this contract
        require(
            IERC20(collateralToken).transferFrom(msg.sender, address(this), amount),
            "NECT transfer failed"
        );
        
        // Approve the LSP to spend the NECT
        IERC20(collateralToken).approve(address(liquidityStabilityPool), amount);
        
        // Provide NECT to the Stability Pool
        liquidityStabilityPool.provideToSP(amount);
        
        emit ProvidedToStabilityPool(msg.sender, amount);
    }
    
    /**
     * @dev Withdraw NECT from the Stability Pool
     * @param amount Amount of NECT to withdraw
     */
    function withdrawFromStabilityPool(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        
        // Get the current deposit in the Stability Pool
        uint256 currentDeposit = liquidityStabilityPool.getDepositorNECTDeposit(address(this));
        require(currentDeposit >= amount, "Insufficient deposit in Stability Pool");
        
        // Withdraw NECT from the Stability Pool
        liquidityStabilityPool.withdrawFromSP(amount);
        
        // Transfer NECT to the user
        require(
            IERC20(collateralToken).transfer(msg.sender, amount),
            "NECT transfer failed"
        );
        
        emit WithdrawnFromStabilityPool(msg.sender, amount);
    }
    
    /**
     * @dev Get the current deposit in the Stability Pool
     * @return Amount of NECT deposited in the Stability Pool by this contract
     */
    function getStabilityPoolDeposit() external view returns (uint256) {
        return liquidityStabilityPool.getDepositorNECTDeposit(address(this));
    }
    
    /**
     * @dev Get the ETH gain from the Stability Pool
     * @return Amount of ETH gained from the Stability Pool by this contract
     */
    function getStabilityPoolETHGain() external view returns (uint256) {
        return liquidityStabilityPool.getDepositorETHGain(address(this));
    }
    
    /**
     * @dev Withdraw ETH gain from the Stability Pool to a trove
     * @param upperHint Upper hint for the trove
     * @param lowerHint Lower hint for the trove
     */
    function withdrawETHGainToTrove(address upperHint, address lowerHint) external onlyOwner {
        liquidityStabilityPool.withdrawETHGainToTrove(upperHint, lowerHint);
    }
    
    // ==================== BeraBorrow Core Integration ====================
    
    /**
     * @dev Open a trove in the BeraBorrow system
     * This allows users to borrow NECT against ETH collateral
     * @param maxFeePercentage Maximum fee percentage for the operation
     * @param nectAmount Amount of NECT to borrow
     * @param upperHint Upper hint for the trove
     * @param lowerHint Lower hint for the trove
     */
    function openTrove(
        uint256 maxFeePercentage,
        uint256 nectAmount,
        address upperHint,
        address lowerHint
    ) external payable {
        // Call BorrowerOperations to open a trove
        borrowerOperations.openTrove{value: msg.value}(
            maxFeePercentage,
            nectAmount,
            upperHint,
            lowerHint
        );
        
        // If the user wants to use the borrowed NECT to mint sXMR, they can call mintWithCollateral separately
    }
    
    /**
     * @dev Add ETH collateral to a trove
     * @param upperHint Upper hint for the trove
     * @param lowerHint Lower hint for the trove
     */
    function addCollateralToTrove(
        address upperHint,
        address lowerHint
    ) external payable {
        // Call BorrowerOperations to add collateral to a trove
        borrowerOperations.addColl{value: msg.value}(upperHint, lowerHint);
    }
    
    /**
     * @dev Withdraw ETH collateral from a trove
     * @param collWithdrawal Amount of ETH to withdraw
     * @param upperHint Upper hint for the trove
     * @param lowerHint Lower hint for the trove
     */
    function withdrawCollateralFromTrove(
        uint256 collWithdrawal,
        address upperHint,
        address lowerHint
    ) external {
        // Call BorrowerOperations to withdraw collateral from a trove
        borrowerOperations.withdrawColl(collWithdrawal, upperHint, lowerHint);
    }
    
    /**
     * @dev Withdraw NECT from a trove
     * @param maxFeePercentage Maximum fee percentage for the operation
     * @param nectAmount Amount of NECT to withdraw
     * @param upperHint Upper hint for the trove
     * @param lowerHint Lower hint for the trove
     */
    function withdrawNECTFromTrove(
        uint256 maxFeePercentage,
        uint256 nectAmount,
        address upperHint,
        address lowerHint
    ) external {
        // Call BorrowerOperations to withdraw NECT from a trove
        borrowerOperations.withdrawNECT(maxFeePercentage, nectAmount, upperHint, lowerHint);
    }
    
    /**
     * @dev Repay NECT to a trove
     * @param nectAmount Amount of NECT to repay
     * @param upperHint Upper hint for the trove
     * @param lowerHint Lower hint for the trove
     */
    function repayNECTToTrove(
        uint256 nectAmount,
        address upperHint,
        address lowerHint
    ) external {
        // Transfer NECT from the user to this contract
        require(
            IERC20(collateralToken).transferFrom(msg.sender, address(this), nectAmount),
            "NECT transfer failed"
        );
        
        // Approve BorrowerOperations to spend the NECT
        IERC20(collateralToken).approve(address(borrowerOperations), nectAmount);
        
        // Call BorrowerOperations to repay NECT to a trove
        borrowerOperations.repayNECT(nectAmount, upperHint, lowerHint);
    }
    
    /**
     * @dev Close a trove
     */
    function closeTrove() external {
        // Call BorrowerOperations to close a trove
        borrowerOperations.closeTrove();
    }
    
    /**
     * @dev Adjust a trove by modifying collateral and debt
     * @param maxFeePercentage Maximum fee percentage for the operation
     * @param collWithdrawal Amount of ETH to withdraw
     * @param nectChange Amount of NECT to change
     * @param isDebtIncrease Whether the debt is increasing
     * @param upperHint Upper hint for the trove
     * @param lowerHint Lower hint for the trove
     */
    function adjustTrove(
        uint256 maxFeePercentage,
        uint256 collWithdrawal,
        uint256 nectChange,
        bool isDebtIncrease,
        address upperHint,
        address lowerHint
    ) external payable {
        // If this is a debt increase, we need to handle the NECT transfer
        if (!isDebtIncrease && nectChange > 0) {
            // Transfer NECT from the user to this contract
            require(
                IERC20(collateralToken).transferFrom(msg.sender, address(this), nectChange),
                "NECT transfer failed"
            );
            
            // Approve BorrowerOperations to spend the NECT
            IERC20(collateralToken).approve(address(borrowerOperations), nectChange);
        }
        
        // Call BorrowerOperations to adjust the trove
        borrowerOperations.adjustTrove{value: msg.value}(
            maxFeePercentage,
            collWithdrawal,
            nectChange,
            isDebtIncrease,
            upperHint,
            lowerHint
        );
    }
    
    /**
     * @dev Mint sXMR tokens directly after borrowing NECT from a trove
     * This is a convenience function that combines borrowing NECT and minting sXMR
     * @param nectAmount Amount of NECT to use as collateral
     * @param priceUpdateData The price update data from Pyth
     */
    function borrowAndMintSXMR(
        uint256 maxFeePercentage,
        uint256 nectAmount,
        address upperHint,
        address lowerHint,
        bytes[] calldata priceUpdateData
    ) external payable {
        // Open a trove and borrow NECT
        borrowerOperations.openTrove{value: msg.value}(
            maxFeePercentage,
            nectAmount,
            upperHint,
            lowerHint
        );
        
        // Mint sXMR with the borrowed NECT
        mintWithCollateral(nectAmount, priceUpdateData);
    }
}
