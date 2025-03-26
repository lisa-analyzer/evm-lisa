// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import "../utils/SpookyAuth.sol";

contract MagicatRarity is SpookyAuth {
    mapping (uint => uint) public rarityOf;

    bool maySetRarities = true;

    function setRarities(uint[] memory rarities, uint256 offset) public onlyAdmin {
        require(maySetRarities);
        uint len = rarities.length;
        for(uint i = 0; i < len; i++)
            rarityOf[i + offset] = rarities[i];
    }

    function relinquishSetRarity() public onlyAdmin {
        maySetRarities = false;
    }

    function rarityOfBatch(uint[] memory tokenIDs) public view returns (uint[] memory rarities) {
        uint len = tokenIDs.length;
        rarities = new uint[](len);
        for(uint i = 0; i < len; i++)
            rarities[i] = rarityOf[tokenIDs[i]];
    }

    function sumOfRarities(uint[] memory tokenIDs) public view returns (uint sum) {
        uint len = tokenIDs.length;
        sum = 0;
        for(uint i = 0; i < len; i++)
            sum += rarityOf[tokenIDs[i]];
    }
}