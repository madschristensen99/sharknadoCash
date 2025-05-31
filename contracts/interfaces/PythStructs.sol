// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library PythStructs {
    // Price feed data structure
    struct Price {
        // Price value
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }
}
