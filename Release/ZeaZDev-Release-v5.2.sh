#!/usr/bin/env bash
# ZeaZDev-Release-v5.2.sh
# ZeaZDev v5.2 — Multi-Node Cluster Deploy + Etherscan V2 Verify + Dashboard + WebSocket
# One-file installer: creates project under INSTALL_PATH (default /opt/ZeaZDev)
# Usage: provide env vars non-interactively or run interactively when prompted.
set -euo pipefail
trap 'echo "[ERROR] Unexpected error on line $LINENO"; exit 1' ERR

### =============== Configuration & Helpers ===============
GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; RESET="\e[0m"
info(){ echo -e "${GREEN}[INFO]${RESET} $*"; }
warn(){ echo -e "${YELLOW}[WARN]${RESET} $*"; }
err(){ echo -e "${RED}[ERROR]${RESET} $*"; }

# Defaults
INSTALL_PATH="${INSTALL_PATH:-/opt/ZeaZDev}"
PROJECT_PATH="$INSTALL_PATH/project"
FRONT_PATH="$INSTALL_PATH/frontend"
DASH_PATH="$INSTALL_PATH/dashboard"
RESULTS_DIR="$INSTALL_PATH/results"
LOG_DIR="$INSTALL_PATH/logs"
BACKUP_DIR="$INSTALL_PATH/backups"
TMP="/tmp/zeadev_v53"
mkdir -p "$PROJECT_PATH" "$FRONT_PATH" "$DASH_PATH" "$RESULTS_DIR" "$LOG_DIR" "$BACKUP_DIR" "$TMP"

# Environment - can be passed in non-interactive mode
: "${MULTI_RPC_LIST:=${MULTI_RPC_LIST:-}}"
: "${WORLD_APP_ID:=${WORLD_APP_ID:-}}"
: "${PRIVATE_KEY:=${PRIVATE_KEY:-}}"
: "${ETHERSCAN_API_KEY:=${ETHERSCAN_API_KEY:-}}"
: "${TELEGRAM_BOT_TOKEN:=${TELEGRAM_BOT_TOKEN:-}}"
: "${TELEGRAM_CHAT_ID:=${TELEGRAM_CHAT_ID:-}}"
: "${GIT_LOG_REPO:=${GIT_LOG_REPO:-}}"
: "${GIT_LOG_BRANCH:=${GIT_LOG_BRANCH:-deploy-logs}}"
: "${FRONT_DOMAIN:=${FRONT_DOMAIN:-http://localhost:3000}}"
: "${NODE_VERSION_OK:=18}"  # recommended Node base (docker uses node:18)
: "${WORLD_ROUTER_FALLBACK:=0x7a5b8bC49D4D17a1aDe87E4E3fCB86B1fFb3D545}"
: "${MAX_VERIFY_RETRIES:=2}"
: "${VERIFY_RETRY_DELAY:=8}"

# Interactive prompts if required envs missing
if [ -z "$MULTI_RPC_LIST" ] || [ -z "$WORLD_APP_ID" ] || [ -z "$PRIVATE_KEY" ]; then
  echo "Some configuration values are missing. You can provide them as environment variables before running the script."
  read -p "Enter MULTI_RPC_LIST (e.g. sepolia=https://... ,worldchain=https://...): " I_MULTI_RPC_LIST
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
  read -p "Enter GIT_LOG_REPO (optional): " I_GITREPO
  GIT_LOG_REPO="${GIT_LOG_REPO:-$I_GITREPO}"
fi

# sanitize MULTI_RPC_LIST
MULTI_RPC_LIST=$(echo "$MULTI_RPC_LIST" | sed 's/ //g')
if [ -z "$MULTI_RPC_LIST" ]; then err "MULTI_RPC_LIST required"; exit 1; fi

info "Install path: $INSTALL_PATH"
info "Project path: $PROJECT_PATH"
info "Frontend path: $FRONT_PATH"

# Utility: normalize MetaMask shorthand (metamask:KEY:chains)
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

# split pairs
IFS=',' read -r -a PAIRS <<< "$MULTI_RPC_LIST"

# prepare .env.EXAMPLE
cat > "$INSTALL_PATH/.env.EXAMPLE" <<EOF
# Example .env for ZeaZDev v5.2
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

