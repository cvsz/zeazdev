#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# ZeaZDev-Release-v5.4.sh
# ZeaZDev — Multi-Node Cluster Deploy + Etherscan V2 Verify + Dashboard + WebSocket
# Version: v5.4 (MemorySafe + HardhatLocalFix + Git Push Enhancements)
# Developer: PHIPHAT PHOEMSUK (ZeaZDev)
# Organization: ZeaZDev — Ecosystem • Innovate • Connect • Grow
# Website: https://app.zeaz.dev/
# Contact: admin@zeaz.dev, support@zeaz.dev
# License: MIT
# -----------------------------------------------------------------------------
set -euo pipefail
trap 'echo "[ERROR] Unexpected error on line $LINENO"; exit 1' ERR

# -------------------------
# Minimal logging helpers
# -------------------------
GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; RESET="\e[0m"
info(){ echo -e "${GREEN}[INFO]${RESET} $*"; }
warn(){ echo -e "${YELLOW}[WARN]${RESET} $*"; }
err(){ echo -e "${RED}[ERROR]${RESET} $*"; }

# -------------------------
# Defaults & Paths
# -------------------------
INSTALL_PATH="${INSTALL_PATH:-/opt/ZeaZDev}"
PROJECT_PATH="$INSTALL_PATH/Project"
FRONT_PATH="$INSTALL_PATH/Frontend"
DASH_PATH="$INSTALL_PATH/Dashboard"
RESULTS_DIR="$INSTALL_PATH/Results"
LOG_DIR="$INSTALL_PATH/Logs"
BACKUP_DIR="$INSTALL_PATH/Backups"
NPM_CACHE_DIR="${NPM_CACHE_DIR:-$INSTALL_PATH/.npm-cache}"
TMP="${TMP:-/tmp/zeazdev_v54}"
mkdir -p "$PROJECT_PATH" "$FRONT_PATH" "$DASH_PATH" "$RESULTS_DIR" "$LOG_DIR" "$BACKUP_DIR" "$NPM_CACHE_DIR" "$TMP"

# -------------------------
# Environment variables (can be provided beforehand)
# -------------------------
: "${MULTI_RPC_LIST:=${MULTI_RPC_LIST:-}}"
: "${WORLD_APP_ID:=${WORLD_APP_ID:-}}"
: "${PRIVATE_KEY:=${PRIVATE_KEY:-}}"
: "${ETHERSCAN_API_KEY:=${ETHERSCAN_API_KEY:-}}"
: "${TELEGRAM_BOT_TOKEN:=${TELEGRAM_BOT_TOKEN:-}}"
: "${TELEGRAM_CHAT_ID:=${TELEGRAM_CHAT_ID:-}}"
: "${GIT_LOG_REPO:=${GIT_LOG_REPO:-}}"
: "${GIT_LOG_BRANCH:=${GIT_LOG_BRANCH:-deploy-logs}}"
: "${FRONT_DOMAIN:=${FRONT_DOMAIN:-http://localhost:3000}}"
: "${MAX_PARALLEL:=${MAX_PARALLEL:-2}}"         # concurrency limit
: "${NODE_MIN_RECOMMENDED:=${NODE_MIN_RECOMMENDED:-18}}"
: "${WORLD_ROUTER_FALLBACK:=0x7a5b8bC49D4D17a1aDe87E4E3fCB86B1fFb3D545}"
: "${SWAP_ON_LOW_MEM:=true}"
: "${MIN_RAM_MB:=2000}"                         # if RAM < this, create swap
: "${INSTALL_HARDHAT_VERSION:=2.20.1}"

