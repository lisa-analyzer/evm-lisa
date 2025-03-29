// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;

library MathV1 {
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function max3(
        int256 a,
        int256 b,
        int256 c
    ) internal pure returns (int256) {
        int256 d = b >= c ? b : c;
        return a >= d ? a : d;
    }

    function min3(
        int256 a,
        int256 b,
        int256 c
    ) internal pure returns (int256) {
        int256 d = b < c ? b : c;
        return a < d ? a : d;
    }

    function abs(int256 x) internal pure returns (int256) {
        return x >= 0 ? x : -x;
    }

    function sign(int256 x) internal pure returns (int8) {
        return x == 0 ? int8(0) : x > 0 ? int8(1) : int8(-1);
    }
}