### =============== Fetch live WorldID Router (best-effort) ===============
info "Attempting to fetch latest WorldID Router address (best-effort) ..."
WORLD_ROUTER=""
try_fetch_world_router(){
  local urls=(
    "https://raw.githubusercontent.com/worldcoin/world-id/main/deployments.json"
    "https://raw.githubusercontent.com/worldcoin/world-id/main/addresses.json"
    "https://raw.githubusercontent.com/worldcoin/world-id/main/deployments/deployments.json"
    "https://raw.githubusercontent.com/worldcoin/world-id/main/README.md"
    "https://docs.world.org/"
  )
  for u in "${urls[@]}"; do
    if command -v curl >/dev/null 2>&1; then
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
}
try_fetch_world_router
info "WorldID Router set to: $WORLD_ROUTER"

### =============== Create base files: Hardhat + contracts + deploy script ===============
info "Writing contracts, hardhat config template, and deploy script..."

# create a function to write hardhat.config.js with customChains mapping per your table
write_hardhat_config(){
  local net_name="$1"    # e.g. sepolia
  local rpc_env_var_name="$2" # we'll use RPC_URL from .env at runtime
  local etherscan_map="$3" # will be written globally; but we write per-network config in each workspace

  cat > hardhat.config.js <<'CFG'
import { config as dotenvConfig } from "dotenv";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";
dotenvConfig();

const { RPC_URL, PRIVATE_KEY, ETHERSCAN_API_KEY } = process.env;

// customChains (Etherscan V2-style mapping) - full mapping referenced in v5.2
const customChains = [
  { network: "sepolia", chainId: 11155111, urls: { apiURL: "https://api-sepolia.etherscan.io/api", browserURL: "https://sepolia.etherscan.io" } },
  { network: "mainnet", chainId: 1, urls: { apiURL: "https://api.etherscan.io/api", browserURL: "https://etherscan.io" } },
  { network: "bsc", chainId: 56, urls: { apiURL: "https://api.bscscan.com/api", browserURL: "https://bscscan.com" } },
  { network: "bscTestnet", chainId: 97, urls: { apiURL: "https://api-testnet.bscscan.com/api", browserURL: "https://testnet.bscscan.com" } },
  { network: "polygon", chainId: 137, urls: { apiURL: "https://api.polygonscan.com/api", browserURL: "https://polygonscan.com" } },
  { network: "polygonAmoy", chainId: 80002, urls: { apiURL: "https://api-amoy.polygonscan.com/api", browserURL: "https://amoy.polygonscan.com" } },
  { network: "avalanche", chainId: 43114, urls: { apiURL: "https://api.snowtrace.io/api", browserURL: "https://snowtrace.io" } },
  { network: "fuji", chainId: 43113, urls: { apiURL: "https://api-fuji.snowtrace.io/api", browserURL: "https://testnet.snowtrace.io" } },
  { network: "optimism", chainId: 10, urls: { apiURL: "https://api-optimistic.etherscan.io/api", browserURL: "https://optimistic.etherscan.io" } },
  { network: "optimismSepolia", chainId: 11155420, urls: { apiURL: "https://api-sepolia-optimistic.etherscan.io/api", browserURL: "https://sepolia-optimistic.etherscan.io" } },
  { network: "arbitrum", chainId: 42161, urls: { apiURL: "https://api-arbitrum.etherscan.io/api", browserURL: "https://arbiscan.io" } },
  { network: "arbitrumSepolia", chainId: 421614, urls: { apiURL: "https://api-sepolia-arbitrum.etherscan.io/api", browserURL: "https://sepolia-arbiscan.io" } },
  { network: "base", chainId: 8453, urls: { apiURL: "https://api.basescan.org/api", browserURL: "https://basescan.org" } },
  { network: "baseSepolia", chainId: 84532, urls: { apiURL: "https://api-sepolia.basescan.org/api", browserURL: "https://sepolia.basescan.org" } },
  { network: "fantom", chainId: 250, urls: { apiURL: "https://api.ftmscan.com/api", browserURL: "https://ftmscan.com" } },
  { network: "fantomTestnet", chainId: 4002, urls: { apiURL: "https://api-testnet.ftmscan.com/api", browserURL: "https://testnet.ftmscan.com" } },
  { network: "gnosis", chainId: 100, urls: { apiURL: "https://api.gnosisscan.io/api", browserURL: "https://gnosisscan.io" } },
  { network: "cronos", chainId: 25, urls: { apiURL: "https://api.cronoscan.com/api", browserURL: "https://cronoscan.com" } }
];

export default {
  solidity: { version: "0.8.20", settings: { optimizer: { enabled: true, runs: 200 } } },
  networks: {
    hardhat: {},
    // actual RPC_URL env is set by the per-network workspace .env before running hardhat
    [process.env.NETWORK || "local"]: { url: process.env.RPC_URL || "", accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [] }
  },
  etherscan: {
    apiKey: { [process.env.NETWORK || "local"]: process.env.ETHERSCAN_API_KEY || "" },
    customChains
  }
};
CFG
}

