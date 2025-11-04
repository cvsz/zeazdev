#!/usr/bin/env bash
# =============================================================================
# 🌐 Developer & Project Information
# 💲 Project: ZeaZDev — Zea Token (\$ZEA)
# 📦 Version: v5.5 (Node22 Compatibility + Hardhat Auto-Patch)
# 👨‍💻 Developer: PHIPHAT PHOEMSUK (ZeaZDev)
# 🏢 Organization: ZeaZDev — Ecosystem • Innovate • Connect • Grow
# 🌍 Website: https://app.zeaz.dev/
# 📧 Contact: admin@zeaz.dev, support@zeaz.dev
# 🔐 License: MIT
# =============================================================================

set -euo pipefail
trap 'echo "[ERROR] Unexpected error on line $LINENO"; exit 1' ERR

GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; RESET="\e[0m"
info(){ echo -e "${GREEN}[INFO]${RESET} $*"; }
warn(){ echo -e "${YELLOW}[WARN]${RESET} $*"; }
err(){ echo -e "${RED}[ERROR]${RESET} $*"; }

INSTALL_PATH="${INSTALL_PATH:-/opt/ZeaZDev}"
PROJECT_PATH="$INSTALL_PATH/Project"
FRONT_PATH="$INSTALL_PATH/Frontend"
DASH_PATH="$INSTALL_PATH/Dashboard"
RESULTS_DIR="$INSTALL_PATH/Results"
LOG_DIR="$INSTALL_PATH/Logs"
BACKUP_DIR="$INSTALL_PATH/Backups"
TMP="${TMP:-/tmp/zeazdev_v55}"
NPM_CACHE_DIR="$INSTALL_PATH/.npm-cache"
mkdir -p "$PROJECT_PATH" "$FRONT_PATH" "$DASH_PATH" "$RESULTS_DIR" "$LOG_DIR" "$BACKUP_DIR" "$TMP" "$NPM_CACHE_DIR"

# -----------------------------------------------------------------------------
# Environment Configuration
# -----------------------------------------------------------------------------
: "${MULTI_RPC_LIST:=${MULTI_RPC_LIST:-}}"
: "${WORLD_APP_ID:=${WORLD_APP_ID:-}}"
: "${PRIVATE_KEY:=${PRIVATE_KEY:-}}"
: "${ETHERSCAN_API_KEY:=${ETHERSCAN_API_KEY:-}}"
: "${TELEGRAM_BOT_TOKEN:=${TELEGRAM_BOT_TOKEN:-}}"
: "${TELEGRAM_CHAT_ID:=${TELEGRAM_CHAT_ID:-}}"
: "${GIT_LOG_REPO:=${GIT_LOG_REPO:-}}"
: "${GIT_LOG_BRANCH:=${GIT_LOG_BRANCH:-deploy-logs}}"
: "${FRONT_DOMAIN:=${FRONT_DOMAIN:-http://localhost:3000}}"
: "${WORLD_ROUTER_FALLBACK:=0x7a5b8bC49D4D17a1aDe87E4E3fCB86B1fFb3D545}"
: "${MAX_PARALLEL:=2}"
: "${INSTALL_HARDHAT_VERSION:=2.19.1}"   # stable fallback
: "${NODE_VERSION:=$(node -v 2>/dev/null || echo 'v0.0.0')}"

# -----------------------------------------------------------------------------
# Node Version Detection
# -----------------------------------------------------------------------------
info "Detected Node.js version: $NODE_VERSION"
if echo "$NODE_VERSION" | grep -qE '^v2[3-9]'; then
  warn "Node.js >=23 detected — Hardhat not guaranteed compatible!"
elif echo "$NODE_VERSION" | grep -qE '^v2[2]\.'; then
  warn "Node.js 22.x detected — applying compatibility patch for Hardhat..."
  export HARDCONFIG_PATCH="true"
elif echo "$NODE_VERSION" | grep -qE '^v1[0-7]\.'; then
  err "Node.js version too old (<18). Please upgrade to 20+"
  exit 1
fi

# -----------------------------------------------------------------------------
# WorldID Router Fetch (best-effort)
# -----------------------------------------------------------------------------
info "Fetching WorldID Router address..."
WORLD_ROUTER="$(curl -fsSL https://raw.githubusercontent.com/worldcoin/world-id/main/deployments.json 2>/dev/null | grep -Eo '0x[0-9a-fA-F]{40}' | head -n1 || true)"
if [ -z "$WORLD_ROUTER" ]; then
  warn "Failed to fetch WorldID router from source, using fallback."
  WORLD_ROUTER="$WORLD_ROUTER_FALLBACK"
fi
info "WorldID Router set to: $WORLD_ROUTER"

