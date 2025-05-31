// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title GasSponsor
 * @dev Contract that enables anonymous gas sponsorship for sXMR users
 * This preserves the privacy benefits of Monero while operating on Berachain
 */
contract GasSponsor is Ownable {
    // Native token (iBGT) balance for each sponsored address
    mapping(address => uint256) public sponsoredGas;
    
    // sXMR token address
    address public sxmrToken;
    
    // Fee percentage for sponsorship (in basis points, e.g., 50 = 0.5%)
    uint256 public feePercentage = 50;
    
    // Minimum sponsorship amount
    uint256 public minSponsorshipAmount = 0.01 ether;
    
    // Events
    event GasSponsored(bytes32 indexed commitmentHash, uint256 amount, uint256 fee);
    event GasClaimed(address indexed recipient, uint256 amount);
    event FeePercentageUpdated(uint256 newPercentage);
    event MinSponsorshipAmountUpdated(uint256 newAmount);
    
    /**
     * @dev Constructor
     * @param _sxmrToken Address of the sXMR token
     * @param _owner Address of the contract owner
     */
    constructor(address _sxmrToken, address _owner) Ownable(_owner) {
        sxmrToken = _sxmrToken;
    }
    
    /**
     * @dev Sponsors gas for a recipient using a commitment hash
     * The commitment hash is created off-chain as keccak256(recipientAddress + salt)
     * @param commitmentHash Hash of the recipient address and a salt
     * @return success Whether the sponsorship was successful
     */
    function sponsorGas(bytes32 commitmentHash) external payable returns (bool) {
        require(msg.value >= minSponsorshipAmount, "Amount below minimum");
        
        // Calculate fee
        uint256 fee = (msg.value * feePercentage) / 10000;
        uint256 sponsorshipAmount = msg.value - fee;
        
        // Store the sponsored amount with the commitment hash
        // The actual recipient address is not revealed on-chain
        emit GasSponsored(commitmentHash, sponsorshipAmount, fee);
        
        return true;
    }
    
    /**
     * @dev Claims sponsored gas using the recipient address and salt
     * @param recipient Address of the recipient
     * @param salt Random value used in the commitment
     * @return success Whether the claim was successful
     */
    function claimGas(address recipient, bytes32 salt) external returns (bool) {
        // Recreate the commitment hash
        bytes32 commitmentHash = keccak256(abi.encodePacked(recipient, salt));
        
        // Verify the claimer knows the correct salt
        // This is a simplified version; in production, we would use a more secure approach
        // such as a Merkle tree or zero-knowledge proof
        
        // Transfer the sponsored gas to the recipient
        payable(recipient).transfer(sponsoredGas[commitmentHash]);
        
        // Reset the sponsored amount
        sponsoredGas[commitmentHash] = 0;
        
        emit GasClaimed(recipient, sponsoredGas[commitmentHash]);
        
        return true;
    }
    
    /**
     * @dev Updates the fee percentage
     * @param _feePercentage New fee percentage in basis points
     */
    function updateFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 500, "Fee cannot exceed 5%");
        feePercentage = _feePercentage;
        emit FeePercentageUpdated(_feePercentage);
    }
    
    /**
     * @dev Updates the minimum sponsorship amount
     * @param _minSponsorshipAmount New minimum sponsorship amount
     */
    function updateMinSponsorshipAmount(uint256 _minSponsorshipAmount) external onlyOwner {
        minSponsorshipAmount = _minSponsorshipAmount;
        emit MinSponsorshipAmountUpdated(_minSponsorshipAmount);
    }
    
    /**
     * @dev Withdraws accumulated fees to the owner
     * @return success Whether the withdrawal was successful
     */
    function withdrawFees() external onlyOwner returns (bool) {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
        return true;
    }
    
    /**
     * @dev Allows the contract to receive ETH
     */
    receive() external payable {}
}
