#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# ZeaZDev-Release-v5.7.sh
# Developer: PHIPHAT PHOEMSUK (ZeaZDev)
# Project: ZeaZDev — ZEA Token Multi-Chain Deployer + WorldID Airdrop + Reward
# Version: v5.7 (Auto SSL + Proxy Mode + Telegram + Multi-network)
# Website: https://app.zeaz.dev/
# Contact: admin@zeaz.dev, support@zeaz.dev
# License: MIT
# -----------------------------------------------------------------------------
set -euo pipefail
trap 'echo "[ERROR] Unexpected error on line $LINENO"; exit 1' ERR

# ---------------------------
# Minimal runtime checks
# ---------------------------
info(){ echo -e "\033[1;32m[INFO]\033[0m $*"; }
warn(){ echo -e "\033[1;33m[WARN]\033[0m $*"; }
err(){ echo -e "\033[1;31m[ERROR]\033[0m $*"; }

if [ "$(id -u)" -ne 0 ]; then
  warn "It's recommended to run as root (sudo). Continuing but some steps may fail."
fi

# ---------------------------
# Defaults (can be overridden via environment variables)
# ---------------------------
INSTALL_PATH="${INSTALL_PATH:-/opt/ZeaZDev}"
PROJECT_PATH="$INSTALL_PATH/Project"
FRONT_PATH="$INSTALL_PATH/Frontend"
DASH_PATH="$INSTALL_PATH/Dashboard"
RESULTS_DIR="$INSTALL_PATH/Results"
LOG_DIR="$INSTALL_PATH/Logs"
BACKUP_DIR="$INSTALL_PATH/Backups"
TMP_DIR="/tmp/zeazdev_v57"
mkdir -p "$PROJECT_PATH" "$FRONT_PATH" "$DASH_PATH" "$RESULTS_DIR" "$LOG_DIR" "$BACKUP_DIR" "$TMP_DIR"

# Environment variables (non-interactive supported)
: "${MULTI_RPC_LIST:=${MULTI_RPC_LIST:-}}"
: "${WORLD_APP_ID:=${WORLD_APP_ID:-}}"
: "${PRIVATE_KEY:=${PRIVATE_KEY:-}}"
: "${ETHERSCAN_API_KEY:=${ETHERSCAN_API_KEY:-}}"
: "${TELEGRAM_BOT_TOKEN:=${TELEGRAM_BOT_TOKEN:-}}"
: "${TELEGRAM_CHAT_ID:=${TELEGRAM_CHAT_ID:-}}"
: "${GIT_LOG_REPO:=${GIT_LOG_REPO:-}}"
: "${GIT_LOG_BRANCH:=${GIT_LOG_BRANCH:-deploy-logs}}"
: "${FRONT_DOMAIN:=${FRONT_DOMAIN:-app.zeaz.dev}}"
: "${WORLD_ROUTER_FALLBACK:=0x7a5b8bC49D4D17a1aDe87E4E3fCB86B1fFb3D545}"
: "${NODE_REQUIRED_MAJOR:=18}"
: "${CERT_EMAIL:=${CERT_EMAIL:-admin@zeaz.dev}}"
: "${DEPLOY_WEBHOOK_URL:=${DEPLOY_WEBHOOK_URL:-}}"

# ---------------------------
# Helper functions
# ---------------------------
normalize_rpc(){
  local raw="$1"
  if [[ "$raw" =~ ^metamask:([^:]+):(.+)$ ]]; then
    local key="${BASH_REMATCH[1]}"
    local chains="${BASH_REMATCH[2]}"
    echo "https://api.metamask.services/v1/${key}?chains=${chains}"
  else
    echo "$raw"
  fi
}

check_command(){
  if ! command -v "$1" >/dev/null 2>&1; then
    return 1
  fi
  return 0
}

# ---------------------------
# Interactive prompts (if required)
# ---------------------------
if [ -z "$MULTI_RPC_LIST" ] || [ -z "$WORLD_APP_ID" ] || [ -z "$PRIVATE_KEY" ]; then
  echo "Interactive mode: some required ENVs are missing. You can set them before running to use non-interactive mode."
  read -p "Enter MULTI_RPC_LIST (format: name=url,name2=url2) : " I_MULTI_RPC_LIST
  MULTI_RPC_LIST="${MULTI_RPC_LIST:-$I_MULTI_RPC_LIST}"
  read -p "Enter WORLD_APP_ID (WorldID app id): " I_WORLD_APP_ID
  WORLD_APP_ID="${WORLD_APP_ID:-$I_WORLD_APP_ID}"
  read -p "Enter PRIVATE_KEY (0x...): " I_PRIVATE_KEY
  PRIVATE_KEY="${PRIVATE_KEY:-$I_PRIVATE_KEY}"
  read -p "Enter ETHERSCAN_API_KEY (optional): " I_ETH
  ETHERSCAN_API_KEY="${ETHERSCAN_API_KEY:-$I_ETH}"
  read -p "Enter TELEGRAM_BOT_TOKEN (optional): " I_TG
  TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-$I_TG}"
  read -p "Enter TELEGRAM_CHAT_ID (optional): " I_TGCHAT
  TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-$I_TGCHAT}"
  read -p "Enter FRONT_DOMAIN (eg app.zeaz.dev): " I_DOMAIN
  FRONT_DOMAIN="${FRONT_DOMAIN:-$I_DOMAIN}"
