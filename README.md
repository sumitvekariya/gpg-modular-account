# Modular Account

[![gh_ci_badge]][gh_ci_link]
[![tg_badge]][tg_link]

[gh_ci_badge]: https://github.com/alchemyplatform/modular-account/actions/workflows/test.yml/badge.svg
[gh_ci_link]: https://github.com/alchemyplatform/modular-account/actions/workflows/test.yml
[tg_badge]: https://img.shields.io/endpoint?color=neon&logo=telegram&label=chat&url=https://mogyo.ro/quart-apis/tgmembercount?chat_id=modular_account_standards
[tg_link]: https://t.me/modular_account_standards

![](./img/ma.png)

Alchemy's Modular Account is a maximally modular, upgradeable smart contract account that is compatible with [ERC-4337](https://eips.ethereum.org/EIPS/eip-4337) and [ERC-6900](https://eips.ethereum.org/EIPS/eip-6900).

> [!WARNING]  
> **This branch contains changes that are under development.** To use the latest audited version make sure to use the correct commit. The tagged versions can be found in the [releases](https://github.com/alchemyplatform/modular-account/releases).

## Overview

This repository contains:

- ERC-6900 compatible account implementations: [src/account](src/account)
- Account factories: [src/factory](src/factory)
  - Generic `AccountFactory` supporting multiple validation types
  - Dedicated `GPGAccountFactory` for GPG-key controlled accounts
- Helper contracts and libraries: [src/helpers](src/helpers), [src/libraries](src/libraries)
- ERC-6900 compatible modules: [src/modules](src/modules)
  - Validation modules:
    - [SingleSignerValidationModule](src/modules/validation/SingleSignerValidationModule.sol): Enables validation for a single signer (EOA or contract).
    - [WebAuthnValidationModule](src/modules/validation/WebAuthnValidationModule.sol): Enables validation for passkey signers.
    - [GPGValidationModule](src/modules/validation/GPGValidationModule.sol): Enables validation for GPG signatures using the `0x696` precompile.
  - Permission-enforcing hook modules:
    - [AllowlistModule](src/modules/permissions/AllowlistModule.sol): Enforces ERC-20 spend limits and address/selector allowlists.
    - [NativeTokenLimitModule](src/modules/permissions/NativeTokenLimitModule.sol): Enforces native token spend limits.
    - [PaymasterGuardModule](src/modules/permissions/PaymasterGuardModule.sol): Enforces use of a specific paymaster.
    - [TimeRangeModule](src/modules/permissions/TimeRangeModule.sol): Enforces time ranges for a given entity.

The contracts conform to these ERC versions:

- ERC-4337: [v0.7.0](https://github.com/eth-infinitism/account-abstraction/blob/releases/v0.7/erc/ERCS/erc-4337.md)
- ERC-6900: [v0.8.0](https://github.com/ethereum/ERCs/blob/c081c445424505d549e0236650917a2aaf3c5743/ERCS/erc-6900.md)

## Development

### Building and testing

```bash
# Install dependencies
forge install
pnpm install

# Build
forge build
FOUNDRY_PROFILE=optimized-build forge build --sizes

# Lint
pnpm lint

# Format
pnpm fmt

# Coverage
pnpm lcov

# Generate gas snapshots
pnpm gas

# Test
pnpm test
forge test -vvv
```

### Deployment

Deployment scripts can be found in the `scripts/` folder, and depend on reading parameters from your local environment or from `.env`. A sample for the required fields can be found at `.env.example`. Note that some have specific foundry profiles needed for deployment.

You will also need provide a wallet to use for deployment. Available options can be found [here](https://book.getfoundry.sh/reference/forge/forge-script#wallet-options---raw).

```bash
FOUNDRY_PROFILE=<profile> forge script script/<deploy_script>.s.sol --rpc-url $RPC_URL --broadcast
```

For deploying the GPG-specific factory:

```bash
FOUNDRY_PROFILE=optimized-build-standalone forge script script/DeployGPGFactory.s.sol --rpc-url $RPC_URL --broadcast
```

## Features overview

### Features

Modular Account can:

1. Deploy contracts via `CREATE` or `CREATE2`.
2. Receive ERC-721 and ERC-1155 tokens.
3. Use applications that depend on ERC-1271 contract signatures.
4. Use applications that use the ERC-165 introspection standard.
5. Be upgradeable to or from most other smart contract account implementations.
6. Be customized in many ways. All customization options can be found [here](./2-customizing-your-modular-account.md).

#### ERC-1271 contract signatures support

Certain applications such as Permit2 or Cowswap use the ERC-1271 contract signatures standard to determine if a smart contract has approved a certain action. Modular Account implements ERC-1271 to allow smart accounts to use these applications.

#### Upgradeability

When modular accounts are created from the factory, an ERC-1967 proxy contract is deployed. Users can update the implementation their proxy points to to choose which smart account implementations to use. Modular Account adheres to the ERC-7201 namespaced storage standard to prevent storage collisions when updating between different implementations.

### Customizing your Modular Account

Modular Account can be customized by:

1. Installing execution functions to add custom execution logic to run, or uninstalling to remove them
2. Installing validations to apply custom validation logic for one or all execution functions, or uninstalling to remove them
3. Installing pre validation hooks that are attached to module entities, or removing them
4. Installing execution hooks that are attached to execution functions, or removing them
5. Installing execution hooks that are attached to module entities, or removing them

#### Lifecycle of a user operation

![](./img/userop-flow.png)

#### Lifecycle of a runtime call

![](./img/runtime-flow.png)

#### Pre-validation hooks

Pre validation hooks are run before validations. Pre-validation hooks are necessary to perform gas related checks for User Operations (session key gas limits, or gas metering taking into account paymaster usage). These checks must happen in the validation phase since a validation success would allow the entrypoint to charge gas for the user operation to the account.

#### Validations

Validations are usually signature validation functions (secp256k1, BLS, WebAuthn, etc). While it's feasible to implement signature validation as a pre-validation hook, it's more efficient and ergonomic to do these in validations since it allows us to apply permissions per module entity using execution hooks. In ERC-4337, accounts can return validation data that's not 0 or 1 to signal the usage of a signature aggregator.

#### Execution hooks

Execution hooks are useful for applying permissions on execution functions to limit the set of possible actions that can be taken. Post-execution hooks are useful for checking the final state after an execution. Pre and post-execution hook pairs are useful for measuring differences in state due to an execution. For example, you could use a pre and post execution hook pair to enforce that swap outputs from a DCA swap performed by a session key fall within a some tolerance price determined by a price oracle.

Execution hooks can be associated either with a module entity to apply permissions on that specific entity, or with an execution selector on the account to apply global restrictions on the account across all entities. A example of a useful global restriction would be to block NFT transfers for NFTs in cold storage, or to apply resource locks.

#### Execution functions

Execution hooks are applied across execution functions. Modular account comes with native execution functions such as `installValidation`, `installExecution`, or `upgradeToAndCall`. However, you could customize the account by installing additional execution functions. After a new execution is installed, when the account is called with that function selector, the account would forward the call to the module associated with that installed execution. An example of a useful execution functions would be to implement callbacks for the account to be able to take flash loans.

### GPG Validation Module Usage

The `GPGValidationModule` allows accounts to be controlled by GPG keys, leveraging the `0x696` precompile for efficient signature verification on-chain.

**Requirements:**

- The chain where the account is deployed **must** support the GPG precompile at address `0x696`.

**Installation Methods:**

1. **Using the dedicated `GPGAccountFactory`**:
   ```solidity
   // Example creation of a GPG-controlled account
   GPGAccountFactory factory = GPGAccountFactory(GPG_FACTORY_ADDRESS);
   ModularAccount account = factory.createGPGAccount(
       bytes8 keyId,      // The GPG key ID (e.g., 0x1234567890ABCDEF)
       bytes memory pubKey, // The full GPG public key bytes
       uint256 salt,      // Arbitrary salt for address prediction
       uint32 entityId    // Entity ID for the validation
   );
   ```

2. **Using the standard `AccountFactory` or manually**:
   ```solidity
   // Example data encoding for installation on existing account
   bytes memory installData = abi.encode(
       uint32 entityId, // Choose an entityId for this key
       bytes8 keyId,    // The specific GPG key ID
       bytes memory pubKey // The full GPG public key bytes
   );
   account.installValidation(GPG_VALIDATION_MODULE_ADDRESS, installData);
   ```

**Signature Format:**

When submitting a `UserOperation` or calling functions requiring validation (`validateRuntime`, `validateSignature`), the signature `bytes` must be formatted as follows:

1.  **Signature Type Byte:** `0x03` (representing `SignatureType.GPG`).
2.  **ABI Encoded Public Key:** The full GPG public key, ABI-encoded as `bytes`.
3.  **ABI Encoded Signature:** The actual GPG signature, ABI-encoded as `bytes`.

**Example Signature Construction (Conceptual):**

```solidity
// Off-chain or in tests
bytes memory signatureData = abi.encodePacked(
    bytes1(uint8(SignatureType.GPG)), // 0x03
    abi.encode(fullPubKeyBytes),      // Encoded pubKey
    abi.encode(gpgSignatureBytes)     // Encoded signature
);
```

The module verifies that the hash of the provided `fullPubKeyBytes` matches the hash stored during installation before calling the precompile with the `digest`, `keyId`, `fullPubKeyBytes`, and `gpgSignatureBytes`.

### GPG Account Factory

For easier integration and deployment of accounts specifically controlled by GPG keys, this repository includes a dedicated `GPGAccountFactory`. This factory simplifies the creation of GPG-controlled accounts by:

1. Focusing only on GPG validation
2. Providing a cleaner and more specialized API
3. Reducing gas costs by eliminating unused validation modules

#### Deployment

To deploy the GPG Account Factory, you need the following environment variables:
- `ENTRY_POINT`: The EntryPoint contract address
- `MODULAR_ACCOUNT_IMPL`: The ModularAccount implementation address
- `GPG_VALIDATION_MODULE`: The deployed GPGValidationModule address
- `ACCOUNT_FACTORY_OWNER`: The owner address for the factory

```bash
FOUNDRY_PROFILE=optimized-build-standalone forge script script/DeployGPGFactory.s.sol --rpc-url $RPC_URL --broadcast
```

## Security

### Audits

Our audit reports can be found in [audits](/audits). The filenames for the reports have the format: `YYYY-MM-DD_VENDOR_FFFFFFF.pdf`, where `YYYY-MM-DD` refers to the date on which the final report was received, `VENDOR` refers to the conductor of the audit, and `FFFFFFF` refers to the short commit hash on which the audit was conducted.

### Bug bounty program

Our Modular Account bug bounty is hosted on the [Cantina](https://cantina.xyz/bounties/246de4d3-e138-4340-bdfc-fc4c95951491) platform.

### Other security considerations

This section contains other security considerations that developers should be aware of when using a Modular Account besides informational issues highlighted in the security audits.

#### Off-chain safety checks

A client should perform the following off-chain checks when interacting with a modular account:

1. When installing a validation, clients should ensure that the entity id has not been previously used in the account
2. When upgrading to a Modular Account, clients should check if the proxy used to be a Modular Account by checking the value of the `initialized` variable at the Modular Account namespaced storage slot within the proxy. If so, any `initializer` functions called would not work, and the configuration of that past Modular Account might be different from the current ownership configuration.
3. When upgrading to a Modular Account, clients should check that the account is an ERC-1967 proxy by checking the ERC-1822 `proxiableUUID` slot.
4. When installing execution function, clients should check that it does not collide with any native function selectors.
5. Clients should ensure that deferred action nonces are unique without dependencies. One possible scheme is to use unix timestamps as part of the nonce.

#### Proxy pattern and initializer functions

Initializer functions are not guarded by any access control modifier. If accounts are not used in a proxy pattern, during the account's constructor, as per Openzeppelin's implementation of `Initializable`, initializer functions are able to be reentered. This design choice can be used by an attacker to install additional validations to take over a user's account.

#### Initializer functions with EIP-7702

When using EIP-7702, the delegate destination should only be the `SemiModularAccount7702` implementation, and not any of the other account variants. Otherwise, if the delegate destination is set to an account with an unprotected initializer function, an attacker will be able to take over the account.

### Semi modular account considerations

`SemiModularAccountBytecode` (`SMABytecode`) is the cheapest account to deploy. It can only be used for new account deployment, and **should NOT** be used for account upgrades due to requiring specific proxy bytecode.

#### Deferred actions

In order for a deferred action to be run at validation, in addition to special encoding (which includes the validation to validate the deferred action itself), it must not break ERC-4337 validation-time rules. For instance, this means that any execution hooks on `installValidation` must comply with EIP-7562.

#### Signature validation flag enablement

The `isSignatureValidation` flag meant to allow a validation function to validate ERC-1271 signatures. Developer should note that for Modular Account this is a very powerful capability to grant as it allows validation functions to approve deferred actions on the account.

## Acknowledgements

The contracts in this repository adhere to the ERC-6900 specification, and are heavily influenced by the design of the ERC-6900 reference implementation.

## License

The contracts provided in this repository in [src](src) are licensed under the GNU General Public License v3.0, included in our repository in [LICENSE-GPL](LICENSE-GPL).

Alchemy Insights, Inc., 548 Market St., PMB 49099, San Francisco, CA 94104; legal@alchemy.com

# GPG Signature Verification

This script verifies GPG signatures using the Modular Account's GPGValidationModule contract deployed on the Tea Sepolia network.

## Prerequisites

- Node.js (v14 or higher)
- npm or yarn

## Setup

1. Clone this repository
2. Install dependencies:

```bash
npm install
# or
yarn install
```

## Usage

Run the verification script:

```bash
npm run verify
# or
yarn verify
```

## How It Works

The script does the following:

1. Connects to the Tea Sepolia network (chain ID 10218)
2. Formats the test GPG signature data for contract verification
3. Attempts to verify the signature using the deployed GPGValidationModule contract
4. Checks if any accounts have registered the sample key ID

## Customizing

To verify a different signature, update the following constants in `verify-gpg-signature.js`:

- `RSA_MESSAGE_HASH`: The message hash that was signed
- `RSA_KEY_ID`: The GPG key ID
- `RSA_PUBLIC_KEY`: The GPG public key
- `RSA_SIGNATURE`: The GPG signature

## Registering Your Own Key

To register your own GPG key with the contract, you'll need:

1. A funded account on the Tea Sepolia network
2. Your GPG key ID and public key

Follow the instructions printed by the script for registering your key.

## Contract Information

- Contract Address: `0xea38Dc6fFAe9221d62c2a2F5BD3AB996345Aea6b`
- Chain: Tea Sepolia (Chain ID: 10218)
- RPC URL: `https://tea-sepolia.g.alchemy.com/public`
