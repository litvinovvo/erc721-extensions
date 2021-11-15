// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

abstract contract ERC721BoundedEnumerable is ERC721Enumerable {
    uint256 public maxSupply;

    constructor(uint256 _maxSupply) {
        maxSupply = _maxSupply;
    }
}