fi

# sanitize MULTI_RPC_LIST
MULTI_RPC_LIST=$(echo "$MULTI_RPC_LIST" | sed 's/ //g')
if [ -z "$MULTI_RPC_LIST" ]; then
  err "MULTI_RPC_LIST is required. Example: sepolia=https://... ,worldchain=https://..."
  exit 1
fi

info "Install path: $INSTALL_PATH"
info "Project path: $PROJECT_PATH"
info "Frontend domain: $FRONT_DOMAIN"
info "Networks: $MULTI_RPC_LIST"

# ---------------------------
# System packages (apt-based) - install minimal dependencies
# ---------------------------
install_system_deps(){
  if check_command apt-get; then
    info "Updating apt and installing system packages (nginx, certbot, build-essential, git, curl, python3)..."
    apt-get update -y
    apt-get install -y nginx git curl jq zip unzip build-essential python3 python3-venv python3-pip
    # certbot (snap preferred)
    if ! check_command certbot >/dev/null 2>&1; then
      info "Installing certbot via snap..."
      apt-get install -y snapd
      snap install core >/dev/null 2>&1 || true
      snap refresh core >/dev/null 2>&1 || true
      snap install --classic certbot || true
      ln -s /snap/bin/certbot /usr/bin/certbot >/dev/null 2>&1 || true
    fi
  else
    warn "Package manager apt-get not detected. Please install nginx, certbot, git, curl, node, npm manually."
  fi
}

install_node_npm(){
  if check_command node && check_command npm; then
    NODE_VER=$(node -v | sed 's/v//')
    info "Detected node version: $NODE_VER"
  else
    info "Installing Node.js (LTS v18) via NodeSource..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
  fi
  # Ensure npm global permissions OK
  npm config set fund false >/dev/null 2>&1 || true
}

# ---------------------------
# Prepare .env.EXAMPLE
# ---------------------------
cat > "$INSTALL_PATH/.env.EXAMPLE" <<EOF
# ZeaZDev v5.7 .env example
MULTI_RPC_LIST=$MULTI_RPC_LIST
WORLD_APP_ID=$WORLD_APP_ID
PRIVATE_KEY=$PRIVATE_KEY
ETHERSCAN_API_KEY=$ETHERSCAN_API_KEY
TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN
TELEGRAM_CHAT_ID=$TELEGRAM_CHAT_ID
GIT_LOG_REPO=$GIT_LOG_REPO
FRONT_DOMAIN=$FRONT_DOMAIN
WORLD_ID_ROUTER_ADDRESS=$WORLD_ROUTER_FALLBACK
DEPLOY_WEBHOOK_URL=$DEPLOY_WEBHOOK_URL
CERT_EMAIL=$CERT_EMAIL
EOF
info ".env.EXAMPLE written to $INSTALL_PATH/.env.EXAMPLE"

# ---------------------------
# Fetch live WorldID Router (best effort)
# ---------------------------
info "Fetching WorldID Router address (best-effort)..."
WORLD_ROUTER=""
urls=(
  "https://raw.githubusercontent.com/worldcoin/world-id/main/deployments.json"
  "https://raw.githubusercontent.com/worldcoin/world-id/main/addresses.json"
  "https://raw.githubusercontent.com/worldcoin/world-id/main/deployments/deployments.json"
)

for u in "${urls[@]}"; do
  if check_command curl; then
    body=$(curl -fsS "$u" 2>/dev/null || true)
    if [ -n "$body" ]; then
      addr=$(echo "$body" | grep -Eo "0x[0-9a-fA-F]{40}" | head -n1 || true)
      if [ -n "$addr" ]; then
        WORLD_ROUTER="$addr"
        break
      fi
    fi
  fi
done
WORLD_ROUTER=${WORLD_ROUTER:-$WORLD_ROUTER_FALLBACK}
info "WorldID Router set to: $WORLD_ROUTER"

# ---------------------------
# Write contracts & scripts templates to TMP_DIR
# ---------------------------
info "Writing contract templates to $TMP_DIR..."
mkdir -p "$TMP_DIR/contracts" "$TMP_DIR/scripts"

