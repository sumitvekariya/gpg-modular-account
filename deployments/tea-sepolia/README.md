# Modular Account Deployment on Tea Sepolia Testnet

This guide explains how to deploy the Modular Account system to the Tea Sepolia testnet, which has native support for GPG signatures through precompiles.

## Network Information

- **Network Name**: Tea Sepolia
- **Chain ID**: 10218
- **Public RPC URL**: https://tea-sepolia.g.alchemy.com/public
- **Block Explorer**: https://sepolia.tea.xyz
- **Faucet**: https://faucet-sepolia.tea.xyz/

## Prerequisites

1. Install Foundry if you haven't already:
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. Have a wallet with Tea Sepolia ETH (use the faucet link above)

## Deployment Steps

### 1. Clone the Repository

```bash
git clone https://github.com/alchemyplatform/modular-account.git
cd modular-account
```

### 2. Build the Project

```bash
forge build
```

### 3. Deploy to Tea Sepolia Testnet

We've created a custom script that handles deployment of all the Modular Account components in one go:

```bash
forge script script/DeployTeaSepolia.s.sol:DeployTeaSepoliaScript --rpc-url https://tea-sepolia.g.alchemy.com/public --private-key YOUR_PRIVATE_KEY --broadcast --verify
```

Replace `YOUR_PRIVATE_KEY` with your actual private key. The `--verify` flag is optional since Tea Sepolia may not have verification support yet.

### 4. Creating Accounts

After deployment, you can create GPG-enabled smart accounts using the GPGAccountFactory. Here's how:

1. Note the deployed GPGAccountFactory address from the deployment output.
2. Import your GPG key into the contract using the `transferGPGKey` function.
3. Create an account specifying your GPG key ID.

## Using the GPG Validation Module

The GPGValidationModule allows Ethereum accounts to verify signatures created with GPG/PGP keys. 

### Key Features:

1. **Native GPG Support**: Tea Sepolia includes a native GPG verification precompile at address `0x0000000000000000000000000000000000000696`.
2. **Easy to Use**: Import a GPG public key, then use your existing GPG tooling to sign messages.
3. **Multiple Key Types**: Supports various GPG key types including RSA and ED25519.

### Example Workflow:

1. Import a GPG public key with `transferGPGKey`
2. Sign a message with your private GPG key
3. Submit the signature for on-chain verification

## Contract Addresses

After deployment, the script will output all deployed contract addresses. The key addresses to note are:

- GPGValidationModule
- AccountFactory
- GPGAccountFactory 

These addresses will be needed when interacting with the system.

## Notes on Tea Sepolia's GPG Precompile

When testing on Tea Sepolia, the GPG precompile returns `0xffffffff` for successful verifications instead of the standard ERC-1271 magic value (`0x1626ba7e`). Our contracts handle this difference automatically. 