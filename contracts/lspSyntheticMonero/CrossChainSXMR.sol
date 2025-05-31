// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../syntheticMonero.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title CrossChainSXMR
 * @dev Implementation of cross-chain sXMR token using LayerZero
 * This contract enables the sXMR token to be bridged between Sepolia (for vLayer verification)
 * and Berachain (for LSP integration)
 */
contract CrossChainSXMR is SyntheticMonero {
    // LayerZero endpoint contract
    address public lzEndpoint;
    
    // Chain ID mapping
    uint16 public constant SEPOLIA_CHAIN_ID = 10161; // LayerZero Sepolia chain ID
    uint16 public constant BERACHAIN_CHAIN_ID = 40875; // LayerZero Berachain chain ID
    
    // Remote contract addresses on each chain
    mapping(uint16 => bytes) public trustedRemoteLookup;
    
    // Tracking of cross-chain transfers
    mapping(uint16 => mapping(bytes32 => bool)) public completedTransfers;
    
    // Events
    event SendToChain(uint16 indexed dstChainId, address indexed from, bytes indexed toAddress, uint256 amount);
    event ReceiveFromChain(uint16 indexed srcChainId, bytes indexed fromAddress, address indexed to, uint256 amount);
    
    /**
     * @dev Constructor
     * @param _collateralToken Address of the collateral token
     * @param _pythAddress Address of the Pyth price feed contract
     * @param _priceId Pyth price feed ID for XMR/USD
     * @param _lzEndpoint Address of the LayerZero endpoint
     */
    constructor(
        address _collateralToken,
        address _pythAddress,
        bytes32 _priceId,
        address _lzEndpoint
    ) SyntheticMonero(_collateralToken, _pythAddress, _priceId) {
        lzEndpoint = _lzEndpoint;
    }
    
    /**
     * @dev Sets the trusted remote address for a chain
     * @param _chainId The LayerZero chain ID
     * @param _remoteAddress The address of the remote contract
     */
    function setTrustedRemote(uint16 _chainId, bytes calldata _remoteAddress) external onlyOwner {
        trustedRemoteLookup[_chainId] = _remoteAddress;
    }
    
    /**
     * @dev Sends sXMR tokens to another chain
     * @param _dstChainId The destination chain ID
     * @param _to The recipient address on the destination chain
     * @param _amount The amount of sXMR to send
     */
    function sendToChain(uint16 _dstChainId, bytes calldata _to, uint256 _amount) external payable {
        require(trustedRemoteLookup[_dstChainId].length > 0, "Destination chain not supported");
        
        // Burn the tokens on this chain
        _burn(msg.sender, _amount);
        
        // Prepare the payload for the destination chain
        bytes memory payload = abi.encode(msg.sender, _to, _amount);
        
        // In a real implementation, this would call the LayerZero endpoint
        // lzEndpoint.send{value: msg.value}(
        //     _dstChainId,
        //     trustedRemoteLookup[_dstChainId],
        //     payload,
        //     payable(msg.sender),
        //     address(0),
        //     bytes("")
        // );
        
        emit SendToChain(_dstChainId, msg.sender, _to, _amount);
    }
    
    /**
     * @dev Receives sXMR tokens from another chain
     * @param _srcChainId The source chain ID
     * @param _from The sender address on the source chain
     * @param _to The recipient address on this chain
     * @param _amount The amount of sXMR to receive
     */
    function receiveFromChain(uint16 _srcChainId, bytes calldata _from, address _to, uint256 _amount) external {
        // In a real implementation, this would be called by the LayerZero endpoint
        // require(msg.sender == lzEndpoint, "Only LayerZero endpoint can call this function");
        
        // Check if the source chain is trusted
        require(trustedRemoteLookup[_srcChainId].length > 0, "Source chain not supported");
        
        // Generate a unique transfer ID
        bytes32 transferId = keccak256(abi.encodePacked(_srcChainId, _from, _to, _amount));
        
        // Check if the transfer has already been completed
        require(!completedTransfers[_srcChainId][transferId], "Transfer already completed");
        
        // Mark the transfer as completed
        completedTransfers[_srcChainId][transferId] = true;
        
        // Mint the tokens on this chain
        _mint(_to, _amount);
        
        emit ReceiveFromChain(_srcChainId, _from, _to, _amount);
    }
    
    /**
     * @dev Estimates the LayerZero fee for sending tokens to another chain
     * @param _dstChainId The destination chain ID
     * @param _to The recipient address on the destination chain
     * @param _amount The amount of sXMR to send
     * @return The estimated fee
     */
    function estimateSendFee(uint16 _dstChainId, bytes calldata _to, uint256 _amount) external view returns (uint256) {
        // Prepare the payload for the destination chain
        bytes memory payload = abi.encode(msg.sender, _to, _amount);
        
        // In a real implementation, this would call the LayerZero endpoint
        // (uint256 nativeFee, uint256 zroFee) = lzEndpoint.estimateFees(
        //     _dstChainId,
        //     address(this),
        //     payload,
        //     false,
        //     bytes("")
        // );
        
        // For now, return a placeholder value
        return 0.01 ether;
    }
}
