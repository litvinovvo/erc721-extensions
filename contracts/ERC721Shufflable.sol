// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "./ERC721BoundedEnumerable.sol";

abstract contract ERC721Shufflable is ERC721BoundedEnumerable {
    using Strings for uint256;
    mapping(uint256 => uint256) randomMap;

    // get random NFT item
    function getRandomItemId(uint256 _index) internal returns (uint256) {
        uint256 randomHash = random("MINT", _index);
        uint256 currentSupply = maxSupply - totalSupply();
        uint256 id = (randomHash % currentSupply) + 1;
        uint256 itemId = randomMap[id] > 0 ? randomMap[id] : id;

        randomMap[id] = randomMap[currentSupply] > 0
            ? randomMap[currentSupply]
            : currentSupply;

        return itemId;
    }

    // generate pseudo random number
    function random(string memory _salt, uint256 _index)
        internal
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        _salt,
                        _index.toString(),
                        block.timestamp.toString(),
                        msg.sender
                    )
                )
            );
    }
}
