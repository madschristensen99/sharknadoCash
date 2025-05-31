// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IPyth} from "./interfaces/IPyth.sol";
import {PythStructs} from "./interfaces/PythStructs.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title SyntheticMonero
 * @dev Implementation of a synthetic Monero (sXMR) token backed by collateral.
 * 
 * This contract allows users to mint sXMR tokens by depositing collateral (e.g., USDC),
 * with the amount of sXMR minted based on the current XMR/USD price from the Pyth oracle.
 * Users can also burn sXMR tokens to redeem their collateral.
 * 
 * The contract maintains a collateralization ratio (default 150%) to ensure the system
 * remains solvent even during price volatility.
 * 
 * Price data is obtained from the Pyth Network oracle, which provides reliable and
 * up-to-date XMR/USD price feeds.
 */
contract SyntheticMonero is ERC20, Ownable {
    // Pyth price feed contract
    IPyth public pyth;
    
    // Pyth price feed ID for XMR/USD
    bytes32 public xmrUsdPriceId;
    
    // Minimum collateralization ratio (150% = 15000)
    uint256 public collateralRatio = 15000; // 150% in basis points
    
    // Collateral token (e.g., USDC)
    address public collateralToken;
    
    // Mapping of user addresses to their collateral amounts
    mapping(address => uint256) public userCollateral;
    
    // Mapping of user addresses to their minted sXMR amounts
    mapping(address => uint256) public userMinted;
    
    // Price update fee for Pyth
    uint256 public pythUpdateFee;
    
    // Events
    event Minted(address indexed user, uint256 collateralAmount, uint256 sxmrAmount);
    event Burned(address indexed user, uint256 sxmrAmount, uint256 collateralAmount);
    event CollateralAdded(address indexed user, uint256 amount);
    event CollateralRemoved(address indexed user, uint256 amount);
    event CollateralRatioUpdated(uint256 newRatio);
    
    /**
     * @dev Constructor to initialize the SyntheticMonero contract
     * @param _pyth Address of the Pyth price feed contract (e.g., 0xA2aa501b19aff244D90cc15a4Cf739D2725B5729 for Base Sepolia)
     * @param _xmrUsdPriceId Pyth price feed ID for XMR/USD (bytes32 identifier for the specific price feed)
     * @param _collateralToken Address of the collateral token (e.g., USDC)
     * @param _owner Address of the contract owner who can adjust parameters
     * 
     * The constructor sets up the initial state of the contract, including the Pyth oracle
     * connection, the specific XMR/USD price feed to use, and the collateral token address.
     * It also initializes the ERC20 token with the name "Synthetic Monero" and symbol "sXMR".
     */
    constructor(
        address _pyth,
        bytes32 _xmrUsdPriceId,
        address _collateralToken,
        address _owner
    ) ERC20("Synthetic Monero", "sXMR") Ownable(_owner) {
        pyth = IPyth(_pyth);
        xmrUsdPriceId = _xmrUsdPriceId;
        collateralToken = _collateralToken;
        
        // Initialize with empty update data to get a base fee
        bytes[] memory emptyUpdateData = new bytes[](0);
        pythUpdateFee = pyth.getUpdateFee(emptyUpdateData);
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
     * @dev Mint sXMR tokens by depositing collateral
     * @param collateralAmount Amount of collateral to deposit (in collateral token's smallest units)
     * @param priceUpdateData The price update data from Pyth (can be empty if no update is needed)
     * 
     * This function allows users to mint sXMR tokens by depositing collateral. The amount of sXMR
     * minted is calculated based on the current XMR/USD price from the Pyth oracle and the
     * collateralization ratio. If price update data is provided, the function will update the
     * price feed before minting.
     * 
     * The formula used to calculate the amount of sXMR minted is:
     * sxmrAmount = (collateralAmount * 10^8 * 10000) / (xmrUsdPrice * collateralRatio)
     * 
     * This ensures that the value of the collateral is at least collateralRatio% of the value
     * of the minted sXMR tokens.
     * 
     * Requirements:
     * - The XMR/USD price must be greater than 0
     * - The user must have approved the contract to spend their collateral tokens
     */
    function mintWithCollateral(uint256 collateralAmount, bytes[] calldata priceUpdateData) external payable {
        // Update price feed if data is provided
        if (priceUpdateData.length > 0) {
            uint256 fee = pyth.getUpdateFee(priceUpdateData);
            pyth.updatePriceFeeds{value: fee}(priceUpdateData);
        }
        
        // Get the current XMR/USD price
        int64 xmrUsdPrice = getXmrUsdPrice();
        require(xmrUsdPrice > 0, "Invalid XMR price");
        
        // Transfer collateral from user to contract
        require(
            IERC20(collateralToken).transferFrom(msg.sender, address(this), collateralAmount),
            "Collateral transfer failed"
        );
        
        // Calculate how much sXMR can be minted based on collateral and price
        // Adjust for decimal differences and collateralization ratio
        uint256 sxmrAmount = (collateralAmount * 10**8 * 10000) / (uint256(uint64(xmrUsdPrice)) * collateralRatio);
        
        // Update user's collateral and minted amounts
        userCollateral[msg.sender] += collateralAmount;
        userMinted[msg.sender] += sxmrAmount;
        
        // Mint sXMR tokens to the user
        _mint(msg.sender, sxmrAmount);
        
        emit Minted(msg.sender, collateralAmount, sxmrAmount);
    }
    
    /**
     * @dev Burns sXMR tokens and redeems collateral
     * @param sxmrAmount Amount of sXMR to burn (in sXMR's smallest units)
     * @param priceUpdateData The price update data from Pyth (can be empty if no update is needed)
     * 
     * This function allows users to burn their sXMR tokens and redeem the corresponding amount of
     * collateral. The amount of collateral redeemed is calculated based on the current XMR/USD price
     * from the Pyth oracle and the collateralization ratio. If price update data is provided, the
     * function will update the price feed before burning.
     * 
     * The formula used to calculate the amount of collateral redeemed is:
     * collateralAmount = (sxmrAmount * uint256(uint64(xmrUsdPrice)) * collateralRatio) / (10^8 * 10000)
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
        
        // Calculate collateral amount to return based on sXMR amount and price
        uint256 collateralToReturn = (sxmrAmount * uint256(uint64(xmrUsdPrice)) * collateralRatio) / (10**8 * 10000);
        
        // Ensure user has enough collateral
        require(userCollateral[msg.sender] >= collateralToReturn, "Insufficient collateral");
        
        // Update user's collateral and minted amounts
        userCollateral[msg.sender] -= collateralToReturn;
        userMinted[msg.sender] -= sxmrAmount;
        
        // Burn sXMR tokens from the user
        _burn(msg.sender, sxmrAmount);
        
        // Return collateral to the user
        require(
            IERC20(collateralToken).transfer(msg.sender, collateralToReturn),
            "Collateral transfer failed"
        );
        
        emit Burned(msg.sender, sxmrAmount, collateralToReturn);
    }
    
    /**
     * @dev Adds additional collateral without minting new tokens
     * @param collateralAmount Amount of collateral to add
     */
    function addCollateral(uint256 collateralAmount) external {
        // Transfer collateral from user to contract
        require(
            IERC20(collateralToken).transferFrom(msg.sender, address(this), collateralAmount),
            "Collateral transfer failed"
        );
        
        // Update user's collateral amount
        userCollateral[msg.sender] += collateralAmount;
        
        emit CollateralAdded(msg.sender, collateralAmount);
    }
    
    /**
     * @dev Removes excess collateral without burning tokens
     * @param collateralAmount Amount of collateral to remove
     * @param priceUpdateData The price update data from Pyth
     */
    function removeExcessCollateral(uint256 collateralAmount, bytes[] calldata priceUpdateData) external payable {
        // Update price feed if data is provided
        if (priceUpdateData.length > 0) {
            uint256 fee = pyth.getUpdateFee(priceUpdateData);
            pyth.updatePriceFeeds{value: fee}(priceUpdateData);
        }
        
        // Get the current XMR/USD price
        int64 xmrUsdPrice = getXmrUsdPrice();
        require(xmrUsdPrice > 0, "Invalid XMR price");
        
        // Calculate minimum required collateral based on minted sXMR and current price
        uint256 requiredCollateral = (userMinted[msg.sender] * uint256(uint64(xmrUsdPrice)) * collateralRatio) / (10**8 * 10000);
        
        // Ensure user has enough excess collateral to remove
        require(userCollateral[msg.sender] >= requiredCollateral + collateralAmount, "Insufficient excess collateral");
        
        // Update user's collateral amount
        userCollateral[msg.sender] -= collateralAmount;
        
        // Return collateral to the user
        require(
            IERC20(collateralToken).transfer(msg.sender, collateralAmount),Add commentMore actions
            "Collateral transfer failed"
        );
        
        emit CollateralRemoved(msg.sender, collateralAmount);
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
        
        // Calculate required collateral based on minted sXMR and current price
        uint256 requiredCollateral = (userMinted[user] * uint256(uint64(xmrUsdPrice)) * collateralRatio) / (10**8 * 10000);
        
        return userCollateral[user] >= requiredCollateral;
    }
    // TODO: sus function pyth price price data should not require a fee right? 
    /**
     * @dev Updates the Pyth update fee
     */
    function updatePythFee() external {
        // Initialize with empty update data to get a base fee
        bytes[] memory emptyUpdateData = new bytes[](0);
        pythUpdateFee = pyth.getUpdateFee(emptyUpdateData);
    }
}
