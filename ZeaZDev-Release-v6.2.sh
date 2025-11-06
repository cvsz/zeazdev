#!/usr/bin/env bash
# =============================================================================
# 🌐 Developer & Project Information
# 💲 ZeaZDev — Zea Token ($ZEA)
# 📦 Version: Release — v6.2 (Hotfix 2)
# 👨‍💻 Developer: PHIPHAT PHOEMSUK (ZeaZDev)
# 🏢 Organization: ZeaZDev — Ecosystem • Innovate • Connect • Grow
# 🌍 Website: https://app.zeaz.dev/
# 📧 Contact: admin@zeaz.dev, support@zeaz.dev
# 🔐 License: MIT
# =============================================================================
# HOTFIX v6.2:
# 1. [FIX] Auto-correct MULTI_RPC_LIST input.
#    - If input is just a URL (no 'net=') and contains 'https://',
#    - the script will auto-prefix 'worldchain=' to fix the format.
# 2. [FIX] Resolved 'unbound variable' error for 'NODE22_MODE'.
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

# --- 1. System Dependencies & Node.js ---
info "Installing system dependencies (Node.js, Nginx, Certbot, Git, Python, Jq)..."
apt update -y
apt install -y git curl build-essential pkg-config python3 python3-pip python3-venv jq zip nginx certbot python3-certbot-nginx

if ! command -v node >/dev/null 2>&1 || [[ "$(node -v)" =~ ^v1[0-7] ]]; then
  info "Installing Node.js 20 (LTS)..."
  apt purge -y nodejs npm || true
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt install -y nodejs
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
/* 🌐 ZeaZDev v6.2 (ZEA Token) 👨‍💻 PHIPHAT PHOEMSUK */
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
/* 🌐 ZeaZDev v6.2 (Airdrop) 👨‍💻 PHIPHAT PHOEMSUK */
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
/* 🌐 ZeaZDev v6.2 (Reward Contract) 👨‍💻 PHIPHAT PHOEMSUK */
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
cat > "$TMP_DIR/deploy.js" <<'JS'
/* 🌐 ZeaZDev v6.2 (Deploy Script) 👨‍💻 PHIPHAT PHOEMSUK */
import hre from "hardhat";
import fs from "fs";
import dotenv from "dotenv";
dotenv.config();
async function main(){
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deployer:", deployer.address);
  
  const ZEAToken = await hre.ethers.getContractFactory("ZEAToken");
  const zea = await ZEAToken.deploy(); await zea.waitForDeployment();
  const zeaAddr = await zea.getAddress(); console.log("ZEAToken:", zeaAddr);

  const Airdrop = await hre.ethers.getContractFactory("Airdrop");
  const airdrop = await Airdrop.deploy(zeaAddr, process.env.WORLD_ID_ROUTER_ADDRESS, process.env.WORLD_APP_ID);
  await airdrop.waitForDeployment(); const airdropAddr = await airdrop.getAddress();
  console.log("Airdrop:", airdropAddr);

  const Reward = await hre.ethers.getContractFactory("Reward");
  const reward = await Reward.deploy(zeaAddr); await reward.waitForDeployment();
  const rewardAddr = await reward.getAddress(); console.log("Reward:", rewardAddr);

  console.log("Funding contracts...");
  await zea.transfer(airdropAddr, hre.ethers.parseUnits("500000000", 18));
  await zea.transfer(rewardAddr, hre.ethers.parseUnits("100000000", 18));
  
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

# --- 6. Write Hardhat Config Template ---
cat > "$TMP_DIR/hardhat.config.js" <<'CFG'
/* 🌐 ZeaZDev v6.2 (Hardhat Config) 👨‍💻 PHIPHAT PHOEMSUK */
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
  npm install --legacy-peer-deps --save @openzeppelin/contracts ethers >/dev/null 2>&1 || true
  
  if [ "$NODE_MAJOR" -ge 22 ]; then
    info "[$net] Node.js $NODE_VER >= 22 detected. Using Hardhat v2.21.1 (Stable)"
    npm install --legacy-peer-deps --save-dev hardhat@2.21.1 @nomicfoundation/hardhat-toolbox@3.0.0 dotenv @nomicfoundation/hardhat-verify >/dev/null 2>&1
  else
    info "[$net] Node.js $NODE_VER < 22 detected. Using Hardhat latest."
    npm install --legacy-peer-deps --save-dev hardhat @nomicfoundation/hardhat-toolbox dotenv @nomicfoundation/hardhat-verify >/dev/null 2>&1
  fi
  
  # E. Auto-Heal HH801 (Install missing sub-plugins)
  info "[$net] Auto-healing missing plugins (HH801)..."
  npm install --legacy-peer-deps --save-dev \
    @nomiclabs/hardhat-etherscan \
    @types/mocha \
    @nomicfoundation/hardhat-chai-matchers \
    @nomiclabs/hardhat-ethers \
    @ethersproject/providers \
    hardhat-gas-reporter solidity-coverage \
    @typechain/ethers-v5 @typechain/hardhat \
    ts-node typechain typescript >/dev/null 2>&1 || true

  # F. Compile (with Node 22 Patch)
  info "[$net] Compiling..."
  set +e
  if [ "$NODE22_MODE" = true ]; then
    info "[$net] Applying Node 22 patch (config.js)..."
    find "$ws/node_modules" -type f -name "type-extensions.js" -exec \
      sed -i 's|\"hardhat/types/config\"|\"hardhat/types/config.js\"|g' {} \; 2>/dev/null || true
  fi
  
  if ! npx hardhat compile 2>"$LOG_DIR/${net}_compile.log"; then
    warn "[$net] Compile failed, see $LOG_DIR/${net}_compile.log"
    return 1
  fi
  set -e
  
  # G. Deploy
  info "[$net] Deploying..."
  if ! npx hardhat run scripts/deploy.js --network "$net" 2>"$LOG_DIR/${net}_deploy.log"; then
    err "[$net] Deploy failed, see $LOG_DIR/${net}_deploy.log"
    return 1
  fi
  
  # H. Collect results
  mv /tmp/zeadev_result.json "$RESULTS_DIR/${net}.json" || true
  info "[$net] Deploy Success. Results saved."
  return 0
}

