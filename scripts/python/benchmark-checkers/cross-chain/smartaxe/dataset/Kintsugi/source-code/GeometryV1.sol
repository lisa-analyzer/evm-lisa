// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;

import "../V1/TypesV1.sol";

library GeometryV1 {
        
    struct Triangle2D {
        TypesV1.Point2D v0;
        TypesV1.Point2D v1;
        TypesV1.Point2D v2;
        uint32 strokeColor;
        uint32 fillColor;
        TypesV1.Chunk2D chunk;
    }

    struct Line2D {
        TypesV1.Point2D v0;
        TypesV1.Point2D v1;
        uint32 color;
        TypesV1.Chunk2D chunk;
    }

    struct Polygon2D {
        TypesV1.Point2D[40960] vertices;
        uint32 vertexCount;
        uint32 strokeColor;
        uint32 fillColor;
        TypesV1.Chunk2D chunk;
    }

    function edge(
        TypesV1.Point2D memory a,
        TypesV1.Point2D memory b,
        TypesV1.Point2D memory c
    ) external pure returns (int256) {
        return ((b.y - a.y) * (c.x - a.x)) - ((b.x - a.x) * (c.y - a.y));
    }

    function getBoundingBox(TypesV1.Point2D[] memory vertices)
        external
        pure
        returns (TypesV1.Point2D memory tl, TypesV1.Point2D memory br)
    {
        int256 xMax = vertices[0].x;
        int256 xMin = vertices[0].x;
        int256 yMax = vertices[0].y;
        int256 yMin = vertices[0].y;

        for (uint256 i; i < vertices.length; i++) {
            TypesV1.Point2D memory p = vertices[i];

            if (p.x > xMax) xMax = p.x;
            if (p.x < xMin) xMin = p.x;
            if (p.y > yMax) yMax = p.y;
            if (p.y < yMin) yMin = p.y;
        }

        return (TypesV1.Point2D(xMin, yMin), TypesV1.Point2D(xMax, yMax));
    }
}