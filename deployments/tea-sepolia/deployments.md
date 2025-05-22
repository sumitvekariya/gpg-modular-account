# Modular Account Deployment on Tea Sepolia Testnet

**Deployment Date:** On `block 2499112`

## Deployed Contract Addresses

### Validation Modules
- **GPGValidationModule**: `0xdD700e3d3122e28A47f8F06190637Be667Ef8B4D`
- **SingleSignerValidationModule**: `0x34CAFCFc973Ab30523220BE650860C3cB9eEb311`
- **WebAuthnValidationModule**: `0x1d348516289b8dcBd9F3Cf1498a3bA9D798f6eF4`

### Security Modules
- **TimeRangeModule**: `0x50f079E89cA649Ca61d48C5Ad3EbE639faC4864E`
- **AllowlistModule**: `0x12cD0b49c23e75E79bFC18BD1e7DE2322aecd934`
- **PaymasterGuardModule**: `0xC8be92A01AB25E290964e44b913638CD9089FCC9`
- **NativeTokenLimitModule**: `0x464bc3f10D154d43c7E47D4cD50A06A445630D18`

### Delegates
- **ExecutionInstallDelegate**: `0x020d902c7F0155e86122d832ac9cC49bb80137ad`

### Implementations
- **ModularAccount**: `0x1ce3E38Ab1141E3daa97C03cB77A2967cF6C8623`
- **SemiModularAccountBytecode**: `0x5168336BEe01514D2f66743C7370013dad2B2039`
- **SemiModularAccountStorageOnly**: `0x693Bf2b39632015FFA5AC24bF8E3D9401BEDf6F7`

### Factories
- **AccountFactory**: *Not redeployed in latest deployment*
- **GPGAccountFactory**: *Not redeployed in latest deployment*

### Configuration
- **EntryPoint**: `0x0000000071727De22E5E9d8BAf0edAc6f37da032`
- **Factory Owner**: `0x5767ba2FF69b38D1f0e567CdCbA8654dA213c8E0`

## Deployment Wallet
- **Address**: `0x5767ba2FF69b38D1f0e567CdCbA8654dA213c8E0`
- **Private Key**: `0x7da7adeae7809b927a6615494016ba27d22dfeaa5e06daa2dd2b450472bde7b4`

## Network Information
- **Network**: Tea Sepolia Testnet
- **Chain ID**: `10218`
- **RPC URL**: `https://tea-sepolia.g.alchemy.com/public`
- **Block Explorer**: `https://sepolia.tea.xyz`

## Deployment Results and Testing

### Latest Deployment Update
- Successfully redeployed the GPGValidationModule and other components to Tea Sepolia.
- This deployment removes the dependency on the deprecated GPGVerifierLib.
- All GPG verification is now handled directly within the GPGValidationModule contract using the 0x696 precompile.
- Transaction hash for GPGValidationModule deployment: `0x21dce1fbe20ca165647399ed070218809f727a89037b28d6fc916cc76f9dba73`

### Complete System Deployment
- Successfully deployed all Modular Account components to Tea Sepolia.
- Deployment costs were minimal on the Tea Sepolia network.

### GPG Key Registration
- Successfully registered a GPG key with the GPGValidationModule.
- Transaction hash: `0x1f8fefa601beb6582e4e6d34fee54aa882585fa75c2a367945f865eab14eb4fc`
- We've verified that the key is properly stored in the module.

### GPG Precompile Testing
- We tested interactions with the native GPG precompile at address `0x0000000000000000000000000000000000000696`.
- Initial tests showed the precompile is responding to calls.
- The precompile interface on Tea Sepolia appears to be compatible with the GPGValidationModule.

### Account Creation Status
- We attempted to create a GPG-enabled account with the GPGAccountFactory but encountered issues.
- Future work should focus on:
  1. Modifying the account factory if needed to work with Tea Sepolia
  2. Completing the full GPG verification flow using real GPG keys

## Next Steps

1. Resolve GPGAccountFactory issues to create GPG-enabled smart accounts
2. Test the complete user operation flow with GPG signatures
3. Develop documentation for users to interact with the deployed system
4. Update the scripts in the repo to use the new module implementation

## Tools Created

1. **DeployTeaSepolia.s.sol**: Script to deploy the entire Modular Account system
2. **deploy_gpg_module.sh**: Script to deploy just the GPGValidationModule
3. **verify-gpg-signature.js**: JavaScript script to test GPG signature verification
4. **test_gpg_precompile.js**: JavaScript test for the GPG precompile (requires ethers.js)

## Previous Deployments

### Deployment on block 2351803
Here's a summary of the previously deployed contracts:
- GPGValidationModule: 0xea38Dc6fFAe9221d62c2a2F5BD3AB996345Aea6b
- SingleSignerValidationModule: 0xF772A6f7541aB4e390637a281007A3461A9811D6
- WebAuthnValidationModule: 0x22714F96631DfdDc67AD92551EA7d8a2681D677C
- ModularAccount implementation: 0x82C33A04cfB438F715f12082Da85058ca5BadEE1
- AccountFactory: 0x95b0844628f8a36493515Df8352173A228462b02
- GPGAccountFactory: 0x1d7267ade690aDC34367f51DB087dE9e5fb0ce57