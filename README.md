# ZeaZDev Mini App

> A World App Mini App with World ID verification for Sybil-resistant rewards and DeFi features

ZeaZDev is a production-ready World App Mini App that uses Zero-Knowledge Proof (ZKP) via World ID to provide Proof of Personhood verification. Users can claim daily rewards, receive airdrops, manage their wallets, and swap tokens - all with gasless transactions powered by a relayer service.

## ✨ Key Features

- **🌍 World ID Verification (ZKP)** - Zero-Knowledge Proof verification for Proof of Personhood, preventing Sybil attacks without revealing personal data
- **📱 React Native Mini App** - Mobile-first experience built with Expo, runs natively in World App
- **🎁 Daily Check-in Rewards** - Earn ZEA tokens every 24 hours with streak tracking to incentivize continuous engagement
- **💰 One-time Airdrop** - Welcome bonus for verified World ID users (1000 ZEA tokens)
- **⚡ Gasless Transactions** - Relayer service pays gas fees, enabling frictionless onboarding for new users
- **💱 DEX Token Swap** - Integrated decentralized exchange functionality for swapping WLD, ETH, ZEA, and USDC
- **👛 Multi-Token Wallet** - Manage WLD tokens and gas tokens (ETH/MATIC) with send functionality
- **🔒 Nullifier Hash Protection** - Prevents the same World ID from being used multiple times (anti-replay attack)
- **🔄 Automatic Streak Tracking** - Consecutive daily check-ins build streaks for potential bonus rewards

## 🛠️ Technology Stack

### Frontend (Mini App)
- **Framework:** React Native 0.73 with Expo ~50.0
- **Navigation:** Expo Router ~3.4
- **World ID SDK:** @worldcoin/idkit-core ^1.0
- **Web3 Integration:** ethers.js ^6.10
- **Storage:** @react-native-async-storage/async-storage
- **Language:** TypeScript 5.3+

### Backend (Verifier & Relayer)
- **Runtime:** Node.js 18+
- **API Framework:** Express.js 4.18
- **Web3 Library:** ethers.js 6.10
- **CORS:** cors 2.8
- **Environment:** dotenv 16.3

### Smart Contracts
- **Language:** Solidity ^0.8.20
- **Development:** Hardhat
- **Libraries:** OpenZeppelin Contracts (Ownable, ReentrancyGuard, IERC20)
- **Token Standard:** ERC-20
- **Networks:** WorldChain (Primary), Ethereum, Base, Sepolia

### Key Smart Contract Features
- World ID ZKP verification with nullifier tracking
- Daily check-in with 24-hour cooldown
- One-time airdrop claim system
- Check-in streak tracking
- Idempotency protection

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed and configured:

