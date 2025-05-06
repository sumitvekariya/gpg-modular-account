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

/// @title MockGPGVerifier
/// @notice A mock contract that mimics the GPG verification precompile at address 0x696
/// @dev This is used for testing the GPG validation module
contract MockGPGVerifier {
    /// @notice Whether verification calls should succeed or fail
    bool private result = true;
    
    /// @notice The last message that was verified
    bytes32 public lastMessage;
    
    /// @notice The last key ID that was verified
    bytes8 public lastKeyId;
    
    /// @notice The last public key that was verified
    bytes public lastPubKey;
    
    /// @notice The last signature that was verified
    bytes public lastSignature;
    
    /// @notice Set whether verification calls should succeed or fail
    /// @param _result Whether verification calls should succeed or fail
    function setVerificationResult(bool _result) external {
        result = _result;
    }
    
    /// @notice Mock the GPG verification precompile
    /// @dev The precompile expects data in the format: abi.encode(bytes32 message, bytes8 keyId, bytes publicKey, bytes signature)
    fallback(bytes calldata data) external returns (bytes memory) {
        // Decode the input data
        (
            bytes32 message,
            bytes8 keyId,
            bytes memory pubKey,
            bytes memory signature
        ) = abi.decode(data, (bytes32, bytes8, bytes, bytes));
        
        // Store the inputs for testing
        lastMessage = message;
        lastKeyId = keyId;
        lastPubKey = pubKey;
        lastSignature = signature;
        
        // Since the GPGValidationModule._verifyGPGSignature function expects a boolean,
        // we need to return a boolean value
        return abi.encode(result);
    }
} 