# ZEAToken.sol
cat > "$TMP_DIR/contracts/ZEAToken.sol" <<'SOL'
/*
// Developer: PHIPHAT PHOEMSUK (ZeaZDev)
// ZeaZDev — ZEA Token (ERC20) - autogenerated by ZeaZDev-Release-v5.7
// SPDX-License-Identifier: MIT
*/
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract ZEAToken is ERC20, Ownable {
  constructor() ERC20("ZEA Token","ZEA") Ownable(msg.sender) {
    _mint(msg.sender, 1000000000 * (10 ** decimals()));
  }
}
SOL

# Airdrop.sol (WorldID verification)
cat > "$TMP_DIR/contracts/Airdrop.sol" <<'SOL'
/*
// Developer: PHIPHAT PHOEMSUK (ZeaZDev)
// ZeaZDev — Airdrop with WorldID (verifyProof)
// SPDX-License-Identifier: MIT
*/
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
interface IWorldID { function verifyProof(uint256 root,uint256 groupId,uint256 signal,uint256 nullifierHash,uint256[8] calldata proof) external view; }
contract Airdrop is Ownable {
  IERC20 public token;
  IWorldID public worldID;
  string public appId;
  string public constant action = "zea-airdrop";
  mapping(uint256 => bool) public nullifierUsed;
  uint256 public constant AIRDROP_AMOUNT = 100 * 10**18;
  event Claimed(address indexed user, uint256 nullifierHash);
  constructor(address t, address w, string memory id) Ownable(msg.sender) {
    token = IERC20(t);
    worldID = IWorldID(w);
    appId = id;
  }
  function claimAirdrop(address recipient, uint256 root, uint256 nullifierHash, uint256[8] calldata proof) external {
    require(!nullifierUsed[nullifierHash], "Already claimed");
    uint256 signal = uint256(keccak256(abi.encodePacked(appId, action, recipient)));
    // worldID.verifyProof(root, 1, signal, nullifierHash, proof); // external view will revert on failure
    worldID.verifyProof(root, 1, signal, nullifierHash, proof);
    nullifierUsed[nullifierHash] = true;
    require(token.transfer(recipient, AIRDROP_AMOUNT), "Transfer failed");
    emit Claimed(recipient, nullifierHash);
  }
}
SOL

# Reward.sol (check-in/reward)
cat > "$TMP_DIR/contracts/Reward.sol" <<'SOL'
/*
// Developer: PHIPHAT PHOEMSUK (ZeaZDev)
// ZeaZDev — Reward contract for check-in / small reward distribution
// SPDX-License-Identifier: MIT
*/
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract Reward is Ownable {
  IERC20 public token;
  uint256 public rewardAmount;
  mapping(address => uint256) public lastClaim;
  uint256 public claimInterval;
  event RewardClaimed(address indexed user, uint256 amount, uint256 ts);
  event RewardParamsUpdated(uint256 amount, uint256 interval);
  constructor(address _token, uint256 _rewardAmount, uint256 _claimInterval) {
    token = IERC20(_token);
    rewardAmount = _rewardAmount;
    claimInterval = _claimInterval;
  }
  function claim() external {
    require(block.timestamp - lastClaim[msg.sender] >= claimInterval, "Wait before claiming");
    require(token.balanceOf(address(this)) >= rewardAmount, "Insufficient reward balance");
    lastClaim[msg.sender] = block.timestamp;
    require(token.transfer(msg.sender, rewardAmount), "Transfer failed");
    emit RewardClaimed(msg.sender, rewardAmount, block.timestamp);
  }
  function setRewardParams(uint256 _rewardAmount, uint256 _claimInterval) external onlyOwner {
    rewardAmount = _rewardAmount;
    claimInterval = _claimInterval;
    emit RewardParamsUpdated(_rewardAmount, _claimInterval);
  }
  function withdrawTokens(address to, uint256 amount) external onlyOwner {
    require(token.transfer(to, amount), "Withdraw failed");
  }
}
SOL

# deploy.js (ESM style, compatible with Hardhat modern)
cat > "$TMP_DIR/scripts/deploy.js" <<'JS'
/*
// Developer: PHIPHAT PHOEMSUK (ZeaZDev)
// Unified deploy script for ZEAToken, Airdrop, Reward
*/
import hre from "hardhat";
import fs from "fs";
import dotenv from "dotenv";
dotenv.config();

