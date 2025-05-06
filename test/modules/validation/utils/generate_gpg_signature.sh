#!/bin/bash

# This script generates a GPG signature for a given message hash
# Usage: ./generate_gpg_signature.sh <message_hash> <key_id>
# Example: ./generate_gpg_signature.sh 28d6c6d977f27bbef776b90957ecc9d7ad8d68ba5c9c8bf71a3994495d8ec190 35734EBD

MESSAGE_HASH=$1
KEY_ID=$2

if [ -z "$MESSAGE_HASH" ] || [ -z "$KEY_ID" ]; then
    echo "Usage: ./generate_gpg_signature.sh <message_hash> <key_id>"
    echo "Example: ./generate_gpg_signature.sh 28d6c6d977f27bbef776b90957ecc9d7ad8d68ba5c9c8bf71a3994495d8ec190 35734EBD"
    exit 1
fi

# Create a temporary directory
TMP_DIR=$(mktemp -d)
cd $TMP_DIR

# Convert the hex message hash to binary
echo $MESSAGE_HASH | xxd -r -p > message.bin

# Sign the message
gpg --detach-sign --armor --local-user $KEY_ID message.bin

# Export the public key
gpg --export --armor $KEY_ID > pubkey.asc
gpg --export $KEY_ID > pubkey.bin

# Convert the signature to hex
SIG_HEX=$(cat message.bin.asc | gpg --dearmor | xxd -p | tr -d '\n')

# Convert the public key to hex
PUBKEY_HEX=$(cat pubkey.bin | xxd -p | tr -d '\n')

# Get the key ID bytes (last 8 bytes) from the key fingerprint
KEY_ID_BYTES=$(gpg --list-keys --with-colons $KEY_ID | grep "fpr" | head -1 | cut -d: -f10 | tail -c 17)

echo "=== Message Hash ==="
echo "$MESSAGE_HASH"

echo "=== Key ID Bytes (for Solidity) ==="
echo "hex\"$KEY_ID_BYTES\""

echo "=== Public Key (for Solidity) ==="
echo "hex\"$PUBKEY_HEX\""

echo "=== Signature (for Solidity) ==="
echo "hex\"$SIG_HEX\""

echo "=== Test Code Snippet ==="
echo "// Message hash"
echo "bytes32 constant MESSAGE_HASH = 0x$MESSAGE_HASH;"
echo ""
echo "// Key ID (last 8 bytes)"
echo "bytes8 constant KEY_ID = hex\"$KEY_ID_BYTES\";"
echo ""
echo "// Public key"
echo "bytes constant PUBLIC_KEY = hex\"$PUBKEY_HEX\";"
echo ""
echo "// Signature"
echo "bytes constant SIGNATURE = hex\"$SIG_HEX\";"

# Clean up
cd - > /dev/null
rm -rf $TMP_DIR

echo ""
echo "Generated successfully!" 