const { ethers } = require('ethers');
const openpgp = require('openpgp');

// Contract information
// const CONTRACT_ADDRESS = '0x11744B41E952D18c61DF11838891748c4746E3c8';
// const CONTRACT_ADDRESS = '0xea38Dc6fFAe9221d62c2a2F5BD3AB996345Aea6b';
const CONTRACT_ADDRESS = '0xdD700e3d3122e28A47f8F06190637Be667Ef8B4D'; // Newly deployed contract with debugging
const RPC_URL = 'https://tea-sepolia.g.alchemy.com/public';
// const RPC_URL = 'http://localhost:8545';

const CHAIN_ID = 10218;


// ED25519 test data for Amit's key
const ED_MESSAGE_HASH = '0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
const ED_KEY_ID = '0x24E607DC5F8E5900';
const ED_PUBLIC_KEY = '0x983304682ef7c316092b06010401da470f01010740375a4fda304ee4658fcabd5ec6aabf8fb16d04855d207d14cdb5748be58ef7c2b415616d6974203c616d697440676d61696c2e636f6d3e88930413160a003b1621041d9c50a52d0e4620f92b1fff24e607dc5f8e59000502682ef7c3021b03050b0908070202220206150a09080b020416020301021e07021780000a091024e607dc5f8e590061f600ff5bf52aed87fd040176485f6be17da14dbde8d9b44524b9b0955c6ad7941cdb6a0100f2fd1773dd909236e12985051edc4b541a57e6e175f6f931bc4e4560690d1303';
const ED_SIGNATURE = '0x88750400160a001d1621041d9c50a52d0e4620f92b1fff24e607dc5f8e59000502682efa4e000a091024e607dc5f8e5900e1fb01008235239b95b61b0637fa3b39ea1a183a784fc2f96070ab8172574aade666a8950100b79b2efac27eba1994e6c24c74372f96d8748e15428dfeb7121cc14728f3910b';