async function main(){
  const network = process.env.NETWORK || "local";
  const [deployer] = await hre.ethers.getSigners();
  console.log("Network:", network);
  console.log("Deployer:", deployer.address);

  const ZEAToken = await hre.ethers.getContractFactory("ZEAToken");
  const z = await ZEAToken.deploy();
  await z.deployTransaction.wait?.() || true;
  const tokenAddr = z.address || (await z.getAddress?.());
  console.log("ZEAToken:", tokenAddr);

  const worldRouter = process.env.WORLD_ID_ROUTER_ADDRESS || process.env.WORLD_ROUTER || "";
  const appId = process.env.WORLD_APP_ID || process.env.WORLD_APP || "";
  const Airdrop = await hre.ethers.getContractFactory("Airdrop");
  const a = await Airdrop.deploy(tokenAddr, worldRouter, appId);
  await a.deployTransaction.wait?.() || true;
  const aAddr = a.address || (await a.getAddress?.());
  console.log("Airdrop:", aAddr);

  const Reward = await hre.ethers.getContractFactory("Reward");
  // reward amount default 10 ZEA
  const rewardAmount = hre.ethers.parseUnits ? hre.ethers.parseUnits("10", 18) : hre.ethers.utils.parseUnits("10", 18);
  const r = await Reward.deploy(tokenAddr, rewardAmount, 86400);
  await r.deployTransaction.wait?.() || true;
  const rAddr = r.address || (await r.getAddress?.());
  console.log("Reward:", rAddr);

  // fund Airdrop and Reward
  const token = await hre.ethers.getContractAt("ZEAToken", tokenAddr, deployer);
  const halfSupply = hre.ethers.parseUnits ? hre.ethers.parseUnits("500000000", 18) : hre.ethers.utils.parseUnits("500000000", 18);
  await (await token.transfer(aAddr, halfSupply)).wait();
  console.log("Airdrop funded with 500,000,000 ZEA");

  const rewardPool = hre.ethers.parseUnits ? hre.ethers.parseUnits("10000", 18) : hre.ethers.utils.parseUnits("10000", 18);
  await (await token.transfer(rAddr, rewardPool)).wait();
  console.log("Reward funded with 10,000 ZEA");

  // write results
  const result = { network, token: tokenAddr, airdrop: aAddr, reward: rAddr, deployer: deployer.address };
  fs.writeFileSync("/tmp/zeadev_result.json", JSON.stringify(result, null, 2));
  console.log("Saved /tmp/zeadev_result.json");

  // attempt explorer verification (non-fatal)
  try {
    await hre.run("verify:verify", { address: aAddr, constructorArguments: [tokenAddr, worldRouter, appId] });
    console.log("Verified Airdrop (if explorer configured)");
  } catch(e){
    console.warn("Verify skipped or failed:", e.message || e);
  }

  // optional webhook
  if (process.env.DEPLOY_WEBHOOK_URL) {
    try {
      const axios = (await import("axios")).default;
      await axios.post(process.env.DEPLOY_WEBHOOK_URL, result, { timeout: 8000 });
      console.log("Posted to webhook");
    } catch(e) {
      console.warn("Webhook post failed:", e.message || e);
    }
  }
}

main().catch(e=>{ console.error(e); process.exit(1); });
JS

info "Templates written."

# ---------------------------
# Per-network workspaces & parallel deploy
# ---------------------------
IFS=',' read -r -a PAIRS <<< "$MULTI_RPC_LIST"
JOB_PIDS=()
RESULTS_TMP="$RESULTS_DIR"
mkdir -p "$RESULTS_TMP"

