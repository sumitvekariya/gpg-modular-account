// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {console} from "forge-std/console.sol";

import {ModularAccount} from "../src/account/ModularAccount.sol";
import {GPGAccountFactory} from "../src/factory/GPGAccountFactory.sol";
import {Artifacts} from "./Artifacts.sol";
import {ScriptBase} from "./ScriptBase.sol";
import {IEntryPoint} from "@eth-infinitism/account-abstraction/interfaces/IEntryPoint.sol";

// Deploys the GPG Account Factory. This requires the following env vars to be set:
// - ENTRY_POINT
// - MODULAR_ACCOUNT_IMPL
// - GPG_VALIDATION_MODULE
// - FACTORY_OWNER
contract DeployGPGFactoryScript is ScriptBase, Artifacts {
    // State vars for expected addresses and salts.
    address public expectedGPGFactoryAddr;
    uint256 public gpgFactorySalt;

    // State vars for factory dependencies
    IEntryPoint public entryPoint;
    ModularAccount public modularAccountImpl;
    address public gpgValidationModule;
    address public factoryOwner;

    function setUp() public {
        // Load the required addresses for the factory deployment from env vars.
        entryPoint = _getEntryPoint();
        modularAccountImpl = ModularAccount(payable(_getModularAccountImpl()));
        gpgValidationModule = _getGPGValidationModule();
        factoryOwner = _getFactoryOwner();

        // Load the expected address and salt from env vars.
        expectedGPGFactoryAddr = vm.envOr("GPG_ACCOUNT_FACTORY", address(0));
        gpgFactorySalt = _getSaltOrZero("GPG_ACCOUNT_FACTORY");
    }

    function run() public onlyProfile("optimized-build-standalone") {
        console.log("******** Deploying GPG Factory *********");

        vm.startBroadcast();

        _safeDeploy(
            "GPG Account Factory",
            expectedGPGFactoryAddr,
            gpgFactorySalt,
            _getGPGAccountFactoryInitcode(
                entryPoint,
                modularAccountImpl,
                gpgValidationModule,
                factoryOwner
            ),
            _wrappedDeployGPGAccountFactory
        );

        vm.stopBroadcast();

        console.log("******** GPG Factory Deployed *********");
    }

    // Wrapper function to be called within _safeDeploy using the context in this contract.
    function _wrappedDeployGPGAccountFactory(bytes32 salt) internal returns (address) {
        _ensureNonzeroFactoryArgs();
        return _deployGPGAccountFactory(
            salt,
            entryPoint,
            modularAccountImpl,
            gpgValidationModule,
            factoryOwner
        );
    }

    function _ensureNonzeroFactoryArgs() internal view {
        bool shouldRevert;
        if (address(modularAccountImpl) == address(0)) {
            console.log("Env Variable 'MODULAR_ACCOUNT_IMPL' not found or invalid during GPG factory deployment");
            shouldRevert = true;
        } else {
            console.log("Using user-defined ModularAccount at: %x", address(modularAccountImpl));
        }

        if (gpgValidationModule == address(0)) {
            console.log(
                "Env Variable 'GPG_VALIDATION_MODULE' not found or invalid during GPG factory deployment"
            );
            shouldRevert = true;
        } else {
            console.log("Using user-defined GPGValidationModule at: %x", gpgValidationModule);
        }

        if (factoryOwner == address(0)) {
            console.log("Env Variable 'ACCOUNT_FACTORY_OWNER' not found or invalid during GPG factory deployment");
            shouldRevert = true;
        } else {
            console.log("Using user-defined factory owner at: %x", factoryOwner);
        }

        if (shouldRevert) {
            revert("Missing or invalid env variables during GPG factory deployment");
        }
    }
} 