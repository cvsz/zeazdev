# ZeaZDev

> A comprehensive Web3 reward and airdrop distribution platform built on Ethereum-compatible blockchains

ZeaZDev is a production-ready blockchain platform designed to simplify the deployment and management of token airdrops and reward distribution systems. It leverages Merkle Tree cryptography for efficient on-chain verification, supports multi-chain deployments, and integrates WorldID for Sybil-resistant user verification.

## ✨ Key Features

- **🎁 Merkle-based Airdrop System** - Efficient token distribution using Merkle Tree proofs, significantly reducing gas costs
- **🏆 On-chain Reward Distribution** - Secure reward system with idempotency protection to prevent double-spending
- **🌍 Multi-chain Support** - Deploy seamlessly on WorldChain, Base, Sepolia, and Ethereum Mainnet
- **🔐 WorldID Integration** - Sybil-resistant identity verification using Worldcoin's Proof of Personhood
- **🚀 Automated Deployment** - One-command deployment scripts with automatic contract verification
- **📊 Real-time Monitoring** - Dashboard for tracking distributions, transactions, and system health
- **🔔 Telegram Notifications** - Automated alerts for critical events and transactions
- **⚡ Gasless Transactions** - Relayer service for sponsoring user transactions (meta-transactions)

## 🛠️ Technology Stack

### Backend
- **Smart Contracts:** Solidity ^0.8.20
- **Development Framework:** Hardhat
- **Libraries:** OpenZeppelin Contracts, ethers.js v6
- **Runtime:** Node.js 18+
- **API Server:** Express.js (for Relayer service)

### Frontend
- **Framework:** Next.js 14+ (React 18+)
- **Web3 Integration:** wagmi, viem, @tanstack/react-query
- **UI Framework:** TailwindCSS
- **Wallet Support:** MetaMask, WalletConnect
- **Identity:** @worldcoin/idkit

### Blockchain / Web3
- **Token Standard:** ERC-20
- **Networks:** WorldChain (Primary), Base, Ethereum, Sepolia (Testnet)
- **Merkle Tree:** merkletreejs, keccak256
- **Verification:** Etherscan API

### DevOps
- **Containerization:** Docker, Docker Compose
- **Web Server:** Nginx with SSL/TLS
- **Process Management:** PM2
- **SSL Certificates:** Certbot (Let's Encrypt)
- **Monitoring:** Telegram Bot integration
- **Version Control:** Git

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed and configured:

- **Node.js v18+** - [Download here](https://nodejs.org/)
- **npm or yarn** - Package manager (comes with Node.js)
- **Docker Desktop** (Optional, for containerized deployment) - [Download here](https://www.docker.com/)
- **MetaMask or compatible wallet** - For testing
- **Private Keys** - Deployer and Relayer wallet private keys
- **RPC Endpoints** - For target blockchain networks

### Installation & Configuration

1. **Clone the Repository**
   ```bash
   git clone https://github.com/ZeaZDev/ZeaZDev.git
   cd ZeaZDev
   ```

2. **Install Dependencies**
   ```bash
   # Install root dependencies
   npm install
   
   # If using separate packages
   cd contracts && npm install
   cd ../frontend && npm install
   ```

3. **Environment Configuration**
   
   Create a `.env` file in the project root (you can start by running `sudo bash run.sh` once, which will create a template):
   
   ```bash
   # First run to generate .env template
   sudo bash run.sh
   ```
   
   Then edit the generated `.env` file:
   
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

#### Method 1: Automated Deployment (Recommended)

The easiest way to deploy the entire system:

```bash
# Run the automated installer
sudo bash run.sh
```

This script will:
1. Generate `.env` template if it doesn't exist (stop and prompt you to edit it)
2. Export environment variables
3. Run the main installer script
4. Deploy smart contracts on all configured networks
5. Set up frontend and backend services
6. Configure Nginx with SSL
7. Start monitoring services

#### Method 2: Manual Deployment

For development or custom deployment:

**Step 1: Generate Merkle Tree**
```bash
cd packages/merkle-generator
npm install
node generate-merkle.js
```

**Step 2: Compile Contracts**
```bash
cd packages/hardhat
npm install
npx hardhat compile
```

**Step 3: Deploy Contracts**
```bash
# Deploy to specific network
npx hardhat run scripts/deploy.js --network sepolia

# Or use the automated script
bash ZeaZDev-Release-v10.1.sh
```

**Step 4: Start Frontend**
```bash
cd packages/frontend
npm install
npm run build
npm start
```

The frontend will be available at `http://localhost:3000`

**Step 5: Start Backend/Relayer (Optional)**
```bash
cd packages/backend
npm install
npm start
```

#### Method 3: Docker Deployment

For containerized deployment:

```bash
# Build and start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

### Accessing the Application

After successful deployment:

- **Frontend dApp:** `https://app.zeaz.dev` or `http://localhost:3000`
- **Admin Dashboard:** `https://dash.zeaz.dev` or `http://localhost:8080`
- **API Server:** `https://api.zeaz.dev` or `http://localhost:3001`

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

1. **Connect Your Wallet**
   - Visit the frontend dApp
   - Click "Connect Wallet"
   - Approve the connection in MetaMask or WalletConnect

2. **Check Airdrop Eligibility**
   - The system will automatically check if your address is in the whitelist
   - If eligible, you'll see the amount you can claim

3. **Claim Your Airdrop**
   - Click the "Claim" button
   - Approve the transaction in your wallet
   - Wait for confirmation
   - Tokens will be transferred to your wallet

4. **Verify with WorldID (Optional)**
   - For certain features, you may need to verify your identity
   - Click "Verify with WorldID"
   - Follow the prompts in the World App
   - Complete the verification

### For Administrators

1. **Deploy Smart Contracts**
   ```bash
   sudo bash run.sh
   ```

2. **Monitor System**
   - Access the Admin Dashboard
   - View transaction history
   - Check system health
   - Monitor reward distributions

3. **Distribute Rewards**
   - The relayer service automatically handles reward distributions
   - Manual distribution can be done through the dashboard
   - All distributions are logged and can be audited

4. **Update Whitelist**
   - Edit the whitelist JSON file
   - Regenerate Merkle tree
   - Update the Merkle root in the contract (requires owner access)

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
