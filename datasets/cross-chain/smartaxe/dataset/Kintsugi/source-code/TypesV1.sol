// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;

library TypesV1 {
    /**
     * @dev Represents a point in two-dimensional space.
     */
    struct Point2D {
        int256 x;
        int256 y;
    }

    /**
     * @dev Represents a chunked rendering region.
     */
    struct Chunk2D {
        uint16 index;
        uint16 width;
        uint16 height;
        uint16 chunkWidth;
        uint16 chunkHeight;
        uint32 startX;
        uint32 startY;
    }
}