# --- 8. Spawn Parallel Jobs (MemorySafe) ---
IFS=',' read -r -a PAIRS <<< "$MULTI_RPC_LIST"
info "Starting parallel deploys (Max $MAX_PARALLEL jobs)"
CURRENT=0
PIDS=()
for pair in "${PAIRS[@]}"; do
  [ -z "$pair" ] && continue
  run_network_job "$pair" &
  PIDS+=($!)
  CURRENT=$((CURRENT+1))
  if [ "$CURRENT" -ge "$MAX_PARALLEL" ]; then
    wait -n || true
    CURRENT=$((CURRENT-1))
  fi
done
info "Waiting for remaining jobs..."
for pid in "${PIDS[@]}"; do wait "$pid" || warn "Job $pid failed"; done

# --- 9. Aggregate Results ---
info "Aggregating results for Dashboard..."
mkdir -p "$FRONT_PATH/src"
echo "[" > "$FRONT_PATH/src/networks.json"
first=true
for f in "$RESULTS_DIR"/*.json; do
  [ ! -f "$f" ] && continue
  if $first; then first=false; else echo "," >> "$FRONT_PATH/src/networks.json"; fi
  cat "$f" >> "$FRONT_PATH/src/networks.json"
done
echo "]" >> "$FRONT_PATH/src/networks.json"

# --- 10. Dashboard Server (Express + WS) ---
info "Setting up Dashboard Server (Express + WebSocket)..."
cd "$INSTALL_PATH"
npm init -y >/dev/null 2>&1 || true
npm pkg set type="module" >/dev/null 2>&1 || true
npm install --legacy-peer-deps express ws chokidar >/dev/null 2>&1 || true

cat > "$INSTALL_PATH/server.js" <<'NODE'
/* 🌐 ZeaZDev v6.2 (Dashboard Server) 👨‍💻 PHIPHAT PHOEMSUK */
import express from "express";
import http from "http";
import { WebSocketServer } from "ws";
import fs from "fs";
import path from "path";
import chokidar from "chokidar";
const PORT = 3000;
const BASE = process.env.INSTALL_PATH || "/opt/ZeaZDev";
const RESULTS_DIR = path.join(BASE, "Results");
const LOG_DIR = path.join(BASE, "Logs");
const DASH_DIR = path.join(BASE, "Dashboard");
const app = express();
app.use(express.static(DASH_DIR));
app.get("/api/results", (req, res) => {
  try {
    const files = fs.existsSync(RESULTS_DIR) ? fs.readdirSync(RESULTS_DIR) : [];
    const data = files.filter(f => f.endsWith(".json")).map(f => 
      JSON.parse(fs.readFileSync(path.join(RESULTS_DIR, f), "utf8"))
    );
    res.json({ ok: true, results: data });
  } catch (e) { res.status(500).json({ ok: false, error: e.message }); }
});
app.get("/api/logtail", (req, res) => {
  try {
    const files = fs.readdirSync(LOG_DIR).filter(f=>f.endsWith(".log")).sort();
    const latest = files.length ? files[files.length-1] : null;
    if (!latest) return res.json({ ok: true, log: "" });
    const log = fs.readFileSync(path.join(LOG_DIR, latest), "utf8");
    res.json({ ok: true, file: latest, log: log.split(/\r?\n/).slice(-200).join("\n") });
  } catch(e){ res.status(500).json({ ok:false, error: e.message }); }
});
const server = http.createServer(app);
const wss = new WebSocketServer({ server, path: "/ws" });
wss.on("connection", ws => ws.send(JSON.stringify({ type:"hello" })));
const watcher = chokidar.watch([RESULTS_DIR, LOG_DIR], { ignoreInitial:true, depth:1 });
watcher.on("all", (ev, fp) => {
  const name = path.basename(fp);
  let data = { type: "fs", file: name, event: ev, ts: Date.now() };
  if (fp.endsWith(".json")) { data.type = "result"; }
  else if (fp.endsWith(".log")) { data.type = "log"; }
  for(const c of wss.clients) if(c.readyState===1) c.send(JSON.stringify(data));
});
server.listen(PORT, () => console.log(`Dashboard Server Running on http://0.0.0.0:${PORT}`));
NODE

