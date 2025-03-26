// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;

import "../V1/TypesV1.sol";
import "../V1/GraphicsV1.sol";
import "../V1/GeometryV1.sol";
import "../V1/RandomV1.sol";
import "../V1/MathV1.sol";

library ProcessingV1 {
    uint32 internal constant BG_COLOR = 0xFFD3D3D3;
    uint32 internal constant FILL_COLOR = 0xFFFFFFFF;
    uint32 internal constant STROKE_COLOR = 0x00000000;
    uint32 internal constant MAX_POLYGON_NODES = 400;

    /**
     * @notice Sets the color used for the background of the drawing surface.
     * @notice https://processing.org/reference/background_.html
     */
    function background(
        uint32[16384] /* 128 * 128 */
            memory result,
        uint32 color,
        TypesV1.Chunk2D memory chunk
    ) internal pure {
        for (uint256 x = 0; x < chunk.chunkWidth; x++) {
            for (uint256 y = 0; y < chunk.chunkHeight; y++) {
                GraphicsV1.setPixel(
                    result,
                    chunk.chunkWidth,
                    int256(x),
                    int256(y),
                    color
                );
            }
        }
    }

    /**
     * @notice A triangle is a plane created by connecting three points. The first two arguments specify the first point, the middle two arguments specify the second point, and the last two arguments specify the third point.
     * @notice https://processing.org/reference/triangle_.html
     * @dev Renders a filled triangle, using the Barycentric rasterization algorithm.
     */
    function triangle(
        uint32[16384] /* 128 * 128 */
            memory result,
        GeometryV1.Triangle2D memory f
    ) internal pure {
        TypesV1.Point2D memory p;

        uint256 minX = f.chunk.startX;
        uint256 maxX = (f.chunk.startX + f.chunk.chunkWidth) - 1;
        uint256 minY = f.chunk.startY;
        uint256 maxY = (f.chunk.startY + f.chunk.chunkHeight) - 1;

        while (GeometryV1.edge(f.v0, f.v1, f.v2) < 0) {
            TypesV1.Point2D memory temp = f.v1;
            f.v1 = f.v2;
            f.v2 = temp;
        }

        for (p.x = int256(minX); p.x <= int256(maxX); p.x++) {
            for (p.y = int256(minY); p.y <= int256(maxY); p.y++) {
                int256 w0 = GeometryV1.edge(f.v1, f.v2, p);
                int256 w1 = GeometryV1.edge(f.v2, f.v0, p);
                int256 w2 = GeometryV1.edge(f.v0, f.v1, p);

                if (w0 >= 0 && w1 >= 0 && w2 >= 0) {
                    GraphicsV1.setPixel(
                        result,
                        f.chunk.chunkWidth,
                        int256(p.x - int32(f.chunk.startX)),
                        int256(p.y - int32(f.chunk.startY)),
                        f.fillColor
                    );
                }
            }
        }

        if (f.strokeColor == f.fillColor) return;

        {
            line(result, GeometryV1.Line2D(f.v0, f.v1, f.strokeColor, f.chunk));
            line(result, GeometryV1.Line2D(f.v1, f.v2, f.strokeColor, f.chunk));
            line(result, GeometryV1.Line2D(f.v2, f.v0, f.strokeColor, f.chunk));
        }
    }

    /**
     * @notice Draws a line (a direct path between two points) to the screen.
     * @notice https://processing.org/reference/line_.html
     * @dev Renders a line between two points, using Bresenham's rasterization algorithm.
     */
    function line(uint32[16384]memory result, GeometryV1.Line2D memory f
    ) internal pure {
        int256 x0 = f.v0.x;
        int256 x1 = f.v1.x;
        int256 y0 = f.v0.y;
        int256 y1 = f.v1.y;

        int256 dx = MathV1.abs(x1 - x0);        
        int256 dy = MathV1.abs(y1 - y0);

        int256 err = (dx > dy ? dx : -dy) / 2;
        int256 e2;

        for (;;) {
            if (
                x0 <= int32(f.chunk.startX) + int16(f.chunk.chunkWidth) - 1 &&
                x0 >= int32(f.chunk.startX) &&
                y0 <= int32(f.chunk.startY) + int16(f.chunk.chunkHeight) - 1 &&
                y0 >= int32(f.chunk.startY)
            ) {
                GraphicsV1.setPixel(
                    result,
                    f.chunk.chunkWidth,
                    x0 - int32(f.chunk.startX),
                    y0 - int32(f.chunk.startY),
                    f.color
                );
            }

            if (x0 == x1 && y0 == y1) break;
            e2 = err;
            if (e2 > -dx) {
                err -= dy;
                x0 += x0 < x1 ? int8(1) : -1;
            }
            if (e2 < dy) {
                err += dx;
                y0 += y0 < y1 ? int8(1) : -1;
            }
        }
    }

    /**
     * @notice Draw a polygon shape to the screen.
     * @notice https://processing.org/reference/beginShape_.html
     * @notice https://processing.org/reference/vertex_.html
     * @notice https://processing.org/reference/endShape_.html
     * @dev Renders a filled polygon, using Finley's algorithm.
     */
    function polygon(uint32[16384] memory result, GeometryV1.Polygon2D memory f
    ) internal pure {
        uint32 polyCorners = f.vertexCount;

        int32[MAX_POLYGON_NODES] memory nodeX;

        for (uint32 pixelY = f.chunk.startY; pixelY < (f.chunk.startY + f.chunk.chunkHeight); pixelY++) {
            uint32 i;

            uint256 nodes = 0;
            uint32 j = polyCorners - 1;
            for (i = 0; i < polyCorners; i++) {
                
                TypesV1.Point2D memory a = TypesV1.Point2D(
                    f.vertices[i].x,
                    f.vertices[i].y
                );
                TypesV1.Point2D memory b = TypesV1.Point2D(
                    f.vertices[j].x,
                    f.vertices[j].y
                );

                if (
                    (a.y < int32(pixelY) && b.y >= int32(pixelY)) ||
                    (b.y < int32(pixelY) && a.y >= int32(pixelY))
                ) {
                    int32 t = int32(a.x) + (int32(pixelY) - int32(a.y)) / (int32(b.y) - int32(a.y)) * (int32(b.x) - int32(a.x));
                    nodeX[nodes++] = t;
                }

                j = i;
            }

            if(nodes == 0) {
                continue; // nothing to draw
            }

            i = 0;
            while (i < nodes - 1) {
                if (nodeX[i] > nodeX[i + 1]) {
                    (nodeX[i], nodeX[i + 1]) = (nodeX[i + 1], nodeX[i]);
                    if (i != 0) i--;
                } else {
                    i++;
                }
            }

            for (i = 0; i < nodes; i += 2) {
                
                if (nodeX[i] >= int32(f.chunk.startX) + int16(f.chunk.chunkHeight)) break;
                if (nodeX[i + 1] <= int32(f.chunk.startX)) continue;
                if (nodeX[i] < int32(f.chunk.startX)) nodeX[i] = int32(f.chunk.startX);                
                if (nodeX[i + 1] > int32(f.chunk.startX) + int16(f.chunk.chunkHeight))
                    nodeX[i + 1] = int32(int32(f.chunk.startX) + int16(f.chunk.chunkHeight));

                for (
                    int32 pixelX = nodeX[i];
                    pixelX < nodeX[i + 1];
                    pixelX++
                ) {
                    if (pixelX >= int32(f.chunk.startX) + int16(f.chunk.chunkHeight)) continue;

                    int32 px = int32(pixelX) - int32(f.chunk.startX);
                    int32 py = int32(pixelY) - int32(f.chunk.startY);

                    if (
                        px >= 0 &&
                        px < int16(f.chunk.chunkWidth) &&
                        py >= 0 &&
                        py < int16(f.chunk.chunkHeight)
                    ) {
                        GraphicsV1.setPixel(
                            result,
                            f.chunk.chunkWidth,
                            px,
                            py,
                            f.fillColor
                        );
                    }
                }
            }
        }

        if (f.strokeColor == f.fillColor) return;

        {
            uint256 j = f.vertices.length - 1;
            for (uint256 i = 0; i < f.vertices.length; i++) {
                TypesV1.Point2D memory a = f.vertices[i];
                TypesV1.Point2D memory b = f.vertices[j];
                line(result, GeometryV1.Line2D(a, b, f.strokeColor, f.chunk));
                j = i;
            }
            line(
                result,
                GeometryV1.Line2D(
                    f.vertices[f.vertices.length - 1],
                    f.vertices[0],
                    f.strokeColor,
                    f.chunk
                )
            );
        }
    }

    /**
     * @notice Renders a number from a random series of numbers having a mean of 0 and standard deviation of 1.
     * @notice https://processing.org/reference/randomGaussian_.html
     */
    function randomGaussian(RandomV1.PRNG memory prng)
        internal
        pure
        returns (int64) {
        return RandomV1.nextGaussian(prng);
    }
}