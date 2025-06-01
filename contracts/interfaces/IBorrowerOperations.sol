// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IBorrowerOperations
 * @dev Interface for the BeraBorrow BorrowerOperations contract
 * Based on the BeraBorrow contract addresses in DeployedContracts.sol
 */
interface IBorrowerOperations {
    /**
     * @dev Open a trove with ETH as collateral
     * @param _maxFeePercentage Maximum fee percentage for the operation
     * @param _NECTAmount Amount of NECT to draw
     * @param _upperHint Upper hint for the trove
     * @param _lowerHint Lower hint for the trove
     */
    function openTrove(
        uint256 _maxFeePercentage,
        uint256 _NECTAmount,
        address _upperHint,
        address _lowerHint
    ) external payable;
    
    /**
     * @dev Add more ETH collateral to a trove
     * @param _upperHint Upper hint for the trove
     * @param _lowerHint Lower hint for the trove
     */
    function addColl(address _upperHint, address _lowerHint) external payable;
    
    /**
     * @dev Withdraw ETH collateral from a trove
     * @param _collWithdrawal Amount of ETH to withdraw
     * @param _upperHint Upper hint for the trove
     * @param _lowerHint Lower hint for the trove
     */
    function withdrawColl(
        uint256 _collWithdrawal,
        address _upperHint,
        address _lowerHint
    ) external;
    
    /**
     * @dev Withdraw NECT from a trove
     * @param _maxFeePercentage Maximum fee percentage for the operation
     * @param _NECTAmount Amount of NECT to withdraw
     * @param _upperHint Upper hint for the trove
     * @param _lowerHint Lower hint for the trove
     */
    function withdrawNECT(
        uint256 _maxFeePercentage,
        uint256 _NECTAmount,
        address _upperHint,
        address _lowerHint
    ) external;
    
    /**
     * @dev Repay NECT to a trove
     * @param _NECTAmount Amount of NECT to repay
     * @param _upperHint Upper hint for the trove
     * @param _lowerHint Lower hint for the trove
     */
    function repayNECT(
        uint256 _NECTAmount,
        address _upperHint,
        address _lowerHint
    ) external;
    
    /**
     * @dev Close a trove
     */
    function closeTrove() external;
    
    /**
     * @dev Adjust a trove by modifying collateral and debt
     * @param _maxFeePercentage Maximum fee percentage for the operation
     * @param _collWithdrawal Amount of ETH to withdraw
     * @param _NECTChange Amount of NECT to change (positive for withdrawal, negative for repayment)
     * @param _isDebtIncrease Whether the debt is increasing
     * @param _upperHint Upper hint for the trove
     * @param _lowerHint Lower hint for the trove
     */
    function adjustTrove(
        uint256 _maxFeePercentage,
        uint256 _collWithdrawal,
        uint256 _NECTChange,
        bool _isDebtIncrease,
        address _upperHint,
        address _lowerHint
    ) external payable;
}
