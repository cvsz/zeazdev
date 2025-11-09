# 🚀 Quick Start Guide - All Phases

This guide helps you get started with the ZeaZDev platform quickly.

## Prerequisites

Before you begin, ensure you have:
- **Node.js v18+** installed ([download here](https://nodejs.org/))
- **npm** (comes with Node.js)
- **Git** for version control

## Quick Start Commands

### ⚡ Fastest Way - Using npm

The simplest way to get started using npm scripts:

```bash
# 1. Validate configuration
npm run check

# 2. Install dependencies
npm run install:all

# 3. Start all services
npm start
```

### 🎯 First-Time Setup (Detailed)

1. **Validate Configuration**
```bash
npm run check
# or
bash start-all-phases.sh --check
```

This validates your environment without starting services. If `.env` files are missing, it will show you how to create them:

```bash
# Copy example files to create your .env files
cp server/.env.example server/.env
cp mini-app/.env.example mini-app/.env

# Edit with your actual configuration
nano server/.env
nano mini-app/.env
```

2. **Install Dependencies**
```bash
npm run install:all
# or
bash start-all-phases.sh --install
```

3. **Validate Again**
```bash
npm run check
# or
bash start-all-phases.sh --check
```

### 🎯 Start Everything (Recommended)
```bash
npm start
# or
npm run start:all
# or
bash start-all-phases.sh --all
```

This will:
1. Check prerequisites
2. Validate environment configuration
3. Install dependencies
4. Start backend service
5. Start mini-app with Expo
6. Show service status

### 📊 Check Status
```bash
npm run status
# or
bash start-all-phases.sh --status
```

Shows:
- Running services (backend, frontend)
- Port availability
- Phase completion percentages

### 🛑 Stop All Services
```bash
npm run stop
# or
bash start-all-phases.sh --stop
```

Cleanly stops all running services.

### 📦 Install Dependencies Only
```bash
npm run install:all
# or
bash start-all-phases.sh --install
```

Installs dependencies without starting services.

## Component-Specific Commands

### Backend Only
```bash
npm run start:backend
# or
bash start-all-phases.sh --backend
```

### Frontend Only
```bash
npm run start:frontend
# or
bash start-all-phases.sh --frontend
```

### Smart Contracts Check
```bash
bash start-all-phases.sh --contracts
```

## Environment Setup

Before running services, create these `.env` files:

### 1. Server Environment (`server/.env`)

Copy from example:
```bash
cp server/.env.example server/.env
```

Then edit with your values:
```bash
# Server Configuration
PORT=3000

# World ID Configuration
WORLD_APP_ID=app_staging_your_app_id_here
WORLD_APP_API_KEY=api_your_secret_api_key_here
WORLD_ACTION_ID=verify-humanity

# Blockchain Configuration
RPC_URL=https://worldchain-mainnet.g.alchemy.com/v2/your-key
RELAYER_PRIVATE_KEY=0xYOUR_RELAYER_PRIVATE_KEY

# Contract Addresses (update after deployment)
WORLD_ID_REWARDS_CONTRACT=0x0000000000000000000000000000000000000000
ZEA_TOKEN_CONTRACT=0x0000000000000000000000000000000000000000
```

### 2. Mini-App Environment (`mini-app/.env`)

Copy from example:
```bash
cp mini-app/.env.example mini-app/.env
```

Then edit with your values:
```bash
# World ID Configuration
WORLD_APP_ID=app_staging_your_app_id_here
WORLD_ACTION_ID=verify-humanity

# API Configuration
API_URL=http://localhost:3000
RPC_URL=https://worldchain-mainnet.g.alchemy.com/v2/your-key
```

## Testing the Application

### 1. Backend API Test
```bash
curl http://localhost:3000/health
```

### 2. Mini-App Test
1. Scan the QR code in Expo DevTools
2. Open in Expo Go app on your device
3. Test World ID verification
4. Test wallet, rewards, and swap features

## Phase Tracking

### View Current Phase Status
```bash
cat PHASE_STATUS.md
```

### Current Status (as of 2025-11-09)
- **Phase 1 (Foundation):** 95% Complete ✅
- **Phase 2 (Core Features):** Planned (Q2 2025) 🟡
- **Phase 3 (Advanced Features):** Planned (Q3 2025) 🟡
- **Phase 4 (Enterprise & Scaling):** Planned (Q4 2025) 🟡

## Troubleshooting

### Configuration Issues
```bash
# Validate your configuration
bash start-all-phases.sh --check

# If .env files are missing, follow the instructions provided
```

### Port 3000 Already in Use
```bash
# Find process using port 3000
lsof -i :3000

# Kill the process
kill -9 <PID>

# Or use the stop command
npm run stop
# or
bash start-all-phases.sh --stop
```

### Dependencies Not Installing
```bash
# Clear npm cache
npm cache clean --force

# Try installing again
npm run install:all
# or
bash start-all-phases.sh --install
```

### Services Not Starting
1. Check logs in `Logs/` directory
2. Verify `.env` files are configured
3. Ensure no other services are using required ports

## Log Files

All logs are stored in `Logs/` directory:
- `server_<timestamp>.log` - Backend service logs
- `miniapp_<timestamp>.log` - Mini-app logs
- `server.pid` - Backend process ID
- `miniapp.pid` - Mini-app process ID

## Next Steps

1. ✅ Run `npm run check` (or `bash start-all-phases.sh --check`) to validate setup
2. ✅ Configure `.env` files using the `.env.example` templates
3. ✅ Run `npm start` (or `bash start-all-phases.sh --all`)
4. ✅ Test backend API at http://localhost:3000/health
5. ✅ Test mini-app on your device
6. ✅ Check `PHASE_STATUS.md` for development roadmap

## Getting Help

```bash
# Show all available npm scripts
npm run

# Show all script options
bash start-all-phases.sh --help
```

**Support:**
- Email: admin@zeaz.dev
- Website: https://app.zeaz.dev
- GitHub: https://github.com/ZeaZDev

---

*For detailed documentation, see [README.md](README.md) and [ROADMAP.md](ROADMAP.md)*
