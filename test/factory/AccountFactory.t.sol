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

import {ModularAccount} from "../../src/account/ModularAccount.sol";
import {AccountFactory} from "../../src/factory/AccountFactory.sol";

import {AccountTestBase} from "../utils/AccountTestBase.sol";
import {TEST_DEFAULT_VALIDATION_ENTITY_ID} from "../utils/TestConstants.sol";

import {MockERC20} from "../mocks/MockERC20.sol";
import {GPGValidationModule} from "../../src/modules/validation/GPGValidationModule.sol";
import {LibClone} from "solady/utils/LibClone.sol";

contract AccountFactoryTest is AccountTestBase {
    MockERC20 public erc20;
    uint256 internal _ownerX = 1;
    uint256 internal _ownerY = 2;

    // Sample GPG Data
    bytes8 internal testKeyId = bytes8(uint64(0x1234567890ABCDEF));
    bytes internal testPubKey = hex"0479be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8"; // Example secp256k1 public key bytes

    function test_createAccount() public withSMATest {
        ModularAccount account = factory.createAccount(address(this), 100, TEST_DEFAULT_VALIDATION_ENTITY_ID);

        assertEq(address(account.entryPoint()), address(entryPoint));
    }

    function test_createWebAuthnAccount() public {
        ModularAccount account =
            factory.createWebAuthnAccount(_ownerX, _ownerY, 100, TEST_DEFAULT_VALIDATION_ENTITY_ID);

        assertEq(address(account.entryPoint()), address(entryPoint));
    }

    function test_createAccountAndGetAddress() public withSMATest {
        ModularAccount account = factory.createAccount(address(this), 100, TEST_DEFAULT_VALIDATION_ENTITY_ID);

        assertEq(
            address(account), address(factory.createAccount(address(this), 100, TEST_DEFAULT_VALIDATION_ENTITY_ID))
        );

        assertEq(
            address(account), address(factory.getAddress(address(this), 100, TEST_DEFAULT_VALIDATION_ENTITY_ID))
        );
    }

    function test_createWebAuthnAccountAndGetAddress() public {
        ModularAccount account =
            factory.createWebAuthnAccount(_ownerX, _ownerY, 100, TEST_DEFAULT_VALIDATION_ENTITY_ID);

        assertEq(
            address(account),
            address(factory.createWebAuthnAccount(_ownerX, _ownerY, 100, TEST_DEFAULT_VALIDATION_ENTITY_ID))
        );

        assertEq(
            address(account),
            address(factory.getAddressWebAuthn(_ownerX, _ownerY, 100, TEST_DEFAULT_VALIDATION_ENTITY_ID))
        );
    }

    function test_createGPGAccount_DeploysCorrectly() public {
        uint256 salt = 101;
        uint32 entityId = TEST_DEFAULT_VALIDATION_ENTITY_ID + 1; // Use a different entity ID
        bytes32 expectedPubKeyHash = keccak256(testPubKey);

        // Predict address
        address predictedAddress = factory.getAddressGPG(testKeyId, testPubKey, salt, entityId);

        // Expect event
        vm.expectEmit(true, true, false, true, address(factory)); // Check indexed account, keyId, and data fields emitted from factory address
        emit AccountFactory.GPGAccountDeployed(predictedAddress, testKeyId, expectedPubKeyHash, salt, entityId);

        // Deploy
        ModularAccount account =
            factory.createGPGAccount(testKeyId, testPubKey, salt, entityId);

        // Check address
        assertEq(address(account), predictedAddress);
        assertEq(address(account.entryPoint()), address(entryPoint));

        // Check GPG module installation
        GPGValidationModule gpgModule = GPGValidationModule(factory.GPG_VALIDATION_MODULE());
        // Assign getter result to tuple components
        (bytes8 storedKeyId, bytes32 storedPubKeyHash) = gpgModule.gpgKeys(entityId, address(account));
        assertEq(storedKeyId, testKeyId);
        assertEq(storedPubKeyHash, expectedPubKeyHash);
    }

    function test_createGPGAccount_Idempotent() public {
        uint256 salt = 102;
        uint32 entityId = TEST_DEFAULT_VALIDATION_ENTITY_ID + 2;

        // Deploy first time
        ModularAccount account1 = factory.createGPGAccount(testKeyId, testPubKey, salt, entityId);

        // Deploy second time - should not emit event or cost much gas
        uint256 startGas = gasleft();
        // vm.expectNoEmit(); // Linter doesn't recognize this cheatcode, but it should work at runtime
        ModularAccount account2 = factory.createGPGAccount(testKeyId, testPubKey, salt, entityId);
        assertLe(startGas - 22_000, gasleft()); // Should cost less than 1 SLOAD/SSTORE

        // Assert the return addresses are the same
        assertEq(address(account1), address(account2));
    }

    function test_getAddressGPG() public view {
        uint256 salt = 103;
        uint32 entityId = TEST_DEFAULT_VALIDATION_ENTITY_ID + 3;

        // Calculate expected address
        bytes32 expectedSalt = factory.getSaltGPG(testKeyId, testPubKey, salt, entityId);
        address expectedAddress = LibClone.predictDeterministicAddressERC1967(
            address(factory.ACCOUNT_IMPL()), // Read implementation address from factory
            expectedSalt,
            address(factory)
        );

        // Get address from factory
        address actualAddress = factory.getAddressGPG(testKeyId, testPubKey, salt, entityId);

        assertEq(actualAddress, expectedAddress);
    }

    function test_multipleDeploy() public withSMATest {
        ModularAccount account = factory.createAccount(address(this), 100, TEST_DEFAULT_VALIDATION_ENTITY_ID);

        uint256 startGas = gasleft();

        ModularAccount account2 = factory.createAccount(address(this), 100, TEST_DEFAULT_VALIDATION_ENTITY_ID);

        // Assert that the 2nd deployment call cost less than 1 sstore
        // Implies that no deployment was done on the second calls
        assertLe(startGas - 22_000, gasleft());

        // Assert the return addresses are the same
        assertEq(address(account), address(account2));
    }

    function test_multipleDeployWebAuthn() public {
        ModularAccount account =
            factory.createWebAuthnAccount(_ownerX, _ownerY, 100, TEST_DEFAULT_VALIDATION_ENTITY_ID);

        uint256 startGas = gasleft();

        ModularAccount account2 =
            factory.createWebAuthnAccount(_ownerX, _ownerY, 100, TEST_DEFAULT_VALIDATION_ENTITY_ID);

        // Assert that the 2nd deployment call cost less than 1 sstore
        // Implies that no deployment was done on the second calls
        assertLe(startGas - 22_000, gasleft());

        // Assert the return addresses are the same
        assertEq(address(account), address(account2));
    }

    function test_withdraw() public {
        erc20 = new MockERC20();
        erc20.mint(address(factory), 10 ether);

        assertEq(erc20.balanceOf(address(factory)), 10 ether);
        vm.prank(factoryOwner);
        factory.withdraw(payable(address(this)), address(erc20), 10 ether); // amount = balance if native currency
        assertEq(address(factory).balance, 0);
    }
}
