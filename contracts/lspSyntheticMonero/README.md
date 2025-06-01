# LSPSyntheticMonero: BeraBorrow Integration

## Overview

The `LSPSyntheticMonero` contract implements a synthetic Monero (sXMR) token backed by NECT collateral with full integration into the BeraBorrow ecosystem. This integration leverages BeraBorrow's innovative features including Proof of Liquidity (PoL) staking, Liquid Stability Pool (LSP), and core borrowing operations.

## Core Features

### Synthetic Monero Token (sXMR)

- ERC20-compliant token representing synthetic Monero
- Backed by NECT collateral at a minimum collateralization ratio of 150%
- Uses Pyth oracle for XMR/USD price feeds
- Supports minting, burning, and collateral management

### BeraBorrow Integration

#### 1. Proof of Liquidity (PoL) Integration

Users can stake their sXMR tokens in a RewardVault to earn BGT rewards:

- **Staking**: Stake sXMR tokens to earn BGT rewards
- **Unstaking**: Withdraw staked sXMR tokens
- **Rewards Harvesting**: Claim earned BGT rewards

#### 2. Liquid Stability Pool (LSP) Integration

Interacts with BeraBorrow's Liquid Stability Pool for enhanced stability:

- **Provide to Stability Pool**: Deposit NECT into the Stability Pool
- **Withdraw from Stability Pool**: Withdraw NECT from the Stability Pool
- **ETH Gain Management**: View and withdraw ETH gains from the Stability Pool

#### 3. BeraBorrow Core Integration

Supports BeraBorrow's borrowing and collateral management operations:

- **Trove Management**: Open, close, and adjust troves
- **Collateral Operations**: Add or withdraw ETH collateral
- **Debt Operations**: Borrow or repay NECT
- **Combined Operations**: Borrow NECT and mint sXMR in a single transaction

## Technical Implementation

### Key Components

- `LSPSyntheticMonero.sol`: Main contract implementing the synthetic Monero token with BeraBorrow integration
- Integration with BeraBorrow contracts via interfaces:
  - `IRewardVault.sol`: Interface for PoL staking and rewards
  - `IRewardVaultFactory.sol`: Interface for creating RewardVaults
  - `ILSP.sol`: Interface for Liquid Stability Pool interactions
  - `IBorrowerOperations.sol`: Interface for BeraBorrow's borrowing operations

### Oracle Integration

- Uses Pyth oracle for XMR/USD price feeds
- Supports price feed updates with proper validation

### Contract Addresses

Uses the deployed BeraBorrow contract addresses from `DeployedContracts.sol` for seamless integration with the existing BeraBorrow ecosystem.

## Deployment

The LSPSyntheticMonero contract has been deployed on Berachain:

- **Contract Address**: [View on Berachain Explorer](https://bera.blockscout.com/tx/0x0bd1dffcdac1f231ea7a40c39dd3f66b0de3c67fd7ff20039d74fd3f99727038)
- **Transaction Hash**: `0x0bd1dffcdac1f231ea7a40c39dd3f66b0de3c67fd7ff20039d74fd3f99727038`