# --- 11. Dashboard UI (Static) ---
cat > "$DASH_PATH/index.html" <<'HTML'
<!doctype html><html><head><meta charset="utf-8"/><title>ZeaZDev Dashboard</title>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<style>body{font-family:Arial,sans-serif;margin:0;background:#111;color:#eee}header{background:#000;color:#0f0;padding:12px 20px;font-family:monospace}
.container{padding:20px;max-width:1200px;margin:auto}.card{background:#222;border:1px solid #444;border-radius:8px;padding:12px;margin-bottom:12px}
pre{white-space:pre-wrap;font-size:12px;max-height:420px;overflow:auto;color:#ccc}.row{padding:8px;border-bottom:1px solid #333}</style>
</head><body><header><strong>ZeaZDev Dashboard (v6.2)</strong> — Deploy & Logs (Live)</header>
<div class="container"><button id="btn-refresh">Refresh</button> <span id="stat">Connecting...</span>
<div class="card"><h3>Deploy Results</h3><div id="results"></div></div>
<div class="card"><h3>Logs (latest)</h3><pre id="logview">No logs yet</pre></div>
<div class="card"><h3>Realtime Events</h3><div id="events" style="max-height:100px;overflow:auto"></div></div>
</div><script type="module" src="/app.js"></script></body></html>
HTML
cat > "$DASH_PATH/app.js" <<'JS'
const $ = (s) => document.getElementById(s);
const $r = $('results'), $l = $('logview'), $e = $('events'), $s = $('stat');
$('btn-refresh').onclick=()=>{loadResults();loadLog();};
async function loadResults(){$s.innerText='loading...';try{const r=await fetch('/api/results');const j=await r.json();$r.innerHTML='';(j.results||[]).forEach(i=>{const d=document.createElement('div');d.className='row';d.innerHTML=`<strong>${i.network}</strong>: Token: ${i.token} | Airdrop: ${i.airdrop} | Reward: ${i.reward}`;$r.appendChild(d)});$s.innerText='OK';}catch(e){$s.innerText='error';}}
async function loadLog(){try{const r=await fetch('/api/logtail');const j=await r.json();if(j.ok)$l.innerText=(j.file?`--- ${j.file} ---\n`:'')+(j.log||'');}catch(e){}}
function addEvent(msg){const d=document.createElement('div');d.style.fontSize='10px';d.innerText=`[${new Date().toLocaleTimeString()}] ${msg}`;$e.prepend(d);}
loadResults();loadLog();
const ws=new WebSocket(`ws://${location.host}/ws`);
ws.onopen=()=>addEvent('WS connected');
ws.onmessage=ev=>{try{const d=JSON.parse(ev.data);if(d.type==='result'){addEvent(`Result: ${d.file}`);loadResults();}else if(d.type==='log'){addEvent(`Log: ${d.file}`);loadLog();}}catch(e){}};
ws.onclose=()=>addEvent('WS closed');
JS

# --- 12. Frontend (Parcel) Setup ---
info "Setting up Frontend (Parcel)..."
cd "$FRONT_PATH"
npm init -y >/dev/null 2>&1 || true
npm pkg set type="module" >/dev/null 2>&1 || true
npm install --legacy-peer-deps react react-dom parcel ethers @worldcoin/idkit >/dev/null 2>&1 || true
mkdir -p "$FRONT_PATH/src"
cat > "$FRONT_PATH/src/index.html" <<'HTML'
<!doctype html><html><head><meta charset="utf-8"><title>ZeaZDev</title></head>
<body><div id="root"></div><script type="module" src="./App.js"></script></body></html>
HTML
cat > "$FRONT_PATH/src/App.js" <<'JS'
/* 🌐 ZeaZDev v6.2 (Frontend) 👨‍💻 PHIPHAT PHOEMSUK */
import React,{useState}from"react";
import{createRoot}from"react-dom/client";
import{ethers}from"ethers";
import{IDKitWidget}from"@worldcoin/idkit";
import networks from "./networks.json";
const ACTION="zea-airdrop";
function App(){
  const [status,setStatus]=useState("Ready");
  async function connect(){ /* ... connect logic ... */ }
  async function handleProof(res){
    setStatus("Verifying proof...");
    /* ... call contract.claimAirdrop ... */
    setStatus("✅ Claimed!");
  }
  return(<div style={{fontFamily:"Arial",padding:20}}>
    <h2>ZeaZDev Airdrop (WorldID)</h2>
    <IDKitWidget app_id={process.env.WORLD_APP_ID} action={ACTION} onSuccess={handleProof}
      render={(p)=><button onClick={p.open}>Verify with World ID</button>}/>
    <div>Status: {status}</div>
    <h3>Deployed Networks:</h3>
    <pre>{JSON.stringify(networks,null,2)}</pre>
  </div>);
}
createRoot(document.getElementById("root")).render(<App/>);
JS

# --- 13. Nginx + SSL + Systemd ---
info "Setting up Nginx Proxy + Auto SSL (Certbot) + Systemd..."

# A. Nginx config
cat > /etc/nginx/sites-available/zeazdev.conf <<EOF
server {
    listen 80;
    server_name $DASH_DOMAIN $FRONT_DOMAIN;
    location / {
        proxy_pass http://127.0.0.1:3000; # Dashboard
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
    location /app { # Assuming frontend runs on different path or port if needed
        proxy_pass http://127.0.0.1:4000; # Frontend (Parcel)
    }
}
EOF
ln -sf /etc/nginx/sites-available/zeazdev.conf /etc/nginx/sites-enabled/

# B. Certbot (Auto SSL)
certbot --nginx --non-interactive --agree-tos -m admin@zeaz.dev -d "$DASH_DOMAIN" -d "$FRONT_DOMAIN" || warn "Certbot failed (check DNS/firewall)"

# C. Systemd Services
cat > /etc/systemd/system/zeazdev-dash.service <<EOF
[Unit]
Description=ZeaZDev Dashboard Server (Node.js)
After=network.target
[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_PATH
ExecStart=/usr/bin/node server.js
Restart=on-failure
Environment=NODE_ENV=production
[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/zeazdev-front.service <<EOF
[Unit]
Description=ZeaZDev Frontend Server (Parcel)
After=network.target
[Service]
Type=simple
User=root
WorkingDirectory=$FRONT_PATH
ExecStart=/usr/bin/npm run start -- --port 4000
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

# D. Start services
systemctl daemon-reload
systemctl enable zeazdev-dash zeazdev-front
systemctl restart nginx
systemctl restart zeazdev-dash
systemctl restart zeazdev-front

# --- 14. Git Push & Telegram ---
info "Finalizing... pushing logs and sending notifications..."
LOGFILE_FINAL="$LOG_DIR/deploy-summary-$(date +%F).log"
echo "ZeaZDev v6.2 Deploy Summary" > "$LOGFILE_FINAL"
cat "$RESULTS_DIR"/*.json >> "$LOGFILE_FINAL" 2>/dev/null || true

if [ -n "$GIT_LOG_REPO" ]; then
  cd "$INSTALL_PATH"
  git init -q || true
  git remote remove origin >/dev/null 2>&1 || true
  git remote add origin "$GIT_LOG_REPO" || true
  git checkout -B "$GIT_LOG_BRANCH" || true
  cp -r "$RESULTS_DIR" results/ 2>/dev/null || true
  cp -r "$LOG_DIR" logs/ 2>/dev/null || true
  git add .
  git -c user.email="ci@zeazdev.local" -c user.name="ZeaZDev CI" commit -m "Deploy v6.2 $(date -u)" >/dev/null 2>&1 || true
  git push -f origin "$GIT_LOG_BRANCH" >/dev/null 2>&1 && info "Logs pushed to Git" || warn "Git push failed"
fi

if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
  SUMMARY=$(cat "$LOGFILE_FINAL" | tail -n 20)
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d chat_id="${TELEGRAM_CHAT_ID}" \
    -d text="✅ ZeaZDev v6.2 Deploy Done ($NODE_VER). Dashboard: https://$DASH_DOMAIN | Frontend: https://$FRONT_DOMAIN ... Summary: $SUMMARY" >/dev/null 2>&1 || true
fi

# --- 15. Cleanup ---
rm -rf "$TMP_DIR"
info "ZeaZDev v6.2 (Hotfix 2) installation complete!"
info "Dashboard: https://$DASH_DOMAIN"
info "Frontend: https://$FRONT_DOMAIN"