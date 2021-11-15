// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./ERC721Shufflable.sol";
import "./ERC721Distributable.sol";
import "./ERC721Whitelistable.sol";

contract NFTCollection is
    ERC721Distributable,
    ERC721Shufflable,
    ERC721Whitelistable,
    ERC721Burnable
{
    using Strings for uint256;

    string private baseURI;
    string private baseExtension = ".json";
    uint256 public cost = 10 ether;
    uint256 public maxMintAmount = 10;
    bool public paused = true;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        uint256 _maxSupply
    ) ERC721(_name, _symbol) ERC721BoundedEnumerable(_maxSupply) {
        setBaseURI(_initBaseURI);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC721, ERC721Enumerable, ERC721Distributable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, ERC721Distributable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    modifier onlyMintable(uint256 _mintAmount) {
        uint256 supply = totalSupply();
        require(!paused, "Minting didn't started yet");
        require(_mintAmount > 0, "You must mint at least one");
        require(_mintAmount <= maxMintAmount, "Max items per mint exceeded");
        require(supply < maxSupply, "All items were minted");
        require(
            supply + _mintAmount <= maxSupply,
            "Fewer items left than you trying to mint"
        );
        _;
    }

    function freeMint(uint256 _mintAmount)
        public
        onlyMintable(_mintAmount)
        onlyMintableFree(_mintAmount)
    {
        // address sender = _msgSender();
        // require(whiteList[sender] > 0, "You are not in the whitelist");
        // require(whiteList[sender] >= _mintAmount, "Exceed free mints");

        mintMany(_mintAmount);
        // whiteList[sender] -= _mintAmount;
    }

    function mint(uint256 _mintAmount)
        public
        payable
        onlyMintable(_mintAmount)
    {
        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount);
        }

        mintMany(_mintAmount);
    }

    function mintMany(uint256 _mintAmount) private {
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, getRandomItemId(i));
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function start() public onlyOwner {
        paused = false;
    }

    function pause() public onlyOwner {
        paused = true;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function withdraw() public payable onlyOwner {
        (bool status, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(status);
    }
}
