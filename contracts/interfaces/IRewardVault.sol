// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IRewardVault
 * @dev Interface for the BeraBorrow RewardVault contract used in Proof of Liquidity (PoL)
 * Based on the official BeraBorrow documentation
 */
interface IRewardVault {
    /**
     * @dev Stake tokens in the vault
     * @param amount Amount of tokens to stake
     */
    function stake(uint256 amount) external;
    
    /**
     * @dev Withdraw the staked tokens from the vault
     * @param amount Amount of tokens to withdraw
     */
    function withdraw(uint256 amount) external;
    
    /**
     * @dev Delegate stake to another address
     * @param account Address to delegate stake to
     * @param amount Amount of tokens to delegate
     */
    function delegateStake(address account, uint256 amount) external;
    
    /**
     * @dev Withdraw tokens staked on behalf of another account by the delegate
     * @param account Address of the account
     * @param amount Amount of tokens to withdraw
     */
    function delegateWithdraw(address account, uint256 amount) external;
    
    /**
     * @dev Get the amount staked by a delegate on behalf of an account
     * @param account Address of the account
     * @param delegate Address of the delegate
     * @return Amount staked by the delegate on behalf of the account
     */
    function getDelegateStake(address account, address delegate) external view returns (uint256);
    
    /**
     * @dev Get the total amount staked by delegates for an account
     * @param account Address of the account
     * @return Total amount staked by delegates
     */
    function getTotalDelegateStaked(address account) external view returns (uint256);
    
    /**
     * @dev Claim rewards
     * @param account Address of the account to claim rewards for
     * @param recipient Address to receive the rewards
     * @return Amount of rewards claimed
     */
    function getReward(address account, address recipient) external returns (uint256);
    
    /**
     * @dev Exit the vault with the staked tokens and claim the reward
     * @param recipient Address to receive the tokens and rewards
     */
    function exit(address recipient) external;
}
