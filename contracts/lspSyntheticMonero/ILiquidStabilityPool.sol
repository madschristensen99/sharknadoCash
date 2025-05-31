// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ILiquidStabilityPool
 * @dev Interface for Bera Borrow's Liquid Stability Pool
 * This interface defines the key functions needed to interact with the LSP
 */
interface ILiquidStabilityPool {
    /**
     * @dev Offsets debt with NECT from the Stability Pool
     * @param _debt The amount of debt to offset
     * @param _coll The amount of collateral from the liquidated position
     * @return The amount of NECT used from the Stability Pool
     */
    function offset(uint256 _debt, uint256 _coll) external returns (uint256);
    
    /**
     * @dev Returns the total NECT deposits in the Stability Pool
     * @return The total NECT in the Stability Pool
     */
    function getTotalNECTDeposits() external view returns (uint256);
    
    /**
     * @dev Returns the deposit of a specific user
     * @param _depositor The address of the depositor
     * @return The NECT deposit amount
     */
    function getDeposit(address _depositor) external view returns (uint256);
}