run_network_job(){
  local pair="$1"
  local net="${pair%%=*}"
  local rpc="${pair#*=}"
  rpc=$(normalize_rpc "$rpc")
  local ws="$PROJECT_PATH/$net"
  mkdir -p "$ws" "$ws/contracts" "$ws/scripts" "$ws/node_modules" || true

  info "[$net] workspace at $ws; RPC: $rpc"

  # write .env
  cat > "$ws/.env" <<EOF
RPC_URL=${rpc}
PRIVATE_KEY=${PRIVATE_KEY}
NETWORK=${net}
WORLD_APP_ID=${WORLD_APP_ID}
ETHERSCAN_API_KEY=${ETHERSCAN_API_KEY}
WORLD_ID_ROUTER_ADDRESS=${WORLD_ROUTER}
DEPLOY_WEBHOOK_URL=${DEPLOY_WEBHOOK_URL}
EOF

  # npm init and set ESM
  (cd "$ws" && npm init -y >/dev/null 2>&1 || true)
  (cd "$ws" && npm pkg set type="module" >/dev/null 2>&1 || true)

  # copy contracts & scripts
  cp "$TMP_DIR/contracts/ZEAToken.sol" "$ws/contracts/ZEAToken.sol"
  cp "$TMP_DIR/contracts/Airdrop.sol" "$ws/contracts/Airdrop.sol"
  cp "$TMP_DIR/contracts/Reward.sol" "$ws/contracts/Reward.sol"
  cp "$TMP_DIR/scripts/deploy.js" "$ws/scripts/deploy.js"

  # write hardhat.config.js (workspace-local)
  cat > "$ws/hardhat.config.js" <<'HCFG'
import { config as dotenvConfig } from "dotenv";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";
dotenvConfig();
const { RPC_URL, PRIVATE_KEY } = process.env;
export default {
  solidity: { version: "0.8.20", settings: { optimizer: { enabled: true, runs: 200 } } },
  networks: { [process.env.NETWORK || "local"]: { url: RPC_URL || "", accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [] } },
  etherscan: { apiKey: { [process.env.NETWORK || "local"]: process.env.ETHERSCAN_API_KEY || "" } }
};
HCFG

  # install minimal deps (try-with-retries; use legacy-peer-deps to reduce conflicts)
  (cd "$ws" && echo "[INFO] Installing minimal npm deps for $net..." && npm install --legacy-peer-deps --save @openzeppelin/contracts ethers >/dev/null 2>&1) || warn "[$net] npm install (minimal) had issues"
  (cd "$ws" && npm install --legacy-peer-deps --save-dev hardhat@2.20.1 @nomicfoundation/hardhat-toolbox@2.0.2 @nomicfoundation/hardhat-verify dotenv --no-audit --no-fund >/dev/null 2>&1) || warn "[$net] npm install (devDeps) had issues"

  # compile with auto-heal attempt
  info "[$net] compiling..."
  set +e
  (cd "$ws" && npx hardhat clean >/dev/null 2>&1 || true)
  (cd "$ws" && npx hardhat compile --show-stack-traces 2>&1 | tee "$LOG_DIR/${net}_compile.log")
  rc=$?
  set -e
  if [ $rc -ne 0 ]; then
    warn "[$net] compile failed; attempting plugin repair..."
    (cd "$ws" && npm install --legacy-peer-deps --save-dev @nomicfoundation/hardhat-ethers @nomicfoundation/hardhat-network-helpers @nomicfoundation/hardhat-chai-matchers --no-audit --no-fund >/dev/null 2>&1) || true
    set +e
    (cd "$ws" && npx hardhat compile --show-stack-traces 2>&1 | tee "$LOG_DIR/${net}_compile_retry.log")
    rc2=$?
    set -e
    if [ $rc2 -ne 0 ]; then
      err "[$net] compile retry failed; check $LOG_DIR/${net}_compile_retry.log"
      return 1
    fi
  fi

  # deploy
  info "[$net] deploying..."
  set +e
  (cd "$ws" && npx hardhat run scripts/deploy.js --network "$net" 2>&1 | tee "$LOG_DIR/${net}_deploy.log")
  rcode=$?
  set -e
  if [ $rcode -ne 0 ]; then
    err "[$net] deploy failed (see $LOG_DIR/${net}_deploy.log)"
    return 1
  fi

  # collect result
  if [ -f /tmp/zeadev_result.json ]; then
    mv /tmp/zeadev_result.json "$RESULTS_TMP/${net}.json" || true
  else
    TOKEN=$(grep -Eo "ZEAToken: 0x[0-9a-fA-F]{40}" "$LOG_DIR/${net}_deploy.log" | awk '{print $2}' || true)
    AIRDROP=$(grep -Eo "Airdrop: 0x[0-9a-fA-F]{40}" "$LOG_DIR/${net}_deploy.log" | awk '{print $2}' || true)
    REWARD=$(grep -Eo "Reward: 0x[0-9a-fA-F]{40}" "$LOG_DIR/${net}_deploy.log" | awk '{print $2}' || true)
    echo "{\"network\":\"${net}\",\"token\":\"${TOKEN}\",\"airdrop\":\"${AIRDROP}\",\"reward\":\"${REWARD}\"}" > "$RESULTS_TMP/${net}.json"
  fi

  info "[$net] job finished."
  return 0
}

# spawn each network job in background
for pair in "${PAIRS[@]}"; do
  if [ -z "$pair" ]; then continue; fi
  run_network_job "$pair" &
  JOB_PIDS+=($!)
  sleep 0.4
done

# wait for jobs
info "Waiting for network jobs to finish..."
FAILED=0
for pid in "${JOB_PIDS[@]}"; do
  wait "$pid" || FAILED=$((FAILED+1))
done
if [ $FAILED -gt 0 ]; then warn "$FAILED network jobs failed"; fi

# ---------------------------
# Aggregate results -> Frontend src/networks.json
# ---------------------------
info "Aggregating results..."
mkdir -p "$FRONT_PATH/src"
echo "[" > "$FRONT_PATH/src/networks.json"
first=true
for f in "$RESULTS_DIR"/*.json; do
  if [ "$first" = true ]; then first=false; else echo "," >> "$FRONT_PATH/src/networks.json"; fi
  cat "$f" >> "$FRONT_PATH/src/networks.json"
done
echo "]" >> "$FRONT_PATH/src/networks.json"
info "networks.json created at $FRONT_PATH/src/networks.json"

# ---------------------------
# Dashboard server (Express + WS) and static UI
# ---------------------------
info "Writing dashboard server and UI..."

mkdir -p "$INSTALL_PATH"
cat > "$INSTALL_PATH/server.js" <<'NODE'
/* Developer: PHIPHAT PHOEMSUK (ZeaZDev)
   ZeaZDev Dashboard Server (Express + WebSocket + chokidar)
*/
import express from "express";
import http from "http";
import { WebSocketServer } from "ws";
import fs from "fs";
import path from "path";
import chokidar from "chokidar";

