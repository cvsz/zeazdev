/**
 * ============================================================================
 * ZeaZDev - Full Omega Ultimate DevOps Professional Enterprises
 * ============================================================================
 * 
 * Project: ZeaZDev Technology Stack
 * File: TECH_STACK.md
 * Version: 1.0.0
 * 
 * Developer: PHIPHAT PHOEMSUK (ZeaZDev)
 * Email: admin@zeaz.dev
 * Website: https://app.zeaz.dev
 * GitHub: https://github.com/ZeaZDev
 * 
 * Description:
 * Complete technology stack documentation covering all layers of the
 * ZeaZDev platform from infrastructure to frontend applications.
 * 
 * License: MIT
 * Copyright (c) 2025 PHIPHAT PHOEMSUK
 * 
 * Last Updated: 2025-01-09
 * ============================================================================
 */

# 🛠️ ZeaZDev Technology Stack

## 📋 Table of Contents
1. [Stack Overview](#stack-overview)
2. [Frontend Technologies](#frontend-technologies)
3. [Backend Technologies](#backend-technologies)
4. [Blockchain & Smart Contracts](#blockchain--smart-contracts)
5. [Databases & Caching](#databases--caching)
6. [Infrastructure & DevOps](#infrastructure--devops)
7. [Security & Monitoring](#security--monitoring)
8. [Third-Party Integrations](#third-party-integrations)
9. [Development Tools](#development-tools)

---

## 🏗️ Stack Overview

### Architecture Layers

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                   │
│  React Native (Mobile) | Next.js (Web) | Unity (Games) │
└─────────────────────┬───────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────┐
│                   Application Layer                     │
│        Express.js API | GraphQL | WebSocket             │
└─────────────────────┬───────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────┐
│                    Business Layer                       │
│    Smart Contracts | Relayer | Game Engine | AI/ML     │
└─────────────────────┬───────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────┐
│                      Data Layer                         │
│   PostgreSQL | MongoDB | Redis | IPFS | Blockchain     │
└─────────────────────┬───────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────┐
│                 Infrastructure Layer                    │
│    AWS/GCP | Kubernetes | Docker | Nginx | CloudFlare  │
└─────────────────────────────────────────────────────────┘
```

---

## 📱 Frontend Technologies

### 1. Mobile Application (React Native)

#### Core Framework
```json
{
  "react-native": "^0.73.2",
  "expo": "~50.0.6",
  "expo-router": "^3.4.6"
}
```

**Why React Native + Expo?**
- Cross-platform (iOS + Android) from single codebase
- Over-the-air (OTA) updates
- Rich ecosystem of native modules
- World App Mini App compatibility
- Faster development cycle

#### UI/UX Libraries
```json
{
  "react-native-reanimated": "^3.6.2",
  "react-native-gesture-handler": "^2.14.1",
  "react-native-safe-area-context": "^4.8.2",
  "react-native-screens": "^3.29.0",
  "@react-native-async-storage/async-storage": "^1.21.0"
}
```

#### Web3 Integration
```json
{
  "ethers": "^6.10.0",
  "@worldcoin/idkit-core": "^1.0.2",
  "@walletconnect/react-native-dapp": "^1.8.0"
}
```

#### State Management
```json
{
  "zustand": "^4.5.0",
  "@tanstack/react-query": "^5.17.19"
}
```

**Why Zustand?**
- Lightweight (< 1KB)
- Simple API
- No boilerplate
- TypeScript support
- DevTools integration

#### Navigation
```json
{
  "expo-router": "^3.4.6",
  "@react-navigation/native": "^6.1.9",
  "@react-navigation/stack": "^6.3.20",
  "@react-navigation/bottom-tabs": "^6.5.11"
}
```

---

### 2. Web Application (Next.js)

#### Core Framework
```json
{
  "next": "^14.1.0",
  "react": "^18.2.0",
  "react-dom": "^18.2.0"
}
```

**Why Next.js 14?**
- App Router (Server Components)
- Incremental Static Regeneration (ISR)
- Built-in API routes
- Image optimization
- SEO-friendly
- Excellent performance

#### Styling
```json
{
  "tailwindcss": "^3.4.1",
  "autoprefixer": "^10.4.17",
  "postcss": "^8.4.33",
  "@headlessui/react": "^1.7.18",
  "clsx": "^2.1.0",
  "tailwind-merge": "^2.2.0"
}
```

**Why TailwindCSS?**
- Utility-first approach
- Responsive design built-in
- Dark mode support
- Component library integration
- Production size optimization

#### Web3 Libraries
```json
{
  "wagmi": "^2.5.7",
  "viem": "^2.7.6",
  "@rainbow-me/rainbowkit": "^2.0.2",
  "connectkit": "^1.7.3"
}
```

#### Charts & Visualization
```json
{
  "recharts": "^2.10.4",
  "d3": "^7.8.5",
  "react-chartjs-2": "^5.2.0",
  "chart.js": "^4.4.1"
}
```

---

### 3. Admin Dashboard

#### Framework
```json
{
  "@refinedev/core": "^4.45.1",
  "@refinedev/nextjs-router": "^6.0.0",
  "@refinedev/antd": "^5.37.0",
  "antd": "^5.13.3"
}
```

**Why Refine.dev?**
- Headless framework
- Built-in CRUD operations
- Authentication ready
- Multi-provider support
- Type-safe

#### Features
- User management
- Transaction monitoring
- Analytics dashboard
- System health
- Admin controls
- Report generation

---

### 4. Game Frontend (Unity)

#### Unity Version
```
Unity 2022.3 LTS (Long Term Support)
```

#### Packages
```json
{
  "com.unity.addressables": "1.21.19",
  "com.unity.cinemachine": "2.9.7",
  "com.unity.timeline": "1.7.6",
  "com.unity.ui": "1.0.0-preview.18"
}
```

#### Web3 Integration
- **ChainSafe Web3.Unity SDK**
- **Thirdweb Unity SDK**
- **Moralis Unity SDK**

#### Game Types
1. **Slot Games** - 2D
2. **Card Games** - 2D/3D
3. **NFT Battles** - 3D
4. **Metaverse Integration** - 3D

---

## ⚙️ Backend Technologies

### 1. API Server (Node.js)

#### Runtime
```json
{
  "node": "^18.19.0",
  "npm": "^10.2.4"
}
```

**Why Node.js 18 LTS?**
- Long-term support until 2025
- Native Fetch API
- Test runner built-in
- Performance improvements
- ESM support

#### Framework
```json
{
  "express": "^4.18.2",
  "fastify": "^4.26.0"
}
```

**Express for**:
- Main API server
- Established ecosystem
- Middleware rich

**Fastify for**:
- High-performance endpoints
- WebSocket server
- Real-time features

#### Middleware
```json
{
  "cors": "^2.8.5",
  "helmet": "^7.1.0",
  "compression": "^1.7.4",
  "express-rate-limit": "^7.1.5",
  "express-validator": "^7.0.1",
  "morgan": "^1.10.0"
}
```

#### Authentication
```json
{
  "jsonwebtoken": "^9.0.2",
  "bcrypt": "^5.1.1",
  "passport": "^0.7.0",
  "passport-jwt": "^4.0.1",
  "passport-local": "^1.0.0",
  "@simplewebauthn/server": "^9.0.3"
}
```

#### Validation
```json
{
  "joi": "^17.12.0",
  "zod": "^3.22.4",
  "class-validator": "^0.14.1"
}
```

---

### 2. GraphQL Server

#### Core
```json
{
  "graphql": "^16.8.1",
  "apollo-server-express": "^3.13.0",
  "graphql-scalars": "^1.22.4",
  "graphql-shield": "^7.6.5",
  "dataloader": "^2.2.2"
}
```

**GraphQL Benefits**:
- Single endpoint
- Client-driven queries
- Type safety
- Real-time subscriptions
- Efficient data fetching

#### Schema
```graphql
type User {
  id: ID!
  walletAddress: String!
  worldIdVerified: Boolean!
  balance: Balance!
  stakes: [Stake!]!
  referrals: [Referral!]!
}

type Query {
  me: User
  user(id: ID!): User
  transactions(first: Int, after: String): TransactionConnection
}

type Mutation {
  verifyWorldID(proof: WorldIDProofInput!): VerifyResult!
  swap(from: TokenInput!, to: TokenInput!): SwapResult!
  stake(amount: String!, period: Int!): StakeResult!
}

type Subscription {
  transactionUpdated(userId: ID!): Transaction!
  priceUpdated(token: String!): Price!
}
```

---

### 3. WebSocket Server

#### Libraries
```json
{
  "ws": "^8.16.0",
  "socket.io": "^4.6.1",
  "ioredis": "^5.3.2"
}
```

**Use Cases**:
- Real-time price updates
- Transaction notifications
- Game events
- Chat system
- Live leaderboards

#### Implementation
```javascript
// Socket.IO Rooms
io.on('connection', (socket) => {
  // Join user room
  socket.join(`user:${userId}`);
  
  // Join price rooms
  socket.join('prices:ZEA');
  socket.join('prices:ZEAZ');
  
  // Emit updates
  io.to(`user:${userId}`).emit('transaction:update', data);
  io.to('prices:ZEA').emit('price:update', price);
});
```

---

### 4. Background Workers

#### Queue System
```json
{
  "bull": "^4.12.0",
  "bullmq": "^5.1.9",
  "@bull-board/express": "^5.14.2"
}
```

**Job Types**:
1. **Transaction Processing**
   - Confirm blockchain transactions
   - Update balances
   - Send notifications

2. **Reward Distribution**
   - Daily check-in rewards
   - Staking rewards calculation
   - Referral commissions

3. **Data Sync**
   - Sync blockchain events
   - Update token prices
   - Generate reports

4. **Maintenance**
   - Clean expired sessions
   - Archive old logs
   - Generate backups

#### Worker Configuration
```javascript
const rewardWorker = new Worker('rewards', async (job) => {
  const { userId, amount, type } = job.data;
  
  // Process reward
  await distributeReward(userId, amount, type);
  
  // Update database
  await updateUserBalance(userId, amount);
  
  // Send notification
  await sendNotification(userId, 'reward_received', { amount });
}, {
  concurrency: 10,
  limiter: {
    max: 100,
    duration: 60000 // 100 jobs per minute
  }
});
```

---

## ⛓️ Blockchain & Smart Contracts

### 1. Development Framework

#### Hardhat
```json
{
  "hardhat": "^2.19.5",
  "@nomicfoundation/hardhat-toolbox": "^4.0.0",
  "@nomicfoundation/hardhat-verify": "^2.0.3"
}
```

**Why Hardhat?**
- Built-in TypeScript support
- Extensive plugin ecosystem
- Advanced debugging
- Mainnet forking
- Gas reporting

#### Alternative: Foundry
```bash
forge 0.2.0
cast 0.2.0
anvil 0.2.0
```

**Foundry Benefits**:
- Rust-based (faster)
- Fuzz testing built-in
- Gas snapshots
- Advanced scripting

---

### 2. Smart Contract Language

#### Solidity
```json
{
  "solidity": "^0.8.20"
}
```

**Compiler Settings**:
```javascript
{
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      },
      viaIR: true
    }
  }
}
```

---

### 3. Smart Contract Libraries

#### OpenZeppelin
```json
{
  "@openzeppelin/contracts": "^5.0.1",
  "@openzeppelin/contracts-upgradeable": "^5.0.1"
}
```

**Used Contracts**:
- `ERC20.sol` - Token standard
- `Ownable.sol` - Access control
- `ReentrancyGuard.sol` - Security
- `Pausable.sol` - Emergency stop
- `SafeERC20.sol` - Safe transfers

#### Chainlink
```json
{
  "@chainlink/contracts": "^0.8.0"
}
```

**Used Services**:
- **VRF (Verifiable Random Function)** - Provably fair randomness for games
- **Price Feeds** - Token price oracles
- **Automation** - Automated reward distribution

---

### 4. Web3 Libraries

#### Ethers.js
```json
{
  "ethers": "^6.10.0"
}
```

**Why Ethers.js v6?**
- Complete TypeScript rewrite
- Modern async/await
- Better error handling
- Smaller bundle size
- ENS integration

#### Usage Example
```typescript
import { ethers } from 'ethers';

const provider = new ethers.JsonRpcProvider(RPC_URL);
const signer = new ethers.Wallet(PRIVATE_KEY, provider);
const contract = new ethers.Contract(ADDRESS, ABI, signer);

// Call contract
const balance = await contract.balanceOf(userAddress);
const tx = await contract.transfer(to, amount);
await tx.wait();
```

---

### 5. Supported Blockchain Networks

| Network | Chain ID | RPC Provider | Purpose |
|---------|----------|--------------|---------|
| WorldChain Mainnet | TBD | Alchemy | Primary network |
| Ethereum Mainnet | 1 | Infura/Alchemy | Major DeFi |
| Base | 8453 | Alchemy | Low fees |
| Polygon | 137 | Alchemy | Scalability |
| BSC | 56 | NodeReal | Gaming |
| Arbitrum | 42161 | Alchemy | L2 scaling |
| Optimism | 10 | Alchemy | L2 scaling |
| Sepolia Testnet | 11155111 | Infura | Testing |

---

### 6. Smart Contract Architecture

```
contracts/
├── tokens/
│   ├── ZeaToken.sol           # $ZEA ERC-20
│   └── ZeaZToken.sol          # $ZEAZ ERC-20
├── rewards/
│   ├── WorldIDRewards.sol     # World ID verification & rewards
│   ├── StakingRewards.sol     # Staking system
│   └── ReferralRewards.sol    # Referral program
├── defi/
│   ├── ZeaSwap.sol           # DEX router
│   ├── LiquidityPool.sol     # AMM pool
│   └── Farming.sol           # Yield farming
├── nft/
│   ├── ZeaNFT.sol            # ERC-721 NFT
│   └── NFTMarketplace.sol    # NFT marketplace
├── gaming/
│   ├── GameSlots.sol         # Slot games
│   └── GameTournament.sol    # Tournament system
└── governance/
    ├── ZeaGovernor.sol       # Governance
    └── Timelock.sol          # Execution delay
```

---

## 🗄️ Databases & Caching

### 1. PostgreSQL 15+

**Primary Database**

```yaml
version: '3.8'
services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: zeazdev_main
      POSTGRES_USER: zeazdev
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
```

**Extensions**:
- `pgcrypto` - Encryption
- `uuid-ossp` - UUID generation
- `pg_stat_statements` - Query analytics
- `timescaledb` - Time-series data

**ORM/Query Builder**:
```json
{
  "prisma": "^5.8.1",
  "@prisma/client": "^5.8.1",
  "knex": "^3.1.0",
  "pg": "^8.11.3"
}
```

---

### 2. MongoDB 6+

**Logs & Analytics Database**

```yaml
mongodb:
  image: mongo:6
  environment:
    MONGO_INITDB_ROOT_USERNAME: admin
    MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD}
  volumes:
    - mongodb_data:/data/db
  ports:
    - "27017:27017"
```

**ODM**:
```json
{
  "mongoose": "^8.1.0"
}
```

**Collections**:
- `transaction_logs`
- `event_logs`
- `audit_trails`
- `analytics_events`

---

### 3. Redis 7+

**Caching & Queue**

```yaml
redis:
  image: redis:7-alpine
  command: redis-server --appendonly yes
  volumes:
    - redis_data:/data
  ports:
    - "6379:6379"
```

**Client**:
```json
{
  "ioredis": "^5.3.2",
  "redis": "^4.6.12"
}
```

**Use Cases**:
- Session storage
- Token price cache
- Rate limiting
- Job queue (Bull)
- Pub/Sub messaging

---

### 4. IPFS (Storage)

**Decentralized Storage**

```json
{
  "ipfs-http-client": "^60.0.1",
  "nft.storage": "^7.1.1"
}
```

**Stored on IPFS**:
- NFT metadata
- User avatars
- Game assets
- Documentation

**Providers**:
- Pinata
- NFT.Storage
- Web3.Storage
- Infura IPFS

---

## 🚀 Infrastructure & DevOps

### 1. Cloud Providers

#### Primary: AWS
**Services Used**:
- **EC2** - Application servers
- **RDS** - Managed PostgreSQL
- **ElastiCache** - Managed Redis
- **S3** - Static asset storage
- **CloudFront** - CDN
- **Route 53** - DNS
- **ELB** - Load balancing
- **WAF** - Web application firewall
- **CloudWatch** - Monitoring

#### Secondary: GCP
**Services Used**:
- **GKE** - Kubernetes Engine
- **Cloud SQL** - Managed database
- **Cloud Storage** - Object storage
- **Cloud CDN** - Content delivery
- **Cloud Armor** - DDoS protection

---

### 2. Container Orchestration

#### Docker
```dockerfile
FROM node:18-alpine AS base

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

EXPOSE 3000
CMD ["npm", "start"]
```

#### Kubernetes
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: zeazdev-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: zeazdev-api
  template:
    metadata:
      labels:
        app: zeazdev-api
    spec:
      containers:
      - name: api
        image: zeazdev/api:latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
```

---

### 3. CI/CD Pipeline

#### GitHub Actions
```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 18
      - run: npm ci
      - run: npm run lint
      - run: npm run test
      - run: npm run build

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Deploy to Production
        run: |
          kubectl apply -f k8s/
          kubectl rollout status deployment/zeazdev-api
```

---

### 4. Reverse Proxy & Load Balancer

#### Nginx
```nginx
upstream api_backend {
    least_conn;
    server api1.zeaz.dev:3000 weight=10;
    server api2.zeaz.dev:3000 weight=10;
    server api3.zeaz.dev:3000 weight=5 backup;
}

server {
    listen 443 ssl http2;
    server_name api.zeaz.dev;
    
    ssl_certificate /etc/ssl/certs/zeaz.dev.crt;
    ssl_certificate_key /etc/ssl/private/zeaz.dev.key;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req zone=api burst=20 nodelay;
    
    location / {
        proxy_pass http://api_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

---

## 🔒 Security & Monitoring

### 1. Security Tools

```json
{
  "@aws-sdk/client-secrets-manager": "^3.490.0",
  "helmet": "^7.1.0",
  "rate-limiter-flexible": "^4.0.0",
  "express-mongo-sanitize": "^2.2.0",
  "xss-clean": "^0.1.4"
}
```

### 2. Monitoring Stack

#### Prometheus + Grafana
```yaml
prometheus:
  image: prom/prometheus:latest
  volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml
    - prometheus_data:/prometheus
  ports:
    - "9090:9090"

grafana:
  image: grafana/grafana:latest
  environment:
    - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
  volumes:
    - grafana_data:/var/lib/grafana
  ports:
    - "3001:3000"
```

#### Logging
```json
{
  "winston": "^3.11.0",
  "winston-daily-rotate-file": "^5.0.0",
  "pino": "^8.17.2",
  "pino-pretty": "^10.3.1"
}
```

---

## 🔌 Third-Party Integrations

### 1. Payment Providers
- **Moonpay** - Fiat on-ramp
- **Transak** - Crypto purchase
- **2C2P** - Thai payment gateway
- **Omise** - Payment processing

### 2. KYC/AML
- **Sumsub** - Identity verification
- **Onfido** - KYC solution
- **Jumio** - ID verification

### 3. Communication
- **SendGrid** - Email service
- **Twilio** - SMS service
- **Telegram Bot API** - Notifications

### 4. Analytics
- **Google Analytics 4**
- **Mixpanel**
- **Amplitude**
- **PostHog** (Open source)

---

## 🛠️ Development Tools

### 1. Code Quality
```json
{
  "eslint": "^8.56.0",
  "prettier": "^3.2.4",
  "husky": "^9.0.6",
  "lint-staged": "^15.2.0",
  "commitlint": "^18.6.0"
}
```

### 2. Testing
```json
{
  "jest": "^29.7.0",
  "vitest": "^1.2.0",
  "@testing-library/react": "^14.1.2",
  "supertest": "^6.3.4",
  "hardhat": "^2.19.5"
}
```

### 3. Documentation
```json
{
  "typedoc": "^0.25.7",
  "swagger-ui-express": "^5.0.0",
  "redoc": "^2.1.3"
}
```

---

**Last Updated**: 2025-01-09  
**Version**: 1.0.0  
**Maintained by**: PHIPHAT PHOEMSUK (ZeaZDev)