// New RSA test data for Chamath's key
const RSA_MESSAGE_HASH = '0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
const RSA_KEY_ID = '0x9A491995D6A56B6F';
const RSA_PUBLIC_KEY = '0x99018d04682ef8f6010c00a7dc6370354038a06c8b6b2b9f51604b05a42192e36c4e71cda6b78153d76a1463d3faded73fbed1081f9e90362913c70b8504aa70140e835d6f43b740c800ab30bd202ef8621464619ba73bc47f035e8a41950e7d7bc37389b344da7813ff2b41e1b984c782077972e1389e5d59175bec530dee337a83f73af54eee234daad36d9d9035b7edd18961b173413bf383b4d7bf5b33c5c6a808cc9525810d19fa924385741c564ac0fb92aa479bef7ba75409e254dbbe93621ffc06c9b9c06f8041b9c8c38764a13e026ff2d0b056d17f462dfa7587545d8cb1a301fceb84df3b9a22775936d02daeeded021e4a7c4013fec29d552430dccf9c18bf69899439e3b6fb22bc2cee4c30d4a011ff53606dbe9b910f99d19e64c020aa1083a9d616d88b8f2700b1ef9918d462884e3e5b43f177ef6bc5e84548e83c6b02ebad478eb4136f806932fbf9af0140bc7e3153e8f958e16f1f1bc0833cc709e746e344f057f77832b72d245dde38fdb13f726b366d1c60a558a8c21d335bb9ab41b1e4a5ffab0011010001b41b6368616d617468203c6368616d61746840676d61696c2e636f6d3e8901d104130108003b162104c8c8fae2f14558c0bdb713309a491995d6a56b6f0502682ef8f6021b03050b0908070202220206150a09080b020416020301021e07021780000a09109a491995d6a56b6f76970bff60f484f2e7ea77a9885f4fa3381b07f4235c1d2d14190c53871e7373e90a0ee2060d641880047cf25f5fa816f7a7975c1c34cca04f8e734c063ea543be3d48ebbb0412dfa79de57559e5750cfa128de0abbcd7acfe8cb0833308e156b420f0b944c30aff1490038955d4b3e1eb71dfe4950e4989d30b256f29a824109f90b60cf8728050bdd08017627aff0f7080f7afd55ec8786dcc608d3f68f87be343bbac350391325def37141502260b82a7cccf6112d3235474a3f68fe94b64e718af72c9167f8af6f12f5c5cb0d79aebc74600c810cc803e84e835627376696b94b3461c977400b3a4441f166e2a6cc377b5502a0f66ba4742692c4630f5f1776786e5999ddca56ca4cef09c7001dfe566b34bb55804043bf4840c96518306a191bf31ce78a0be8ba64fe33450389d14cc97e93b5390aabbab0c676a8567215d97ef65dc11c2d3fe648dc4ca4f913a4430c0e6a9b57ca5442f74df8b94a7c5cb666fa17f777e741a3510bba23aa33a7d935aca3e08861ec23147722252707f85a335c3';
const RSA_SIGNATURE = '0x8901b304000108001d162104c8c8fae2f14558c0bdb713309a491995d6a56b6f0502682efa71000a09109a491995d6a56b6f695e0c009e3561a619473370b6ed4de93ca9f9fead91611266185036a2a640b023df7bb4c3039678d61a10fe736c26ef3037fa059ac0e411572c6d2cf1cd8ff8536784851e7d8ee7998df2a8359cfdc0380db598b1acb66347a11868d61e11e8902dd482491f80f2e24c9b3d2b64c6c6b0be586c79a43f451516b93b989f9746827b1448ca1347674001c59ec52a12bcd2a43c51142ec9504d6be4910e20e4d79751e3211aca3955531a8fac889e31a74d12d4c340b756dcb7403a2a114704091fb6175da2f7a8bc62b938ab10363c856432c84d1952337b8dc3058feedcf7b12873bddc8aef7adf8bfd5decd604b8ff92668a7996e0f1926a4edeaab2796fa438b13b81edfd3dd0fa61a509fd82e06d902f0a4c2759b1f95fa197f7761a0015ee8d927049f23612314c69e5a68d397fc82ddaec001011f1b24a4f4413f46177f8bc4b89ccf9255914e6bd3c7b77fbffb166bba50557406625a4cd3fbf120c81231afd80eabb70081a53f98b5c58eb13b57db871a208e8495b6310f0aa8c3adda21e6a94';