# -------------------------
# Interactive prompts for required fields
# -------------------------
if [ -z "$MULTI_RPC_LIST" ] || [ -z "$WORLD_APP_ID" ] || [ -z "$PRIVATE_KEY" ]; then
  echo "Some required environment variables are missing. You can set them as ENV before running for non-interactive mode."
  read -p "Enter MULTI_RPC_LIST (e.g. sepolia=https://...,worldchain=https://...): " I_MULTI_RPC_LIST
  MULTI_RPC_LIST="${MULTI_RPC_LIST:-$I_MULTI_RPC_LIST}"
  read -p "Enter WORLD_APP_ID: " I_WORLD_APP_ID
  WORLD_APP_ID="${WORLD_APP_ID:-$I_WORLD_APP_ID}"
  read -p "Enter PRIVATE_KEY (0x...): " I_PRIVATE_KEY
  PRIVATE_KEY="${PRIVATE_KEY:-$I_PRIVATE_KEY}"
  read -p "Enter ETHERSCAN_API_KEY (optional): " I_ETHERSCAN
  ETHERSCAN_API_KEY="${ETHERSCAN_API_KEY:-$I_ETHERSCAN}"
  read -p "Enter TELEGRAM_BOT_TOKEN (optional): " I_TGBOT
  TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-$I_TGBOT}"
  read -p "Enter TELEGRAM_CHAT_ID (optional): " I_TGCHAT
  TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-$I_TGCHAT}"
  read -p "Enter GIT_LOG_REPO (optional, include PAT if using HTTP auth): " I_GITREPO
  GIT_LOG_REPO="${GIT_LOG_REPO:-$I_GITREPO}"
fi

# sanitize MULTI_RPC_LIST
MULTI_RPC_LIST=$(echo "$MULTI_RPC_LIST" | sed 's/ //g')
if [ -z "$MULTI_RPC_LIST" ]; then err "MULTI_RPC_LIST is required"; exit 1; fi

info "Install path: $INSTALL_PATH"
info "Project path: $PROJECT_PATH"
info "Frontend path: $FRONT_PATH"
info "Concurrency limit (MAX_PARALLEL) = $MAX_PARALLEL"

# -------------------------
# Helpers
# -------------------------
normalize_rpc(){
  local raw="$1"
  if [[ "$raw" =~ ^metamask:([^:]+):(.+)$ ]]; then
    local key="${BASH_REMATCH[1]}"; local chains="${BASH_REMATCH[2]}"
    echo "https://api.metamask.services/v1/${key}?chains=${chains}"
  else
    echo "$raw"
  fi
}

# -------------------------
# System memory / swap helper
# -------------------------
ensure_swap_if_low_memory(){
  if [ "$SWAP_ON_LOW_MEM" != "true" ]; then return; fi
  if command -v free >/dev/null 2>&1; then
    total_mb=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$total_mb" -lt "$MIN_RAM_MB" ]; then
      info "Low memory detected (${total_mb}MB) — creating 2GB swap..."
      if [ ! -f /swapfile-zeazdev ]; then
        sudo fallocate -l 2G /swapfile-zeazdev || dd if=/dev/zero of=/swapfile-zeazdev bs=1M count=2048
        sudo chmod 600 /swapfile-zeazdev
        sudo mkswap /swapfile-zeazdev
        sudo swapon /swapfile-zeazdev
        info "Swap created and enabled (/swapfile-zeazdev)"
      else
        warn "Swap file already exists"
      fi
    fi
  fi
}

# -------------------------
# Fetch WorldID Router (best-effort)
# -------------------------
try_fetch_world_router(){
  info "Attempting to fetch WorldID Router address (best-effort)..."
  local urls=(
    "https://raw.githubusercontent.com/worldcoin/world-id/main/deployments.json"
    "https://raw.githubusercontent.com/worldcoin/world-id/main/addresses.json"
    "https://raw.githubusercontent.com/worldcoin/world-id/main/deployments/deployments.json"
    "https://raw.githubusercontent.com/worldcoin/world-id/main/README.md"
    "https://docs.world.org/"
  )
  local addr=""
  for u in "${urls[@]}"; do
    if command -v curl >/dev/null 2>&1; then
      body=$(curl -fsS "$u" 2>/dev/null || true)
      if [ -n "$body" ]; then
        addr=$(echo "$body" | grep -Eo "0x[0-9a-fA-F]{40}" | head -n1 || true)
        if [ -n "$addr" ]; then
          echo "$addr"; return 0
        fi
      fi
    fi
  done
  echo "$WORLD_ROUTER_FALLBACK"
}

WORLD_ROUTER=$(try_fetch_world_router)
info "WorldID Router set to: $WORLD_ROUTER"

