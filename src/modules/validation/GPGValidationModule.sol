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

import {IModule} from "@erc6900/reference-implementation/interfaces/IModule.sol";
import {IValidationModule} from "@erc6900/reference-implementation/interfaces/IValidationModule.sol";
import {ReplaySafeWrapper} from "@erc6900/reference-implementation/modules/ReplaySafeWrapper.sol";
import {PackedUserOperation} from "@eth-infinitism/account-abstraction/interfaces/PackedUserOperation.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import {SignatureType} from "../../helpers/SignatureType.sol";
import {ModuleBase} from "../ModuleBase.sol";
import {console} from "forge-std/console.sol";

/// @title GPG Validation Module
/// @author Modular Account Contributors
/// @notice This validation module enables GPG signature validation using the 0x696 precompile.
/// @dev This module requires a chain that supports the GPG precompile at address 0x696
///
/// NOTE:
/// - The first byte of the signature is the SignatureType, indicating GPG or Contract Owner.
/// - Uninstallation will NOT disable all installed entity IDs of an account. It only uninstalls the
///   entity ID that is passed in. Account must remove access for each entity ID if want to disable all.
/// - This validation supports composition that other validation can relay on entities in this validation.
contract GPGValidationModule is IValidationModule, ReplaySafeWrapper, ModuleBase {
    using MessageHashUtils for bytes32;

    /// @dev Structure to store GPG public key and keyId
    struct PubKey {
        bytes8 keyId;
        bytes32 pubKeyHash; // Hash of the public key for storage efficiency
    }

    /// @dev Address of the GPG signature verification precompile
    address private constant _GPG_VERIFIER = address(0x696);

    uint256 internal constant _SIG_VALIDATION_PASSED = 0;
    uint256 internal constant _SIG_VALIDATION_FAILED = 1;

    // bytes4(keccak256("isValidSignature(bytes32,bytes)"))
    bytes4 internal constant _1271_MAGIC_VALUE = 0x1626ba7e;
    bytes4 internal constant _1271_INVALID = 0xffffffff;

    /// @notice Mapping of GPG public keys and keyIds for each account and entity
    mapping(uint32 entityId => mapping(address account => PubKey)) public gpgKeys;

    /// @notice This event is emitted when the GPG key of an account's validation changes.
    /// @param account The account whose validation key changed.
    /// @param entityId The entityId for the account and the key.
    /// @param newKeyId The new GPG keyId.
    /// @param newPubKeyHash The hash of the new GPG public key.
    /// @param previousKeyId The previous GPG keyId.
    /// @param previousPubKeyHash The hash of the previous GPG public key.
    event GPGKeyTransferred(
        address indexed account,
        uint32 indexed entityId,
        bytes8 newKeyId,
        bytes32 newPubKeyHash,
        bytes8 previousKeyId,
        bytes32 previousPubKeyHash
    ) anonymous;

    error InvalidSignatureType();
    error InvalidPubKey();
    error NotAuthorized();
    error GPGPrecompileError();

    /// @notice Transfer GPG key of the account's validation.
    /// @param entityId The entityId for the account and the key.
    /// @param keyId The GPG keyId.
    /// @param pubKey The GPG public key.
    function transferGPGKey(uint32 entityId, bytes8 keyId, bytes calldata pubKey) external {
        _transferGPGKey(entityId, keyId, pubKey);
    }

    /// @inheritdoc IModule
    function onInstall(bytes calldata data) external override {
        (uint32 entityId, bytes8 keyId, bytes memory pubKey) = abi.decode(data, (uint32, bytes8, bytes));
        _transferGPGKey(entityId, keyId, pubKey);
    }

    /// @inheritdoc IModule
    function onUninstall(bytes calldata data) external override {
        uint32 entityId = abi.decode(data, (uint32));
        _transferGPGKey(entityId, bytes8(0), "");
    }

    /// @inheritdoc IValidationModule
    function validateUserOp(uint32 entityId, PackedUserOperation calldata userOp, bytes32 userOpHash)
        external
        view
        override
        returns (uint256)
    {
        // Validate the user op signature against the GPG key
        if (userOp.signature.length < 1) {
            return _SIG_VALIDATION_FAILED;
        }

        SignatureType sigType = SignatureType(uint8(bytes1(userOp.signature)));
        if (sigType == SignatureType.GPG) {
            bytes32 messageHash = userOpHash.toEthSignedMessageHash();

            // Extract pubKey and signature from the userOp.signature
            // Format: 1 byte sigType + pubKey length + pubKey + signature
            (bytes memory pubKey, bytes memory signature) = _extractPubKeyAndSignature(userOp.signature);

            // Validate the pubKey matches the stored one
            PubKey memory storedKey = gpgKeys[entityId][userOp.sender];
            if (keccak256(pubKey) != storedKey.pubKeyHash) {
                console.log("Public key hash mismatch");
                return _SIG_VALIDATION_FAILED;
            }

            // Validate the signature using the GPG precompile library
            if (_verifyGPGSignature(messageHash, storedKey.keyId, pubKey, signature)) {
                return _SIG_VALIDATION_PASSED;
            }
        }

        return _SIG_VALIDATION_FAILED;
    }

    /// @inheritdoc IValidationModule
    function validateRuntime(
        address account,
        uint32 entityId,
        address sender,
        uint256,
        bytes calldata data,
        bytes calldata signature
    ) external view override {
        // For runtime validation, we need to be more flexible.
        // We could either:
        // 1. Require the transaction to be sent directly from an authorized signer
        // 2. Check if a valid GPG signature is provided in the data

        // For simplicity, we'll implement option 1 first
        // We could expand this later to handle GPG signatures embedded in the data

        if (signature.length > 0) {
            // If signature is provided, verify it
            SignatureType sigType = SignatureType(uint8(bytes1(signature)));
            if (sigType == SignatureType.GPG) {
                bytes32 digest = keccak256(data);
                (bytes memory pubKey, bytes memory sig) = _extractPubKeyAndSignature(signature);

                // Validate the pubKey matches the stored one
                PubKey memory storedKey = gpgKeys[entityId][account];
                if (keccak256(pubKey) != storedKey.pubKeyHash) {
                    revert NotAuthorized();
                }

                // Validate the signature using the GPG precompile library
                if (_verifyGPGSignature(digest, storedKey.keyId, pubKey, sig)) {
                    return;
                }
            }
            revert NotAuthorized();
        } else {
            // If no signature provided, the sender must be the account itself (internal call)
            if (sender != account) {
                revert NotAuthorized();
            }
        }
    }

    /// @inheritdoc IValidationModule
    function validateSignature(address account, uint32 entityId, address, bytes32 digest, bytes calldata signature)
        external
        view
        override
        returns (bytes4)
    {
        if (signature.length < 1) {
            return _1271_INVALID;
        }

        SignatureType sigType = SignatureType(uint8(bytes1(signature)));
        if (sigType == SignatureType.GPG) {
            (bytes memory pubKey, bytes memory sig) = _extractPubKeyAndSignature(signature);

            // Validate the pubKey matches the stored one
            PubKey memory storedKey = gpgKeys[entityId][account];
            if (keccak256(pubKey) != storedKey.pubKeyHash) {
                console.log("Public key hash mismatch");

                // revert with message
                revert("public key hash mismatch");
            }

            console.log("Public key hash found");

            // Validate the signature using the GPG precompile library
            if (_verifyGPGSignature(digest, storedKey.keyId, pubKey, sig)) {
                return _1271_MAGIC_VALUE;
            }
        }

        return _1271_INVALID;
    }

    // ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    // ┃    Module interface functions    ┃
    // ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

    /// @inheritdoc IModule
    function moduleId() external pure returns (string memory) {
        return "modular-account.gpg-validation-module.1.0.0";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ModuleBase, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IValidationModule).interfaceId || super.supportsInterface(interfaceId));
    }

    // ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    // ┃    Internal / Private functions    ┃
    // ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

    function _transferGPGKey(uint32 entityId, bytes8 keyId, bytes memory pubKey) internal {
        bytes32 pubKeyHash = pubKey.length > 0 ? keccak256(pubKey) : bytes32(0);

        PubKey memory previousKey = gpgKeys[entityId][msg.sender];
        gpgKeys[entityId][msg.sender] = PubKey({keyId: keyId, pubKeyHash: pubKeyHash});

        emit GPGKeyTransferred(msg.sender, entityId, keyId, pubKeyHash, previousKey.keyId, previousKey.pubKeyHash);
    }

    /// @notice Verifies a GPG signature using the precompile
    /// @param digest The message digest that was signed
    /// @param keyId The GPG keyId used for signing
    /// @param pubKey The GPG public key corresponding to the keyId
    /// @param signature The GPG signature bytes
    /// @return valid True if the signature is valid according to the precompile
    function _verifyGPGSignature(bytes32 digest, bytes8 keyId, bytes memory pubKey, bytes memory signature)
        private
        view
        returns (bool valid)
    {
        // Input for precompile: abi.encode(digest, keyId, pubKey, signature)
        bytes memory data = abi.encode(digest, keyId, pubKey, signature);

        console.logBytes(data);

        console.log("GPG VERIFY: Precompile data size:", data.length, "bytes");

        // Perform staticcall to the precompile
        (bool success, bytes memory returndata) = _GPG_VERIFIER.staticcall{gas: 100_000}(data);

        console.log("GPG VERIFY: Call success:", success);
        console.log("GPG VERIFY: Return data length:", returndata.length);

        // Check for successful call
        if (!success) {
            console.log("GPG VERIFY ERROR: Precompile call failed");
            return false;
        }

        // Empty return data means invalid signature
        if (returndata.length == 0) {
            console.log("GPG VERIFY ERROR: Empty return data");
            return false;
        }

        // Decode the boolean result
        bool result = abi.decode(returndata, (bool));
        console.log("GPG VERIFY: Verification result:", result);
        return result;
    }

    /// @dev Extracts the public key and signature from the raw signature data
    /// @param rawSignature The raw signature data (first byte is SignatureType)
    /// @return pubKey The GPG public key
    /// @return signature The GPG signature
    function _extractPubKeyAndSignature(bytes calldata rawSignature)
        internal
        pure
        returns (bytes memory pubKey, bytes memory signature)
    {
        // Skip the first byte (signature type)
        bytes calldata data = rawSignature[1:];

        // First 32 bytes contain length information for dynamic arrays
        uint256 pubKeyOffset;
        uint256 sigOffset;

        assembly {
            // Load offsets from calldata
            pubKeyOffset := calldataload(data.offset)
            sigOffset := calldataload(add(data.offset, 32))
        }

        // Safety checks for offsets
        require(pubKeyOffset <= data.length, "Invalid pubKeyOffset");
        require(sigOffset <= data.length, "Invalid sigOffset");
        require(sigOffset >= pubKeyOffset, "sigOffset must be >= pubKeyOffset");

        // Extract public key
        pubKey = data[pubKeyOffset:sigOffset];

        // Extract signature
        signature = data[sigOffset:];

        return (pubKey, signature);
    }
}
