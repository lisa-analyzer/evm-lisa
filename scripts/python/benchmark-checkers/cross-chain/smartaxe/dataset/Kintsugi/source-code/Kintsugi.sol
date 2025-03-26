// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;

import "../../V1/ProcessingV1.sol";
import "../../V1/IRenderer.sol";
import "../../V1/IAttributes.sol";
import "./Layers/HatchLayer.sol";
import "./Layers/WatercolorLayer.sol";
import "./Layers/KintsugiLayer.sol";
import "./Draw/HatchDraw.sol";
import "./Draw/KintsugiDraw.sol";
import "./Draw/WatercolorDraw.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract Kintsugi is IRenderer, IAttributes {

    using Address for address;

    address private _owner;
    address private _executor;

    constructor(address executor) {
        require(executor.isContract(), "invalid executor");
        _owner = msg.sender;
        _executor = executor;
    }

    function changeExecutor(address newExecutor) public {
        require(msg.sender == _owner, "owner only");
        require(newExecutor != address(0x0), "address must be set");
        _executor = newExecutor;        
    }

    function getAttributes(int32 seed)
        external
        view
        override        
        returns (string memory result)
    {
        require(msg.sender == _owner || msg.sender == _executor, "denied");
        require(seed != 0, "seed not specified");
        
        RandomV1.PRNG memory prng = RandomV1.buildSeedTable(seed);
        
        result = string(abi.encodePacked('{"attributes":['));

        {
            (HatchLayer.HatchParameters memory h) = HatchLayer.getParameters(prng);                        
            prng = h.prng;

            result = string(abi.encodePacked(result, '{"trait_type":"hatch_color","value":"'));
            result = string(abi.encodePacked(result, getColorName(h.color)));
            result = string(abi.encodePacked(result, '"},'));
        }

        {
            (WatercolorLayer.WatercolorParameters memory w) = WatercolorLayer.getParameters(prng);
            prng = w.prng;
            
            result = string(abi.encodePacked(result, '{"trait_type":"watercolor_count","value":"'));
            result = string(abi.encodePacked(result, Strings.toString(w.stackCount)));  
            result = string(abi.encodePacked(result, '"},'));

            for(uint8 i = 0; i < w.stackCount; i++) {
                result = string(abi.encodePacked(result, '{"trait_type":"watercolor_', Strings.toString(i + 1), '_color","value":"'));
                result = string(abi.encodePacked(result, getColorName(w.stackColors[i])));
                result = string(abi.encodePacked(result, '"},'));
            }
        }

        {
            (KintsugiLayer.KintsugiParameters memory k, RandomV1.PRNG memory p) = KintsugiLayer.getParameters(prng, seed);
            prng = p;       
            
            result = string(abi.encodePacked(result, '{"trait_type":"kintsugi_layers","value":"'));
            result = string(abi.encodePacked(result, Strings.toString(k.layers)));
            result = string(abi.encodePacked(result, '"}'));
        }

        return string(abi.encodePacked(result, ']}'));
    }

    function getColorName(uint32 color) private pure returns(string memory colorName) {

        color = GraphicsV1.setOpacity(color, 255);

        if(color == 0xFF0088DC) {
            return string(abi.encodePacked('Blue Cola'));    
        } else if(color == 0xFFB31942) {
            colorName = string(abi.encodePacked('American Red'));    
        } else if(color == 0xFFEB618F) {
            colorName = string(abi.encodePacked('Pastel Rose'));    
        } else if(color == 0xFF6A0F8E) {
            colorName = string(abi.encodePacked('Vivid Purple'));    
        } else if(color == 0xFF4FBF26) {
            colorName = string(abi.encodePacked('Perfect Green'));    
        } else if(color == 0xFF6F4E37) {
            colorName = string(abi.encodePacked('Coffee'));    
        } else if(color == 0xFFFF9966) {
            colorName = string(abi.encodePacked('Atomic Tangerine'));    
        } else if(color == 0xFFBED9DB) {
            colorName = string(abi.encodePacked('Phosphate Turquoise'));    
        } else if(color == 0xFF998E80) {
            colorName = string(abi.encodePacked('Hankey Brown'));    
        } else if(color == 0xFFFFB884) {
            colorName = string(abi.encodePacked('Coral Gold'));    
        } else if(color == 0xFF2E4347) {
            colorName = string(abi.encodePacked('Metallic Gray'));    
        } else if(color == 0xFF0A837F) {
            colorName = string(abi.encodePacked('Green Hills'));    
        } else if(color == 0xFF076461) {
            colorName = string(abi.encodePacked('Evening Green Hills'));    
        } else if(color == 0xFF394240) {
            colorName = string(abi.encodePacked('Private Black'));    
        } else if(color == 0xFFFAF4B1) {
            colorName = string(abi.encodePacked('Yellow Moon'));    
        } else if(color == 0xFFFFFFFF) {
            colorName = string(abi.encodePacked('White'));    
        } else {
            colorName = string(abi.encodePacked('Unknown'));    
        } 
    }

    function render(IRenderer.RenderArgs memory args)
        external
        view
        override
        returns (IRenderer.RenderArgs memory results)
    {
        require(msg.sender == _owner || msg.sender == _executor, "denied");
        require(args.index != -1, "rendering is finished");
        require(args.index >= 0 && args.index < 64, "index must be in range 0-63");
        require(args.stage >= 0 && args.stage < 104, "stage must be in range 0-103");
        require(args.seed != 0, "seed not specified");

        RandomV1.PRNG memory prng = RandomV1.buildSeedTable(args.seed);

        HatchLayer.HatchParameters memory hatch;
        {           
            (HatchLayer.HatchParameters memory h) = HatchLayer.getParameters(prng);
            hatch = h;
            prng = h.prng;
        }

        WatercolorLayer.WatercolorParameters memory watercolors;
        {
            (WatercolorLayer.WatercolorParameters memory w) = WatercolorLayer.getParameters(prng);
            watercolors = w;
            prng = w.prng;
        }

        KintsugiLayer.KintsugiParameters memory kintsugi;
        {
            (KintsugiLayer.KintsugiParameters memory k, RandomV1.PRNG memory p) = KintsugiLayer.getParameters(prng, args.seed);
            kintsugi = k;
            prng = p;
        }        

        if(args.stage == 0)
        {
            return background_stage(args);
        }
        else if(args.stage == 1)
        {
            return hatch_stage(hatch, prng, args);
        }
        else if(args.stage > 1 && args.stage < 103)
        {
            return watercolor_stage(watercolors, args.prng, args);
        }       
        else if(args.stage == 103)
        {
            return kintsugi_stage(kintsugi, args);
        } 
        else {
            revert("invalid render arguments");
        }        
    }

    function background_stage(IRenderer.RenderArgs memory args) private pure returns (IRenderer.RenderArgs memory results) {
        ProcessingV1.background(
            args.buffer,
            0xFF3B4248,
            TypesV1.Chunk2D(
                uint16(args.index),
                1024,
                1024,
                128,
                128,
                (uint16(args.index) % 8) * 128,
                (uint16(args.index) / 8) * 128
            )
        );
        return IRenderer.RenderArgs(args.index, args.stage + 1, args.seed, args.buffer, args.prng);
    }

    function hatch_stage(HatchLayer.HatchParameters memory hatch, RandomV1.PRNG memory prng, RenderArgs memory args) private pure returns (IRenderer.RenderArgs memory results) {

        require(hatch.opacity > 0, "opacity not set");
        require(hatch.spacing > 0, "spacing not set");
        require(hatch.color > 0, "color not set");
        
        uint32[16384] memory buffer = HatchDraw.draw(HatchDraw.Draw(
            args.buffer,
            hatch,
            TypesV1.Chunk2D(
                uint16(args.index),
                1024,
                1024,
                128,
                128,
                (uint16(args.index) % 8) * 128,
                (uint16(args.index) / 8) * 128
            ))
        );

        return IRenderer.RenderArgs(args.index, args.stage + 1, args.seed, buffer, prng);
    }

    function watercolor_stage(WatercolorLayer.WatercolorParameters memory watercolors, RandomV1.PRNG memory prng, IRenderer.RenderArgs memory args) private pure returns (IRenderer.RenderArgs memory results) {
        require(watercolors.stackCount > 0, "stackCount not set");
        require(watercolors.stackColors.length > 0, "stackColors not set");
                
        WatercolorLayer.StackList memory stackList;
        {
            (WatercolorLayer.StackList memory s) = WatercolorLayer.buildStackList(prng, watercolors);                        
            stackList = s;
            prng = s.prng;
        }    

        uint32[16384] memory buffer = WatercolorDraw.draw(
            WatercolorDraw.Draw(
                args.buffer,
                watercolors,
                stackList,
                TypesV1.Chunk2D(
                    uint16(args.index),
                    1024,
                    1024,
                    128,
                    128,
                    (uint16(args.index) % 8) * 128,
                    (uint16(args.index) / 8) * 128
                )
            )
        );

        return IRenderer.RenderArgs(args.index, args.stage + 1, args.seed, buffer, prng);
    }

    function kintsugi_stage(KintsugiLayer.KintsugiParameters memory kintsugi, IRenderer.RenderArgs memory args)
        private pure returns (IRenderer.RenderArgs memory results) {
        
        require(kintsugi.layers > 0, "layers not set");

        int64[4096] memory noiseTable = NoiseV1.buildNoiseTable(args.seed);
        
        uint32[16384] memory buffer = KintsugiDraw.draw(KintsugiDraw.Draw(
            args.buffer,
            kintsugi,
            noiseTable,
            TypesV1.Chunk2D(
                uint16(args.index),
                1024,
                1024,
                128,
                128,
                (uint16(args.index) % 8) * 128,
                (uint16(args.index) / 8) * 128
            ))
        );

        return IRenderer.RenderArgs(args.index == 63 ? -1 : args.index + 1, 0, args.seed, buffer, args.prng);
    }
}