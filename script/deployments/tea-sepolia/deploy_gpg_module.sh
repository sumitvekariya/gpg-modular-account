#!/bin/bash

# Script to deploy GPGValidationModule to Tea Sepolia testnet
# and perform related operations

# Set -e to exit on error
set -e

echo "===== Starting GPGValidationModule Deployment Process ====="

# Step 1: Generate ABI
echo "Generating ABI..."
forge inspect src/modules/validation/GPGValidationModule.sol:GPGValidationModule abi --json > GPGValidationModule.abi.json
echo "ABI generated and saved to GPGValidationModule.abi.json"

# Step 2: Flatten the contract
echo "Flattening contract..."
forge flatten src/modules/validation/GPGValidationModule.sol > GPGValidationModule_flat.sol
echo "Contract flattened and saved to GPGValidationModule_flat.sol"

# Step 3: Deploy the contract
echo "Deploying contract to Tea Sepolia..."
DEPLOY_OUTPUT=$(forge script script/deployments/tea-sepolia/Deploy.s.sol:DeployTeaSepoliaScript --rpc-url https://tea-sepolia.g.alchemy.com/public --sender 0x5767ba2FF69b38D1f0e567CdCbA8654dA213c8E0 --private-key 7da7adeae7809b927a6615494016ba27d22dfeaa5e06daa2dd2b450472bde7b4 --broadcast)

# Extract the GPGValidationModule address from the deployment output
GPG_MODULE_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep "GPGValidationModule deployed at:" | awk '{print $4}')

if [ -z "$GPG_MODULE_ADDRESS" ]; then
    echo "Failed to extract GPGValidationModule address from deployment output"
    exit 1
fi

echo "GPGValidationModule deployed at: $GPG_MODULE_ADDRESS"

# Save the address to a file for future reference
echo "$GPG_MODULE_ADDRESS" > gpg_module_address.txt
echo "Contract address saved to gpg_module_address.txt"

# Step 4: Verify the contract
echo "Verifying contract on Tea Sepolia Explorer..."
forge verify-contract "$GPG_MODULE_ADDRESS" src/modules/validation/GPGValidationModule.sol:GPGValidationModule --chain-id 10218 --verifier-url https://sepolia.tea.xyz/api --compiler-version 0.8.26 --num-of-optimizations 200 --verifier custom --evm-version paris

echo "===== GPGValidationModule Deployment Process Complete ====="
echo "Contract Address: $GPG_MODULE_ADDRESS"
echo "ABI file: GPGValidationModule.abi.json"
echo "Flattened contract: GPGValidationModule_flat.sol" 