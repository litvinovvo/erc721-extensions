// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTCollection is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string private baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 10 ether;
    uint256 public maxSupply = 100;
    uint256 public maxMintAmount = 10;
    bool public paused = true;

    mapping(uint256 => uint256) randomMap;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // distribute royalties between holders
    receive() external payable {
        uint256 supply = totalSupply();
        uint256 valuePerEach = msg.value / supply;

        for (uint256 i = 0; i < supply; i++) {
            (bool status, ) = payable(this.ownerOf(this.tokenByIndex(i))).call{
                value: valuePerEach
            }("");
            require(status, "Royalty transfer failed");
        }
    }

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

    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused, "Minting didn't started yet");
        require(_mintAmount > 0, "You must mint at least one");
        require(_mintAmount <= maxMintAmount, "Max items per mint exceeded");
        require(supply < maxSupply, "All items were minted");
        require(
            supply + _mintAmount <= maxSupply,
            "Fewer items left than you trying to mint"
        );

        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount);
        }

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
        (bool status, ) = payable(owner()).call{value: address(this).balance}("");
        require(status);
    }
}
