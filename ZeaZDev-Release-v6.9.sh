#!/usr/bin/env bash
# =============================================================================
# 🌐 Developer & Project Information
# 💲 ZeaZDev — Zea Token ($ZEA)
# 📦 Version: Release — v6.9 (Hotfix 9)
# 👨‍💻 Developer: PHIPHAT PHOEMSUK (ZeaZDev)
# 🏢 Organization: ZeaZDev — Ecosystem • Innovate • Connect • Grow
# 🌍 Website: https://app.zeaz.dev/
# 📧 Contact: admin@zeaz.dev, support@zeaz.dev
# 🔐 License: MIT
# =============================================================================
# HOTFIX v6.9 (Critical Build & Runtime Fixes):
# 1. [FIX] (Parcel Build) Fixed 'Did you mean "index.html"?' error.
#    - The script now runs 'npm pkg delete main' in the Frontend directory
#    - to remove the conflicting "main": "index.js" key from package.json.
# 2. [FIX] (Runtime) Fixed 'TMP_PDIR: unbound variable' typo.
#    - Changed 'rm -rf "$TMP_PDIR"' to 'rm -rf "$TMP_DIR"'.
# 3. [FIX] (Ethers v5): Includes v6.6 fix for Ethers v5 syntax (resolves
#    all 'Job ... failed'/'Compile failed' errors from Node.js 22+).
# 4. [FIX] (apt-get): Includes v6.8 fix for 'apt-get' compatibility.
# 5. [FIX] (Persistence): Includes v6.7 fix for storing/loading .env.
# 6. [FIX] (502 Bad Gateway): Includes v6.5 fix for static Nginx frontend.
# =============================================================================

set -euo pipefail
trap 'echo -e "\e[31m[ERROR]\e[0m Unexpected error on line $LINENO"; exit 1' ERR

# --- UI ---
GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; RESET="\e[0m"
info(){ echo -e "${GREEN}[INFO]${RESET} $*"; }
warn(){ echo -e "${YELLOW}[WARN]${RESET} $*"; }
err(){ echo -e "${RED}[ERROR]${RESET} $*"; }

if [ "$(id -u)" -ne 0 ]; then
  err "สคริปต์นี้ต้องรันด้วย sudo (sudo bash $0) เนื่องจากต้องติดตั้ง Nginx, Certbot และ systemd"
  exit 1
fi

# --- Defaults & Paths ---
INSTALL_PATH="${INSTALL_PATH:-/opt/ZeaZDev}"
PROJECT_PATH="$INSTALL_PATH/Project"
FRONT_PATH="$INSTALL_PATH/Frontend"
DASH_PATH="$INSTALL_PATH/Dashboard"
RESULTS_DIR="$INSTALL_PATH/Results"
LOG_DIR="$INSTALL_PATH/Logs"
BACKUP_DIR="$INSTALL_PATH/Backups"
TMP_DIR="/tmp/zeazdev_build_$$"
LOGFILE="$LOG_DIR/zeazdev-install-$(date +%F).log"

mkdir -p "$PROJECT_PATH" "$FRONT_PATH" "$DASH_PATH" "$RESULTS_DIR" "$LOG_DIR" "$BACKUP_DIR" "$TMP_DIR"
exec > >(tee -a "$LOGFILE") 2>&1