# -------------------------
# Prepare .env example
# -------------------------
mkdir -p "$INSTALL_PATH"
cat > "$INSTALL_PATH/.env.EXAMPLE" <<EOF
# ZeaZDev v5.4 .env example
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
info ".env.EXAMPLE written to $INSTALL_PATH/.env.EXAMPLE"

# -------------------------
# Contracts & deploy script templates
# -------------------------
mkdir -p "$TMP"
cat > "$TMP/ZEAToken.sol" <<'SOL'
/* -----------------------------------------------------------------------------
   Developer: PHIPHAT PHOEMSUK (ZeaZDev)
   Project: Zea Token ($ZEA)
   File: ZEAToken.sol
   License: MIT
   -----------------------------------------------------------------------------
*/
 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.20;
 import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
 import "@openzeppelin/contracts/access/Ownable.sol";
 contract ZEAToken is ERC20, Ownable {
   constructor() ERC20("ZEA Token","ZEA") Ownable(msg.sender) {
     _mint(msg.sender, 1000000000 * (10 ** decimals()));
   }
 }
SOL

cat > "$TMP/Airdrop.sol" <<'SOL'
/* -----------------------------------------------------------------------------
   Developer: PHIPHAT PHOEMSUK (ZeaZDev)
   File: Airdrop.sol
   Description: Airdrop contract integrated with WorldID for Sybil-resistance
   -----------------------------------------------------------------------------
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
interface IWorldID { function verifyProof(uint256,uint256,uint256,uint256,uint256[8] calldata) external view; }
contract Airdrop is Ownable {
  IERC20 public token; IWorldID public worldID; string public appId; string public constant action="zea-airdrop";
  mapping(uint256=>bool) public nullifierUsed; uint256 public constant AIRDROP_AMOUNT=100*10**18;
  event Claimed(address indexed user,uint256 nullifierHash);
  constructor(address t,address w,string memory id) Ownable(msg.sender) { token = IERC20(t); worldID = IWorldID(w); appId = id; }
  function claimAirdrop(address r,uint256 root,uint256 n,uint256[8] calldata p) external {
    require(!nullifierUsed[n], "Claimed");
    uint256 s = uint256(keccak256(abi.encodePacked(appId,action,r)));
    worldID.verifyProof(root,1,s,n,p);
    nullifierUsed[n] = true;
    require(token.transfer(r, AIRDROP_AMOUNT), "Fail");
    emit Claimed(r,n);
  }
}
SOL

cat > "$TMP/deploy.js" <<'JS'
/* -----------------------------------------------------------------------------
   Developer: PHIPHAT PHOEMSUK (ZeaZDev)
   File: deploy.js
   Purpose: Deploy ZEAToken and Airdrop, then fund Airdrop with 500M ZEA
   -----------------------------------------------------------------------------
*/
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
    console.log("Verified on explorer");
  } catch (e) {
    console.warn("Verify failed (non-fatal):", e && e.message ? e.message : e);
  }
  fs.writeFileSync("/tmp/zeadev_result.json", JSON.stringify({ network: process.env.NETWORK, token: tokenAddr, airdrop: aAddr }));
}
main().catch(e=>{ console.error(e); process.exit(1); });
JS

# -------------------------
# Work: split MULTI_RPC_LIST into pairs
# -------------------------
IFS=',' read -r -a PAIRS <<< "$MULTI_RPC_LIST"

# -------------------------
# Preflight: ensure swap if low memory
# -------------------------
ensure_swap_if_low_memory

# -------------------------
# Concurrency control helpers
# -------------------------
declare -a JOB_PIDS
RESULTS_TMP="$RESULTS_DIR"
mkdir -p "$RESULTS_TMP"

# shared npm cache env
export npm_config_cache="$NPM_CACHE_DIR"