- **Node.js v18+** - [Download here](https://nodejs.org/)
- **npm or yarn** - Package manager (comes with Node.js)
- **Expo CLI** - Install with `npm install -g expo-cli`
- **Expo Go App** (iOS/Android) - For testing Mini App on real devices
- **World ID Account** - Register at [World App](https://worldcoin.org/download)
- **World ID Developer Portal Access** - [developer.worldcoin.org](https://developer.worldcoin.org/)
- **Private Keys:**
  - Deployer wallet private key (for smart contract deployment)
  - Relayer wallet private key (for gasless transactions)
- **RPC Endpoints** - Alchemy or Infura API keys for target blockchain networks

### World ID Setup Instructions

#### Step 1: Register Your Mini App on Worldcoin Developer Portal

1. **Visit the Developer Portal:**
   - Go to [https://developer.worldcoin.org/](https://developer.worldcoin.org/)
   - Sign in with your Worldcoin account

2. **Create a New App:**
   - Click "Create New App"
   - Enter app details:
     - **App Name:** ZeaZDev Mini App
     - **App Description:** World ID verified rewards and DeFi platform
     - **App Type:** Mini App

3. **Configure Actions:**
   - Create an action for verification:
     - **Action Name:** `verify-humanity`
     - **Action ID:** (will be auto-generated, e.g., `verify-humanity_12345`)
     - **Description:** Verify user is a unique human for rewards
     - **Max Verifications:** 1 (per person)

4. **Get Your Credentials:**
   - **App ID:** (e.g., `app_staging_abc123def456...`) - For frontend
   - **API Key:** (e.g., `api_secret_xyz789...`) - For backend verification
   - **Action ID:** Use for specific verification flows

5. **Configure Callback URLs** (if using web version):
   - Development: `http://localhost:3000`
   - Production: `https://app.zeaz.dev`

#### Step 2: Set Environment Variables

Create a `.env` file in both `mini-app/` and `server/` directories:

### Installation & Configuration

1. **Clone the Repository**
   ```bash
   git clone https://github.com/ZeaZDev/ZeaZDev.git
   cd ZeaZDev
   ```

2. **Configure Mini App (Frontend)**
   
   ```bash
   cd mini-app
   npm install
   ```
   
   Create `mini-app/.env`:
   ```bash
   # World ID Configuration (from Developer Portal)
   WORLD_APP_ID=app_staging_your_app_id_here
   WORLD_ACTION_ID=verify-humanity_your_action_id
   
   # API Configuration
   API_URL=http://localhost:3000
   RPC_URL=https://worldchain-mainnet.g.alchemy.com/v2/your-key
   ```

3. **Configure Backend Verifier**
   
   ```bash
   cd ../server
   npm install
   ```
   
   Create `server/.env`:
   ```bash
   # Server Configuration
   PORT=3000
   
   # World ID Configuration
   WORLD_APP_ID=app_staging_your_app_id_here
   WORLD_APP_API_KEY=api_your_secret_api_key_here
   WORLD_ACTION_ID=verify-humanity_your_action_id
   
   # Blockchain Configuration
   RPC_URL=https://worldchain-mainnet.g.alchemy.com/v2/your-key
   RELAYER_PRIVATE_KEY=0xYOUR_RELAYER_PRIVATE_KEY
   
   # Contract Addresses (update after deployment)
   WORLD_ID_REWARDS_CONTRACT=0x0000000000000000000000000000000000000000
   ZEA_TOKEN_CONTRACT=0x0000000000000000000000000000000000000000
   ```

4. **Deploy Smart Contracts**
   
   ```bash
   cd ../contracts
   npm install
   npx hardhat compile
   
   # Deploy WorldIDRewards contract
   npx hardhat run scripts/deploy-worldid-rewards.js --network worldchain
   ```
   
   Copy the deployed contract addresses and update them in `server/.env`

5. **Legacy Configuration (if using original deployment scripts)**
   
   For backward compatibility with existing deployment scripts:
   
   Create `.env` file in the project root:
   
   ```ini
   # === ZeaZDev Configuration ===
   
   # 1. Network Configuration (Required)
   # Format: network_name=rpc_url (comma-separated, no spaces)
   MULTI_RPC_LIST="worldchain=https://worldchain-mainnet.g.alchemy.com/v2/YOUR_KEY,base=https://base-mainnet.g.alchemy.com/v2/YOUR_KEY,sepolia=https://sepolia.infura.io/v3/YOUR_KEY"
   
   # 2. Private Keys (Required)
   # Deployer Key: Used to deploy contracts and own them
   PRIVATE_KEY="0xYOUR_DEPLOYER_PRIVATE_KEY"
   # Relayer Key: Hot wallet for gasless transactions
   RELAYER_PRIVATE_KEY="0xYOUR_RELAYER_PRIVATE_KEY"
   
   # 3. WorldID Configuration (Required for identity features)
   # Public App ID for Frontend/IDKit
   WORLD_APP_ID="app_staging_YOUR_APP_ID"
   # Secret API Key for Backend verification
   WORLD_APP_API_KEY="api_YOUR_API_KEY"
   
   # 4. Domain Configuration (Required for production)
   FRONT_DOMAIN="app.zeaz.dev"
   DASH_DOMAIN="dash.zeaz.dev"
   API_DOMAIN="api.zeaz.dev"
   
   # 5. Block Explorer Verification (Optional)
   ETHERSCAN_API_KEY="YOUR_ETHERSCAN_API_KEY"
   
   # 6. Notifications (Optional)
   TELEGRAM_BOT_TOKEN="YOUR_BOT_TOKEN"
   TELEGRAM_CHAT_ID="YOUR_CHAT_ID"
   
   # 7. Git Logging (Optional)
   GIT_LOG_REPO="https://github.com/yourusername/logs.git"
   GIT_LOG_BRANCH="main"
   ```

4. **Configure Whitelist for Airdrop**
   
   Edit the whitelist file for Merkle tree generation:
   
   ```bash
   nano packages/merkle-generator/whitelist.example.json
   ```
   
   Example format:
   ```json
   [
     {
       "address": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
       "amount": "100000000000000000000"
     },
     {
       "address": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
       "amount": "250000000000000000000"
     }
   ]
   ```

### Running the Project

#### Running the Mini App (Development)

**Step 1: Start Backend Verifier Server**
```bash
cd server
npm start
```

The backend will start on `http://localhost:3000` and handle:
- World ID proof verification
- Gasless transaction relay
- Reward distribution
- Swap quotes

**Step 2: Start Mini App**
```bash
cd mini-app
npm start
# or
expo start
```

This will open the Expo Dev Tools in your browser.

**Step 3: Test on Device**
- Scan the QR code with Expo Go app (iOS/Android)
- The Mini App will load on your device
- Test World ID verification flow
- Test all features (Wallet, Rewards, Swap)

#### Running on World App (Production)

To deploy your Mini App to World App:

1. **Build for Production:**
   ```bash
   cd mini-app
   eas build --platform ios
   eas build --platform android
   ```

2. **Submit to World App:**
   - Follow World App Mini App submission guidelines
   - Provide App ID and action configurations
   - Wait for approval

3. **Production Backend:**
   ```bash
   cd server
   npm start
   # Use PM2 for process management in production
   pm2 start verifier.js --name zeazdev-verifier
   ```

#### Legacy Deployment (Original Scripts)

For backward compatibility with existing deployment infrastructure:

```bash
# Run the automated installer
sudo bash run.sh
```

This will deploy the original Web3 infrastructure including Merkle-based airdrops.

### Accessing the Application

**Development:**
- **Mini App:** Via Expo Go app (scan QR code)
- **Backend API:** `http://localhost:3000`
- **Smart Contracts:** Deployed on configured networks

**Production (World App):**
- **Mini App:** Available in World App's Mini Apps section
- **Backend API:** Your production API URL
- **Smart Contracts:** Deployed on WorldChain/Ethereum Mainnet

## 🧪 Running Tests

To run the automated tests for smart contracts:

```bash
cd packages/hardhat
npx hardhat test
```

To run tests with coverage:

```bash
npx hardhat coverage
```

To run frontend tests:

```bash
cd packages/frontend
npm test
```

## 📖 Usage Guide

### For End Users

#### First Time Setup

1. **Open ZeaZDev Mini App**
   - Launch World App on your device
   - Navigate to Mini Apps section
   - Open ZeaZDev Mini App

2. **Verify with World ID (Required)**
   - The app will show "Verify with World ID" screen
   - Click the verification button
   - World App will prompt you to scan with Orb or use Device verification
   - Complete the verification process
   - Your Zero-Knowledge Proof will be generated and verified
   - Once successful, you'll gain access to all features

#### Daily Usage

**Claim Welcome Airdrop (One-time)**
1. After verification, go to "Rewards" tab
2. Find the "Welcome Airdrop" section
3. Click "Claim Airdrop"
4. Confirm the transaction
5. Receive 1000 ZEA tokens instantly (gasless!)

**Daily Check-in**
1. Open "Rewards" tab
2. Click "Check In Now" button (available every 24 hours)
3. Earn 100 ZEA tokens per check-in
4. Build your streak by checking in daily
5. Track your total rewards and current streak

**Manage Wallet**
1. Go to "Wallet" tab
2. View your WLD and Gas token balances
3. Send tokens:
   - Click "Send" button
   - Select token (WLD or ETH)
   - Enter recipient address
   - Enter amount
   - Confirm transaction (gasless!)

**Swap Tokens**
1. Go to "Swap" tab
2. Select tokens to swap (e.g., WLD → ETH)
3. Enter amount
4. Review exchange rate and price impact
5. Click "Swap" and confirm
6. Transaction executes via DEX (gasless!)

### For Developers

#### Deploy New Instance

1. **Register Mini App:**
   ```bash
   # Get World App ID and API Key from developer portal
   # Update .env files in mini-app/ and server/
   ```

2. **Deploy Smart Contracts:**
   ```bash
   cd contracts
   npx hardhat run scripts/deploy-worldid-rewards.js --network worldchain
   # Note the contract address
   ```

3. **Fund Reward Contract:**
   ```bash
   # Send ZEA tokens to WorldIDRewards contract
   # Ensure relayer wallet has gas tokens
   ```

4. **Update Configuration:**
   ```bash
   # Update contract addresses in server/.env
   # Update API URL in mini-app/.env
   ```

5. **Start Services:**
   ```bash
   # Terminal 1: Backend
   cd server && npm start
   
   # Terminal 2: Mini App
   cd mini-app && expo start
   ```

#### Monitor System

**Check Backend Logs:**
```bash
cd server
npm start
# Watch console for verification requests, transactions
```

**Check Contract Status:**
```bash
npx hardhat console --network worldchain
> const contract = await ethers.getContractAt("WorldIDRewards", "0x...")
> await contract.getContractBalance()
> await contract.isUserVerified("0x...")
```

**Monitor User Activity:**
- All events are emitted on-chain
- Parse `UserVerified`, `DailyCheckIn`, `AirdropClaimed` events
- Track via blockchain explorer

## 📁 Project Structure

```
ZeaZDev/
├── contracts/                  # Smart contracts
│   ├── Reward.sol             # Reward distribution contract
│   └── ...
├── scripts/                    # Deployment and utility scripts
│   ├── deploy.js              # Main deployment script
│   └── ...
├── packages/                   # Monorepo packages (if used)
│   ├── hardhat/               # Hardhat configuration
│   ├── frontend/              # Next.js frontend dApp
│   ├── merkle-generator/      # Merkle tree generator
│   └── installer-app/         # Electron installer (optional)
├── Rewards/                    # Reward system documentation
├── .github/                    # GitHub Actions workflows
├── docker-compose.yml          # Docker Compose configuration
├── run.sh                      # Main execution wrapper
├── ZeaZDev-Release-v10.1.sh   # Main installer script
├── PROJECT_BLUEPRINT.md        # Comprehensive project blueprint
├── .env.example               # Environment variables template
└── README.md                  # This file
```

## 🔐 Security Considerations

### Smart Contract Security
- All contracts use OpenZeppelin's battle-tested implementations
- Ownable pattern for access control
- Idempotency protection to prevent double-spending
- ReentrancyGuard for external calls
- Regular security audits recommended

### Operational Security
- **Private Keys:** Store securely, never commit to version control
- **Environment Variables:** Use `.env` files, add to `.gitignore`
- **Relayer Wallet:** Fund with minimal amount, monitor balance
- **Rate Limiting:** Implement on API endpoints
- **SSL/TLS:** Always use HTTPS in production
- **Firewall:** Configure proper firewall rules
- **Monitoring:** Set up alerts for suspicious activities

### Best Practices
1. Use separate deployer and relayer keys
2. Test on testnets before mainnet deployment
3. Verify all contracts on block explorers
4. Implement multi-signature for critical operations
5. Regular backups of configuration and data
6. Keep dependencies up to date
7. Monitor gas prices and adjust strategies
8. Use hardware wallets for deployer keys in production

## 🤝 Contributing

Contributions are welcome! To contribute to ZeaZDev:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure your code follows the existing style and includes appropriate tests.

### Development Guidelines
- Write clear commit messages
- Add tests for new features
- Update documentation as needed
- Follow Solidity and JavaScript best practices
- Run linter before committing

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

### MIT License Summary
- ✅ Commercial use
- ✅ Modification
- ✅ Distribution
- ✅ Private use
- ⚠️ Liability and warranty limitations apply

## 👤 Contact & Support

**Developer:** PHIPHAT PHOEMSUK (ZeaZDev)

**Email:** admin@zeaz.dev

**Website:** [https://app.zeaz.dev/](https://app.zeaz.dev/)

**GitHub:** [https://github.com/ZeaZDev](https://github.com/ZeaZDev)

### Support Channels
- **GitHub Issues:** For bug reports and feature requests
- **Email:** For general inquiries and support
- **Telegram:** Community support (check website for link)

## 🙏 Acknowledgments

- **OpenZeppelin** - For secure smart contract libraries
- **Hardhat** - For excellent development framework
- **Worldcoin** - For WorldID integration
- **Ethereum Community** - For continuous innovation
- **Contributors** - Thank you to all who have contributed to this project

## 📊 Project Status

- **Current Version:** v10.1
- **Status:** Active Development
- **Stability:** Beta (use with caution in production)
- **Last Updated:** 2025

### Roadmap
- [x] Core smart contracts
- [x] Merkle-based airdrop system
- [x] Multi-chain deployment
- [x] WorldID integration
- [ ] Mobile app
- [ ] Advanced analytics
- [ ] NFT reward support
- [ ] Governance features

## 📚 Additional Resources

- [Project Blueprint (Thai)](PROJECT_BLUEPRINT.md) - Comprehensive technical documentation
- [Smart Contract Documentation](contracts/README.md) - Contract specifications
- [API Documentation](docs/API.md) - Backend API reference
- [Deployment Guide](docs/DEPLOYMENT.md) - Detailed deployment instructions
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions

---

**Note:** This is a living document and will be updated as the project evolves. Always refer to the latest version in the repository.

Made with ❤️ by ZeaZDev Team