const PORT = process.env.DASH_PORT ? Number(process.env.DASH_PORT) : 3000;
const BASE = process.env.PROJECT_DIR || "/opt/ZeaZDev";
const RESULTS_DIR = path.join(BASE, "Results");
const LOG_DIR = path.join(BASE, "Logs");
const DASH_DIR = path.join(BASE, "Dashboard");

const app = express();
app.use(express.json());
app.use(express.static(DASH_DIR));

app.get("/api/results", (req, res) => {
  try {
    const files = fs.existsSync(RESULTS_DIR) ? fs.readdirSync(RESULTS_DIR) : [];
    const data = [];
    for (const f of files) {
      if (f.endsWith(".json")) {
        try { data.push(JSON.parse(fs.readFileSync(path.join(RESULTS_DIR, f), "utf8"))); } catch(e){}
      }
    }
    res.json({ ok: true, results: data });
  } catch (e) { res.status(500).json({ ok:false, error: e.message }); }
});

app.get("/api/logtail", (req, res) => {
  try {
    const lines = parseInt(req.query.lines || "200", 10);
    if (!fs.existsSync(LOG_DIR)) return res.json({ ok:true, log: "" });
    const files = fs.readdirSync(LOG_DIR).filter(f=>f.endsWith(".log")).sort();
    if (files.length===0) return res.json({ ok:true, log: "" });
    const latest = files[files.length-1];
    const raw = fs.readFileSync(path.join(LOG_DIR, latest), "utf8");
    const arr = raw.split(/\r?\n/).slice(-lines).join("\n");
    res.json({ ok:true, file: latest, log: arr });
  } catch(e){ res.status(500).json({ ok:false, error: e.message }); }
});

const server = http.createServer(app);
const wss = new WebSocketServer({ server, path: "/ws" });

function broadcast(obj){
  const str = JSON.stringify(obj);
  for(const c of wss.clients) if(c.readyState===1) c.send(str);
}
wss.on("connection", ws => ws.send(JSON.stringify({ type:"hello", ts: Date.now() })));

if(!fs.existsSync(RESULTS_DIR)) fs.mkdirSync(RESULTS_DIR, { recursive:true });
if(!fs.existsSync(LOG_DIR)) fs.mkdirSync(LOG_DIR, { recursive:true });

const watcher = chokidar.watch([RESULTS_DIR, LOG_DIR], { ignoreInitial:true, depth:1 });
watcher.on("all", (ev, fp) => {
  const name = path.basename(fp);
  if(fp.endsWith(".json")) {
    try { const raw = fs.readFileSync(fp, "utf8"); broadcast({ type:"result", file: name, data: JSON.parse(raw), event: ev, ts: Date.now() }); }
    catch(e) { broadcast({ type:"result_error", file: name, error: e.message, ts: Date.now() }); }
  } else if(fp.endsWith(".log")) {
    const raw = fs.readFileSync(fp, "utf8"); broadcast({ type:"log", file: name, log: raw.slice(-20000), event: ev, ts: Date.now() }); 
  } else {
    broadcast({ type:"fs", file: name, event: ev, ts: Date.now() });
  }
});

server.listen(PORT, () => console.log(`Dashboard Server Running on http://0.0.0.0:${PORT}`));
NODE

