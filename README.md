# What is the repository?
This is repository with experimental NFT contract template based on HardHat.

Contract features:
1. Mint process randomization
2. Royalty distribution between owners

**Contracts never been audited, use it on your own risk**

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

4. Run compile and any other commands from package.json/scripts