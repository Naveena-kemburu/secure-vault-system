# Secure Vault System

## Overview

Authorization-Governed Vault System for Controlled Asset Withdrawals is a blockchain-based secure multi-contract system implementing deterministic authorization mechanisms with replay protection. The system separates asset custody (vault) from permission validation (authorization manager) across two smart contracts, ensuring that withdrawals can only occur when explicitly authorized.

## Architecture

### System Components

The system consists of two primary smart contracts:

1. **SecureVault.sol** - Responsible for:
   - Accepting deposits from any address
   - Managing pooled fund custody
   - Executing withdrawals only after authorization verification
   - Emitting deposit and withdrawal events

2. **AuthorizationManager.sol** - Responsible for:
   - Validating withdrawal authorizations using ECDSA signatures
   - Enforcing single-use authorization policy (replay protection)
   - Tracking consumed authorizations to prevent duplication
   - Maintaining signer information

### Design Decisions

#### Separation of Concerns
- The vault does NOT perform cryptographic verification
- Authorization validation is delegated to the dedicated AuthorizationManager
- This separation reduces surface area for vulnerabilities and allows independent testing

#### Authorization Format
Authorizations are constructed deterministically using `keccak256` hashing of:
```solidity
keccak256(abi.encodePacked(
    vault_address,
    recipient_address,
    withdrawal_amount,
    authorization_id,
    chain_id
))
```

This ensures authorizations are bound to:
- Specific vault instance
- Specific blockchain network (via chain ID)
- Specific recipient
- Specific withdrawal amount
- Unique authorization identifier

#### Replay Protection
- Each authorization is single-use
- The `usedAuthorizations` mapping tracks consumed authorizations by their ID
- Once an authorization is used, attempting to reuse it will revert
- This prevents replay attacks across transactions and blocks

#### State Management
- Authorization verification occurs BEFORE state updates
- Fund transfers occur AFTER state is committed
- This prevents potential race conditions and ensures consistency

## Security Considerations

### Cryptographic Guarantees
- ECDSA signatures provide authentication of authorization data
- Message hashing includes network-specific chain ID to prevent cross-chain attacks
- Deterministic message construction prevents ambiguity

### Access Control
- No privileged operations in the vault (decentralized architecture)
- Only the authorization signer can create valid authorizations
- No admin keys or upgrade mechanisms

### Known Limitations
- Gas optimizations not prioritized (code clarity over cost)
- No multi-signature support (single signer model)
- No authorization revocation mechanism (by design)

## Getting Started

### Prerequisites
- Docker and Docker Compose
- Node.js 16+ (if running locally without Docker)

### Quick Start with Docker

```bash
# Clone the repository
git clone https://github.com/Naveena-kemburu/secure-vault-system.git
cd secure-vault-system

# Start the local blockchain and deploy contracts
docker-compose up

# The deployed contract addresses will be displayed in the logs
```

### Manual Local Setup

```bash
# Install dependencies
npm install

# Compile contracts
npm run compile

# Deploy to local network (requires running Hardhat node in another terminal)
npm run deploy:local
```

## Usage Example

### 1. Generate Authorization

```javascript
const { ethers } = require('ethers');

// Construct authorization message
const authId = ethers.id('unique-id-123');
const messageHash = ethers.keccak256(
  ethers.solidityPacked(
    ['address', 'address', 'uint256', 'bytes32', 'uint256'],
    [vaultAddress, recipientAddress, withdrawalAmount, authId, chainId]
  )
);

// Sign with authorized key
const signature = await signerKey.signMessage(ethers.getBytes(messageHash));
```

### 2. Execute Withdrawal

```javascript
const tx = await vault.withdraw(
  recipientAddress,
  withdrawalAmount,
  authId,
  signature
);
await tx.wait();
```

## Testing

Comprehensive test suite included in `tests/system.spec.js`:

- Successful deposits
- Successful withdrawals with valid authorization
- Failed withdrawals with invalid signatures
- Replay protection (reusing same authorization fails)
- Authorization scope validation (wrong recipient/amount fails)
- Cross-chain attack prevention

## Deployment

### Contract Addresses

After running `docker-compose up`, contract addresses are output to the logs and saved in deployment artifacts.

### Environment Configuration

Create a `.env` file (if deploying to live networks):
```
RPC_URL=https://your-rpc-endpoint
PRIVATE_KEY=0x...
AUTHORIZATION_SIGNER=0x...
```

## File Structure

```
secure-vault-system/
├── contracts/
│   ├── SecureVault.sol
│   └── AuthorizationManager.sol
├── scripts/
│   └── deploy.js
├── tests/
│   └── system.spec.js
├── docker/
│   ├── Dockerfile
│   └── entrypoint.sh
├── docker-compose.yml
├── package.json
├── hardhat.config.js
└── README.md
```

## License

MIT License - See LICENSE file for details
