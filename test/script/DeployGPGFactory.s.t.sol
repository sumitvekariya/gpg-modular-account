// This file is part of Modular Account.
//
// Copyright 2024 Alchemy Insights, Inc.
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General
// Public License as published by the Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the
// implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
// more details.
//
// You should have received a copy of the GNU General Public License along with this program. If not, see
// <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {ModularAccount} from "../../src/account/ModularAccount.sol";
import {GPGAccountFactory} from "../../src/factory/GPGAccountFactory.sol";
import {GPGValidationModule} from "../../src/modules/validation/GPGValidationModule.sol";
import {DeployGPGFactoryScript} from "../../script/DeployGPGFactory.s.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {IEntryPoint} from "@eth-infinitism/account-abstraction/interfaces/IEntryPoint.sol";

contract DeployGPGFactoryTest is Test {
    address public entryPoint;
    address public modularAccountImpl;
    address public gpgValidationModule;
    address public factoryOwner;
    address public expectedGPGFactory;

    function setUp() public {
        entryPoint = makeAddr("EntryPoint");
        modularAccountImpl = makeAddr("ModularAccountImpl");
        gpgValidationModule = makeAddr("GPG Validation Module");
        factoryOwner = makeAddr("Factory Owner");
        
        // Predict the factory address
        bytes memory initCode = abi.encodePacked(
            type(GPGAccountFactory).creationCode,
            abi.encode(
                entryPoint,
                modularAccountImpl,
                gpgValidationModule,
                factoryOwner
            )
        );
        
        // Calculate the CREATE2 address
        expectedGPGFactory = Create2.computeAddress(bytes32(0), keccak256(initCode), address(0x4e59b44847b379578588920cA78FbF26c0B4956C));

        // Set environment variables
        vm.setEnv("ENTRYPOINT", vm.toString(entryPoint));
        vm.setEnv("MODULAR_ACCOUNT_IMPL", vm.toString(modularAccountImpl));
        vm.setEnv("GPG_VALIDATION_MODULE", vm.toString(gpgValidationModule));
        vm.setEnv("ACCOUNT_FACTORY_OWNER", vm.toString(factoryOwner));
        vm.setEnv("GPG_ACCOUNT_FACTORY", vm.toString(expectedGPGFactory));
        vm.setEnv("FOUNDRY_PROFILE", "optimized-build-standalone");
    }

    function test_deployGPGFactoryScript() public {
        DeployGPGFactoryScript script = new DeployGPGFactoryScript();
        
        // Need to setup script first to load env variables
        script.setUp();
        
        // Make these assertions to confirm env variables were correctly loaded
        assertEq(address(script.entryPoint()), entryPoint);
        assertEq(address(script.modularAccountImpl()), modularAccountImpl);
        assertEq(script.gpgValidationModule(), gpgValidationModule);
        assertEq(script.factoryOwner(), factoryOwner);
        assertEq(script.expectedGPGFactoryAddr(), expectedGPGFactory);
        
        // Mock bytecode for all external contracts
        vm.etch(entryPoint, bytes("EntryPoint"));
        vm.etch(modularAccountImpl, bytes("ModularAccountImpl"));
        vm.etch(gpgValidationModule, bytes("GPGValidationModule"));
        
        // Create a CREATE2 factory (matches the one used in Artifacts.sol)
        address create2Factory = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
        vm.etch(create2Factory, bytes("CREATE2Factory"));
        
        // Create a mock implementation of the CREATE2 factory
        vm.mockCall(
            create2Factory,
            abi.encodeWithSignature("deploy(bytes,bytes32)"),
            abi.encode(expectedGPGFactory)
        );
        
        // Mock the existence of the expected factory address
        vm.etch(expectedGPGFactory, bytes("GPGAccountFactory"));
        
        // Run the script
        script.run();
    }
} 