// ABI for GPGValidationModule contract
const CONTRACT_ABI = [
  {
    "type": "function",
    "name": "_verifyGPGSignature",
    "inputs": [
      {
        "name": "digest",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "keyId",
        "type": "bytes8",
        "internalType": "bytes8"
      },
      {
        "name": "pubKey",
        "type": "bytes",
        "internalType": "bytes"
      },
      {
        "name": "signature",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [
      {
        "name": "valid",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "gpgKeys",
    "inputs": [
      {
        "name": "entityId",
        "type": "uint32",
        "internalType": "uint32"
      },
      {
        "name": "account",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [
      {
        "name": "keyId",
        "type": "bytes8",
        "internalType": "bytes8"
      },
      {
        "name": "pubKeyHash",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "moduleId",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "string",
        "internalType": "string"
      }
    ],
    "stateMutability": "pure"
  },
  {
    "type": "function",
    "name": "onInstall",
    "inputs": [
      {
        "name": "data",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "onUninstall",
    "inputs": [
      {
        "name": "data",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "replaySafeHash",
    "inputs": [
      {
        "name": "account",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "hash",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "supportsInterface",
    "inputs": [
      {
        "name": "interfaceId",
        "type": "bytes4",
        "internalType": "bytes4"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "transferGPGKey",
    "inputs": [
      {
        "name": "entityId",
        "type": "uint32",
        "internalType": "uint32"
      },
      {
        "name": "keyId",
        "type": "bytes8",
        "internalType": "bytes8"
      },
      {
        "name": "pubKey",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "validateRuntime",
    "inputs": [
      {
        "name": "account",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "entityId",
        "type": "uint32",
        "internalType": "uint32"
      },
      {
        "name": "sender",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "data",
        "type": "bytes",
        "internalType": "bytes"
      },
      {
        "name": "signature",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "validateSignature",
    "inputs": [
      {
        "name": "account",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "entityId",
        "type": "uint32",
        "internalType": "uint32"
      },
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "digest",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "signature",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bytes4",
        "internalType": "bytes4"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "validateUserOp",
    "inputs": [
      {
        "name": "entityId",
        "type": "uint32",
        "internalType": "uint32"
      },
      {
        "name": "userOp",
        "type": "tuple",
        "internalType": "struct PackedUserOperation",
        "components": [
          {
            "name": "sender",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "nonce",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "initCode",
            "type": "bytes",
            "internalType": "bytes"
          },
          {
            "name": "callData",
            "type": "bytes",
            "internalType": "bytes"
          },
          {
            "name": "accountGasLimits",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "preVerificationGas",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "gasFees",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "paymasterAndData",
            "type": "bytes",
            "internalType": "bytes"
          },
          {
            "name": "signature",
            "type": "bytes",
            "internalType": "bytes"
          }
        ]
      },
      {
        "name": "userOpHash",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "event",
    "name": "GPGKeyTransferred",
    "inputs": [
      {
        "name": "account",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "entityId",
        "type": "uint32",
        "indexed": true,
        "internalType": "uint32"
      },
      {
        "name": "newKeyId",
        "type": "bytes8",
        "indexed": false,
        "internalType": "bytes8"
      },
      {
        "name": "newPubKeyHash",
        "type": "bytes32",
        "indexed": false,
        "internalType": "bytes32"
      },
      {
        "name": "previousKeyId",
        "type": "bytes8",
        "indexed": false,
        "internalType": "bytes8"
      },
      {
        "name": "previousPubKeyHash",
        "type": "bytes32",
        "indexed": false,
        "internalType": "bytes32"
      }
    ],
    "anonymous": true
  },
  {
    "type": "error",
    "name": "GPGPrecompileError",
    "inputs": []
  },
  {
    "type": "error",
    "name": "InvalidPubKey",
    "inputs": []
  },
  {
    "type": "error",
    "name": "InvalidSignatureType",
    "inputs": []
  },
  {
    "type": "error",
    "name": "NotAuthorized",
    "inputs": []
  },
  {
    "type": "error",
    "name": "NotImplemented",
    "inputs": []
  },
  {
    "type": "error",
    "name": "UnexpectedDataPassed",
    "inputs": []
  }
]




// SignatureType enum values from the contract
const SignatureType = {
  GPG: 2
};

// Valid magic value from ERC-1271
const MAGIC_VALUE = '0x1626ba7e';
const INVALID_VALUE = '0xffffffff';

// Helper function to create raw signature data similar to the Solidity test
function createRawSignatureData(pubKey, signature) {
  // Ensure we have bytes data
  const pubKeyBytes = ethers.getBytes(pubKey);
  const signatureBytes = ethers.getBytes(signature);

  // Calculate offsets: first 64 bytes are the offsets (2 * 32 bytes)
  const pubKeyOffset = 64;
  const sigOffset = pubKeyOffset + pubKeyBytes.length;

  // Create the final data structure with explicit offsets and data
  // This matches the Solidity test implementation exactly
  return ethers.concat([
    ethers.zeroPadValue(ethers.toBeHex(pubKeyOffset), 32),  // Offset to pubKey
    ethers.zeroPadValue(ethers.toBeHex(sigOffset), 32),     // Offset to signature
    pubKey,                                                  // Public key data
    signature                                                // Signature data
  ]);
}

async function main() {
  try {
    // Connect to the network
    const provider = new ethers.JsonRpcProvider(RPC_URL);
    console.log(`Connected to network with chainId: ${(await provider.getNetwork()).chainId}`);

    // Create a contract instance
    const contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, provider);

    // Use a sample wallet for testing
    const wallet = new ethers.Wallet("7da7adeae7809b927a6615494016ba27d22dfeaa5e06daa2dd2b450472bde7b4").connect(provider);
    console.log(`Using test wallet address: ${wallet.address}`);

    // Step 1: Set up the entity ID
    const entityId = 1; // Example entity ID

    // Test with new RSA key (Chamath's key)
    console.log("\n==== Testing with New RSA Key (Chamath) ====");
    await testKey(contract, wallet, provider, entityId, RSA_KEY_ID, RSA_PUBLIC_KEY, RSA_MESSAGE_HASH, RSA_SIGNATURE);

    // Test with new ED25519 key (Amit's key)
    console.log("\n==== Testing with New ED25519 Key (Amit) ====");
    await testKey(contract, wallet, provider, entityId, ED_KEY_ID, ED_PUBLIC_KEY, ED_MESSAGE_HASH, ED_SIGNATURE);

    console.log('\nScript execution complete.');

  } catch (error) {
    console.error('Error:', error);
  }
}

// Extracted test function to avoid code duplication
async function testKey(contract, wallet, provider, entityId, keyId, pubKey, messageHash, signature) {
  try {
    // Step 2: Convert Key ID to bytes8
    const keyIdBytes = keyId.startsWith('0x') ? keyId : `0x${keyId}`;

    // Step 3: Format the signature properly for the contract
    // Format: [SignatureType (1 byte)] + [encoded pubKey and signature]
    // Following the pattern in the test file: abi.encodePacked(bytes1(uint8(SignatureType.GPG)), _createRawSignatureData(...))
    const sigTypeByte = ethers.toBeHex(SignatureType.GPG, 1).slice(2); // Convert to 1 byte and remove 0x prefix
    const rawSignatureData = createRawSignatureData(pubKey, signature).slice(2); // Remove 0x prefix

    // Complete signature = SignatureType byte + raw signature data
    const formattedSignature = `0x${sigTypeByte}${rawSignatureData}`;

    console.log('\nFormatted signature for contract verification:');
    console.log(`SignatureType: ${SignatureType.GPG} (0x${sigTypeByte})`);
    console.log(`Public Key Length: ${ethers.getBytes(pubKey).length} bytes`);
    console.log(`Signature Length: ${ethers.getBytes(signature).length} bytes`);
    console.log(`Public key hash: ${ethers.keccak256(pubKey)}`);
    console.log(`Stored key hash: ${(await contract.gpgKeys(entityId, wallet.address))[1]}`);

    // For validateSignature, use the exact same format as for direct verification
    const validateSignatureFormat = formattedSignature;

    console.log('\nAttempting direct validation...');
    try {
      // Check if the key is already registered
      const keyInfo = await contract.gpgKeys(entityId, wallet.address);
      console.log(`Key info for account ${wallet.address}:`, {
        keyId: keyInfo[0],
        pubKeyHash: keyInfo[1]
      });

      if (keyInfo[0].toLowerCase() === keyIdBytes.toLowerCase()) {
        console.log(`✅ Key ID ${keyId} is registered for account ${wallet.address}`);
      } else {
        console.log(`❌ Key ID ${keyId} is not registered for account ${wallet.address}`);

        // Check if we have funds to register
        const balance = await provider.getBalance(wallet.address);
        console.log(`Account balance: ${ethers.formatEther(balance)} ETH`);

        // Try to register the key if we have funds
        if (balance > 0) {
          const contractWithSigner = contract.connect(wallet);

          try {
            console.log('Attempting to register the key...');
            const tx = await contractWithSigner.transferGPGKey(
              entityId,
              keyIdBytes,
              pubKey
            );

            console.log('Transaction sent:', tx.hash);
            await tx.wait();
            console.log('Key registered successfully!');
          } catch (error) {
            console.log('Error registering key:', error.message);
          }
        } else {
          console.log('Not enough funds to register key. Skipping registration.');
        }
      }

      // Directly call _verifyGPGSignature
      console.log('\nTrying to call _verifyGPGSignature directly...');
      try {
        // Get the key info to use the correct public key hash
        const keyInfo = await contract.gpgKeys(entityId, wallet.address);
        console.log('Key info:', {
          keyId: keyInfo[0],
          pubKeyHash: keyInfo[1],
        });

        // Calculate hash of public key for comparison
        const calculatedPubKeyHash = ethers.keccak256(pubKey);
        console.log(`Calculated hash of pubKey: ${calculatedPubKeyHash}`);

        if (keyInfo[1].toLowerCase() !== calculatedPubKeyHash.toLowerCase()) {
          console.log('⚠️ Public key hash mismatch - verification will likely fail');
        }

        // Verify using openpgp.js for cross-checking
        try {
          console.log('\nAttempting verification with openpgp.js...');
          const messageBytes = Buffer.from(messageHash.slice(2), 'hex');
          const pgpMessage = await openpgp.createMessage({ binary: messageBytes });

          let pgpSignature;

          try {
            const signatureBuffer = Buffer.from(signature.slice(2), 'hex');
            pgpSignature = await openpgp.readSignature({ binarySignature: signatureBuffer });
            console.log('Successfully parsed signature with openpgp.js');
          } catch (e) {
            console.error('Error parsing signature with openpgp.js:', e.message);
            throw e; // Re-throw to stop further execution in this block
          }

          try {
            // Use the full public key for openpgp.js verification
            const publicKeyBuffer = Buffer.from(pubKey.slice(2), 'hex');
            pgpPublicKeyForOpenPGPJS = await openpgp.readKey({ binaryKey: publicKeyBuffer });
            console.log('Successfully parsed full public key with openpgp.js');
          } catch (e) {
            console.error('Error parsing full public key with openpgp.js:', e.message);
            throw e; // Re-throw to stop further execution in this block
          }

          const verificationResult = await openpgp.verify({
            message: pgpMessage,
            signature: pgpSignature,
            verificationKeys: pgpPublicKeyForOpenPGPJS
          });

          if (verificationResult.signatures.length > 0 && (await verificationResult.signatures[0].verified)) {
            console.log('✅ openpgp.js verification successful! Key ID:', verificationResult.signatures[0].keyID.toHex());
          } else {
            console.log('❌ openpgp.js verification failed.');
            if (verificationResult.signatures.length > 0) {
              console.log('Signature error details:', verificationResult.signatures[0].reason);
            }
          }
        } catch (pgpError) {
          console.log('Error during openpgp.js verification:', pgpError.message);
        }

        //  Try calling the function with better error handling
        //TODO: use this only when _verifyGPGSignature is made public
        // try {
        //   const directResult = await contract._verifyGPGSignature(
        //     messageHash,  // digest
        //     keyIdBytes,   // keyId
        //     pubKey,       // pubKey
        //     signature     // signature
        //   );

        //   console.log('Direct verification result:', directResult);
        //   console.log(directResult ? '✅ Direct verification successful!' : '❌ Direct verification failed.');
        // } catch (callError) {
        //   console.log('Direct call error:', callError.message);

        //   // Check if there's additional error data
        //   if (callError.data) {
        //     console.log('Error data:', callError.data);
        //   }
        // }

        // Now test validateSignature method (ERC-1271 validation)
        console.log('\nTrying to call validateSignature (ERC-1271 validation)...');
        try {
          // validateSignature expects a properly formatted signature with the type prefix
          const validateResult = await contract.validateSignature(
            wallet.address,    // account
            entityId,          // entityId
            ethers.ZeroAddress, // unused parameter
            messageHash,       // digest
            validateSignatureFormat // Use the correctly formatted signature for validation
          );

          // Check against expected return values
          const isValid = validateResult === MAGIC_VALUE;
          console.log('ERC-1271 validation result:', validateResult);
          console.log(isValid
            ? '✅ ERC-1271 validation successful!'
            : `❌ ERC-1271 validation failed. Got: ${validateResult}, Expected: ${MAGIC_VALUE}`);
        } catch (callError) {
          console.log('ERC-1271 validation error:', callError.message);

          // Check if the error contains a revert reason
          if (callError.data) {
            console.log('Error data:', callError.data);
          }

          // If we have an error message, extract and display it
          const errorMessage = callError.message.match(/reverted with reason string '([^']+)'/);
          if (errorMessage && errorMessage[1]) {
            console.log('Revert reason:', errorMessage[1]);
          }
        }
      } catch (error) {
        console.log('Error setting up verification:', error.message);
      }
    } catch (error) {
      console.log('Validation failed:', error.message);
    }
  } catch (error) {
    console.log('Test execution error:', error.message);
  }
}

main(); 