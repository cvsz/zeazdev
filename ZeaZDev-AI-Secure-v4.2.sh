#!/usr/bin/env bash
# ZeaZDev-AI-Secure-v4.3.sh
# Auto-Heal & Verify — Final Production (install path /opt/ZeaZDev)
set -euo pipefail
GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; BLUE="\e[34m"; RESET="\e[0m"
DIV="────────────────────────────────────────────"

echo -e "${BLUE}$DIV"
echo -e "🌸 ZeaZDev v4.3 — Auto-Heal & Verify (Install: /opt/ZeaZDev)"
echo -e "$DIV${RESET}"

info(){ echo -e "${GREEN}[INFO]${RESET} $*"; }
warn(){ echo -e "${YELLOW}[WARN]${RESET} $*"; }
err(){ echo -e "${RED}[ERROR]${RESET} $*"; }

LOG="/opt/ZeaZDev/zeadev-v4.3.log"
mkdir -p /opt/ZeaZDev || true
exec > >(tee -a "$LOG") 2>&1

# require root
if [ "$(id -u)" -ne 0 ]; then
  err "โปรดรันสคริปต์ด้วยสิทธิ์ root (sudo)"
  exit 1
fi

# basic commands
for c in node npm curl sed awk grep tail; do
  command -v "$c" >/dev/null 2>&1 || { err "$c ไม่พบในระบบ — ติดตั้งก่อนรัน"; exit 1; }
done

NODE_VER=$(node -v || echo "v0.0.0"); NODE_MAJOR=$(echo "${NODE_VER#v}" | cut -d. -f1)
info "Node detected: $NODE_VER"