# dashboard UI static
mkdir -p "$DASH_PATH"
cat > "$DASH_PATH/index.html" <<'HTML'
<!doctype html><html><head><meta charset="utf-8"/><title>ZeaZDev Dashboard</title><meta name="viewport" content="width=device-width,initial-scale=1"/></head><body>
<style>body{font-family:Inter,Arial,sans-serif;margin:0;background:#f6f7fb;color:#111}header{background:#0f172a;color:#fff;padding:12px 20px} .container{padding:20px;max-width:1200px;margin:auto}.card{background:#fff;border-radius:8px;padding:12px;box-shadow:0 2px 6px rgba(0,0,0,0.06);margin-bottom:12px}pre{white-space:pre-wrap;font-size:12px;max-height:420px;overflow:auto}.row{display:flex;justify-content:space-between;padding:8px;border-bottom:1px solid #f0f0f5}</style>
<header><strong>ZeaZDev Dashboard</strong> — Deploy & Logs (live)</header>
<div class="container">
<div style="display:flex;gap:12px;margin-bottom:12px"><button id="btn-refresh">Refresh</button><div id="status">Status: <span id="stat">idle</span></div></div>
<div class="card"><h3>Deploy Results</h3><div id="results"></div></div>
<div class="card"><h3>Logs (latest)</h3><pre id="logview">No logs yet</pre></div>
<div class="card"><h3>Realtime Events</h3><div id="events"></div></div>
</div>
<script type="module" src="/app.js"></script>
</body></html>
HTML

cat > "$DASH_PATH/app.js" <<'JS'
const BASE='';
const resultsEl=document.getElementById('results'), logView=document.getElementById('logview'), eventsEl=document.getElementById('events'), stat=document.getElementById('stat');
document.getElementById('btn-refresh').onclick=()=>{loadResults();loadLog();}
async function loadResults(){stat.innerText='loading';try{const r=await fetch(`${BASE}/api/results`);const j=await r.json();resultsEl.innerHTML='';(j.results||[]).forEach(item=>{const d=document.createElement('div');d.className='row';d.innerHTML=`<div><strong>${item.network||'n/a'}</strong></div><div>Token: ${item.token||'-'}<br>Airdrop: ${item.airdrop||'-'}<br>Reward: ${item.reward||'-'}</div>`;resultsEl.appendChild(d)});stat.innerText='ok'}catch(e){stat.innerText='error';addEvent('Error loading results: '+e.message)}}
async function loadLog(){try{const r=await fetch(`${BASE}/api/logtail?lines=400`);const j=await r.json();if(j.ok)logView.innerText=(j.file?('--- '+j.file+' ---\n'):'')+(j.log||'');}catch(e){addEvent('Error loading log: '+e.message)}}
function addEvent(msg){const d=document.createElement('div');d.style.padding='8px';d.style.borderBottom='1px solid #eee';d.innerText=`[${new Date().toLocaleTimeString()}] ${msg}`;eventsEl.prepend(d);}
loadResults(); loadLog();
const proto = location.protocol==='https:'?'wss:':'ws:'; const ws=new WebSocket(`${proto}//${location.host}/ws`);
ws.addEventListener('open',()=>addEvent('WS connected'));
ws.addEventListener('message', ev => { try { const d=JSON.parse(ev.data); if(d.type==='result'){addEvent(`Result update: ${d.data.network||d.file}`); loadResults();} else if(d.type==='log'){addEvent(`Log updated: ${d.file}`); loadLog();} else addEvent(`Event: ${JSON.stringify(d).slice(0,200)}`); } catch(e){ addEvent('WS parse error'); } });
ws.addEventListener('close',()=>addEvent('WS closed')); ws.addEventListener('error', e=>addEvent('WS error'));
JS

# ---------------------------
# Start dashboard server (systemd)
# ---------------------------
info "Installing dashboard server service..."
cd "$INSTALL_PATH"
( npm init -y >/dev/null 2>&1 || true )
( npm pkg set type="module" >/dev/null 2>&1 || true )
( npm install --no-audit --no-fund express ws chokidar --legacy-peer-deps >/dev/null 2>&1 ) || warn "dashboard deps install issue"

cat > /etc/systemd/system/zeazdev-dashboard.service <<'SERV'
[Unit]
Description=ZeaZDev Dashboard Server
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/ZeaZDev
ExecStart=/usr/bin/node server.js
Restart=on-failure
User=root
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
SERV

systemctl daemon-reload || true
systemctl enable --now zeazdev-dashboard.service || warn "Failed to enable/start zeazdev-dashboard.service (check journalctl)"

# ---------------------------
# Frontend minimal (Parcel) + systemd for parcel dev server
# ---------------------------
info "Writing minimal frontend and starting parcel dev server..."

mkdir -p "$FRONT_PATH/src"
cp "$FRONT_PATH/src/networks.json" "$FRONT_PATH/src/networks.json" 2>/dev/null || true

cat > "$FRONT_PATH/src/index.html" <<'HTML'
<!doctype html><html><head><meta charset="utf-8"><title>ZeaDev</title></head><body><div id="root"></div><script type="module" src="./App.js"></script></body></html>
HTML

cat > "$FRONT_PATH/src/App.js" <<'JS'
import { createRoot } from "react-dom/client";
async function main(){
  try {
    const res = await fetch('./networks.json'); const data = await res.json();
    document.body.innerHTML = `<h2>ZeaDev Multi Deploy (aggregated)</h2><pre>${JSON.stringify(data,null,2)}</pre>`;
  } catch(e) { document.body.innerHTML = `<pre>Error loading networks.json: ${e}</pre>`; }
}
main();
JS

( cd "$FRONT_PATH" && npm init -y >/dev/null 2>&1 || true )
( cd "$FRONT_PATH" && npm pkg set type="module" >/dev/null 2>&1 || true )
( cd "$FRONT_PATH" && npm install --legacy-peer-deps react react-dom parcel --no-audit --no-fund >/dev/null 2>&1 ) || warn "frontend deps install issue"

cat > /etc/systemd/system/zeazdev-frontend.service <<'SERV'
[Unit]
Description=ZeaZDev Frontend (Parcel)
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/ZeaZDev/Frontend
ExecStart=/usr/bin/env npx parcel src/index.html --port 3000
Restart=on-failure
User=root
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
SERV

systemctl daemon-reload || true
systemctl enable --now zeazdev-frontend.service || warn "Failed to enable/start zeazdev-frontend.service"

# ---------------------------
# Nginx reverse proxy + Certbot (Auto SSL)
# ---------------------------
info "Configuring nginx reverse proxy for $FRONT_DOMAIN..."
NGINX_CONF="/etc/nginx/sites-available/zeazdev"
cat > "$NGINX_CONF" <<NGC
server {
    listen 80;
    server_name ${FRONT_DOMAIN} www.${FRONT_DOMAIN};

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /dashboard/ {
        proxy_pass http://127.0.0.1:3000/;
    }
}
NGC

ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/zeazdev
nginx -t >/dev/null 2>&1 || warn "nginx config test failed"
systemctl reload nginx || true

# obtain certificate via certbot (nginx plugin)
if check_command certbot; then
  info "Requesting TLS certificate for $FRONT_DOMAIN via certbot..."
  certbot --nginx -d "$FRONT_DOMAIN" -d "www.$FRONT_DOMAIN" --non-interactive --agree-tos -m "$CERT_EMAIL" || warn "certbot failed (manual intervention may be required)"
  systemctl reload nginx || true
else
  warn "certbot not available; skipping auto SSL"
fi

# ---------------------------
# Push deploy logs to Git (optional)
# ---------------------------
LOGFILE="$LOG_DIR/deploy-$(date -u +%Y%m%dT%H%M%SZ).log"
echo "ZeaZDev Deploy Logs - $(date -u)" > "$LOGFILE"
for f in "$RESULTS_DIR"/*.json; do echo "---- $f ----" >> "$LOGFILE"; cat "$f" >> "$LOGFILE"; echo >> "$LOGFILE"; done
for f in "$LOG_DIR"/*.log; do echo "---- $f ----" >> "$LOGFILE"; tail -n 400 "$f" >> "$LOGFILE"; echo >> "$LOGFILE"; done

if [ -n "$GIT_LOG_REPO" ]; then
  info "Pushing logs to git repo $GIT_LOG_REPO (branch $GIT_LOG_BRANCH)"
  cd "$INSTALL_PATH"
  git init -q || true
  git remote remove origin >/dev/null 2>&1 || true
  git remote add origin "$GIT_LOG_REPO" || true
  git checkout -B "$GIT_LOG_BRANCH" || true
  cp "$LOGFILE" ./deploy-latest.log
  mkdir -p results logs
  cp -r "$RESULTS_DIR"/* results/ 2>/dev/null || true
  cp -r "$LOG_DIR"/* logs/ 2>/dev/null || true
  git add deploy-latest.log results logs || true
  git -c user.email="ci@zeazdev.local" -c user.name="ZeaZDev CI" commit -m "Deploy logs $(date -u)" >/dev/null 2>&1 || true
  git push -f origin "$GIT_LOG_BRANCH" >/dev/null 2>&1 && info "Logs pushed to $GIT_LOG_REPO#$GIT_LOG_BRANCH" || warn "Git push failed (check credentials)"
fi

# ---------------------------
# Telegram notify summary
# ---------------------------
if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
  MSG="✅ *ZeaZDev v5.7 Multi-Deploy finished.*%0A"
  for f in "$RESULTS_DIR"/*.json; do
    if [ -f "$f" ]; then
      n=$(jq -r .network "$f"); t=$(jq -r .token "$f"); a=$(jq -r .airdrop "$f"); r=$(jq -r .reward "$f")
      MSG="${MSG}%0A*${n}*%0AToken: \`${t}\`%0AAirdrop: \`${a}\`%0AReward: \`${r}\`%0A"
    fi
  done
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" -d chat_id="${TELEGRAM_CHAT_ID}" -d text="$MSG" -d parse_mode=MarkdownV2 >/dev/null 2>&1 || warn "Telegram notification failed"
  info "Telegram summary sent"
fi

info "ZeaZDev v5.7 deployment script finished."
info "Dashboard (http/https) served by nginx at https://$FRONT_DOMAIN (if cert obtained)"
info "Dashboard service: systemctl status zeazdev-dashboard"
info "Frontend service: systemctl status zeazdev-frontend"
info "Results: $RESULTS_DIR, Logs: $LOG_DIR, Backups: $BACKUP_DIR"

# done
exit 0
