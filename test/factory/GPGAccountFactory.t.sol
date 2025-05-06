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
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LibClone} from "solady/utils/LibClone.sol";

import {ModularAccount} from "../../src/account/ModularAccount.sol";
import {GPGAccountFactory} from "../../src/factory/GPGAccountFactory.sol";
import {GPGValidationModule} from "../../src/modules/validation/GPGValidationModule.sol";
import {AccountTestBase} from "../utils/AccountTestBase.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

contract GPGAccountFactoryTest is AccountTestBase {
    bytes8 private constant TEST_KEY_ID = 0x1234567890ABCDEF;
    bytes private constant TEST_PUB_KEY = hex"04d984a555a4339d5c3c8fad4625f9d72b8466c56736fc758e36f258823e307a0da9252d303a7c69f329c569694093ec9686e450d0e5860aaa7e85c89bbadbef4f";
    uint32 private constant TEST_ENTITY_ID = 1;

    GPGAccountFactory public gpgFactory;
    address gpgFactoryOwner; // Renamed to avoid conflict

    function setUp() public override {
        super.setUp();
        
        gpgFactoryOwner = makeAddr("gpgFactoryOwner");
        vm.startPrank(gpgFactoryOwner);
        
        // Deploy a fresh GPG validation module for testing
        GPGValidationModule gpgModule = new GPGValidationModule();
        
        // Deploy the GPG account factory using variables from AccountTestBase
        gpgFactory = new GPGAccountFactory(
            entryPoint,
            ModularAccount(payable(address(accountImplementation))),
            address(gpgModule),
            gpgFactoryOwner
        );
        
        vm.stopPrank();
    }

    function test_createGPGAccount_DeploysCorrectly() public {
        uint256 salt = 100;
        
        // Get the predicted address
        address predictedAddress = gpgFactory.getAddressGPG(TEST_KEY_ID, TEST_PUB_KEY, salt, TEST_ENTITY_ID);
        
        // Verify that no code exists at the predicted address
        assertEq(predictedAddress.code.length, 0);
        
        // Deploy the account
        vm.expectEmit(true, true, false, true, address(gpgFactory));
        bytes32 pubKeyHash = keccak256(TEST_PUB_KEY);
        emit GPGAccountFactory.GPGAccountDeployed(predictedAddress, TEST_KEY_ID, pubKeyHash, salt, TEST_ENTITY_ID);
        
        ModularAccount account = gpgFactory.createGPGAccount(TEST_KEY_ID, TEST_PUB_KEY, salt, TEST_ENTITY_ID);
        
        // Verify the account was deployed correctly
        assertEq(address(account), predictedAddress);
        assertGt(predictedAddress.code.length, 0);
        
        // Verify the account has the GPG validation module installed
        GPGValidationModule gpgModule = GPGValidationModule(gpgFactory.GPG_VALIDATION_MODULE());
        
        // Verify the pubkey is stored correctly
        // Note: This test is dependent on internal storage layout of GPGValidationModule
        // We're verifying that the keyId is correctly stored for the account
        (bytes8 keyId, bytes32 storedPubKeyHash) = gpgModule.gpgKeys(TEST_ENTITY_ID, address(account));
        assertEq(keyId, TEST_KEY_ID);
        assertEq(storedPubKeyHash, pubKeyHash);
    }

    function test_createGPGAccount_Idempotent() public {
        uint256 salt = 100;
        
        // Create the account
        ModularAccount account1 = gpgFactory.createGPGAccount(TEST_KEY_ID, TEST_PUB_KEY, salt, TEST_ENTITY_ID);
        
        // Create again with the same parameters
        ModularAccount account2 = gpgFactory.createGPGAccount(TEST_KEY_ID, TEST_PUB_KEY, salt, TEST_ENTITY_ID);
        
        // Verify both calls return the same account
        assertEq(address(account1), address(account2));
    }

    function test_getAddressGPG() public {
        uint256 salt = 100;
        
        // Calculate the expected address
        bytes32 expectedSalt = gpgFactory.getSaltGPG(TEST_KEY_ID, TEST_PUB_KEY, salt, TEST_ENTITY_ID);
        
        // Use LibClone directly which is what the factory uses
        address expectedAddress = LibClone.predictDeterministicAddressERC1967(
            address(gpgFactory.ACCOUNT_IMPL()),
            expectedSalt,
            address(gpgFactory)
        );
        
        // Get address from factory
        address actualAddress = gpgFactory.getAddressGPG(TEST_KEY_ID, TEST_PUB_KEY, salt, TEST_ENTITY_ID);
        
        // Verify
        assertEq(actualAddress, expectedAddress);
    }

    function test_withdraw() public {
        // Set up test
        address recipient = makeAddr("recipient");
        uint256 amount = 10 ether;
        
        // Create an ERC20 token and mint some to the factory
        MockERC20 erc20 = new MockERC20();
        erc20.mint(address(gpgFactory), amount);
        
        // Also send ETH to factory
        vm.deal(address(gpgFactory), amount);
        
        // Verify initial state
        assertEq(erc20.balanceOf(address(gpgFactory)), amount);
        assertEq(address(gpgFactory).balance, amount);
        
        // Withdraw as non-owner - should revert
        vm.expectRevert();
        gpgFactory.withdraw(payable(recipient), address(erc20), amount);
        
        // Withdraw as owner - ERC20
        vm.prank(gpgFactoryOwner);
        gpgFactory.withdraw(payable(recipient), address(erc20), amount);
        assertEq(erc20.balanceOf(address(gpgFactory)), 0);
        assertEq(erc20.balanceOf(recipient), amount);
        
        // Withdraw as owner - ETH
        vm.prank(gpgFactoryOwner);
        gpgFactory.withdraw(payable(recipient), address(0), 0); // amount = balance if native currency
        assertEq(address(gpgFactory).balance, 0);
        assertEq(recipient.balance, amount);
    }
} 