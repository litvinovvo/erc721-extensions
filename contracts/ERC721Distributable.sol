// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721EnumerableOwners.sol";

abstract contract ERC721Distributable is
    ERC721Enumerable,
    ERC721EnumerableOwners,
    Ownable
{
    mapping(address => bool) public noRoyalties;
    address[] public noRoyaltiesArray;

    function setNoRoyalties(address[] memory _list) external onlyOwner {
        for (uint256 i = 0; i < noRoyaltiesArray.length; i++) {
            delete noRoyalties[noRoyaltiesArray[i]];
        }
        noRoyaltiesArray = _list;
        for (uint256 i = 0; i < noRoyaltiesArray.length; i++) {
            noRoyalties[noRoyaltiesArray[i]] = true;
        }
    }

    receive() external payable {
        uint256 extraSupply;
        for (uint256 j = 0; j < noRoyaltiesArray.length; j++) {
            extraSupply += balanceOf(noRoyaltiesArray[j]);
        }

        uint256 supply = totalSupply();
        uint256 valuePerEach = msg.value / (supply - extraSupply);

        for (uint256 i = 0; i < totalOwners(); i++) {
            address owner = ownerByIndex(i);
            if (noRoyalties[owner]) continue;
            (bool status, ) = payable(owner).call{
                value: valuePerEach * balanceOf(owner)
            }("");
            require(status, "Royalty transfer failed");
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC721Enumerable, ERC721EnumerableOwners) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
