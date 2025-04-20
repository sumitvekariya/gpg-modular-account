#!/bin/bash
# GPG Test Helper
# This script helps with testing the GPG Validation Module using real GPG signatures

# Function to print usage
print_usage() {
  echo "GPG Test Helper - Tool for testing GPG signatures with the validation module"
  echo ""
  echo "Usage:"
  echo "  $0 [command]"
  echo ""
  echo "Commands:"
  echo "  list-keys      List available GPG keys"
  echo "  sign-message   Sign a message with a GPG key"
  echo "  verify         Run the tests with the real precompile"
  echo "  help           Show this help message"
  echo ""
}

# Function to list GPG keys
list_keys() {
  echo "Listing available GPG keys:"
  echo "=========================="
  gpg --list-keys
  echo ""
  echo "Note the key ID (last 8 characters of the long hex string)"
  echo "Example: For a key showing as 'pub   ed25519 2023-01-01 [SC] ABCDEF0123456789ABCDEF0123456789ABCDEF01'"
  echo "The key ID would be: 23456789ABCDEF01"
  echo ""
}

# Function to sign a message
sign_message() {
  echo "Sign a message with GPG"
  echo "======================="
  
  # Prompt for key ID
  read -p "Enter the GPG key ID (last 8 chars of key): " KEY_ID
  
  # Prompt for the message to sign
  echo ""
  echo "Enter the message hash to sign (hex, 64 characters):"
  read MESSAGE_HASH
  
  # Validate the message hash
  if [[ ! $MESSAGE_HASH =~ ^[0-9a-fA-F]{64}$ ]]; then
    echo "Error: Invalid message hash. It should be 64 hex characters."
    return 1
  fi
  
  # Create a temporary file
  TEMP_DIR=$(mktemp -d)
  MSG_FILE="$TEMP_DIR/message.bin"
  SIG_FILE="$TEMP_DIR/signature.sig"
  
  # Convert hex message to binary
  echo $MESSAGE_HASH | xxd -r -p > $MSG_FILE
  
  # Sign the message
  echo "Signing message with key $KEY_ID..."
  if gpg --detach-sign --local-user $KEY_ID $MSG_FILE; then
    # Get signature in hex format
    HEX_SIG=$(cat $MSG_FILE.sig | xxd -p | tr -d '\n')
    
    echo ""
    echo "Signature created successfully!"
    echo ""
    echo "GPG signature in hex format (copy this to your test):"
    echo "$HEX_SIG"
    echo ""
    echo "To use this signature in the test:"
    echo "1. Set useRealPrecompile = true in the test"
    echo "2. Replace the empty hex string with the signature above:"
    echo "   bytes memory realSignature = hex\"$HEX_SIG\";"
    echo ""
  else
    echo "Error: Failed to sign the message."
  fi
  
  # Clean up
  rm -rf $TEMP_DIR
}

# Function to run the tests with the real precompile
run_verify_tests() {
  echo "Running tests with real precompile"
  echo "=================================="
  echo "Make sure you're running these tests on tea-geth!"
  echo ""
  
  # Run the forge test for the GPG module with verbosity
  cd /Users/sarkazein./Documents/Personal/Open\ Source\ Contribution/modular-account
  forge test --match-contract GPGValidationModuleTest --match-test testWithRealGPGPrecompile -vvv
}

# Main script logic
case "$1" in
  "list-keys")
    list_keys
    ;;
  "sign-message")
    sign_message
    ;;
  "verify")
    run_verify_tests
    ;;
  "help"|"")
    print_usage
    ;;
  *)
    echo "Unknown command: $1"
    print_usage
    exit 1
    ;;
esac

exit 0 