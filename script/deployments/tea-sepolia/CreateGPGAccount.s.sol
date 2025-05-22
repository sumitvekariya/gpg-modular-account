// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.26;

import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {GPGValidationModule} from "../../../src/modules/validation/GPGValidationModule.sol";
import {ModularAccount} from "../../../src/account/ModularAccount.sol";
import {IEntryPoint} from "@eth-infinitism/account-abstraction/interfaces/IEntryPoint.sol";

// Define the interface for the factory
interface IGPGAccountFactory {
    function createAccount(bytes32 salt, uint32 entityId) external returns (address);
}

/**
 * @title CreateGPGAccountScript
 * @notice This script creates a new GPG-enabled account using the deployed GPGAccountFactory
 * @dev Run with: 
 *      forge script script/deployments/tea-sepolia/CreateGPGAccount.s.sol:CreateGPGAccountScript --rpc-url https://tea-sepolia.g.alchemy.com/public --private-key YOUR_PRIVATE_KEY --broadcast
 */
contract CreateGPGAccountScript is Script {
    // Deployed contract addresses from Tea Sepolia
    address constant GPG_ACCOUNT_FACTORY = 0x1d7267ade690aDC34367f51DB087dE9e5fb0ce57;
    address constant GPG_VALIDATION_MODULE = 0xea38Dc6fFAe9221d62c2a2F5BD3AB996345Aea6b;
    
    // Your GPG key information - REPLACE THESE WITH YOUR ACTUAL GPG KEY INFO
    bytes8 constant GPG_KEY_ID = hex"35734EBD"; // Replace with your GPG key ID
    bytes constant GPG_PUBLIC_KEY = hex"99010d0467fca8e7010800dbd9bbc23a0cac0c8a5bbdaba8a7516898e4b9ba783fe3d44a630e5e8dcc3999d1a67d0993568fd7d9daa0de5c0f5c31db4cc47da8b0cc2fe78b68d52a3a37c45bef19ef493c5d54de762df2c33a3fb4bda047f9c00ea1ade4c21f67d8e50eb2c53fb9aad90cbff27ba9b9f5ff22d3ee08c2de73b6198a0cd5a0d6dddd387aa0f5c309288d7c4c034ca2b15da6c1b5caafa63c29f9010a2b8c2fa1d48fcb3d5bb1119b04e6748a0a56f6feeecefd1f7ed5a8ced3cf869a66abce51ecad8eda17c19a8fbad8d0fa4e77a1de8cb2895b9c54fd0fa17a10b85a466d94b9f06fea8f4ee73cb90d5bab6b28ccde1304642c0da9dc21d61e6a1e2bf9d1e3c07580e3faf4d3ec9cd69f5e3cab7d6a95e74bf28849e61c65d0c04d06cf53671e1c3a146f9a0dce0ec14bfbfb1aa9cafc5bc0fb8c6c9bb1c98fb26c0e81c3af3dfc8e32bafdf8d99cefeaa3f2c4c4eebb85da0cc4a06b8e33e0ecafbe23b4d76ad22e2fdc97b0e5be2aef6f88d107a3d6d40df4e0faf11fb7543c18fd4a9236d11b3a656fa11b06a66a8fb10811eab0ff6ef2ea60bf7d7ba56a3f5115cdf140fa69fe0d2467a9eaa9c83b69d5a5bca0c34cd5e79bc4f99ce2fbfa7bc2f9ba50e28a2f25eedcfb73c71c13a4b1d3cc42ecc5dba6e2b1a73b7b8a7a2f4e9fe1dd2e4a6f1b3cd7421b4f00ce4a79eb13afb44fb52b0de5de2df362c7dc67fd7f0be1ef29d80ffb29bfd78f45d36abc4a6b84611f030800010200f8d425cb26b89f135dd04fdc9f87f83635734ebdda120295923ce6dee7f31461253c6836c87b5cc6b321005b0002010801"; // Replace with your GPG public key
    
    // Entity ID for the GPG validation (usually 1)
    uint32 constant ENTITY_ID = 1;
    
    // Salt for the create2 - change this if you want to deploy multiple accounts
    bytes32 constant SALT = bytes32(uint256(1));
    
    function setUp() public {}
    
    function run() public {
        console.log("Starting GPG Account creation process");
        console.logBytes8(GPG_KEY_ID);
        
        vm.startBroadcast();
        
        // Step 1: First, we'll import the GPG key into the validation module
        GPGValidationModule gpgModule = GPGValidationModule(GPG_VALIDATION_MODULE);
        gpgModule.transferGPGKey(ENTITY_ID, GPG_KEY_ID, GPG_PUBLIC_KEY);
        console.log("GPG Key transferred to validation module");
        
        // Step 2: Create the account using the factory
        IGPGAccountFactory factory = IGPGAccountFactory(GPG_ACCOUNT_FACTORY);
        address accountAddress = factory.createAccount(SALT, ENTITY_ID);
        
        console.log("GPG-enabled account created at:", accountAddress);
        
        vm.stopBroadcast();
        
        console.log("Next steps:");
        console.log("1. Fund your new account with some Tea Sepolia ETH");
        console.log("2. Use your GPG key to sign transactions from this account");
    }
} 