# run job for a network
run_network_job(){
  local pair="$1"
  local net="${pair%%=*}"
  local rpc="${pair#*=}"
  rpc=$(normalize_rpc "$rpc")
  local ws="$PROJECT_PATH/$net"
  mkdir -p "$ws" "$ws/contracts" "$ws/scripts"
  cd "$ws" || return 1

  info "[$net] workspace at $ws; RPC: $rpc"

  # write workspace .env
  cat > "$ws/.env" <<EOF
RPC_URL=${rpc}
PRIVATE_KEY=${PRIVATE_KEY}
NETWORK=${net}
WORLD_APP_ID=${WORLD_APP_ID}
ETHERSCAN_API_KEY=${ETHERSCAN_API_KEY}
WORLD_ID_ROUTER_ADDRESS=${WORLD_ROUTER}
EOF

  # ensure package.json + ESM mode
  if [ ! -f "$ws/package.json" ]; then
    (cd "$ws" && npm init -y >/dev/null 2>&1 || true)
    (cd "$ws" && npm pkg set type="module" >/dev/null 2>&1 || true)
  fi

  # copy contracts + script
  cp "$TMP/ZEAToken.sol" "$ws/contracts/ZEAToken.sol"
  cp "$TMP/Airdrop.sol" "$ws/contracts/Airdrop.sol"
  cp "$TMP/deploy.js" "$ws/scripts/deploy.js"

  # write minimal hardhat.config.js
  cat > "$ws/hardhat.config.js" <<'HHCFG'
import { config as dotenvConfig } from "dotenv";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";
dotenvConfig();
const { RPC_URL, PRIVATE_KEY } = process.env;
export default {
  solidity: { version: "0.8.20", settings: { optimizer: { enabled: true, runs: 200 } } },
  networks: {
    [process.env.NETWORK || "local"]: { url: RPC_URL || "", accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [] }
  },
  etherscan: { apiKey: { [process.env.NETWORK || "local"]: process.env.ETHERSCAN_API_KEY || "" } }
};
HHCFG

  # ensure local hardhat installed (prevent HHE22)
  if [ ! -d "$ws/node_modules/hardhat" ]; then
    info "[$net] installing local Hardhat & minimal devDeps (may take a moment)..."
    (cd "$ws" && npm install --no-audit --no-fund --legacy-peer-deps --save-dev "hardhat@${INSTALL_HARDHAT_VERSION}" @nomicfoundation/hardhat-toolbox@^2.0.0 @nomicfoundation/hardhat-verify dotenv chai jq zip >/dev/null 2>&1) || true
  fi

  # try compile with retries and auto-heal
  local compile_ok=1
  for attempt in 1 2 3; do
    info "[$net] compile attempt #$attempt..."
    set +e
    (cd "$ws" && ./node_modules/.bin/hardhat clean >/dev/null 2>&1 || true)
    (cd "$ws" && ./node_modules/.bin/hardhat compile --show-stack-traces 2>&1 | tee "$LOG_DIR/${net}_compile.log")
    rc=$?
    set -e
    if [ $rc -eq 0 ]; then
      compile_ok=0
      break
    else
      warn "[$net] compile failed on attempt #$attempt (see $LOG_DIR/${net}_compile.log). Retrying with auto-heal..."
      (cd "$ws" && npm install --no-audit --no-fund --legacy-peer-deps --save-dev @nomicfoundation/hardhat-ethers@^3.1.0 @nomicfoundation/hardhat-network-helpers@^1.0.0 @nomicfoundation/hardhat-chai-matchers@^1.0.0 >/dev/null 2>&1) || true
      sleep 2
    fi
  done

  if [ $compile_ok -ne 0 ]; then
    err "[$net] compile failed after retries — check $LOG_DIR/${net}_compile.log"
    return 1
  fi

  # deploy (single attempt with log capture)
  info "[$net] deploying..."
  set +e
  (cd "$ws" && ./node_modules/.bin/hardhat run scripts/deploy.js --network "$net" 2>&1 | tee "$LOG_DIR/${net}_deploy.log")
  rcode=$?
  set -e
  if [ $rcode -ne 0 ]; then
    err "[$net] deploy failed — see $LOG_DIR/${net}_deploy.log"
    return 1
  fi

  # collect result (from /tmp/zeadev_result.json or parse logs)
  if [ -f /tmp/zeadev_result.json ]; then
    mv /tmp/zeadev_result.json "$RESULTS_TMP/${net}.json" || true
  else
    TOKEN=$(grep -Eo "Token: 0x[0-9a-fA-F]{40}" "$LOG_DIR/${net}_deploy.log" | awk '{print $2}' || true)
    AIRDROP=$(grep -Eo "Airdrop: 0x[0-9a-fA-F]{40}" "$LOG_DIR/${net}_deploy.log" | awk '{print $2}' || true)
    echo "{\"network\":\"${net}\",\"token\":\"${TOKEN}\",\"airdrop\":\"${AIRDROP}\"}" > "$RESULTS_TMP/${net}.json"
  fi

  info "[$net] done"
  return 0
}

