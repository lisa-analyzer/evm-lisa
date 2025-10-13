// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;

interface IAttributes {

    function getAttributes(int32 seed) external view returns (string memory attributes);
}