// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IRewardVaultFactory
 * @dev Interface for the BeraBorrow RewardVaultFactory contract used in Proof of Liquidity (PoL)
 * Based on the official BeraBorrow documentation
 */
interface IRewardVaultFactory {
    /**
     * @dev Create a new RewardVault for a staking token
     * @param stakingToken Address of the token to be staked in the vault
     * @return Address of the newly created RewardVault
     */
    function createRewardVault(address stakingToken) external returns (address);
    
    /**
     * @dev Predict the address of the reward vault for a given staking token
     * @param stakingToken Address of the staking token
     * @return Address of the RewardVault for the staking token
     */
    function predictRewardVaultAddress(address stakingToken) external view returns (address);
    
    /**
     * @dev Get the vault for a staking token
     * @param stakingToken Address of the staking token
     * @return Address of the RewardVault for the staking token
     */
    function getVault(address stakingToken) external view returns (address);
    
    /**
     * @dev Get the number of vaults that have been created
     * @return Number of vaults created
     */
    function allVaultsLength() external view returns (uint256);
}
