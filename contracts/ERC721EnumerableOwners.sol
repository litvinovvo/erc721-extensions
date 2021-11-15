// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract ERC721EnumerableOwners is ERC721 {
    address[] private _allOwners;

    mapping(address => uint256) private _allOwnersIndex;

    function totalOwners() public view returns (uint256) {
        return _allOwners.length;
    }

    function ownerByIndex(uint256 index) public view returns (address) {
        require(
            index < _allOwners.length,
            "ERC721EnumerableOwners: owner index out of range"
        );
        return _allOwners[index];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (to != address(0) && balanceOf(to) == 0) {
            _addOwnerToAllOwnersEnumeration(to);
        }

        if (from != address(0) && balanceOf(from) == 1) {
            _removeOwnerFromAllOwnersEnumeration(from);
        }
    }

    function _addOwnerToAllOwnersEnumeration(address owner) private {
        _allOwnersIndex[owner] = _allOwners.length;
        _allOwners.push(owner);
    }

    function _removeOwnerFromAllOwnersEnumeration(address owner) private {
        uint256 lastOwnerIndex = _allOwners.length - 1;
        uint256 ownerIndex = _allOwnersIndex[owner];
        address lastOwner = _allOwners[lastOwnerIndex];

        _allOwners[ownerIndex] = lastOwner;
        _allOwnersIndex[lastOwner] = ownerIndex;

        delete _allOwnersIndex[owner];
        _allOwners.pop();
    }
}