# interactive inputs (can be automated by piping env vars)
read -p "Network [1=Sepolia,2=OptimismGoerli,3=WorldChain] (default 3): " NET
case "${NET:-3}" in 1) NETWORK="sepolia";; 2) NETWORK="optimismGoerli";; *) NETWORK="worldchain-sepolia";; esac
read -p "WORLD_APP_ID: " WORLD_APP_ID
read -p "PRIVATE_KEY (0x...): " PRIVATE_KEY
read -p "ETHERSCAN_API_KEY (optional): " ETHERSCAN_KEY
read -p "Alchemy API Key (optional): " ALCHEMY_KEY
read -p "Frontend domain (default http://localhost:3000): " FRONT_DOMAIN
FRONT_DOMAIN=${FRONT_DOMAIN:-http://localhost:3000}

# build RPC
RPCS=()
[ -n "$ALCHEMY_KEY" ] && RPCS+=("https://${NETWORK}.g.alchemy.com/v2/${ALCHEMY_KEY}")
# add placeholder local
if [ ${#RPCS[@]} -eq 0 ]; then RPCS+=("http://localhost:8545"); fi

info "Install path: /opt/ZeaZDev"
INSTALL_PATH="/opt/ZeaZDev"
PROJECT_PATH="$INSTALL_PATH/project"
FRONT_PATH="$INSTALL_PATH/frontend"

# remove old install
rm -rf "$INSTALL_PATH" || true
mkdir -p "$PROJECT_PATH" "$FRONT_PATH" || true
cd "$PROJECT_PATH"

# write .env
cat > .env <<EOF
RPC_URL=${RPCS[0]}
PRIVATE_KEY=${PRIVATE_KEY}
NETWORK=${NETWORK}
WORLD_APP_ID=${WORLD_APP_ID}
ETHERSCAN_API_KEY=${ETHERSCAN_KEY}
EOF
info ".env created"

# initialize package
npm init -y >/dev/null 2>&1 || true
npm pkg set type="module" >/dev/null 2>&1 || true

# pick hardhat/toolbox version for node
if [ "$NODE_MAJOR" -ge 22 ]; then
  HH_VER="2.20.1"; TOOLBOX_VER="2.0.2"
else
  HH_VER="2.17.2"; TOOLBOX_VER="1.0.2"
fi
info "Installing Hardhat@${HH_VER} + @nomicfoundation/hardhat-toolbox@${TOOLBOX_VER}"
npm install --force --legacy-peer-deps --save-dev "hardhat@${HH_VER}" "@nomicfoundation/hardhat-toolbox@${TOOLBOX_VER}" dotenv

# auto-heal: remove legacy plugins that cause Ethers mismatch, install foundation ethers (v6) or labs (v5) as needed
warn "Cleaning legacy plugins if any..."
npm uninstall @nomiclabs/hardhat-ethers @ethersproject/providers >/dev/null 2>&1 || true

# Install foundation ethers + core deps
info "Installing core runtime deps and plugin bundle (auto-heal)"
# This bundle addresses HH801 and common peer conflicts; uses force+legacy-peer-deps to reduce ERESOLVE issues
set +e
npm install --force --legacy-peer-deps --save-dev \
@ethersproject/providers@^5.4.7 \
@nomicfoundation/hardhat-ethers@^3.1.0 \
@nomicfoundation/hardhat-network-helpers@^1.0.0 \
@nomicfoundation/hardhat-chai-matchers@^1.0.0 \
@nomicfoundation/hardhat-verify@^2.0.0 \
@typechain/ethers-v5@^10.1.0 \
@typechain/hardhat@^6.1.2 \
hardhat-gas-reporter@^1.0.8 \
solidity-coverage@^0.8.1 \
ts-node@^10.9.1 \
typechain@^8.3.0 \
typescript@^5.3.3 \
chai@^4.3.7 \
--loglevel=error
RC=$?
set -e
if [ $RC -ne 0 ]; then
  warn "Auto-heal: some installs failed; retrying with unsafe-perm"
  npm install --unsafe-perm --force --legacy-peer-deps --save-dev \
  @ethersproject/providers@^5.4.7 \
  @nomicfoundation/hardhat-ethers@^3.1.0 \
  @nomicfoundation/hardhat-network-helpers@^1.0.0 \
  @nomicfoundation/hardhat-chai-matchers@^1.0.0 \
  @nomicfoundation/hardhat-verify@^2.0.0 \
  @typechain/ethers-v5@^10.1.0 \
  @typechain/hardhat@^6.1.2 \
  hardhat-gas-reporter@^1.0.8 \
  solidity-coverage@^0.8.1 \
  ts-node@^10.9.1 \
  typechain@^8.3.0 \
  typescript@^5.3.3 \
  chai@^4.3.7 || warn "Final attempt failed; continuing (may still work)"
fi

# ensure runtime libs
npm install --legacy-peer-deps --save @openzeppelin/contracts ethers || true

# create contracts + deploy script (OZ v5 Ownable(msg.sender))
mkdir -p contracts scripts
cat > contracts/ZEAToken.sol <<'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract ZEAToken is ERC20, Ownable {
  constructor() ERC20("ZEA Token","ZEA") Ownable(msg.sender) {
    _mint(msg.sender, 1000000000 * (10 ** decimals()));
  }
}
EOF

cat > contracts/Airdrop.sol <<'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
interface IWorldID { function verifyProof(uint256 root,uint256 groupId,uint256 signal,uint256 nullifierHash,uint256[8] calldata proof) external view; }
contract Airdrop is Ownable {
  IERC20 public token; IWorldID public worldID; string public appId; string public constant action = "zea-airdrop";
  mapping(uint256 => bool) public nullifierUsed; uint256 public constant AIRDROP_AMOUNT = 100 * 10**18;
  event Claimed(address indexed user, uint256 nullifierHash);
  constructor(address _token, address _worldID, string memory _appId) Ownable(msg.sender) {
    token = IERC20(_token); worldID = IWorldID(_worldID); appId = _appId;
  }
  function claimAirdrop(address recipient, uint256 root, uint256 nullifierHash, uint256[8] calldata proof) external {
    require(!nullifierUsed[nullifierHash], "Already claimed");
    uint256 signal = uint256(keccak256(abi.encodePacked(appId, action, recipient)));
    worldID.verifyProof(root, 1, signal, nullifierHash, proof);
    nullifierUsed[nullifierHash] = true;
    require(token.transfer(recipient, AIRDROP_AMOUNT), "Transfer failed");
    emit Claimed(recipient, nullifierHash);
  }
}
EOF

cat > scripts/deploy.js <<'EOF'
import hre from "hardhat";
import fs from "fs";
import dotenv from "dotenv";
dotenv.config();
async function main(){
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deployer:", deployer.address);
  const ZEAToken = await hre.ethers.getContractFactory("ZEAToken");
  const zea = await ZEAToken.deploy(); await zea.waitForDeployment();
  const tokenAddr = await zea.getAddress(); console.log("ZEAToken:", tokenAddr);
  const Airdrop = await hre.ethers.getContractFactory("Airdrop");
  const airdrop = await Airdrop.deploy(tokenAddr, process.env.WORLD_ID_ROUTER_ADDRESS || "0x7a5b8bC49D4D17a1aDe87E4E3fCB86B1fFb3D545", process.env.WORLD_APP_ID);
  await airdrop.waitForDeployment(); const airdropAddr = await airdrop.getAddress(); console.log("Airdrop:", airdropAddr);
  await zea.transfer(airdropAddr, hre.ethers.parseUnits("500000000", 18));
  console.log("✅ 500M ZEA funded to Airdrop");
  // update frontend placeholder if exists
  const front = "../frontend/src/App.js";
  if (fs.existsSync(front)) {
    let c = fs.readFileSync(front, "utf8");
    c = c.replace(/REPLACE_WITH_AIRDROP_ADDRESS/g, airdropAddr);
    fs.writeFileSync(front, c);
    console.log("🔁 Frontend App.js updated");
  }
}
main().catch(e => { console.error(e); process.exitCode = 1; });
EOF

# hardhat config
cat > hardhat.config.js <<'EOF'
import { config as dotenvConfig } from "dotenv";
import "@nomicfoundation/hardhat-toolbox";
dotenvConfig();
const { RPC_URL, PRIVATE_KEY, ETHERSCAN_API_KEY } = process.env;
export default {
  solidity: { version: "0.8.20", settings: { optimizer: { enabled: true, runs: 200 } } },
  networks: {
    hardhat: {},
    worldchain: { url: RPC_URL, accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [] }
  },
  etherscan: { apiKey: ETHERSCAN_API_KEY || "" }
};
EOF

# compile with auto-heal loop for HH801
info "Compiling contracts (auto-heal loop)"
MAX_RETRIES=3; RET=0
while true; do
  set +e
  npx hardhat clean >/dev/null 2>&1 || true
  npx hardhat compile --show-stack-traces 2>&1 | tee /tmp/hh_compile_output.log
  RC=$?
  set -e
  if [ $RC -eq 0 ]; then info "Compiled successfully"; break; fi

  if grep -q "HH801" /tmp/hh_compile_output.log || grep -q "requires the following dependencies" /tmp/hh_compile_output.log; then
    warn "HH801 detected — running auto-heal (install recommended deps)"
    npm install --unsafe-perm --force --legacy-peer-deps --save-dev \
    @ethersproject/providers@^5.4.7 \
    @nomicfoundation/hardhat-network-helpers@^1.0.0 \
    @nomicfoundation/hardhat-chai-matchers@^1.0.0 \
    @nomicfoundation/hardhat-ethers@^3.1.0 \
    @nomicfoundation/hardhat-verify@^2.0.0 \
    @typechain/ethers-v5@^10.1.0 \
    @typechain/hardhat@^6.1.2 \
    hardhat-gas-reporter@^1.0.8 \
    solidity-coverage@^0.8.1 \
    ts-node@^10.9.1 \
    typechain@^8.3.0 \
    typescript@^5.3.3 \
    chai@^4.3.7 || warn "Auto-heal install returned non-zero"
    ((RET++))
    if [ $RET -ge $MAX_RETRIES ]; then err "Reached max auto-heal attempts"; exit 1; fi
    info "Retrying compile..."
    sleep 1
    continue
  else
    err "Compile failed for other reason — see /tmp/hh_compile_output.log"
    tail -n +1 /tmp/hh_compile_output.log
    exit 1
  fi
done

# deploy with simple RPC failover order
info "Deploying contracts (attempting RPC failover)"
DEPLOY_OK=false
for rpc in "${RPCS[@]}"; do
  info "Using RPC: $rpc"
  # update env
  sed -E "s#^RPC_URL=.*#RPC_URL=${rpc}#" .env > .env.tmp 2>/dev/null || cp .env .env.tmp
  mv .env.tmp .env
  export RPC_URL="$rpc"
  set +e
  npx hardhat run scripts/deploy.js --network worldchain 2>&1 | tee /tmp/hh_deploy.log
  RC_DEP=$?
  set -e
  if [ $RC_DEP -eq 0 ]; then DEPLOY_OK=true; break; else warn "Deploy failed on $rpc (RC $RC_DEP)"; fi
done

if ! $DEPLOY_OK; then err "Deploy failed on all RPCs — check logs: $LOG & /tmp/hh_deploy.log"; exit 1; fi

# try to parse airdrop address
AIRDROP_ADDR=$(grep -Eo "Airdrop: 0x[0-9a-fA-F]{40}" /tmp/hh_deploy.log | head -n1 | awk '{print $2}' || true)
if [ -z "$AIRDROP_ADDR" ]; then AIRDROP_ADDR=$(grep -Eo "✅ 500M ZEA funded to 0x[0-9a-fA-F]{40}" /tmp/hh_deploy.log | head -n1 | grep -Eo "0x[0-9a-fA-F]{40}" || true); fi
info "Airdrop address detected: ${AIRDROP_ADDR:-(none)}"

# verify if key provided
if [ -n "${ETHERSCAN_KEY:-}" ]; then
  info "Verifying contracts (etherscan/worldscan)"
  set +e
  npx hardhat verify --network worldchain "${AIRDROP_ADDR}" 2>&1 | tee /tmp/hh_verify.log || warn "Verify returned non-zero"
  set -e
fi

# frontend scaffold/update
info "Scaffolding frontend and updating contract address"
cd "$FRONT_PATH"
npm init -y >/dev/null 2>&1 || true
npm pkg set type="module" >/dev/null 2>&1 || true
npm install --legacy-peer-deps react react-dom parcel ethers @worldcoin/idkit --save >/dev/null 2>&1 || true

mkdir -p src
cat > src/index.html <<'HTML'
<!doctype html><html><head><meta charset="utf-8"><title>ZeaDev</title></head><body><div id="root"></div><script type="module" src="./App.js"></script></body></html>
HTML

cat > src/App.js <<'JS'
import React,{useState}from"react";import{createRoot}from"react-dom/client";import{ethers}from"ethers";import{IDKitWidget}from"@worldcoin/idkit";
const CONTRACT="REPLACE_WITH_AIRDROP_ADDRESS";
const ABI=["function claimAirdrop(address,uint256,uint256,uint256[8])"];
const APP_ID="YOUR_WORLD_APP_ID";const ACTION="zea-airdrop";
function App(){const[s,setS]=useState(null);const[a,setA]=useState("");const[st,setSt]=useState("");const[e,setE]=useState("");
async function connect(){try{const p=new ethers.BrowserProvider(window.ethereum);await p.send("eth_requestAccounts",[]);const sg=await p.getSigner();setS(sg);setA(await sg.getAddress());}catch(err){setE(String(err));}}
async function handleProof(r){try{setSt("Claiming...");const c=new ethers.Contract(CONTRACT,ABI,s);const root=r.merkle_root||r.root;const n=r.nullifier_hash||r.nullifierHash;const pf=r.proof||[];const tx=await c.claimAirdrop(a,root,n,pf);await tx.wait();setSt("✅ Claimed");}catch(err){setE(String(err));}}
return(<div style={{fontFamily:"Arial",padding:20}}><h2>ZeaDev Airdrop</h2>{!a? <button onClick={connect}>Connect Wallet</button>:<div>Connected: {a}</div>}<br/><IDKitWidget app_id={APP_ID} action={ACTION} onSuccess={handleProof} render={(p)=><button onClick={p.open}>Verify with World ID</button>} /><div>{st}</div>{e&&<div style={{color:"red"}}>{e}</div>}</div>);}
createRoot(document.getElementById("root")).render(<App/>);
JS

if [ -n "$AIRDROP_ADDR" ]; then
  sed -i "s|REPLACE_WITH_AIRDROP_ADDRESS|${AIRDROP_ADDR}|g" src/App.js || true
fi

# start frontend (background)
( npm run start --silent &>/dev/null || npx parcel src/index.html --port 3000 &>/dev/null ) &

info "✅ ZeaZDev v4.3 completed. Frontend available at ${FRONT_DOMAIN}"
echo -e "${BLUE}$DIV${RESET}"
echo -e "${GREEN}Logs: ${LOG}${RESET}"
echo -e "${BLUE}$DIV${RESET}"
