# What is the repository?
This is repository with experimental ERC721 composable extensions.

Available contracts/extensions:
1. ERC721BoundedEnumerable: OpenZeppelin Enumerable extension with limited supply
2. ERC721EnumerableOwners: Maintain unique owners list
3. ERC721Distributable: Royalty distribution between owners, you could set ignore list for marketplaces
4. ERC721Shufflable: Mint pseudo randomization
5. ERC721Whitelistable: Whitelist for free mints
6. NFTCollection: Example contract that combines all of the extensions 

**Code never been audited, use it on your own risk**

# Setup
1. Run npm i

2. Create .env config file, template:

        TESTNET_PRIVATE_KEY="REPLACE WITH YOUR PRIVATE KEY"
        TESTNET="REPLACE WITH YOUR RPC"

        MAINNET_PRIVATE_KEY="REPLACE WITH YOUR PRIVATE KEY"
        MAINNET="REPLACE WITH YOUR RPC"

        NFT_NAME="REPLACE WITH YOUR NAME"
        NFT_SYMBOL="REPLACE WITH YOUR SYMBOL"
        NFT_BASE_URI="REPLACE WITH YOUR BASE URI"
        NFT_MAX_SUPPLY=100

4. Run compile and any other commands from package.json/scripts