# --- ENV Vars (Non-Interactive / Interactive Fallback) ---
: "${MULTI_RPC_LIST:=${MULTI_RPC_LIST:-}}"
: "${WORLD_APP_ID:=${WORLD_APP_ID:-}}"
: "${PRIVATE_KEY:=${PRIVATE_KEY:-}}"
: "${ETHERSCAN_API_KEY:=${ETHERSCAN_API_KEY:-}}"
: "${TELEGRAM_BOT_TOKEN:=${TELEGRAM_BOT_TOKEN:-}}"
: "${TELEGRAM_CHAT_ID:=${TELEGRAM_CHAT_ID:-}}"
: "${GIT_LOG_REPO:=${GIT_LOG_REPO:-}}"
: "${GIT_LOG_BRANCH:=${GIT_LOG_BRANCH:-deploy-logs}}"
: "${FRONT_DOMAIN:=${FRONT_DOMAIN:-app.zeaz.dev}}"
: "${DASH_DOMAIN:=${DASH_DOMAIN:-dash.zeaz.dev}}"
: "${WORLD_ROUTER_FALLBACK:=0x57f928158C3EE7CDad1e4D8642503c4D0201f611}"
: "${MAX_PARALLEL:=2}"
: "${MIN_RAM_MB:=2000}"

# --- Interactive Setup (ถ้า ENV ขาด) ---
if [ -z "$MULTI_RPC_LIST" ] || [ -z "$WORLD_APP_ID" ] || [ -z "$PRIVATE_KEY" ]; then
  warn "Interactive mode: กรุณาใส่ค่าที่จำเป็น (หรือตั้ง ENV ไวล่วงหน้า)"
  read -p "Enter MULTI_RPC_LIST (e.g. worldchain=https://...): " I_MULTI_RPC_LIST
  MULTI_RPC_LIST="${MULTI_RPC_LIST:-$I_MULTI_RPC_LIST}"
  read -p "Enter WORLD_APP_ID: " I_WORLD_APP_ID
  WORLD_APP_ID="${WORLD_APP_ID:-$I_WORLD_APP_ID}"
  read -p "Enter PRIVATE_KEY (0x...): " I_PRIVATE_KEY
  PRIVATE_KEY="${PRIVATE_KEY:-$I_PRIVATE_KEY}"
  read -p "Enter FRONT_DOMAIN (e.g. app.zeaz.dev): " I_FRONT
  FRONT_DOMAIN="${FRONT_DOMAIN:-$I_FRONT}"
  read -p "Enter DASH_DOMAIN (e.g. dash.zeaz.dev): " I_DASH
  DASH_DOMAIN="${DASH_DOMAIN:-$I_DASH}"
  read -p "Enter ETHERSCAN_API_KEY (optional): " I_ETH
  ETHERSCAN_API_KEY="${ETHERSCAN_API_KEY:-$I_ETH}"
fi
MULTI_RPC_LIST=$(echo "$MULTI_RPC_LIST" | sed 's/ //g')

# --- [FIX v6.2] Auto-correct user input format ---
if [[ "$MULTI_RPC_LIST" != *'='* ]] && [[ "$MULTI_RPC_LIST" == *'https://'* ]]; then
  warn "Input '$MULTI_RPC_LIST' lacks format. Assuming default network 'worldchain'."
  MULTI_RPC_LIST="worldchain=$MULTI_RPC_LIST"
  info "Corrected MULTI_RPC_LIST: $MULTI_RPC_LIST"
fi
# --- [END FIX] ---

# --- [FEAT v6.7] Store Environment Variables ---
info "Storing environment variables to $INSTALL_PATH/.env for persistence..."
cat > "$INSTALL_PATH/.env" <<EOF
# ZeaZDev v6.9 Environment File
# This file is loaded by the systemd service.

# Paths
INSTALL_PATH=$INSTALL_PATH

# Networks
MULTI_RPC_LIST="$MULTI_RPC_LIST"

# Keys
PRIVATE_KEY="$PRIVATE_KEY"

# WorldID
WORLD_APP_ID="$WORLD_APP_ID"
WORLD_ROUTER_FALLBACK="$WORLD_ROUTER_FALLBACK"

# Domains
FRONT_DOMAIN="$FRONT_DOMAIN"
DASH_DOMAIN="$DASH_DOMAIN"

# Verification (Optional)
ETHERSCAN_API_KEY="$ETHERSCAN_API_KEY"