# Write generic contract files (will be copied into each per-network workspace)
cat > "$TMP/ZEAToken.sol" <<'SOL'
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
  // try verify programmatically (non-fatal)
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

### =============== Per-network workspace creation & parallel deploy ===============
info "Preparing per-network workspaces and starting parallel deploys..."

# convert PAIRS into array of "name=rpc" already sanitized
declare -a JOB_PIDS
RESULTS_TMP="$RESULTS_DIR"
mkdir -p "$RESULTS_TMP"

run_network_job(){
  local pair="$1"  # e.g. sepolia=https://...
  local net="${pair%%=*}"
  local rpc="${pair#*=}"
  rpc=$(normalize_rpc "$rpc")
  local ws="$PROJECT_PATH/$net"
  mkdir -p "$ws" "$ws/contracts" "$ws/scripts"
  cd "$ws"

  info "[$net] workspace at $ws; RPC: $rpc"

  # write .env for this workspace
  cat > "$ws/.env" <<EOF
RPC_URL=${rpc}
PRIVATE_KEY=${PRIVATE_KEY}
NETWORK=${net}
WORLD_APP_ID=${WORLD_APP_ID}
ETHERSCAN_API_KEY=${ETHERSCAN_API_KEY}
WORLD_ID_ROUTER_ADDRESS=${WORLD_ROUTER}
EOF

  # initialize npm + set ESM mode
  if [ ! -f "$ws/package.json" ]; then
    (cd "$ws" && npm init -y >/dev/null 2>&1 || true)
    (cd "$ws" && npm pkg set type="module" >/dev/null 2>&1 || true)
  fi

  # copy contracts & scripts
  cp "$TMP/ZEAToken.sol" "$ws/contracts/ZEAToken.sol"
  cp "$TMP/Airdrop.sol" "$ws/contracts/Airdrop.sol"
  cp "$TMP/deploy.js" "$ws/scripts/deploy.js"
  # write hardhat.config.js in workspace
  cat > "$ws/hardhat.config.js" <<'HCFG'
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
HCFG

  # install dependencies (minimal, using legacy flags)
  (cd "$ws" && npm install --legacy-peer-deps --save @openzeppelin/contracts ethers >/dev/null 2>&1) || true
  (cd "$ws" && npm install --legacy-peer-deps --save-dev hardhat@2.20.1 @nomicfoundation/hardhat-toolbox@2.0.2 @nomicfoundation/hardhat-verify@^2.0.0 dotenv chai jq zip --no-audit --no-fund >/dev/null 2>&1) || true

  # compile (attempt auto-heal if missing plugins)
  info "[$net] compiling..."
  set +e
  (cd "$ws" && npx hardhat clean >/dev/null 2>&1 || true)
  (cd "$ws" && npx hardhat compile --show-stack-traces 2>&1 | tee "$LOG_DIR/${net}_compile.log")
  local rc=$?
  set -e
  if [ $rc -ne 0 ]; then
    warn "[$net] compile failed; attempting auto-heal plugin install..."
    (cd "$ws" && npm install --legacy-peer-deps --save-dev @nomicfoundation/hardhat-ethers@^3.1.0 @nomicfoundation/hardhat-network-helpers@^1.0.0 @nomicfoundation/hardhat-chai-matchers@^1.0.0 --no-audit --no-fund >/dev/null 2>&1) || true
    (cd "$ws" && npx hardhat compile --show-stack-traces 2>&1 | tee "$LOG_DIR/${net}_compile_retry.log") || { err "[$net] compile retry failed"; return 1; }
  fi

  # deploy with retries and failover for this specific network (we already have RPC set)
  info "[$net] deploying..."
  set +e
  (cd "$ws" && npx hardhat run scripts/deploy.js --network "$net" 2>&1 | tee "$LOG_DIR/${net}_deploy.log")
  local rcode=$?
  set -e
  if [ $rcode -ne 0 ]; then
    err "[$net] deploy failed (see $LOG_DIR/${net}_deploy.log)"
    return 1
  fi

  # copy result (from /tmp/zeadev_result.json)
  if [ -f /tmp/zeadev_result.json ]; then
    mv /tmp/zeadev_result.json "$RESULTS_TMP/${net}.json" || true
  else
    # try extract from deploy log
    TOKEN=$(grep -Eo "Token: 0x[0-9a-fA-F]{40}" "$LOG_DIR/${net}_deploy.log" | awk '{print $2}' || true)
    AIRDROP=$(grep -Eo "Airdrop: 0x[0-9a-fA-F]{40}" "$LOG_DIR/${net}_deploy.log" | awk '{print $2}' || true)
    echo "{\"network\":\"${net}\",\"token\":\"${TOKEN}\",\"airdrop\":\"${AIRDROP}\"}" > "$RESULTS_TMP/${net}.json"
  fi
  info "[$net] done"
  return 0
}

