// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.26;

/**
 * @title GPG Verifier Library
 * @author Modular Account Contributors
 * @notice Provides functionality to interact with the GPG signature verification precompile at 0x696.
 */
library GPGVerifierLib {
    /// @dev Address of the GPG signature verification precompile
    address internal constant _GPG_VERIFIER = address(0x696);

    /// @notice Verifies a GPG signature using the precompile
    /// @param digest The message digest that was signed
    /// @param keyId The GPG keyId used for signing
    /// @param pubKey The GPG public key corresponding to the keyId
    /// @param signature The GPG signature bytes
    /// @return valid True if the signature is valid according to the precompile
    function verifyGPGSignature(bytes32 digest, bytes8 keyId, bytes memory pubKey, bytes memory signature)
        internal
        view
        returns (bool valid)
    {
        // Input for precompile: abi.encode(digest, keyId, pubKey, signature)
        bytes memory data = abi.encode(digest, keyId, pubKey, signature);
        
        // Perform staticcall to the precompile
        (bool success, bytes memory returndata) = _GPG_VERIFIER.staticcall(data);
        
        // Check for successful call and correct return data length (expecting a single bool -> 32 bytes)
        if (!success || returndata.length != 32) {
            return false;
        }
        
        // Decode the boolean result
        return abi.decode(returndata, (bool));
    }
} 