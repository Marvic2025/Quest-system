# Quest-system Clarity Smart Contract

A decentralized quest and reward system built on the Stacks blockchain using Clarity smart contracts.

## Features

- **Create Quests:** Admins can create quests with custom descriptions, reward types (fungible or non-fungible tokens), amounts, and expiry.
- **Join Quests:** Users can join active quests.
- **Complete Quests:** Quests can be marked as completed for users.
- **Claim Rewards:** Users can claim rewards after completing quests, receiving either GOLD (FT) or BADGE (NFT).
- **Input Validation:** All user-supplied data is validated for safety and contract integrity.

## Contract Structure

- **Fungible Token:** `GOLD`
- **Non-Fungible Token:** `BADGE`
- **Maps:**  
  - `quests`: Stores quest details  
  - `quest-participants`: Tracks user participation and completion

## Usage

### Deploy

1. Clone the repository.
2. Install [Clarinet](https://docs.stacks.co/docs/clarinet/overview/) for local development.
3. Run `clarinet check` to verify contract syntax.
4. Deploy using Clarinet or your preferred Stacks deployment tool.

### Functions

- `create-quest(quest-id, description, reward-type, reward-amount, expiry)`
- `join-quest(quest-id)`
- `complete-quest(quest-id, user)`
- `claim-reward(quest-id)`

See the contract source for argument details and error codes.

## Error Codes

- `ERR-QUEST-EXISTS`
- `ERR-NOT-AUTHORIZED`
- `ERR-QUEST-EXPIRED`
- `ERR-NOT-JOINED`
- `ERR-ALREADY-JOINED`
- `ERR-ALREADY-COMPLETED`
- `ERR-NOT-COMPLETED`
- `ERR-ALREADY-CLAIMED`
- `ERR-FT-MINT`
- `ERR-NFT-MINT`

## Development

- All contract logic is in `contracts/Quest-system.clar`.
- Test coverage and deployment scripts are recommended for production use.