# Notifications (Optional)
TELEGRAM_BOT_TOKEN="$TELEGRAM_BOT_TOKEN"
TELEGRAM_CHAT_ID="$TELEGRAM_CHAT_ID"
GIT_LOG_REPO="$GIT_LOG_REPO"
GIT_LOG_BRANCH="$GIT_LOG_BRANCH"
EOF
info ".env file saved to $INSTALL_PATH/.env"
# --- [END FEAT] ---

# --- 1. System Dependencies & Node.js ---
info "Installing system dependencies (Node.js, Nginx, Certbot, Git, Python, Jq)..."
# --- [FIX v6.8] ---
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y git curl build-essential pkg-config python3 python3-pip python3-venv jq zip nginx certbot python3-certbot-nginx
# --- [END FIX] ---

if ! command -v node >/dev/null 2>&1 || [[ "$(node -v)" =~ ^v1[0-7] ]]; then
  info "Installing Node.js 20 (LTS)..."
  # --- [FIX v6.8] ---
  apt-get purge -y nodejs npm || true
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y nodejs
  # --- [END FIX] ---
fi
NODE_VER=$(node -v); NODE_MAJOR=$(echo "$NODE_VER" | sed 's/v\([0-9]*\).*/\1/')
info "Node.js $NODE_VER (Major $NODE_MAJOR) installed."

# --- [FIX v6.1] ---
NODE22_MODE=false
if [ "$NODE_MAJOR" -ge 22 ]; then
  NODE22_MODE=true
  info "Node.js $NODE_VER >= 22. Applying compatibility patches."
fi
# --- [END FIX] ---

# --- 2. Auto Swap (MemorySafe) ---
if command -v free >/dev/null 2>&1; then
  total_mb=$(free -m | awk '/^Mem:/{print $2}')
  if [ "$total_mb" -lt "$MIN_RAM_MB" ] && [ ! -f /swapfile-zeazdev ]; then
    info "Low memory (${total_mb}MB) — creating 2GB swap..."
    fallocate -l 2G /swapfile-zeazdev || dd if=/dev/zero of=/swapfile-zeazdev bs=1M count=2048
    chmod 600 /swapfile-zeazdev && mkswap /swapfile-zeazdev && swapon /swapfile-zeazdev
    info "Swap created and enabled"
  fi
fi

# --- 3. WorldID Router ---
info "WorldID Router set to fixed address: $WORLD_ROUTER_FALLBACK"
WORLD_ROUTER="$WORLD_ROUTER_FALLBACK"

# --- 4. Write Contract Templates ---
info "Writing contract templates..."
cat > "$TMP_DIR/ZEAToken.sol" <<'SOL'
/* 🌐 ZeaZDev v6.9 (ZEA Token) 👨‍💻 PHIPHAT PHOEMSUK */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract ZEAToken is ERC20, Ownable {
    constructor() ERC20("Zea Token","ZEA") Ownable(msg.sender) {
        _mint(msg.sender, 1000000000 * (10 ** decimals()));
    }
}
SOL

cat > "$TMP_DIR/Airdrop.sol" <<'SOL'
/* 🌐 ZeaZDev v6.9 (Airdrop) 👨‍💻 PHIPHAT PHOEMSUK */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
interface IWorldID { function verifyProof(uint256,uint256,uint256,uint256,uint256[8] calldata) external view; }
contract Airdrop is Ownable {
    IERC20 public token; IWorldID public worldID; string public appId;
    string public constant action="zea-airdrop";
    mapping(uint256=>bool) public nullifierUsed;
    uint256 public constant AIRDROP_AMOUNT=100*10**18;
    event Claimed(address indexed user,uint256 nullifierHash);
    constructor(address t,address w,string memory id) Ownable(msg.sender){ token=IERC20(t); worldID=IWorldID(w); appId=id; }
    function claimAirdrop(address r,uint256 root,uint256 n,uint256[8] calldata p) external {
        require(!nullifierUsed[n],"Claimed");
        uint256 s=uint256(keccak256(abi.encodePacked(appId,action,r)));
        worldID.verifyProof(root,1,s,n,p);
        nullifierUsed[n]=true;
        require(token.transfer(r,AIRDROP_AMOUNT),"Fail");
        emit Claimed(r,n);
    }
}
SOL

