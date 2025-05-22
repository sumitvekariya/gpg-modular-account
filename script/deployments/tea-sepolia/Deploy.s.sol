// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {console} from "forge-std/console.sol";

import {ModularAccount} from "../../../src/account/ModularAccount.sol";
import {SemiModularAccountBytecode} from "../../../src/account/SemiModularAccountBytecode.sol";
import {SemiModularAccountStorageOnly} from "../../../src/account/SemiModularAccountStorageOnly.sol";
import {GPGValidationModule} from "../../../src/modules/validation/GPGValidationModule.sol";
import {SingleSignerValidationModule} from "../../../src/modules/validation/SingleSignerValidationModule.sol";
import {WebAuthnValidationModule} from "../../../src/modules/validation/WebAuthnValidationModule.sol";
import {ExecutionInstallDelegate} from "../../../src/helpers/ExecutionInstallDelegate.sol";
import {NativeTokenLimitModule} from "../../../src/modules/permissions/NativeTokenLimitModule.sol";
import {AllowlistModule} from "../../../src/modules/permissions/AllowlistModule.sol";
import {PaymasterGuardModule} from "../../../src/modules/permissions/PaymasterGuardModule.sol";
import {TimeRangeModule} from "../../../src/modules/permissions/TimeRangeModule.sol";
import {Artifacts} from "../../Artifacts.sol";
import {ScriptBase} from "../../ScriptBase.sol";
import {IEntryPoint} from "@eth-infinitism/account-abstraction/interfaces/IEntryPoint.sol";

/**
 * @title DeployTeaSepoliaScript
 * @notice This script deploys the entire Modular Account system to the Tea Sepolia testnet
 * @dev Run using: forge script script/deployments/tea-sepolia/Deploy.s.sol:DeployTeaSepoliaScript --rpc-url https://tea-sepolia.g.alchemy.com/public --broadcast
 */
