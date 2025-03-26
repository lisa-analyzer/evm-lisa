// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;

import "../V1/Fix64V1.sol";
import "../V1/TypesV1.sol";
import "../V1/NoiseV1.sol";
import "../V1/RandomV1.sol";
import "../V1/Trig256.sol";

/*
    A noise-based particle simulator, built for generative art that uses flow fields.

    Based on techniques in Sighack's "Getting Creative with Perlin Noise Fields":
    See: https://github.com/sighack/perlin-noise-fields
    See: https://github.com/sighack/perlin-noise-fields/blob/master/LICENSE

    THIRD PARTY NOTICES:
    ====================

    MIT License

    Copyright (c) 2018 Manohar Vanga

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/

library ParticleV1 {
    uint16 internal constant NOISE_TABLE_SIZE = 4096;

    struct Particle2D {
        int64 ox;
        int64 oy;
        int64 px;
        int64 py;
        int64 x;
        int64 y;
        uint32 frames;
        bool dead;
        TypesV1.Point2D force;
        uint8 _lifetime;
        int64 _forceScale;
        int64 _noiseScale;
    }

    function update(
        int64[NOISE_TABLE_SIZE] memory noiseTable,
        Particle2D memory p,
        uint256 width,
        uint256 height
    ) internal pure {
        p.frames++;

        if (p.frames >= p._lifetime) {
            p.dead = true;
            return;
        }

        p.force = forceAt(noiseTable, p, p.x, p.y);

        if (
            p.x >= int256(width) + int256(width) / 2 ||
            p.x < -int256(width) / 2 ||
            p.y >= int256(height) + int256(height) / 2 ||
            p.y < -int256(height) / 2
        ) {
            p.dead = true;
            return;
        }

        p.px = p.x;
        p.py = p.y;                

        p.x += int64(p.force.x);
        p.y += int64(p.force.y);        
    }

    function forceAt(
        int64[NOISE_TABLE_SIZE] memory noiseTable,
        Particle2D memory p,
        int64 x,
        int64 y
    ) internal pure returns (TypesV1.Point2D memory force) {

        int64 nx = Fix64V1.mul(x * Fix64V1.ONE, p._noiseScale);       
        int64 ny = Fix64V1.mul(y * Fix64V1.ONE, p._noiseScale);
        
        int64 noise = NoiseV1.noise(noiseTable, nx, ny);
        int64 theta = Fix64V1.mul(noise, Fix64V1.TWO_PI);

        return forceFromAngle(p, theta);
    }

    function forceFromAngle(Particle2D memory p, int64 theta)
        internal
        pure
        returns (TypesV1.Point2D memory force)
    {
        int64 px = Trig256.cos(theta);
        int64 py = Trig256.sin(theta);

        int64 pxl = Fix64V1.mul(px, p._forceScale) >> 32 /* FRACTIONAL_PLACES */;
        int64 pyl = Fix64V1.mul(py, p._forceScale) >> 32 /* FRACTIONAL_PLACES */;        
        
        force = TypesV1.Point2D(int32(pxl), int32(pyl));
    }
}