cat > "$TMP_DIR/Reward.sol" <<'SOL'
/* 🌐 ZeaZDev v6.9 (Reward Contract) 👨‍💻 PHIPHAT PHOEMSUK */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract Reward is Ownable {
    IERC20 public zeaToken;
    mapping(address => uint256) public lastClaimed;
    uint256 public constant DAILY_REWARD = 10 * 10**18;
    uint256 public constant COOLDOWN = 24 hours;
    constructor(address _token) Ownable(msg.sender) { zeaToken = IERC20(_token); }
    function dailyCheckIn() external {
        require(block.timestamp >= lastClaimed[msg.sender] + COOLDOWN, "Cooldown");
        lastClaimed[msg.sender] = block.timestamp;
        require(zeaToken.transfer(msg.sender, DAILY_REWARD), "Transfer failed");
    }
    function fund(uint256 amount) external onlyOwner {
        require(zeaToken.transferFrom(msg.sender, address(this), amount), "Fund failed");
    }
}
SOL

# --- 5. Write Deploy Script Template ---
# --- [FIX v6.6] ---
# Downgraded script to Ethers v5 syntax to match Hardhat Toolbox v3.0.0
cat > "$TMP_DIR/deploy.js" <<'JS'
/* 🌐 ZeaZDev v6.9 (Deploy Script - Ethers v5 Syntax) 👨‍💻 PHIPHAT PHOEMSUK */
import hre from "hardhat";
import fs from "fs";
import dotenv from "dotenv";
dotenv.config();

async function main(){
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deployer:", deployer.address);
  
  const ZEAToken = await hre.ethers.getContractFactory("ZEAToken");
  const zea = await ZEAToken.deploy(); 
  await zea.deployed(); // Ethers v5 syntax
  const zeaAddr = zea.address; // Ethers v5 syntax
  console.log("ZEAToken:", zeaAddr);

  const Airdrop = await hre.ethers.getContractFactory("Airdrop");
  const airdrop = await Airdrop.deploy(zeaAddr, process.env.WORLD_ID_ROUTER_ADDRESS, process.env.WORLD_APP_ID);
  await airdrop.deployed(); // Ethers v5 syntax
  const airdropAddr = airdrop.address; // Ethers v5 syntax
  console.log("Airdrop:", airdropAddr);

  const Reward = await hre.ethers.getContractFactory("Reward");
  const reward = await Reward.deploy(zeaAddr);
  await reward.deployed(); // Ethers v5 syntax
  const rewardAddr = reward.address; // Ethers v5 syntax
  console.log("Reward:", rewardAddr);

  console.log("Funding contracts...");
  // Ethers v5 syntax
  await zea.transfer(airdropAddr, hre.ethers.utils.parseUnits("500000000", 18));
  await zea.transfer(rewardAddr, hre.ethers.utils.parseUnits("100000000", 18));
  
  const result = {
    network: process.env.NETWORK,
    token: zeaAddr,
    airdrop: airdropAddr,
    reward: rewardAddr
  };
  fs.writeFileSync("/tmp/zeadev_result.json", JSON.stringify(result));

  try {
    console.log("Verifying ZEAToken...");
    await hre.run("verify:verify", { address: zeaAddr, constructorArguments: [] });
    console.log("Verifying Airdrop...");
    await hre.run("verify:verify", { address: airdropAddr, constructorArguments: [zeaAddr, process.env.WORLD_ID_ROUTER_ADDRESS, process.env.WORLD_APP_ID] });
    console.log("Verifying Reward...");
    await hre.run("verify:verify", { address: rewardAddr, constructorArguments: [zeaAddr] });
  } catch (e) {
    console.warn("Verify failed (non-fatal):", e.message);
  }
}
main().catch(e=>{ console.error(e); process.exit(1); });
JS
# --- [END FIX] ---

