// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;

import "RandomV1.sol";

interface IRenderer {

    struct RenderArgs {
        int16 index;
        uint8 stage;
        int32 seed;        
        uint32[16384] buffer;
        RandomV1.PRNG prng;
    }

    /**
     * @notice Renders a chunk of the artwork, given an index.
     * @dev The output is an array of packed uint32s, in ARGB format.     
     */
    function render(RenderArgs memory args) external view returns (RenderArgs memory results);
}