# spawn jobs in background
for pair in "${PAIRS[@]}"; do
  if [ -z "$pair" ]; then continue; fi
  run_network_job "$pair" &
  JOB_PIDS+=($!)
  sleep 0.6
done

# wait for jobs
info "Waiting for all network jobs to finish..."
FAILED=0
for pid in "${JOB_PIDS[@]}"; do
  wait "$pid" || FAILED=$((FAILED+1))
done
if [ $FAILED -gt 0 ]; then warn "$FAILED network jobs failed"; fi

### =============== Aggregate results -> frontend/networks.json ===============
info "Aggregating results for dashboard..."
mkdir -p "$FRONT_PATH/src"
echo "[" > "$FRONT_PATH/src/networks.json"
first=true
for f in "$RESULTS_DIR"/*.json; do
  if [ "$first" = true ]; then first=false; else echo "," >> "$FRONT_PATH/src/networks.json"; fi
  cat "$f" >> "$FRONT_PATH/src/networks.json"
done
echo "]" >> "$FRONT_PATH/src/networks.json"
info "networks.json written to $FRONT_PATH/src/networks.json"

### =============== Dashboard server (Express + WebSocket) ===============
info "Writing dashboard server and UI..."

# server.js
cat > "$INSTALL_PATH/server.js" <<'NODE'
import express from "express";
import http from "http";
import { WebSocketServer } from "ws";
import fs from "fs";
import path from "path";
import chokidar from "chokidar";

const PORT = process.env.DASH_PORT ? Number(process.env.DASH_PORT) : 3000;
const BASE = process.env.PROJECT_DIR || "/opt/ZeaZDev";
const RESULTS_DIR = path.join(BASE, "results");
const LOG_DIR = path.join(BASE, "logs");
const DASH_DIR = path.join(BASE, "dashboard");

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

server.listen(PORT, () => console.log(`Dashboard server running on http://0.0.0.0:${PORT}`));
NODE

# install minimal server deps
(cd "$INSTALL_PATH" && npm init -y >/dev/null 2>&1 || true)
(cd "$INSTALL_PATH" && npm pkg set type="module" >/dev/null 2>&1 || true)
(cd "$INSTALL_PATH" && npm install --legacy-peer-deps express ws chokidar --no-audit --no-fund >/dev/null 2>&1) || true

# Dashboard static UI
mkdir -p "$DASH_PATH"
cat > "$DASH_PATH/index.html" <<'HTML'
<!doctype html><html><head><meta charset="utf-8"/><title>ZeaZDev Dashboard</title><meta name="viewport" content="width=device-width,initial-scale=1"/></head><body>
<style>
body{font-family:Inter,Arial,sans-serif;margin:0;background:#f6f7fb;color:#111}header{background:#0f172a;color:#fff;padding:12px 20px} .container{padding:20px;max-width:1200px;margin:auto}
.card{background:#fff;border-radius:8px;padding:12px;box-shadow:0 2px 6px rgba(0,0,0,0.06);margin-bottom:12px}
pre{white-space:pre-wrap;font-size:12px;max-height:420px;overflow:auto}
.row{display:flex;justify-content:space-between;padding:8px;border-bottom:1px solid #f0f0f5}
</style>
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
async function loadResults(){stat.innerText='loading';try{const r=await fetch(`${BASE}/api/results`);const j=await r.json();resultsEl.innerHTML='';(j.results||[]).forEach(item=>{const d=document.createElement('div');d.className='row';d.innerHTML=`<div><strong>${item.network||'n/a'}</strong></div><div>Token: ${item.token||'-'}<br>Airdrop: ${item.airdrop||'-'}</div>`;resultsEl.appendChild(d)});stat.innerText='ok'}catch(e){stat.innerText='error';addEvent('Error loading results: '+e.message)}}
async function loadLog(){try{const r=await fetch(`${BASE}/api/logtail?lines=400`);const j=await r.json();if(j.ok)logView.innerText=(j.file?('--- '+j.file+' ---\n'):'')+(j.log||'');}catch(e){addEvent('Error loading log: '+e.message)}}
function addEvent(msg){const d=document.createElement('div');d.style.padding='8px';d.style.borderBottom='1px solid #eee';d.innerText=`[${new Date().toLocaleTimeString()}] ${msg}`;eventsEl.prepend(d);}
loadResults(); loadLog();
const proto = location.protocol==='https:'?'wss:':'ws:'; const ws=new WebSocket(`${proto}//${location.host}/ws`);
ws.addEventListener('open',()=>addEvent('WS connected'));
ws.addEventListener('message', ev => { try { const d=JSON.parse(ev.data); if(d.type==='result'){addEvent(`Result update: ${d.data.network||d.file}`); loadResults();} else if(d.type==='log'){addEvent(`Log updated: ${d.file}`); loadLog();} else addEvent(`Event: ${JSON.stringify(d).slice(0,200)}`); } catch(e){ addEvent('WS parse error'); } });
ws.addEventListener('close',()=>addEvent('WS closed')); ws.addEventListener('error', e=>addEvent('WS error'));
JS

info "Dashboard UI written to $DASH_PATH (server will serve this)"

### =============== Start Dashboard server (background) ===============
info "Starting dashboard server (background)"
(cd "$INSTALL_PATH" && node server.js &>/tmp/zeadev_dashboard.log & echo $! > /tmp/zeadev_dashboard.pid)

### =============== Git push deploy logs if configured ===============
info "Preparing deploy logs..."
LOGFILE="$LOG_DIR/deploy-$(date -u +%Y%m%dT%H%M%SZ).log"
echo "ZeaZDev v5.2 Deploy Logs - $(date -u)" > "$LOGFILE"
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
  git -c user.email="ci@zeadev.local" -c user.name="ZeaZDev CI" commit -m "Deploy logs $(date -u)" >/dev/null 2>&1 || true
  git push -f origin "$GIT_LOG_BRANCH" >/dev/null 2>&1 && info "Logs pushed to $GIT_LOG_REPO#$GIT_LOG_BRANCH" || warn "Git push failed (check credentials)"
fi

### =============== Telegram notify summary ===============
if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
  MSG="✅ ZeaZDev v5.2 Multi-Deploy finished.\n"
  for f in "$RESULTS_DIR"/*.json; do
    n=$(jq -r .network "$f"); t=$(jq -r .token "$f"); a=$(jq -r .airdrop "$f")
    MSG="${MSG}\n${n}\n Token: ${t}\n Airdrop: ${a}\n"
  done
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" -d chat_id="${TELEGRAM_CHAT_ID}" -d text="$MSG" >/dev/null 2>&1 || warn "Telegram notification failed"
  info "Telegram summary sent"
fi

### =============== Start simple frontend (parcel) for project frontend & health monitor ===============
info "Creating minimal frontend in $FRONT_PATH and starting health monitor..."
mkdir -p "$FRONT_PATH/src"
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

# install parcel and react
(cd "$FRONT_PATH" && npm init -y >/dev/null 2>&1 || true)
(cd "$FRONT_PATH" && npm pkg set type="module" >/dev/null 2>&1 || true)
(cd "$FRONT_PATH" && npm install --legacy-peer-deps react react-dom parcel --no-audit --no-fund >/dev/null 2>&1) || true

# start parcel dev server in background and health monitor
( cd "$FRONT_PATH" && npx parcel src/index.html --port 3000 &>/tmp/zeadev_parcel.log & echo $! > /tmp/zeadev_parcel.pid )
sleep 4
info "Parcel frontend started (pid $(cat /tmp/zeadev_parcel.pid 2>/dev/null || echo 'n/a'))"

# simple health monitor (background)
(
  PIDFILE="/tmp/zeadev_parcel.pid"
  while true; do
    sleep 25
    if ! curl -sSf "http://localhost:3000" >/dev/null 2>&1; then
      warn "Frontend unhealthy — restarting parcel"
      kill $(cat $PIDFILE 2>/dev/null) >/dev/null 2>&1 || true
      ( cd "$FRONT_PATH" && npx parcel src/index.html --port 3000 &>/tmp/zeadev_parcel.log & echo $! > $PIDFILE )
      if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" -d chat_id="${TELEGRAM_CHAT_ID}" -d text="⚠️ ZeaZDev frontend restarted" >/dev/null 2>&1 || true
      fi
    fi
  done
) &

info "ZeaZDev v5.2 completed. Dashboard: http://<server-ip>:3000 (served by $INSTALL_PATH/server.js)"
info "Results placed in: $RESULTS_DIR; Logs: $LOG_DIR; Backups: $BACKUP_DIR"
info "If running in Docker, bind mount $INSTALL_PATH to persist results/logs."

# done
