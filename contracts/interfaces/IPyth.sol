// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {PythStructs} from "./PythStructs.sol";

interface IPyth {
    function getPrice(bytes32 priceId) external view returns (PythStructs.Price memory price);
    function getUpdateFee(bytes[] calldata updateData) external view returns (uint256 fee);
    function updatePriceFeeds(bytes[] calldata updateData) external payable;
}