contract DeployTeaSepoliaScript is ScriptBase, Artifacts {
    // The ERC-4337 EntryPoint contract address
    address constant ENTRY_POINT = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;
    
    // Deployed contract addresses - these will be filled during deployment
    address public executionInstallDelegate;
    address public singleSignerValidationModule;
    address public webAuthnValidationModule;
    address public gpgValidationModule;
    address public timeRangeModule;
    address public allowlistModule;
    address public paymasterGuardModule;
    address public nativeTokenLimitModule;
    
    address public modularAccountImpl;
    address public semiModularAccountBytecodeImpl;
    address public semiModularAccountStorageOnlyImpl;
    
    address public accountFactory;
    address public gpgAccountFactory;
    
    // The address that will own the factory
    address public factoryOwner;
    
    function setUp() public {
        // Get factory owner from the caller
        factoryOwner = msg.sender;
        console.log("Factory owner will be:", factoryOwner);
    }
    
    function run() public {
        console.log("******** Deploying to Tea Sepolia Testnet ********");
        console.log("Chain ID:", block.chainid);
        console.log("EntryPoint at:", ENTRY_POINT);
        
        vm.startBroadcast();
        
        // Step 1: Deploy all validation modules and other standalone contracts
        deployStandalones();
        
        // Step 2: Deploy the implementations
        deployImplementations();
        
        // Step 3: Deploy the factories
        deployFactories();
        
        vm.stopBroadcast();
        
        // Print final deployment summary
        printDeploymentSummary();
    }
    
    function deployStandalones() internal {
        console.log("******** Deploying Validation Modules ********");
        
        // Deploy GPGValidationModule
        gpgValidationModule = address(new GPGValidationModule());
        console.log("GPGValidationModule deployed at:", gpgValidationModule);
        
        // Deploy SingleSignerValidationModule
        singleSignerValidationModule = address(new SingleSignerValidationModule());
        console.log("SingleSignerValidationModule deployed at:", singleSignerValidationModule);
        
        // Deploy WebAuthnValidationModule
        webAuthnValidationModule = address(new WebAuthnValidationModule());
        console.log("WebAuthnValidationModule deployed at:", webAuthnValidationModule);
        
        // Deploy ExecutionInstallDelegate
        executionInstallDelegate = address(new ExecutionInstallDelegate());
        console.log("ExecutionInstallDelegate deployed at:", executionInstallDelegate);
        
        // Deploy security modules
        timeRangeModule = address(new TimeRangeModule());
        console.log("TimeRangeModule deployed at:", timeRangeModule);
        
        allowlistModule = address(new AllowlistModule());
        console.log("AllowlistModule deployed at:", allowlistModule);
        
        paymasterGuardModule = address(new PaymasterGuardModule());
        console.log("PaymasterGuardModule deployed at:", paymasterGuardModule);
        
        nativeTokenLimitModule = address(new NativeTokenLimitModule());
        console.log("NativeTokenLimitModule deployed at:", nativeTokenLimitModule);
        
        console.log("******** All Standalone Modules Deployed ********");
    }
    
    function deployImplementations() internal {
        console.log("******** Deploying Account Implementations ********");
        
        // Deploy ModularAccount implementation
        modularAccountImpl = address(new ModularAccount(IEntryPoint(ENTRY_POINT), ExecutionInstallDelegate(executionInstallDelegate)));
        console.log("ModularAccount implementation deployed at:", modularAccountImpl);
        
        // Deploy SemiModularAccountBytecode implementation
        semiModularAccountBytecodeImpl = address(new SemiModularAccountBytecode(IEntryPoint(ENTRY_POINT), ExecutionInstallDelegate(executionInstallDelegate)));
        console.log("SemiModularAccountBytecode implementation deployed at:", semiModularAccountBytecodeImpl);
        
        // Deploy SemiModularAccountStorageOnly implementation
        semiModularAccountStorageOnlyImpl = address(new SemiModularAccountStorageOnly(IEntryPoint(ENTRY_POINT), ExecutionInstallDelegate(executionInstallDelegate)));
        console.log("SemiModularAccountStorageOnly implementation deployed at:", semiModularAccountStorageOnlyImpl);
        
        console.log("******** All Implementations Deployed ********");
    }
    
    function deployFactories() internal {
        console.log("******** Deploying Account Factories ********");
        
        // Deploy the main account factory
        accountFactory = _deployAccountFactory(
            bytes32(uint256(1)), // Salt for deterministic deployment
            IEntryPoint(ENTRY_POINT),
            ModularAccount(payable(modularAccountImpl)),
            SemiModularAccountBytecode(payable(semiModularAccountBytecodeImpl)),
            singleSignerValidationModule,
            webAuthnValidationModule,
            gpgValidationModule,
            factoryOwner
        );
        console.log("AccountFactory deployed at:", accountFactory);
        
        // Deploy the GPG-specific account factory
        gpgAccountFactory = _deployGPGAccountFactory(
            bytes32(uint256(1)), // Salt for deterministic deployment
            IEntryPoint(ENTRY_POINT),
            ModularAccount(payable(modularAccountImpl)),
            gpgValidationModule,
            factoryOwner
        );
        console.log("GPGAccountFactory deployed at:", gpgAccountFactory);
        
        console.log("******** All Factories Deployed ********");
    }
    
    function printDeploymentSummary() internal view {
        console.log("");
        console.log("******** Tea Sepolia Deployment Summary ********");
        console.log("Chain ID:", block.chainid);
        console.log("");
        console.log("---- Validation Modules ----");
        console.log("GPGValidationModule:", gpgValidationModule);
        console.log("SingleSignerValidationModule:", singleSignerValidationModule);
        console.log("WebAuthnValidationModule:", webAuthnValidationModule);
        console.log("");
        console.log("---- Security Modules ----");
        console.log("TimeRangeModule:", timeRangeModule);
        console.log("AllowlistModule:", allowlistModule);
        console.log("PaymasterGuardModule:", paymasterGuardModule);
        console.log("NativeTokenLimitModule:", nativeTokenLimitModule);
        console.log("");
        console.log("---- Delegates ----");
        console.log("ExecutionInstallDelegate:", executionInstallDelegate);
        console.log("");
        console.log("---- Implementations ----");
        console.log("ModularAccount:", modularAccountImpl);
        console.log("SemiModularAccountBytecode:", semiModularAccountBytecodeImpl);
        console.log("SemiModularAccountStorageOnly:", semiModularAccountStorageOnlyImpl);
        console.log("");
        console.log("---- Factories ----");
        console.log("AccountFactory:", accountFactory);
        console.log("GPGAccountFactory:", gpgAccountFactory);
        console.log("");
        console.log("---- Configuration ----");
        console.log("EntryPoint:", ENTRY_POINT);
        console.log("Factory Owner:", factoryOwner);
        console.log("");
        console.log("******** Deployment Complete ********");
    }
} 