// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ILSP
 * @dev Interface for the BeraBorrow Liquid Stability Pool (LSP) contract
 * Based on the BeraBorrow contract addresses in DeployedContracts.sol
 */
interface ILSP {
    /**
     * @dev Provide NECT to the Stability Pool
     * @param _amount Amount of NECT to provide
     */
    function provideToSP(uint256 _amount) external;
    
    /**
     * @dev Withdraw NECT from the Stability Pool
     * @param _amount Amount of NECT to withdraw
     */
    function withdrawFromSP(uint256 _amount) external;
    
    /**
     * @dev Withdraw ETH gain to a specified address
     * @param _upperHint Upper hint for the trove
     * @param _lowerHint Lower hint for the trove
     */
    function withdrawETHGainToTrove(address _upperHint, address _lowerHint) external;
    
    /**
     * @dev Get the user's deposit in the Stability Pool
     * @param _depositor Address of the depositor
     * @return User's deposit
     */
    function getDepositorNECTDeposit(address _depositor) external view returns (uint256);
    
    /**
     * @dev Get the user's ETH gain from the Stability Pool
     * @param _depositor Address of the depositor
     * @return User's ETH gain
     */
    function getDepositorETHGain(address _depositor) external view returns (uint256);
}
