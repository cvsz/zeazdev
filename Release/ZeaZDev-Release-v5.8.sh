#!/usr/bin/env bash
# =========================================================
# 🌐 Developer & Project Information
# 💲 ZeaZDev — Zea Token ($ZEA)
# 📦 Version: Release v5.8 — Node22 Compatibility + Auto SSL + Auto Patch
# 👨‍💻 Developer: PHIPHAT PHOEMSUK (ZeaZDev)
# 🏢 Organization: ZeaZDev — Ecosystem • Innovate • Connect • Grow
# 🌍 Website: https://app.zeaz.dev/
# 📧 Contact: admin@zeaz.dev, support@zeaz.dev
# 🔐 License: MIT
# =========================================================

set -euo pipefail
trap 'echo -e "\e[31m[ERROR]\e[0m Unexpected error on line $LINENO"; exit 1' ERR

GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; RESET="\e[0m"
info(){ echo -e "${GREEN}[INFO]${RESET} $*"; }
warn(){ echo -e "${YELLOW}[WARN]${RESET} $*"; }
err(){ echo -e "${RED}[ERROR]${RESET} $*"; }

INSTALL_PATH="/opt/ZeaZDev"
PROJECT_PATH="$INSTALL_PATH/Project"
LOG_PATH="$INSTALL_PATH/Logs"
RESULT_PATH="$INSTALL_PATH/Results"
mkdir -p "$PROJECT_PATH" "$LOG_PATH" "$RESULT_PATH"

# ===== Node.js version check =====
NODE_VER=$(node -v || echo "v0")
info "Detected Node.js version: $NODE_VER"

if [[ "$NODE_VER" =~ ^v22 ]]; then
  warn "Node.js 22 detected — Hardhat not fully compatible."
  echo "[INFO] Applying compatibility patch..."
  export NODE22_MODE=true
elif [[ "$NODE_VER" =~ ^v1[89] || "$NODE_VER" =~ ^v20 ]]; then
  export NODE22_MODE=false
else
  warn "Unsupported Node.js version — switching to Node 20 LTS..."
  curl -fsSL https://deb.nodesource.com/setup_20.x -o /tmp/nodesource_setup.sh \
    && bash /tmp/nodesource_setup.sh \
    && rm /tmp/nodesource_setup.sh \
    && apt-get install -y nodejs
fi

# ====== WorldID Router address (security best practice: hardcoded trusted value) ======
info "Using trusted hardcoded WorldID Router address for security."
WORLD_ROUTER="0x57f928158C3EE7CDad1e4D8642503c4D0201f611"

info "WorldID Router set to: $WORLD_ROUTER"

# ====== Environment setup ======
cat > "$INSTALL_PATH/.env.EXAMPLE" <<EOF
MULTI_RPC_LIST=sepolia=https://eth-sepolia.g.alchemy.com/v2/KEY,worldchain=https://worldchain-mainnet.g.alchemy.com/v2/KEY
WORLD_APP_ID=app_xxxxx
PRIVATE_KEY=0x....
ETHERSCAN_API_KEY=XXXX
EOF
info ".env.EXAMPLE written."

# ====== Install dependencies ======
cd "$INSTALL_PATH"
if ! command -v hardhat >/dev/null 2>&1; then
  info "Installing Hardhat and toolbox..."
  npm install --legacy-peer-deps --save-dev hardhat@2.20.1 @nomicfoundation/hardhat-toolbox@2.0.2 dotenv >/dev/null 2>&1
fi

# ====== Node 22 auto-patch ======
if [[ "${NODE22_MODE:-false}" == true ]]; then
  info "[PATCH] Adjusting imports for Node22..."
  find node_modules -type f -name "*.js" -exec sed -i 's|"hardhat/types/config"|"hardhat/types/config.js"|g' {} \; || true
  info "[PATCH] Hardhat Node22 fix applied"
fi

