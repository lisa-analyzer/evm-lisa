// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;

import "../V1/ParticleV1.sol";
import "../V1/TypesV1.sol";

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

abstract contract ParticleSetV1 {
    uint16 internal constant NOISE_TABLE_SIZE = 4095;
    uint16 internal constant PARTICLE_TABLE_SIZE = 5000;

    struct ParticleSet2D {
        ParticleV1.Particle2D[5000] particles;
        bool dead;
    }
    
    function update(
        int64[NOISE_TABLE_SIZE + 1] memory noiseTable,
        ParticleSet2D memory set,
        uint16 particleCount,
        uint256 width,
        uint256 height
    ) internal pure {
        set.dead = true;
        for (uint16 i = 0; i < particleCount; i++) {
            ParticleV1.Particle2D memory p = set.particles[i];
            if (p.dead) {
                continue;
            }
            set.dead = false;
            ParticleV1.update(noiseTable, p, width, height);
        }
    }

    function draw(
        ParticleSet2D memory set,
        uint16 particleCount,
        uint32[16384] memory result,
        TypesV1.Chunk2D memory chunk
    ) internal pure {
        if (set.dead) {
            return;
        }

        for (uint256 i = 0; i < particleCount; i++) {
            ParticleV1.Particle2D memory p = set.particles[i];
            if (p.dead) {
                continue;
            }
            step(p, result, chunk);
        }
    }

    function step(
        ParticleV1.Particle2D memory p, uint32[16384] memory result,
        TypesV1.Chunk2D memory chunk
    ) internal pure virtual;
}