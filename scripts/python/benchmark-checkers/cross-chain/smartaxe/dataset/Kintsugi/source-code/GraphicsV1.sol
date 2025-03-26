// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;

library GraphicsV1 {
    
    function setPixel(
        uint32[16384 /* 128 * 128 */] memory result,
        uint256 width,
        int256 x,
        int256 y,
        uint32 color
    ) internal pure {
        uint256 p = uint256(int256(width) * y + x);
        result[p] = blend(result[p], color);
    }

    function blend(uint32 bg, uint32 fg) internal pure returns (uint32) {
        uint32 r1 = bg >> 16;
        uint32 g1 = bg >> 8;
        uint32 b1 = bg;
        
        uint32 a2 = fg >> 24;
        uint32 r2 = fg >> 16;
        uint32 g2 = fg >> 8;
        uint32 b2 = fg;
        
        uint32 alpha = (a2 & 0xFF) + 1;
        uint32 inverseAlpha = 257 - alpha;

        uint32 r = (alpha * (r2 & 0xFF) + inverseAlpha * (r1 & 0xFF)) >> 8;
        uint32 g = (alpha * (g2 & 0xFF) + inverseAlpha * (g1 & 0xFF)) >> 8;
        uint32 b = (alpha * (b2 & 0xFF) + inverseAlpha * (b1 & 0xFF)) >> 8;

        uint32 rgb = 0;
        rgb |= uint32(0xFF) << 24;
        rgb |= r << 16;
        rgb |= g << 8;
        rgb |= b;

        return rgb;
    }

    function setOpacity(uint32 color, uint32 opacity) internal pure returns (uint32) {

        require(opacity > 0 && opacity <= 255, "opacity must be between 0 and 255");
        
        uint32 r = color >> 16 & 0xFF;
        uint32 g = color >> 8 & 0xFF;
        uint32 b = color & 0xFF;

        uint32 rgb = 0;
        rgb |= opacity << 24;
        rgb |= r << 16;
        rgb |= g << 8;
        rgb |= b;

        return uint32(rgb);     
    }
}