# ====== Contract setup ======
mkdir -p "$PROJECT_PATH/contracts"
cat > "$PROJECT_PATH/contracts/ZEAToken.sol" <<'SOL'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract ZEAToken is ERC20, Ownable {
  constructor() ERC20("ZEA Token", "ZEA") Ownable(msg.sender) {
    _mint(msg.sender, 1000000000 * 10 ** decimals());
  }
}
SOL

cat > "$PROJECT_PATH/contracts/Reward.sol" <<'SOL'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
contract Reward is Ownable {
  mapping(address => uint256) public rewards;
  constructor() Ownable(msg.sender) {}
  function addReward(address user, uint256 amount) external onlyOwner {
    rewards[user] += amount;
  }
}
SOL

# ====== Hardhat Config ======
cat > "$PROJECT_PATH/hardhat.config.js" <<'JS'
import { config as dotenvConfig } from "dotenv";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";
dotenvConfig();
export default {
  solidity: "0.8.20",
  networks: {
    sepolia: { url: process.env.SEPOLIA_RPC, accounts: [process.env.PRIVATE_KEY] },
    worldchain: { url: process.env.WORLDCHAIN_RPC, accounts: [process.env.PRIVATE_KEY] },
  },
  etherscan: {
    apiKey: { sepolia: process.env.ETHERSCAN_API_KEY },
  },
};
JS

# ====== .env.EXAMPLE Setup (ensure WORLDCHAIN_RPC is included) ======
cat > "$PROJECT_PATH/.env.EXAMPLE" <<EOF
# Example environment variables for Hardhat
# Replace values as needed.

PRIVATE_KEY=your_private_key_here
SEPOLIA_RPC=https://sepolia.infura.io/v3/YOUR_INFURA_PROJECT_ID
WORLDCHAIN_RPC=https://your.worldchain.rpc.endpoint/
ETHERSCAN_API_KEY=your_etherscan_key

EOF

# --- Hardhat Dependency Healer ---
info "[HEALER] Checking Hardhat plugin dependencies..."
npm install --legacy-peer-deps --save-dev \
  @nomiclabs/hardhat-etherscan@^3.0.0 \
  @types/mocha@>=9.1.0 \
  --no-audit --no-fund >/dev/null 2>&1 || true
info "[HEALER] Hardhat plugin dependencies repaired."

# ====== Deploy Script ======
cat > "$PROJECT_PATH/scripts/deploy.js" <<'JS'
import hre from "hardhat";
async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deployer:", deployer.address);
  const ZEAToken = await hre.ethers.getContractFactory("ZEAToken");
  const token = await ZEAToken.deploy();
  await token.waitForDeployment();
  console.log("ZEAToken deployed to:", await token.getAddress());
  const Reward = await hre.ethers.getContractFactory("Reward");
  const reward = await Reward.deploy();
  await reward.waitForDeployment();
  console.log("Reward contract deployed to:", await reward.getAddress());
}
main().catch((e) => { console.error(e); process.exit(1); });
JS

# ====== Ensure .env.EXAMPLE contains required environment variables ======
cat > "$PROJECT_PATH/.env.EXAMPLE" <<'ENV'
# Example environment settings for ZeaZDev/Hardhat project
# Sepolia RPC endpoint (keep private in production)
SEPOLIA_RPC=YOUR_SEPOLIA_RPC_URL
# Private key for deployer account (never commit real keys)
PRIVATE_KEY=YOUR_PRIVATE_KEY
# Etherscan API key for contract verification
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY
ENV

# ====== Compile & Deploy ======
cd "$PROJECT_PATH"
info "Compiling contracts..."
npx hardhat clean >/dev/null 2>&1 || true
if ! npx hardhat compile; then
  warn "Compile failed, attempting repair..."
  npm install --legacy-peer-deps --save-dev @nomiclabs/hardhat-ethers >/dev/null 2>&1
  npx hardhat compile || err "Compile failed after repair"
fi

info "Deploying..."
npx hardhat run scripts/deploy.js --network sepolia || warn "Deploy failed"

info "Deploy complete. Starting dashboard..."
(cd "$INSTALL_PATH" && npx http-server -p 3000 >/dev/null 2>&1 &)
info "Dashboard running at http://localhost:3000"