# -------------------------
# Spawn jobs with concurrency limiting
# -------------------------
info "Starting parallel deploys (max $MAX_PARALLEL concurrent jobs)"
CURRENT=0
PIDS=()
for pair in "${PAIRS[@]}"; do
  [ -z "$pair" ] && continue
  # wait if we have reached limit
  while [ "$CURRENT" -ge "$MAX_PARALLEL" ]; do
    wait -n || true
    CURRENT=$((CURRENT-1))
  done
  run_network_job "$pair" &
  pid=$!
  PIDS+=($pid)
  CURRENT=$((CURRENT+1))
  sleep 0.4
done

# wait all jobs
info "Waiting for all network jobs to finish..."
FAILED=0
for p in "${PIDS[@]}"; do
  if ! wait "$p"; then FAILED=$((FAILED+1)); fi
done
if [ "$FAILED" -gt 0 ]; then warn "$FAILED network job(s) failed"; fi

# -------------------------
# Aggregate results => frontend/networks.json
# -------------------------
info "Aggregating results for dashboard..."
mkdir -p "$FRONT_PATH/src"
outf="$FRONT_PATH/src/networks.json"
echo "[" > "$outf"
first=true
for f in "$RESULTS_DIR"/*.json; do
  if [ ! -f "$f" ]; then continue; fi
  if $first; then first=false; else echo "," >> "$outf"; fi
  cat "$f" >> "$outf"
done
echo "]" >> "$outf"
info "networks.json written to $outf"

# -------------------------
# Dashboard server (Express + WebSocket)
# -------------------------
info "Writing dashboard server and static UI..."
mkdir -p "$DASH_PATH"

cat > "$INSTALL_PATH/server.js" <<'NODE'
/* ZeaZDev Dashboard Server
   - Express static serve from Dashboard folder
   - /api/results => aggregated results
   - /api/logtail => latest log tail
   - WebSocket /ws => broadcast file events
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
    res.json({ ok:true, results: data });
  } catch(e){ res.status(500).json({ ok:false, error: e.message }); }
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

# install server deps
(cd "$INSTALL_PATH" && npm init -y >/dev/null 2>&1 || true)
(cd "$INSTALL_PATH" && npm pkg set type="module" >/dev/null 2>&1 || true)
(cd "$INSTALL_PATH" && npm install --no-audit --no-fund express ws chokidar --legacy-peer-deps >/dev/null 2>&1) || true

# dashboard ui
cat > "$DASH_PATH/index.html" <<'HTML'
<!doctype html><html><head><meta charset="utf-8"/><title>ZeaZDev Dashboard</title>
<meta name="viewport" content="width=device-width,initial-scale=1"/></head><body>
<style>body{font-family:Inter,Arial,sans-serif;margin:0;background:#f6f7fb;color:#111}
header{background:#0f172a;color:#fff;padding:12px 20px} .container{padding:20px;max-width:1200px;margin:auto}
.card{background:#fff;border-radius:8px;padding:12px;box-shadow:0 2px 6px rgba(0,0,0,0.06);margin-bottom:12px}
pre{white-space:pre-wrap;font-size:12px;max-height:420px;overflow:auto}
.row{display:flex;justify-content:space-between;padding:8px;border-bottom:1px solid #f0f0f5}
</style>
<header><strong>ZeaZDev Dashboard</strong> — Deploy & Logs (live)</header>
<div class="container"><div style="display:flex;gap:12px;margin-bottom:12px"><button id="btn-refresh">Refresh</button>
<div id="status">Status: <span id="stat">idle</span></div></div>
<div class="card"><h3>Deploy Results</h3><div id="results"></div></div>
<div class="card"><h3>Logs (latest)</h3><pre id="logview">No logs yet</pre></div>
<div class="card"><h3>Realtime Events</h3><div id="events"></div></div>
</div>
<script type="module" src="/app.js"></script></body></html>
HTML

cat > "$DASH_PATH/app.js" <<'JS'
const BASE=''; const resultsEl=document.getElementById('results'), logView=document.getElementById('logview'), eventsEl=document.getElementById('events'), stat=document.getElementById('stat');
document.getElementById('btn-refresh').onclick=()=>{loadResults();loadLog();}
async function loadResults(){stat.innerText='loading';try{const r=await fetch(`${BASE}/api/results`);const j=await r.json();resultsEl.innerHTML='';(j.results||[]).forEach(item=>{const d=document.createElement('div');d.className='row';d.innerHTML=`<div><strong>${item.network||'n/a'}</strong></div><div>Token: ${item.token||'-'}<br>Airdrop: ${item.airdrop||'-'}</div>`;resultsEl.appendChild(d)});stat.innerText='ok'}catch(e){stat.innerText='error';addEvent('Error loading results: '+e.message)}}
async function loadLog(){try{const r=await fetch(`${BASE}/api/logtail?lines=400`);const j=await r.json();if(j.ok)logView.innerText=(j.file?('--- '+j.file+' ---\n'):'')+(j.log||'');}catch(e){addEvent('Error loading log: '+e.message)}}
function addEvent(msg){const d=document.createElement('div');d.style.padding='8px';d.style.borderBottom='1px solid #eee';d.innerText=`[${new Date().toLocaleTimeString()}] ${msg}`;eventsEl.prepend(d);}
loadResults(); loadLog();
const proto = location.protocol==='https:'?'wss:':'ws:'; const ws=new WebSocket(`${proto}//${location.host}/ws`);
ws.addEventListener('open',()=>addEvent('WS connected'));
ws.addEventListener('message', ev => { try { const d=JSON.parse(ev.data); if(d.type==='result'){addEvent(`Result update: ${d.data.network||d.file}`); loadResults();} else if(d.type==='log'){addEvent(`Log updated: ${d.file}`); loadLog();} else addEvent(`Event: ${JSON.stringify(d).slice(0,200)}`); } catch(e){ addEvent('WS parse error'); } });
ws.addEventListener('close',()=>addEvent('WS closed')); ws.addEventListener('error', e=>addEvent('WS error'));
JS

# -------------------------
# Start dashboard server in background
# -------------------------
info "Starting dashboard server in background..."
(cd "$INSTALL_PATH" && node server.js &>/tmp/zeazdev_dashboard.log & echo $! > /tmp/zeazdev_dashboard.pid) || warn "Failed to start dashboard server"

# -------------------------
# Git push logs (if configured)
# -------------------------
info "Preparing deploy logs..."
LOGFILE="$LOG_DIR/deploy-$(date -u +%Y%m%dT%H%M%SZ).log"
echo "ZeaZDev v5.4 Deploy Logs - $(date -u)" > "$LOGFILE"
for f in "$RESULTS_DIR"/*.json; do echo "---- $f ----" >> "$LOGFILE"; cat "$f" >> "$LOGFILE"; echo >> "$LOGFILE"; done
for f in "$LOG_DIR"/*.log; do echo "---- $f ----" >> "$LOGFILE"; tail -n 400 "$f" >> "$LOGFILE"; echo >> "$LOGFILE"; done

if [ -n "$GIT_LOG_REPO" ]; then
  info "Pushing deploy logs to Git repository (token hidden)"
  # sanitize output for logs (don't print token)
  SAFE_REMOTE=$(echo "$GIT_LOG_REPO" | sed -E 's#(https://)[^@]+@#\1***TOKEN***@#')
  info "Remote (sanitized): $SAFE_REMOTE (branch: $GIT_LOG_BRANCH)"

  cd "$INSTALL_PATH" || true
  git init -q || true
  git remote remove origin >/dev/null 2>&1 || true
  git remote add origin "$GIT_LOG_REPO" || true
  git checkout -B "$GIT_LOG_BRANCH" || true

  mkdir -p results logs
  cp -r "$RESULTS_DIR"/* results/ 2>/dev/null || true
  cp -r "$LOG_DIR"/* logs/ 2>/dev/null || true
  cp "$LOGFILE" ./deploy-latest.log || true

  # commit & push with retry
  git add . >/dev/null 2>&1 || true
  git -c user.email="ci@zeazdev.local" -c user.name="ZeaZDev CI" commit -m "Auto deploy $(date -u)" >/dev/null 2>&1 || true

  PUSH_OK=1
  for attempt in 1 2 3; do
    if git push -f origin "$GIT_LOG_BRANCH" >/dev/null 2>&1; then
      info "✅ Logs pushed to Git repository (branch: $GIT_LOG_BRANCH)"
      PUSH_OK=0
      break
    else
      warn "Git push attempt #$attempt failed — retrying..."
      sleep 2
    fi
  done
  if [ $PUSH_OK -ne 0 ]; then warn "Git push failed after retries; check credentials and network"
  fi
fi

# -------------------------
# Telegram notify summary (optional)
# -------------------------
if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
  MSG="✅ ZeaZDev v5.4 Multi-Deploy finished.\n"
  for f in "$RESULTS_DIR"/*.json; do
    if [ -f "$f" ]; then
      n=$(jq -r .network "$f"); t=$(jq -r .token "$f"); a=$(jq -r .airdrop "$f")
      MSG="${MSG}\n${n}\n Token: ${t}\n Airdrop: ${a}\n"
    fi
  done
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" -d chat_id="${TELEGRAM_CHAT_ID}" -d text="$MSG" >/dev/null 2>&1 || warn "Telegram notify failed"
  info "Telegram summary sent"
fi

# -------------------------
# Frontend (Parcel) + Health Monitor
# -------------------------
info "Preparing minimal frontend and starting parcel dev server..."
mkdir -p "$FRONT_PATH/src"
# ensure networks.json exists (may be empty)
cat > "$FRONT_PATH/src/networks.json" <<EOF
$(cat "$FRONT_PATH/src/networks.json" 2>/dev/null || echo "[]")
EOF

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

# install minimal frontend deps
(cd "$FRONT_PATH" && npm init -y >/dev/null 2>&1 || true)
(cd "$FRONT_PATH" && npm pkg set type="module" >/dev/null 2>&1 || true)
(cd "$FRONT_PATH" && npm install --no-audit --no-fund react react-dom parcel --legacy-peer-deps >/dev/null 2>&1) || true

# start parcel and health monitor
( cd "$FRONT_PATH" && npx parcel src/index.html --port 3000 &>/tmp/zeazdev_parcel.log & echo $! > /tmp/zeazdev_parcel.pid )
sleep 4
info "Parcel frontend started (pid $(cat /tmp/zeazdev_parcel.pid 2>/dev/null || echo 'n/a'))"

# health monitor in background
(
  PIDFILE="/tmp/zeazdev_parcel.pid"
  while true; do
    sleep 25
    if ! curl -sSf "http://localhost:3000" >/dev/null 2>&1; then
      warn "Frontend unhealthy — restarting parcel"
      kill $(cat $PIDFILE 2>/dev/null) >/dev/null 2>&1 || true
      ( cd "$FRONT_PATH" && npx parcel src/index.html --port 3000 &>/tmp/zeazdev_parcel.log & echo $! > $PIDFILE )
      if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" -d chat_id="${TELEGRAM_CHAT_ID}" -d text="⚠️ ZeaZDev frontend restarted" >/dev/null 2>&1 || true
      fi
    fi
  done
) &

# -------------------------
# Final summary & notes
# -------------------------
info "ZeaZDev v5.4 completed. Dashboard: http://<server-ip>:3000 (served by $INSTALL_PATH/server.js)"
info "Results: $RESULTS_DIR"
info "Logs: $LOG_DIR"
info "Backups: $BACKUP_DIR"
info "If running in Docker, bind-mount $INSTALL_PATH to persist results/logs."

# End of script