# --- 6. Write Hardhat Config Template ---
cat > "$TMP_DIR/hardhat.config.js" <<'CFG'
/* 🌐 ZeaZDev v6.9 (Hardhat Config) 👨‍💻 PHIPHAT PHOEMSUK */
import { config as dotenvConfig } from "dotenv";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";
dotenvConfig();
const { RPC_URL, PRIVATE_KEY, ETHERSCAN_API_KEY } = process.env;
export default {
  solidity: { version: "0.8.20", settings: { optimizer: { enabled: true, runs: 200 } } },
  networks: {
    [process.env.NETWORK || "local"]: {
      url: RPC_URL || "",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : []
    }
  },
  etherscan: {
    apiKey: { [process.env.NETWORK || "local"]: ETHERSCAN_API_KEY || "" },
    customChains: [
      { network: "worldchain", chainId: 424242, urls: { apiURL: "https://explorer.worldchain.io/api", browserURL: "https://explorer.worldchain.io" } },
      { network: "sepolia", chainId: 11155111, urls: { apiURL: "https://api-sepolia.etherscan.io/api", browserURL: "https://sepolia.etherscan.io" } },
      { network: "base", chainId: 8453, urls: { apiURL: "https://api.basescan.org/api", browserURL: "https://basescan.org" } },
      { network: "bnb", chainId: 56, urls: { apiURL: "https://api.bscscan.com/api", browserURL: "https://bscscan.com" } }
    ]
  }
};
CFG

# --- 7. Helper: Run Network Job (Compile, Deploy, Verify) ---
run_network_job() {
  local pair="$1" # e.g. sepolia=https://...
  
  if [[ "$pair" != *'='* ]]; then
    warn "Skipping invalid entry '$pair'. Format must be network=rpc_url."
    return 1
  fi
  local net="${pair%%=*}"
  local rpc="${pair#*=}"
  if [ -z "$net" ] || [ -z "$rpc" ]; then
    warn "Skipping invalid entry '$pair'. Both network and rpc must be set."
    return 1
  fi

  local ws="$PROJECT_PATH/$net"
  info "[$net] Starting job... Workspace: $ws"
  
  mkdir -p "$ws/contracts" "$ws/scripts"
  cd "$ws"
  
  # A. Write .env for this network
  cat > .env <<EOF
RPC_URL=${rpc}
PRIVATE_KEY=${PRIVATE_KEY}
NETWORK=${net}
WORLD_APP_ID=${WORLD_APP_ID}
ETHERSCAN_API_KEY=${ETHERSCAN_API_KEY}
WORLD_ID_ROUTER_ADDRESS=${WORLD_ROUTER}
EOF

  # B. Init NPM + Set ESM
  npm init -y >/dev/null 2>&1 || true
  npm pkg set type="module" >/dev/null 2>&1 || true
  
  # C. Copy templates
  cp "$TMP_DIR/ZEAToken.sol" "$ws/contracts/ZEAToken.sol"
  cp "$TMP_DIR/Airdrop.sol" "$ws/contracts/Airdrop.sol"
  cp "$TMP_DIR/Reward.sol" "$ws/contracts/Reward.sol"
  cp "$TMP_DIR/deploy.js" "$ws/scripts/deploy.js"
  cp "$TMP_DIR/hardhat.config.js" "$ws/hardhat.config.js"

  # D. Dependency Healer (Node 22 + HHE22 + HH801 Fix)
  info "[$net] Installing dependencies (Hardhat, OZ, Ethers)..."
  export NPM_CONFIG_CACHE="$INSTALL_PATH/.npm-cache"
  npm install --legacy-peer-deps --