/**
 * ============================================================================
 * ZeaZDev - Full Omega Ultimate DevOps Professional Enterprises
 * ============================================================================
 * 
 * Project: ZeaZDev Database Schema
 * File: DATABASE_SCHEMA.md
 * Version: 1.0.0
 * 
 * Developer: PHIPHAT PHOEMSUK (ZeaZDev)
 * Email: admin@zeaz.dev
 * Website: https://app.zeaz.dev
 * GitHub: https://github.com/ZeaZDev
 * 
 * Description:
 * Complete database schema documentation for ZeaZDev platform including
 * PostgreSQL tables, indexes, relationships, and MongoDB collections.
 * 
 * License: MIT
 * Copyright (c) 2025 PHIPHAT PHOEMSUK
 * 
 * Database Stack:
 * - PostgreSQL 15+ (Primary relational database)
 * - MongoDB 6+ (Logs and analytics)
 * - Redis 7+ (Caching and sessions)
 * 
 * Last Updated: 2025-01-09
 * ============================================================================
 */

# 🗄️ ZeaZDev Database Schema

## 📋 Table of Contents
1. [Database Architecture](#database-architecture)
2. [PostgreSQL Schema](#postgresql-schema)
3. [MongoDB Collections](#mongodb-collections)
4. [Redis Cache Structure](#redis-cache-structure)
5. [Data Relationships](#data-relationships)
6. [Indexes & Performance](#indexes--performance)
7. [Backup & Recovery](#backup--recovery)
8. [Security & Access Control](#security--access-control)

---

## 🏗️ Database Architecture

### Overview
```
┌──────────────────────────────────────────────────────┐
│                  Application Layer                   │
└─────────────┬────────────────────────┬───────────────┘
              │                        │
              ▼                        ▼
┌─────────────────────┐    ┌─────────────────────┐
│   PostgreSQL 15+    │    │    MongoDB 6+       │
│  (Primary Data)     │    │  (Logs & Events)    │
├─────────────────────┤    ├─────────────────────┤
│ • Users             │    │ • Transaction Logs  │
│ • Wallets           │    │ • Event Logs        │
│ • Transactions      │    │ • Audit Trails      │
│ • Staking           │    │ • Analytics         │
│ • NFTs              │    │ • User Activity     │
│ • Referrals         │    └─────────────────────┘
└─────────────────────┘
              │
              ▼
┌─────────────────────┐
│     Redis 7+        │
│   (Cache & Queue)   │
├─────────────────────┤
│ • Session Cache     │
│ • Token Prices      │
│ • User Balances     │
│ • Rate Limiting     │
│ • Job Queue         │
└─────────────────────┘
```

### Database Selection Rationale

**PostgreSQL** - Primary Database
- ACID compliance for financial data
- Complex relationships and joins
- Strong data integrity
- Advanced indexing
- JSON support for flexible fields

**MongoDB** - Logs & Analytics
- High-write throughput for logs
- Flexible schema for events
- Time-series data
- Aggregation pipeline
- Easy horizontal scaling

**Redis** - Cache & Queue
- In-memory speed
- Session management
- Real-time data
- Pub/Sub for notifications
- Job queue (Bull)

---

## 💾 PostgreSQL Schema

### Database: `zeazdev_main`

---

### Table: `users`
**Purpose**: Store user account information

```sql
CREATE TABLE users (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- User Identity
    wallet_address VARCHAR(42) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE,
    username VARCHAR(50) UNIQUE,
    
    -- World ID Verification
    world_id_hash VARCHAR(66) UNIQUE, -- nullifier hash
    world_id_verified BOOLEAN DEFAULT false,
    world_id_verified_at TIMESTAMP,
    
    -- Profile
    display_name VARCHAR(100),
    bio TEXT,
    avatar_url TEXT,
    banner_url TEXT,
    
    -- KYC/AML
    kyc_level INTEGER DEFAULT 0, -- 0: None, 1: Basic, 2: Intermediate, 3: Advanced
    kyc_status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected
    kyc_verified_at TIMESTAMP,
    kyc_documents JSONB,
    
    -- Preferences
    language VARCHAR(5) DEFAULT 'en', -- en, th, cn, jp, kr
    currency VARCHAR(3) DEFAULT 'USD',
    timezone VARCHAR(50) DEFAULT 'UTC',
    notifications_enabled BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    
    -- Security
    two_factor_enabled BOOLEAN DEFAULT false,
    two_factor_secret VARCHAR(32),
    recovery_email VARCHAR(255),
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    is_banned BOOLEAN DEFAULT false,
    ban_reason TEXT,
    banned_at TIMESTAMP,
    
    -- Referral
    referral_code VARCHAR(10) UNIQUE,
    referred_by UUID REFERENCES users(id),
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP,
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Indexes
CREATE INDEX idx_users_wallet ON users(wallet_address);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_world_id ON users(world_id_hash);
CREATE INDEX idx_users_referral_code ON users(referral_code);
CREATE INDEX idx_users_referred_by ON users(referred_by);
CREATE INDEX idx_users_created_at ON users(created_at DESC);
```

---

### Table: `wallets`
**Purpose**: Store user wallet balances

```sql
CREATE TABLE wallets (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Relations
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Wallet Type
    wallet_type VARCHAR(20) NOT NULL, -- main, gaming, savings
    
    -- Balances (stored as strings to prevent precision loss)
    zea_balance DECIMAL(36, 18) DEFAULT 0,
    zeaz_balance DECIMAL(36, 18) DEFAULT 0,
    usdc_balance DECIMAL(36, 6) DEFAULT 0,
    eth_balance DECIMAL(36, 18) DEFAULT 0,
    btc_balance DECIMAL(36, 8) DEFAULT 0,
    
    -- Locked/Staked Amounts
    zea_locked DECIMAL(36, 18) DEFAULT 0,
    zeaz_locked DECIMAL(36, 18) DEFAULT 0,
    
    -- Wallet Metadata
    is_primary BOOLEAN DEFAULT false,
    is_frozen BOOLEAN DEFAULT false,
    freeze_reason TEXT,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_transaction_at TIMESTAMP,
    
    -- Constraints
    UNIQUE(user_id, wallet_type)
);

-- Indexes
CREATE INDEX idx_wallets_user_id ON wallets(user_id);
CREATE INDEX idx_wallets_type ON wallets(wallet_type);
CREATE INDEX idx_wallets_updated ON wallets(updated_at DESC);
```

---

### Table: `transactions`
**Purpose**: Store all financial transactions

```sql
CREATE TABLE transactions (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Relations
    user_id UUID NOT NULL REFERENCES users(id),
    from_wallet_id UUID REFERENCES wallets(id),
    to_wallet_id UUID REFERENCES wallets(id),
    
    -- Transaction Details
    transaction_type VARCHAR(30) NOT NULL, 
    -- Types: transfer, swap, deposit, withdrawal, reward, airdrop, 
    --        stake, unstake, claim, fee, refund, purchase
    
    -- Amounts
    token_symbol VARCHAR(10) NOT NULL,
    amount DECIMAL(36, 18) NOT NULL,
    fee DECIMAL(36, 18) DEFAULT 0,
    
    -- Blockchain Details
    chain VARCHAR(20), -- ethereum, worldchain, base, bsc, polygon
    tx_hash VARCHAR(66) UNIQUE,
    block_number BIGINT,
    gas_used BIGINT,
    gas_price DECIMAL(36, 18),
    
    -- Status
    status VARCHAR(20) DEFAULT 'pending', 
    -- pending, processing, completed, failed, cancelled
    
    error_message TEXT,
    
    -- Metadata
    description TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Idempotency
    idempotency_key VARCHAR(64) UNIQUE,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

-- Indexes
CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_type ON transactions(transaction_type);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_tx_hash ON transactions(tx_hash);
CREATE INDEX idx_transactions_created ON transactions(created_at DESC);
CREATE INDEX idx_transactions_idempotency ON transactions(idempotency_key);
```

---

### Table: `rewards`
**Purpose**: Track user rewards and check-ins

```sql
CREATE TABLE rewards (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Relations
    user_id UUID NOT NULL REFERENCES users(id),
    transaction_id UUID REFERENCES transactions(id),
    
    -- Reward Details
    reward_type VARCHAR(30) NOT NULL,
    -- Types: daily_checkin, airdrop, referral, staking, 
    --        gaming, achievement, special_event
    
    amount DECIMAL(36, 18) NOT NULL,
    token_symbol VARCHAR(10) NOT NULL,
    
    -- Daily Check-in Specific
    checkin_date DATE,
    streak_count INTEGER DEFAULT 0,
    
    -- Airdrop Specific
    airdrop_campaign VARCHAR(50),
    merkle_proof JSONB,
    
    -- Status
    claimed BOOLEAN DEFAULT false,
    claimed_at TIMESTAMP,
    
    -- Expiry
    expires_at TIMESTAMP,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_rewards_user_id ON rewards(user_id);
CREATE INDEX idx_rewards_type ON rewards(reward_type);
CREATE INDEX idx_rewards_claimed ON rewards(claimed);
CREATE INDEX idx_rewards_checkin_date ON rewards(checkin_date);
CREATE UNIQUE INDEX idx_rewards_daily_checkin ON rewards(user_id, checkin_date) 
    WHERE reward_type = 'daily_checkin';
```

---

### Table: `staking`
**Purpose**: Track staking positions

```sql
CREATE TABLE staking (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Relations
    user_id UUID NOT NULL REFERENCES users(id),
    wallet_id UUID NOT NULL REFERENCES wallets(id),
    
    -- Staking Details
    token_symbol VARCHAR(10) NOT NULL,
    amount DECIMAL(36, 18) NOT NULL,
    
    -- Lock Period
    lock_period INTEGER, -- days (NULL for flexible)
    lock_start_date TIMESTAMP NOT NULL,
    lock_end_date TIMESTAMP,
    
    -- APY
    apy DECIMAL(5, 2) NOT NULL, -- e.g., 25.50 for 25.5%
    
    -- Rewards
    rewards_earned DECIMAL(36, 18) DEFAULT 0,
    last_reward_claim TIMESTAMP,
    
    -- Status
    status VARCHAR(20) DEFAULT 'active',
    -- active, unstaking, completed, cancelled
    
    -- Auto-compound
    auto_compound BOOLEAN DEFAULT false,
    
    -- Early Withdrawal
    early_withdrawal_penalty DECIMAL(5, 2), -- percentage
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    unstaked_at TIMESTAMP
);

-- Indexes
CREATE INDEX idx_staking_user_id ON staking(user_id);
CREATE INDEX idx_staking_status ON staking(status);
CREATE INDEX idx_staking_token ON staking(token_symbol);
CREATE INDEX idx_staking_end_date ON staking(lock_end_date);
```

---

### Table: `referrals`
**Purpose**: Track referral relationships and rewards

```sql
CREATE TABLE referrals (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Relations
    referrer_id UUID NOT NULL REFERENCES users(id),
    referee_id UUID NOT NULL REFERENCES users(id),
    
    -- Referral Details
    referral_code VARCHAR(10) NOT NULL,
    level INTEGER NOT NULL DEFAULT 1, -- 1, 2, or 3
    
    -- Rewards
    total_commission_earned DECIMAL(36, 18) DEFAULT 0,
    commission_currency VARCHAR(10) DEFAULT 'ZEA',
    
    -- Activity Tracking
    referee_signup_date TIMESTAMP,
    referee_first_stake_date TIMESTAMP,
    referee_first_swap_date TIMESTAMP,
    referee_total_volume DECIMAL(36, 18) DEFAULT 0,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(referrer_id, referee_id),
    CHECK(referrer_id != referee_id)
);

-- Indexes
CREATE INDEX idx_referrals_referrer ON referrals(referrer_id);
CREATE INDEX idx_referrals_referee ON referrals(referee_id);
CREATE INDEX idx_referrals_code ON referrals(referral_code);
CREATE INDEX idx_referrals_active ON referrals(is_active);
```

---

### Table: `nfts`
**Purpose**: Track NFT ownership and metadata

```sql
CREATE TABLE nfts (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Relations
    owner_id UUID NOT NULL REFERENCES users(id),
    creator_id UUID REFERENCES users(id),
    
    -- NFT Details
    token_id BIGINT NOT NULL,
    contract_address VARCHAR(42) NOT NULL,
    chain VARCHAR(20) NOT NULL,
    
    -- Metadata
    name VARCHAR(200) NOT NULL,
    description TEXT,
    image_url TEXT NOT NULL,
    animation_url TEXT,
    external_url TEXT,
    
    -- Attributes
    attributes JSONB DEFAULT '[]'::jsonb,
    
    -- Rarity
    rarity VARCHAR(20), -- common, rare, epic, legendary
    rarity_score DECIMAL(10, 2),
    
    -- Collection
    collection_name VARCHAR(100),
    collection_id UUID,
    
    -- Marketplace
    is_listed BOOLEAN DEFAULT false,
    list_price DECIMAL(36, 18),
    list_currency VARCHAR(10),
    
    -- Stats
    view_count INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    
    -- Timestamps
    minted_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(contract_address, token_id, chain)
);

-- Indexes
CREATE INDEX idx_nfts_owner ON nfts(owner_id);
CREATE INDEX idx_nfts_creator ON nfts(creator_id);
CREATE INDEX idx_nfts_contract ON nfts(contract_address);
CREATE INDEX idx_nfts_collection ON nfts(collection_id);
CREATE INDEX idx_nfts_listed ON nfts(is_listed);
CREATE INDEX idx_nfts_rarity ON nfts(rarity);
```

---

### Table: `games`
**Purpose**: Track game sessions and results

```sql
CREATE TABLE games (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Relations
    user_id UUID NOT NULL REFERENCES users(id),
    
    -- Game Details
    game_type VARCHAR(30) NOT NULL,
    -- slot_classic, slot_video, poker, dice, lottery
    
    game_name VARCHAR(100),
    
    -- Betting
    bet_amount DECIMAL(36, 18) NOT NULL,
    bet_currency VARCHAR(10) NOT NULL,
    
    -- Result
    result VARCHAR(20) NOT NULL, -- win, loss, draw
    payout_amount DECIMAL(36, 18) DEFAULT 0,
    payout_multiplier DECIMAL(10, 2),
    
    -- Provably Fair
    seed_server VARCHAR(64),
    seed_client VARCHAR(64),
    seed_combined VARCHAR(128),
    random_number TEXT,
    
    -- Jackpot
    is_jackpot BOOLEAN DEFAULT false,
    jackpot_amount DECIMAL(36, 18),
    
    -- Session
    session_id VARCHAR(64),
    round_number INTEGER,
    
    -- Timestamps
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP,
    
    -- Metadata
    game_data JSONB DEFAULT '{}'::jsonb
);

-- Indexes
CREATE INDEX idx_games_user_id ON games(user_id);
CREATE INDEX idx_games_type ON games(game_type);
CREATE INDEX idx_games_result ON games(result);
CREATE INDEX idx_games_jackpot ON games(is_jackpot);
CREATE INDEX idx_games_session ON games(session_id);
CREATE INDEX idx_games_started ON games(started_at DESC);
```

---

### Table: `bank_accounts`
**Purpose**: Store linked bank account information (Thai banks)

```sql
CREATE TABLE bank_accounts (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Relations
    user_id UUID NOT NULL REFERENCES users(id),
    
    -- Bank Details
    bank_code VARCHAR(10) NOT NULL, -- KBANK, BBL, KTB, SCB, etc.
    bank_name VARCHAR(100) NOT NULL,
    account_number VARCHAR(20) NOT NULL,
    account_name VARCHAR(200) NOT NULL,
    
    -- Verification
    is_verified BOOLEAN DEFAULT false,
    verification_method VARCHAR(20), -- small_deposit, document
    verified_at TIMESTAMP,
    
    -- Limits
    daily_deposit_limit DECIMAL(36, 2) DEFAULT 0,
    daily_withdrawal_limit DECIMAL(36, 2) DEFAULT 0,
    
    -- Usage Stats
    total_deposits DECIMAL(36, 2) DEFAULT 0,
    total_withdrawals DECIMAL(36, 2) DEFAULT 0,
    last_used_at TIMESTAMP,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(user_id, bank_code, account_number)
);

-- Indexes
CREATE INDEX idx_bank_accounts_user_id ON bank_accounts(user_id);
CREATE INDEX idx_bank_accounts_bank_code ON bank_accounts(bank_code);
CREATE INDEX idx_bank_accounts_verified ON bank_accounts(is_verified);
```

---

### Table: `fiat_transactions`
**Purpose**: Track fiat deposit/withdrawal transactions

```sql
CREATE TABLE fiat_transactions (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Relations
    user_id UUID NOT NULL REFERENCES users(id),
    bank_account_id UUID REFERENCES bank_accounts(id),
    transaction_id UUID REFERENCES transactions(id),
    
    -- Transaction Type
    transaction_type VARCHAR(20) NOT NULL, -- deposit, withdrawal
    
    -- Fiat Details
    fiat_currency VARCHAR(3) NOT NULL, -- THB, USD, EUR
    fiat_amount DECIMAL(36, 2) NOT NULL,
    
    -- Crypto Details
    crypto_currency VARCHAR(10) NOT NULL,
    crypto_amount DECIMAL(36, 18) NOT NULL,
    exchange_rate DECIMAL(18, 6) NOT NULL,
    
    -- Fees
    platform_fee DECIMAL(36, 2) DEFAULT 0,
    bank_fee DECIMAL(36, 2) DEFAULT 0,
    total_fee DECIMAL(36, 2) DEFAULT 0,
    
    -- Payment Details
    payment_method VARCHAR(30), -- bank_transfer, promptpay, card
    payment_reference VARCHAR(100),
    
    -- Status
    status VARCHAR(20) DEFAULT 'pending',
    -- pending, processing, completed, failed, cancelled, refunded
    
    error_message TEXT,
    
    -- Provider
    provider VARCHAR(50), -- internal, moonpay, transak, etc.
    provider_transaction_id VARCHAR(100),
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

-- Indexes
CREATE INDEX idx_fiat_transactions_user_id ON fiat_transactions(user_id);
CREATE INDEX idx_fiat_transactions_type ON fiat_transactions(transaction_type);
CREATE INDEX idx_fiat_transactions_status ON fiat_transactions(status);
CREATE INDEX idx_fiat_transactions_created ON fiat_transactions(created_at DESC);
```

---

### Table: `cards`
**Purpose**: Track virtual and physical crypto cards

```sql
CREATE TABLE cards (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Relations
    user_id UUID NOT NULL REFERENCES users(id),
    wallet_id UUID NOT NULL REFERENCES wallets(id),
    
    -- Card Details
    card_type VARCHAR(20) NOT NULL, -- virtual, physical
    card_number VARCHAR(19) UNIQUE, -- Encrypted
    card_holder_name VARCHAR(100),
    expiry_date VARCHAR(7), -- MM/YYYY
    cvv VARCHAR(4), -- Encrypted
    
    -- Status
    status VARCHAR(20) DEFAULT 'pending',
    -- pending, active, frozen, cancelled, expired
    
    -- Limits
    daily_spend_limit DECIMAL(36, 2) DEFAULT 0,
    monthly_spend_limit DECIMAL(36, 2) DEFAULT 0,
    
    -- Usage
    total_spent DECIMAL(36, 2) DEFAULT 0,
    last_used_at TIMESTAMP,
    
    -- Cashback
    cashback_tier VARCHAR(20), -- basic, verified, premium, vip
    cashback_rate DECIMAL(5, 2), -- percentage
    total_cashback_earned DECIMAL(36, 2) DEFAULT 0,
    
    -- Shipping (for physical cards)
    shipping_address TEXT,
    shipped_at TIMESTAMP,
    delivery_status VARCHAR(20),
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activated_at TIMESTAMP
);

-- Indexes
CREATE INDEX idx_cards_user_id ON cards(user_id);
CREATE INDEX idx_cards_type ON cards(card_type);
CREATE INDEX idx_cards_status ON cards(status);
CREATE INDEX idx_cards_number ON cards(card_number);
```

---

## 📊 MongoDB Collections

### Database: `zeazdev_logs`

---

### Collection: `transaction_logs`
**Purpose**: Detailed transaction activity logs

```javascript
{
    _id: ObjectId(),
    transaction_id: "uuid",
    user_id: "uuid",
    timestamp: ISODate(),
    
    // Action
    action: "transfer", // swap, stake, claim, etc.
    
    // Details
    from_address: "0x...",
    to_address: "0x...",
    amount: "1000.50",
    token: "ZEA",
    
    // Blockchain
    chain: "worldchain",
    tx_hash: "0x...",
    block_number: 12345678,
    gas_used: 21000,
    
    // Status
    status: "completed",
    
    // Metadata
    ip_address: "1.2.3.4",
    user_agent: "Mozilla/5.0...",
    device_id: "...",
    
    // Performance
    processing_time_ms: 1234,
    
    created_at: ISODate()
}

// Indexes
db.transaction_logs.createIndex({ transaction_id: 1 })
db.transaction_logs.createIndex({ user_id: 1, timestamp: -1 })
db.transaction_logs.createIndex({ tx_hash: 1 })
db.transaction_logs.createIndex({ timestamp: -1 })
db.transaction_logs.createIndex({ created_at: 1 }, { expireAfterSeconds: 7776000 }) // 90 days TTL
```

---

### Collection: `event_logs`
**Purpose**: System and user events

```javascript
{
    _id: ObjectId(),
    event_type: "user_login", // user_signup, kyc_submitted, etc.
    user_id: "uuid",
    timestamp: ISODate(),
    
    // Event Data
    data: {
        ip_address: "1.2.3.4",
        location: "Bangkok, Thailand",
        device: "iPhone 14 Pro",
        success: true
    },
    
    // Severity
    severity: "info", // debug, info, warning, error, critical
    
    // Source
    source: "frontend", // backend, smart_contract, worker
    
    created_at: ISODate()
}

// Indexes
db.event_logs.createIndex({ user_id: 1, timestamp: -1 })
db.event_logs.createIndex({ event_type: 1, timestamp: -1 })
db.event_logs.createIndex({ severity: 1, timestamp: -1 })
db.event_logs.createIndex({ created_at: 1 }, { expireAfterSeconds: 2592000 }) // 30 days TTL
```

---

### Collection: `audit_trails`
**Purpose**: Audit trail for security and compliance

```javascript
{
    _id: ObjectId(),
    user_id: "uuid",
    admin_id: "uuid", // if admin action
    timestamp: ISODate(),
    
    // Action
    action: "balance_adjustment",
    category: "financial", // security, user_management, system
    
    // Before/After State
    before: {
        balance: "1000.00 ZEA"
    },
    after: {
        balance: "1100.00 ZEA"
    },
    
    // Reason
    reason: "Compensation for service outage",
    
    // Metadata
    ip_address: "1.2.3.4",
    metadata: {},
    
    created_at: ISODate()
}

// Indexes
db.audit_trails.createIndex({ user_id: 1, timestamp: -1 })
db.audit_trails.createIndex({ admin_id: 1, timestamp: -1 })
db.audit_trails.createIndex({ category: 1, timestamp: -1 })
// No TTL - keep forever for compliance
```

---

### Collection: `analytics_events`
**Purpose**: User behavior analytics

```javascript
{
    _id: ObjectId(),
    user_id: "uuid",
    session_id: "uuid",
    timestamp: ISODate(),
    
    // Event
    event_name: "page_view",
    page: "/swap",
    
    // User Context
    device: "mobile",
    platform: "ios",
    app_version: "1.2.3",
    
    // Location
    country: "TH",
    city: "Bangkok",
    
    // Properties
    properties: {
        from_token: "ZEA",
        to_token: "USDC",
        amount: "100"
    },
    
    created_at: ISODate()
}

// Indexes
db.analytics_events.createIndex({ user_id: 1, timestamp: -1 })
db.analytics_events.createIndex({ event_name: 1, timestamp: -1 })
db.analytics_events.createIndex({ session_id: 1 })
db.analytics_events.createIndex({ created_at: 1 }, { expireAfterSeconds: 15552000 }) // 180 days TTL
```

---

## 🔴 Redis Cache Structure

### Key Patterns

#### Session Management
```
session:{session_id} = {
    user_id: "uuid",
    wallet_address: "0x...",
    created_at: timestamp,
    expires_at: timestamp
}
TTL: 24 hours
```

#### User Balance Cache
```
balance:{user_id}:{token} = "1000.50"
TTL: 5 minutes
```

#### Token Prices
```
price:{token_symbol}:{currency} = "0.05"
TTL: 1 minute
```

#### Rate Limiting
```
ratelimit:{user_id}:{endpoint} = counter
TTL: 1 hour
```

#### Job Queue
```
bull:{queue_name}:{job_id} = job_data
TTL: Varies by job
```

---

## 🔗 Data Relationships

### Entity Relationship Diagram (ERD)

```
┌─────────┐
│  Users  │
└────┬────┘
     │
     ├──── Wallets (1:N)
     │
     ├──── Transactions (1:N)
     │
     ├──── Rewards (1:N)
     │
     ├──── Staking (1:N)
     │
     ├──── Referrals (1:N as referrer)
     │
     ├──── Referrals (1:1 as referee)
     │
     ├──── NFTs (1:N)
     │
     ├──── Games (1:N)
     │
     ├──── Bank Accounts (1:N)
     │
     └──── Cards (1:N)
```

---

## 📈 Indexes & Performance

### Index Strategy

#### Query Patterns Optimized
1. **User lookup by wallet address** (exact match)
2. **Transaction history** (user_id + time range)
3. **Pending transactions** (status filter)
4. **Daily check-in validation** (user + date)
5. **Referral tree traversal** (referrer_id)
6. **NFT marketplace** (listed + rarity)
7. **Game history** (user + time range)

### Composite Indexes
```sql
-- Frequent query: User's pending transactions
CREATE INDEX idx_transactions_user_status_date 
ON transactions(user_id, status, created_at DESC);

-- Frequent query: Active stakes by user
CREATE INDEX idx_staking_user_status 
ON staking(user_id, status) WHERE status = 'active';

-- Frequent query: Listed NFTs by rarity
CREATE INDEX idx_nfts_listed_rarity 
ON nfts(is_listed, rarity, list_price) WHERE is_listed = true;
```

### Performance Targets
- Query response time: < 100ms (95th percentile)
- Write throughput: 10,000 TPS
- Read throughput: 100,000 TPS
- Index size: < 30% of table size

---

## 💾 Backup & Recovery

### Backup Strategy

#### PostgreSQL
**Full Backup**: Daily at 2:00 AM UTC
```bash
pg_dump -Fc zeazdev_main > backup_$(date +%Y%m%d).dump
```

**Incremental Backup**: Every 6 hours
```bash
pg_basebackup -D /backup/incremental/$(date +%Y%m%d_%H)
```

**WAL Archiving**: Continuous
```sql
archive_mode = on
archive_command = 'cp %p /archive/%f'
```

**Retention**: 30 days

---

#### MongoDB
**Snapshot**: Daily at 3:00 AM UTC
```bash
mongodump --db zeazdev_logs --out /backup/mongo_$(date +%Y%m%d)
```

**Retention**: 30 days

---

#### Redis
**RDB Snapshot**: Every hour
```bash
save 3600 1
```

**AOF**: Enabled
```bash
appendonly yes
appendfsync everysec
```

---

### Disaster Recovery

**RPO (Recovery Point Objective)**: 5 minutes  
**RTO (Recovery Time Objective)**: 30 minutes

**DR Procedures**:
1. Automatic failover to hot standby
2. Restore from latest backup
3. Replay WAL logs
4. Verify data integrity
5. Switch DNS to DR site

---

## 🔒 Security & Access Control

### Database Roles

```sql
-- Read-only role for analytics
CREATE ROLE analytics_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO analytics_read;

-- Application role
CREATE ROLE app_user;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO app_user;
GRANT DELETE ON transactions, logs TO app_user;

-- Admin role
CREATE ROLE db_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO db_admin;
```

### Encryption

**At Rest**:
- PostgreSQL: TDE (Transparent Data Encryption)
- MongoDB: Encrypted storage engine
- Redis: Disk encryption

**In Transit**:
- SSL/TLS for all connections
- Certificate-based authentication

**Sensitive Fields**:
```sql
-- Encrypt PII fields
CREATE EXTENSION pgcrypto;

-- Example: Encrypt card numbers
UPDATE cards 
SET card_number = pgp_sym_encrypt(card_number, 'encryption_key');
```

### Audit Logging
```sql
-- Enable audit logging
CREATE EXTENSION pgaudit;
ALTER SYSTEM SET pgaudit.log = 'write, ddl';
```

---

## 📊 Database Monitoring

### Metrics to Monitor
- Connection pool usage
- Query performance (slow queries)
- Replication lag
- Disk usage
- Cache hit rate
- Lock contention

### Tools
- **Prometheus + Grafana**: Metrics visualization
- **pg_stat_statements**: Query performance
- **pgBadger**: Log analyzer
- **MongoDB Atlas**: Cloud monitoring

---

## 📝 Maintenance Tasks

### Daily
- [ ] Verify backups completed
- [ ] Check replication status
- [ ] Review slow query log
- [ ] Monitor disk usage

### Weekly
- [ ] Analyze query plans
- [ ] Update statistics
- [ ] Review index usage
- [ ] Clean up old logs

### Monthly
- [ ] Vacuum analyze
- [ ] Reindex if needed
- [ ] Review and optimize queries
- [ ] Capacity planning review

---

## 📞 Contact

**Database Administrator**: dba@zeaz.dev  
**DevOps Team**: devops@zeaz.dev

---

*Last Updated: 2025-01-09*  
*Version: 1.0.0*  
*Author: PHIPHAT PHOEMSUK (ZeaZDev)*
