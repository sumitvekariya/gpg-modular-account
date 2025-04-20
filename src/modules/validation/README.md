# Validation Modules

Validation modules are responsible for authorizing operations on a modular account. This directory contains the following validation modules:

- **SingleSignerValidationModule**: Enables ECDSA signature validation with secp256k1 keys (standard Ethereum EOA validation)
- **WebAuthnValidationModule**: Enables passkey (WebAuthn) signature validation for better security
- **GPGValidationModule**: Enables GPG signature validation using the GPG precompile at address `0x696`

## GPG Validation Module

The GPG Validation Module allows users to validate UserOperations and transactions using GPG keys. This module leverages the GPG precompile at address `0x696` which is available in tea-geth.

### Features

- Validate signatures using GPG keys
- Support for key rotation/transfer
- Compatible with ERC-1271 signature validation
- Works with ERC-4337 UserOperations

### Testing with Real GPG Signatures

To test the GPG validation module with real GPG signatures, you need to:

1. Run a [tea-geth](https://github.com/tgethconsortium/tea-geth) node with the GPG precompile enabled:
   ```
   git clone https://github.com/tgethconsortium/tea-geth.git
   cd tea-geth
   make geth
   ./build/bin/geth --dev --http --http.api eth,web3,net,debug,personal --http.corsdomain "*" --http.addr 0.0.0.0 --nodiscover --allow-insecure-unlock
   ```

2. Use the provided script to generate GPG signatures for testing:
   ```
   cd test/modules/validation/utils
   chmod +x generate_gpg_signature.sh
   ./generate_gpg_signature.sh <message_hash> <key_id>
   ```

3. Run the GPG validation tests using Forge:
   ```
   forge test --match-pattern "testWithRealGPGSignature" -vv
   ```

### Integrating with your Account

To use this module with your Modular Account:

1. Install the module in your account:
   ```solidity
   // Create the installation data
   // entityId = Unique ID for this signing entity
   // keyId = 8-byte GPG key ID
   // pubKey = Exported GPG public key bytes
   bytes memory installData = abi.encode(entityId, keyId, pubKey);
   
   // Install the module
   IAccount(accountAddress).installModule(
       address(gpgValidationModule),
       installData
   );
   ```

2. Sign transactions with your GPG key:
   ```
   # 1. Obtain the message hash to sign
   # 2. Use GPG to sign the hash
   gpg --detach-sign --armor --local-user <key_id> messagehash.bin
   
   # 3. Format the signature for use with the module
   # The signature format is:
   # [1 byte signature type (0x01 for GPG)] + abi.encode(pubKey, signature)
   ```

3. Use the signature in your UserOperation or transaction.

### Requirements

- The GPG Validation Module requires a chain that supports the GPG precompile at address `0x696`, such as a tea-geth node.
- You need to have access to a GPG key and its corresponding public key.

### Installation

To install the GPG Validation Module on your modular account:

```solidity
// Example: Install the GPG validation module with a specific GPG key
bytes8 gpgKeyId = 0x49CEB217B43F2378;
bytes memory gpgPublicKey = 0x...; // Your full GPG public key
uint32 entityId = 1; // Entity ID for this validation

// Encode the installation data
bytes memory installData = abi.encode(entityId, gpgKeyId, gpgPublicKey);

// Install the module
address gpgValidationModule = address(new GPGValidationModule());
account.installModule(gpgValidationModule, installData);
```

### Usage

#### Creating Valid Signatures

To create a valid signature for the GPG validation module:

1. Generate a message hash to sign (this will depend on the specific operation)
2. Sign the message hash with your GPG key using either:
   - Command line: `echo "MESSAGE_HASH_HEX" | xxd -r -p | gpg --detach-sign -a --local-user KEY_ID`
   - Or using GPG API in your preferred programming language
3. Format the signature for the validation module:
   ```solidity
   // Signature format: SignatureType + encoded pubKey and signature
   bytes memory signature = abi.encodePacked(
       uint8(SignatureType.GPG),
       abi.encode(gpgPublicKey, gpgSignature)
   );
   ```

#### Verifying Signatures

The module has three main validation functions:

1. `validateUserOp`: Validates UserOperations for ERC-4337 account abstraction
2. `validateRuntime`: Validates runtime calls to the account
3. `validateSignature`: Validates signatures for ERC-1271 compatibility

Each function checks that:
- The signature has the correct format
- The GPG public key matches the stored one
- The signature is valid according to the GPG precompile

### Testing with Real GPG Keys

A helper script is provided to test with real GPG keys. Run it from the project root:

```bash
./script/gpg-test-helper.sh list-keys     # List your available GPG keys
./script/gpg-test-helper.sh sign-message  # Sign a message with a GPG key
./script/gpg-test-helper.sh verify        # Run tests with the real precompile
```

### Security Considerations

- The GPG public key is stored as a hash to save storage costs. The full key must be provided when verifying signatures.
- GPG verification is done by the precompile at address `0x696`. Make sure you're using a chain that supports this precompile.
- The first byte of the signature indicates the signature type and must be `0x02` for GPG signatures.

### Module ID

The module ID for the GPG validation module is: `modular-account.gpg-validation-module.1.0.0` 