# -----------------------------------------------------------------------------
# Prepare .env example
# -----------------------------------------------------------------------------
cat > "$INSTALL_PATH/.env.EXAMPLE" <<EOF
# =============================================================================
# 🌐 Developer & Project Information
# 💲 ZeaZDev — Zea Token (\$ZEA)
# 📦 Version: v5.5 (Node22 Compatibility + Hardhat Auto-Patch)
# 👨‍💻 Developer: PHIPHAT PHOEMSUK (ZeaZDev)
# 🏢 Organization: ZeaZDev — Ecosystem • Innovate • Connect • Grow
# 🌍 Website: https://app.zeaz.dev/
# 📧 Contact: admin@zeaz.dev
# =============================================================================
MULTI_RPC_LIST=$MULTI_RPC_LIST
WORLD_APP_ID=$WORLD_APP_ID
PRIVATE_KEY=$PRIVATE_KEY
ETHERSCAN_API_KEY=$ETHERSCAN_API_KEY
TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN
TELEGRAM_CHAT_ID=$TELEGRAM_CHAT_ID
GIT_LOG_REPO=$GIT_LOG_REPO
GIT_LOG_BRANCH=$GIT_LOG_BRANCH
FRONT_DOMAIN=$FRONT_DOMAIN
EOF
info ".env.EXAMPLE written."

IFS=',' read -r -a PAIRS <<< "$MULTI_RPC_LIST"

# -----------------------------------------------------------------------------
# Contract Templates with Developer Info Header
# -----------------------------------------------------------------------------
cat > "$TMP/ZEAToken.sol" <<'SOL'
// =============================================================================
// 🌐 Developer & Project Information
// 💲 ZeaZDev — Zea Token (\$ZEA)
// 📦 Version: v5.5 (Node22 Compatibility + Hardhat Auto-Patch)
// 👨‍💻 Developer: PHIPHAT PHOEMSUK (ZeaZDev)
// 🏢 Organization: ZeaZDev — Ecosystem • Innovate • Connect • Grow
// 🌍 Website: https://app.zeaz.dev/
// 📧 Contact: admin@zeaz.dev
// =============================================================================
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract ZEAToken is ERC20, Ownable {
    constructor() ERC20("ZEA Token", "ZEA") Ownable(msg.sender) {
        _mint(msg.sender, 1000000000 * (10 ** decimals()));
    }
}
SOL

cat > "$TMP/Airdrop.sol" <<'SOL'
// =============================================================================
// 🌐 Developer & Project Information
// 💲 ZeaZDev — Zea Token (\$ZEA)
// 📦 Version: v5.5
// 👨‍💻 Developer: PHIPHAT PHOEMSUK (ZeaZDev)
// =============================================================================
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
interface IWorldID { function verifyProof(uint256,uint256,uint256,uint256,uint256[8] calldata) external view; }
contract Airdrop is Ownable {
  IERC20 public token; IWorldID public worldID; string public appId;
  mapping(uint256=>bool) public nullifierUsed;
  uint256 public constant AIRDROP_AMOUNT = 100*10**18;
  event Claimed(address indexed user,uint256 nullifierHash);
  constructor(address t,address w,string memory id) Ownable(msg.sender) {
    token = IERC20(t); worldID = IWorldID(w); appId = id;
  }
  function claimAirdrop(address r,uint256 root,uint256 n,uint256[8] calldata p) external {
    require(!nullifierUsed[n],"Already claimed");
    uint256 s = uint256(keccak256(abi.encodePacked(appId,"zea-airdrop",r)));
    worldID.verifyProof(root,1,s,n,p);
    nullifierUsed[n] = true;
    require(token.transfer(r,AIRDROP_AMOUNT),"Fail");
    emit Claimed(r,n);
  }
}
SOL

cat > "$TMP/deploy.js" <<'JS'
/* =============================================================================
🌐 Developer & Project Information
💲 ZeaZDev — Zea Token (\$ZEA)
📦 Version: v5.5 (Node22 Compatibility + Hardhat Auto-Patch)
👨‍💻 Developer: PHIPHAT PHOEMSUK (ZeaZDev)
============================================================================= */
import hre from "hardhat";
import fs from "fs";
import dotenv from "dotenv";
dotenv.config();
async function main(){
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deployer:", deployer.address);
  const ZEAToken = await hre.ethers.getContractFactory("ZEAToken");
  const z = await ZEAToken.deploy(); await z.waitForDeployment();
  const tokenAddr = await z.getAddress();
  console.log("Token:", tokenAddr);
  const Airdrop = await hre.ethers.getContractFactory("Airdrop");
  const a = await Airdrop.deploy(tokenAddr, process.env.WORLD_ID_ROUTER_ADDRESS, process.env.WORLD_APP_ID);
  await a.waitForDeployment();
  const aAddr = await a.getAddress();
  console.log("Airdrop:", aAddr);
  await z.transfer(aAddr, hre.ethers.parseUnits("500000000", 18));
  console.log("Funded 500M ZEA to Airdrop");
  try {
    await hre.run("verify:verify", { address: aAddr, constructorArguments: [tokenAddr, process.env.WORLD_ID_ROUTER_ADDRESS, process.env.WORLD_APP_ID] });
    console.log("Verified on Etherscan");
  } catch (e) {
    console.warn("Verify failed:", e.message || e);
  }
  fs.writeFileSync("/tmp/zeadev_result.json", JSON.stringify({ network: process.env.NETWORK, token: tokenAddr, airdrop: aAddr }));
}
main().catch(e=>{ console.error(e); process.exit(1); });
JS

echo
info "✅ Header variable fix applied (escaped \$ZEA). You can rerun safely:"
echo "   bash ZeaZDev-Release-v5.5-fixed.sh"
