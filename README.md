# BOUNTY-core

A decentralized bounty management and payout system built with Clarity for the Stacks blockchain.

## Overview

BOUNTY-core is a smart contract that enables:
- Creation of bounties with STX rewards
- Submission of work for bounties
- Approval of submissions by bounty creators or admins
- Automated payout of rewards to winners
- Admin and emergency controls for contract management

## Features
- Escrow-free bounty funding (reward is transferred directly from creator to winner)
- Submission and approval tracking
- Per-user bounty and submission records
- Admin management (add/remove admins)
- Emergency pause/unpause controls

## Use Cases
- Freelance marketplaces
- DAO task rewards
- Open-source incentives
- Bug bounty programs

## Contract Structure

- **Ownership:**
  - `contract-owner`: The deployer, with full admin rights
- **Admins:**
  - Can be added/removed by the owner
  - Can approve submissions
- **Bounties:**
  - Created by any user, specifying a reward
  - Track creator, reward, open/closed status, winner, and creation block
- **Submissions:**
  - Users can submit work to open bounties
  - Each submission is tracked and can be approved
- **Emergency Controls:**
  - Owner can pause/unpause contract operations

## Key Functions

### Public Functions
- `create-bounty (reward uint)`
  - Create a new bounty with a specified STX reward
- `submit-work (id uint)`
  - Submit work for a bounty
- `approve-submission (id uint) (user principal)`
  - Approve a user's submission and trigger payout
- `add-admin (admin principal)` / `remove-admin (admin principal)`
  - Manage admin accounts
- `pause` / `unpause`
  - Emergency controls

### Read-Only Functions
- `get-bounty-info (id uint)`
- `get-submission (id uint) (user principal)`
- `get-bounty-count`
- `is-paused`

## Error Codes
- `ERR-UNAUTHORIZED` (u100): Unauthorized action
- `ERR-PAUSED` (u101): Contract is paused
- `ERR-INVALID-AMOUNT` (u102): Invalid reward amount
- `ERR-BOUNTY-NOT-FOUND` (u103): Bounty does not exist
- `ERR-BOUNTY-CLOSED` (u104): Bounty is closed
- `ERR-ALREADY-SUBMITTED` (u105): Submission already exists
- `ERR-NOT-SUBMITTED` (u106): Submission not found
- `ERR-ALREADY-PAID` (u107): Submission already approved

## How It Works
1. **Create Bounty:**
   - Any user can call `create-bounty` with a reward amount (in STX).
2. **Submit Work:**
   - Users submit work to open bounties using `submit-work`.
3. **Approve Submission:**
   - Bounty creator or admin approves a submission, triggering STX payout from creator to winner.
4. **Admin Controls:**
   - Owner can add/remove admins and pause/unpause the contract.

## Development & Testing

- Contract: `contracts/BOUNTY-core.clar`
- Tests: `tests/BOUNTY-core.test.ts`
- Project uses [Clarinet](https://github.com/hirosystems/clarinet) for local development and testing.

### Run Checks
```
clarinet check
```

### Run Tests
```
npm test
```

## Security Notes
- The contract does not hold funds in escrow; rewards are paid directly from the creator to the winner upon approval.
- Only the contract owner can add/remove admins and pause/unpause the contract.
