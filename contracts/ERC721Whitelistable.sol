// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721BoundedEnumerable.sol";

abstract contract ERC721Whitelistable is ERC721BoundedEnumerable, Ownable {
    mapping(address => uint256) public whitelist;

    modifier onlyMintableFree(uint256 _mintAmount) {
        address sender = _msgSender();
        require(whitelist[sender] > 0, "You are not in the whitelist");
        require(whitelist[sender] >= _mintAmount, "Exceed free mints");

        _;
        whitelist[sender] -= _mintAmount;
    }

    function setWhitelist(
        address[] memory _addresses,
        uint256[] memory _balances
    ) external onlyOwner {
        require(
            _addresses.length == _balances.length,
            "Addresses and balances have different length"
        );
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = _balances[i];
        }
    }
}
