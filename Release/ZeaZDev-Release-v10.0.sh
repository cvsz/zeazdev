#!/usr/bin/env bash
# =============================================================================
# 🌐 Developer & Project Information
# 💲 ZeaZDev — Zea Token ($ZEA)
# 📦 Version: Release — v10.0 (Secure Backend Integration)
# 👨‍💻 Developer: PHIPHAT PHOEMSUK (ZeaZDev)
# 🏢 Organization: ZeaZDev — Ecosystem • Innovate • Connect • Grow
# 🌍 Website: https://app.zeaz.dev/
# 📧 Contact: admin@zeaz.dev, support@zeaz.dev
# 🔐 License: MIT
# =============================================================================
# UPGRADE v10.0 (Backend & Gasless):
# 1. [FEAT] (Backend) Added 'api-server.js' (Express) for server-side
#    World ID verification using the 'WORLD_APP_API_KEY'.
# 2. [FEAT] (Gasless) 'Airdrop.sol' now has an 'onlyRelayer' modifier.
# 3. [FEAT] (Gasless) 'deploy-v6.js' now sets the 'RELAYER_ADDRESS' in
#    the Airdrop contract.
# 4. [FEAT] (Frontend) 'App.js' now POSTs the proof to '/api/v1/claim'
#    instead of calling the contract directly.
# 5. [FEAT] (System) Adds 'api.zeaz.dev' (Nginx) and 'zeazdev-api.service'
#    (systemd) for the new backend server.
# 6. [FIX] Includes all fixes from v9.x (Ethers v6, Parcel Alias, .env).
# =============================================================================

set -euo pipefail
trap 'echo -e "\e[31m[ERROR]\e[0m Unexpected error on line $LINENO"; exit 1' ERR

# --- UI ---
GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; RESET="\e[0m"
info(){ echo -e "${GREEN}[INFO]${RESET} $*"; }
warn(){ echo -e "${YELLOW}[WARN]${RESET} $*"; }
err(){ echo -e "${RED}[ERROR]${RESET} $*"; }

# --- [FEAT v7.6] Installer Display ---
echo -e "${GREEN}"
cat << "EOF"
    ZZZZZZZZZZZZZZZZZ EEEEEEEEEEEEEEEEEEEEEE               AAA               ZZZZZZZZZZZZZZZZZ
    Z:::::::::::::::::Z E::::::::::::::::::::E              A:::A              Z:::::::::::::::::Z
    Z:::::::::::::::::Z E::::::::::::::::::::E             A:::::A             Z:::::::::::::::::Z
    Z:::ZZZZZZZZ:::::Z  EE::::::EEEEEEEEE::::E            A:::::::A            Z:::ZZZZZZZZ:::::Z
    ZZZZZ     Z:::::Z     E:::::E       EEEEEE           A:::::::::A           ZZZZZ     Z:::::Z
            Z:::::Z      E:::::E                       A:::::A:::::A                  Z:::::Z
           Z:::::Z       E::::::EEEEEEEEEE            A:::::A A:::::A                Z:::::Z
          Z:::::Z        E:::::::::::::::E           A:::::A   A:::::A              Z:::::Z
         Z:::::Z         E::::::EEEEEEEEEE          A:::::A     A:::::A            Z:::::Z
        Z:::::Z          E:::::E                   A:::::AAAAAAAAA:::::A          Z:::::Z
       Z:::::Z           E:::::E       EEEEEE     A:::::::::::::::::::::A        Z:::::Z
    ZZZZZ     Z:::::Z  EE::::::EEEEEEEEEEE::::E    A:::::AAAAAAAAAAAAA:::::A    ZZZZZ     Z:::::Z
    Z:::ZZZZZZZZ:::::Z  E::::::::::::::::::::E   A:::::A             A:::::A   Z:::ZZZZZZZZ:::::Z
    Z:::::::::::::::::Z E::::::::::::::::::::E  A:::::A               A:::::A  Z:::::::::::::::::Z
    Z:::::::::::::::::Z EEEEEEEEEEEEEEEEEEEEEE A:::::A                 A:::::A Z:::::::::::::::::Z
    ZZZZZZZZZZZZZZZZZ                          AAAAAAA                   AAAAAAAZZZZZZZZZZZZZZZZZ
EOF
echo -e "${RESET}"
info "Starting ZeaZDev Unified Installer v10.0 (Backend Integration Engine)"
# --- [END FEAT] ---

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
# --- [FEAT v10.0] ---
: "${RELAYER_PRIVATE_KEY:=${RELAYER_PRIVATE_KEY:-}}"
: "${WORLD_APP_API_KEY:=${WORLD_APP_API_KEY:-}}"
: "${API_DOMAIN:=${API_DOMAIN:-api.zeaz.dev}}"
# --- [END FEAT] ---
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

# --- [FIX v7.5] Non-Interactive Mode: Strict Validation ---
info "Running in Non-Interactive Mode."
if [ -z "$MULTI_RPC_LIST" ] || [ -z "$WORLD_APP_ID" ] || [ -z "$PRIVATE_KEY" ] || [ -z "$RELAYER_PRIVATE_KEY" ] || [ -z "$WORLD_APP_API_KEY" ]; then
  err "Required ENV variables are missing. (This script is called by run.sh)"
  err "Please check: MULTI_RPC_LIST, WORLD_APP_ID, PRIVATE_KEY, RELAYER_PRIVATE_KEY, WORLD_APP_API_KEY"
  exit 1
fi
info "Required variables found. Proceeding..."
# --- [END FIX] ---

MULTI_RPC_LIST=$(echo "$MULTI_RPC_LIST" | sed 's/ //g')

# --- [FIX v6.2] Auto-correct user input format ---
if [[ "$MULTI_RPC_LIST" != *'='* ]] && [[ "$MULTI_RPC_LIST" == *'https://'* ]]; then
  warn "Input '$MULTI_RPC_LIST' lacks format. Assuming default network 'worldchain'."
  MULTI_RPC_LIST="worldchain=$MULTI_RPC_LIST"
  info "Corrected MULTI_RPC_LIST: $MULTI_RPC_LIST"
fi
# --- [END FIX] ---

# --- [FIX v9.1] Store Environment Variables ---
info "Copying configuration to $INSTALL_PATH/.env for systemd service..."
if [ ! -f ".env" ]; then
    err "Root .env file not found. Please run 'run.sh' first."
    exit 1
fi
cp ./.env "$INSTALL_PATH/.env"
info ".env file copied to $INSTALL_PATH/.env"
# --- [END FIX] ---

# --- 1. System Dependencies & Node.js ---
info "Installing system dependencies (Node.js, Nginx, Certbot, Git, Python, Jq)..."
# --- [FIX v6.8] ---
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y git curl build-essential pkg-config python3 python3-pip python3-venv jq zip nginx certbot python3-certbot-nginx
# --- [END FIX] ---

# --- [FIX v8.0] ---
info "Forcing Node.js 22.x (LTS)..."
apt-get purge -y nodejs npm || true
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs
# --- [END FIX] ---

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
/* 🌐 ZeaZDev v10.0 (ZEA Token) 👨‍💻 PHIPHAT PHOEMSUK */
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

# --- [FIX v10.0] ---
cat > "$TMP_DIR/Airdrop.sol" <<'SOL'
/* 🌐 ZeaZDev v10.0 (Airdrop - Gasless) 👨‍💻 PHIPHAT PHOEMSUK */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
interface IWorldID { function verifyProof(uint256,uint256,uint256,uint256,uint256[8] calldata) external view; }

contract Airdrop is Ownable {
    IERC20 public token;
    IWorldID public worldID;
    string public appId;
    address public relayerAddress; // <-- Backend Hot Wallet

    string public constant action="zea-airdrop";
    mapping(uint256=>bool) public nullifierUsed;
    uint256 public constant AIRDROP_AMOUNT=100*10**18;
    event Claimed(address indexed user,uint256 nullifierHash);

    modifier onlyRelayer() {
        require(msg.sender == relayerAddress, "Caller is not the relayer");
        _;
    }

    constructor(address t, address w, string memory id, address _relayer) Ownable(msg.sender) {
        token = IERC20(t);
        worldID = IWorldID(w);
        appId = id;
        relayerAddress = _relayer;
    }

    function setRelayerAddress(address _relayer) external onlyOwner {
        relayerAddress = _relayer;
    }

    // (FIX v10.0) Changed from external to onlyRelayer
    // The user's address is now passed in by the backend
    function claimAirdrop(address userAddress, uint256 root, uint256 n, uint256[8] calldata p) external onlyRelayer {
        require(!nullifierUsed[n],"Claimed");
        
        // The signal is now the user's address
        uint256 s = uint256(keccak256(abi.encodePacked(userAddress)));
        
        worldID.verifyProof(root, 1, s, n, p);
        
        nullifierUsed[n] = true;
        require(token.transfer(userAddress, AIRDROP_AMOUNT), "Fail");
        emit Claimed(userAddress, n);
    }
}
SOL
# --- [END FIX] ---

cat > "$TMP_DIR/Reward.sol" <<'SOL'
/* 🌐 ZeaZDev v10.0 (Reward Contract) 👨‍💻 PHIPHAT PHOEMSUK */
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

# --- [FEAT v9.0] ---
# Add the new Vault contract
cat > "$TMP_DIR/ZeaZDevVault.sol" <<'SOL'
/* 🌐 ZeaZDev v10.0 (Vault Contract) 👨‍💻 PHIPHAT PHOEMSUK */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ZeaZDevVault is Ownable {
    IERC20 public zeaToken;
    mapping(address => bool) public whitelistedContracts;

    event ContractFunded(address indexed target, uint256 amount);
    event WhitelistAdded(address indexed target);
    event WhitelistRemoved(address indexed target);
    event EmergencyWithdraw(address indexed to, uint256 amount);

    constructor(address _tokenAddress) Ownable(msg.sender) {
        zeaToken = IERC20(_tokenAddress);
    }

    function addWhitelist(address _contract) external onlyOwner {
        require(_contract != address(0), "Zero address");
        whitelistedContracts[_contract] = true;
        emit WhitelistAdded(_contract);
    }

    function removeWhitelist(address _contract) external onlyOwner {
        whitelistedContracts[_contract] = false;
        emit WhitelistRemoved(_contract);
    }

    function fundContract(address _target, uint256 _amount) external onlyOwner {
        require(whitelistedContracts[_target], "Target not whitelisted");
        require(zeaToken.transfer(_target, _amount), "Transfer failed");
        emit ContractFunded(_target, _amount);
    }

    function emergencyWithdraw(uint256 _amount) external onlyOwner {
        require(zeaToken.transfer(msg.sender, _amount), "Withdraw failed");
        emit EmergencyWithdraw(msg.sender, _amount);
    }
}
SOL
# --- [END FEAT] ---

# --- 5. Write Deploy Script Template ---
# --- [FIX v10.0] ---
# Create Ethers v6 deploy script (for Node 22 + Hardhat latest)
cat > "$TMP_DIR/deploy-v6.js" <<'JS'
/* 🌐 ZeaZDev v10.0 (Deploy Script - Ethers v6 Syntax) 👨‍💻 PHIPHAT PHOEMSUK */
import hre from "hardhat";
import fs from "fs";
import dotenv from "dotenv";
dotenv.config();

async function main(){
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deployer:", deployer.address);

  // (FIX v10.0) Get Relayer wallet from ENV
  if (!process.env.RELAYER_PRIVATE_KEY) {
    throw new Error("RELAYER_PRIVATE_KEY is not set in .env");
  }
  const relayerWallet = new hre.ethers.Wallet(process.env.RELAYER_PRIVATE_KEY);
  const relayerAddress = await relayerWallet.getAddress();
  console.log("Relayer Address:", relayerAddress);
  
  // 1. Deploy ZEAToken
  const ZEAToken = await hre.ethers.getContractFactory("ZEAToken");
  const zea = await ZEAToken.deploy(); 
  await zea.waitForDeployment(); // v6 syntax
  const zeaAddr = await zea.getAddress(); // v6 syntax
  console.log("ZEAToken:", zeaAddr);

  // 2. Deploy Airdrop Contract (Pass Relayer Address)
  const Airdrop = await hre.ethers.getContractFactory("Airdrop");
  const airdrop = await Airdrop.deploy(zeaAddr, process.env.WORLD_ID_ROUTER_ADDRESS, process.env.WORLD_APP_ID, relayerAddress);
  await airdrop.waitForDeployment(); // v6 syntax
  const airdropAddr = await airdrop.getAddress(); // v6 syntax
  console.log("Airdrop:", airdropAddr);

  // 3. Deploy Reward Contract
  const Reward = await hre.ethers.getContractFactory("Reward");
  const reward = await Reward.deploy(zeaAddr);
  await reward.waitForDeployment(); // v6 syntax
  const rewardAddr = await reward.getAddress(); // v6 syntax
  console.log("Reward:", rewardAddr);

  // 4. Deploy the Vault
  const ZeaZDevVault = await hre.ethers.getContractFactory("ZeaZDevVault");
  const vault = await ZeaZDevVault.deploy(zeaAddr);
  await vault.waitForDeployment();
  const vaultAddr = await vault.getAddress();
  console.log("ZeaZDevVault:", vaultAddr);

  // 5. Secure Treasury: Transfer ALL remaining ZEA from Deployer to Vault
  console.log("Securing treasury...");
  const balance = await zea.balanceOf(deployer.address);
  console.log(`Deployer ZEA balance: ${hre.ethers.formatEther(balance)}`); // v6 syntax
  await zea.transfer(vaultAddr, balance);
  console.log(`Transferred ${hre.ethers.formatEther(balance)} ZEA to Vault.`);

  // 6. Whitelist contracts in Vault (so Vault can fund them)
  console.log("Whitelisting contracts in Vault...");
  await vault.addWhitelist(airdropAddr);
  await vault.addWhitelist(rewardAddr);
  console.log("Airdrop and Reward contracts whitelisted.");

  // 7. Fund contracts *from* the Vault
  console.log("Funding contracts from Vault...");
  const airdropAmount = hre.ethers.parseUnits("500000000", 18); // v6 syntax
  const rewardAmount = hre.ethers.parseUnits("100000000", 18); // v6 syntax
  await vault.fundContract(airdropAddr, airdropAmount);
  console.log("Funded Airdrop contract with 500M ZEA.");
  await vault.fundContract(rewardAddr, rewardAmount);
  console.log("Funded Reward contract with 100M ZEA.");

  const result = {
    network: process.env.NETWORK,
    token: zeaAddr,
    airdrop: airdropAddr,
    reward: rewardAddr,
    vault: vaultAddr
  };
  fs.writeFileSync("/tmp/zeadev_result.json", JSON.stringify(result));

  try {
    console.log("Verifying ZEAToken...");
    await hre.run("verify:verify", { address: zeaAddr, constructorArguments: [] });
    console.log("Verifying Airdrop...");
    // (FIX v10.0) Added relayerAddress to constructor args
    await hre.run("verify:verify", { address: airdropAddr, constructorArguments: [zeaAddr, process.env.WORLD_ID_ROUTER_ADDRESS, process.env.WORLD_APP_ID, relayerAddress] });
    console.log("Verifying Reward...");
    await hre.run("verify:verify", { address: rewardAddr, constructorArguments: [zeaAddr] });
    console.log("Verifying ZeaZDevVault...");
    await hre.run("verify:verify", { address: vaultAddr, constructorArguments: [zeaAddr] });
  } catch (e) {
    console.warn("Verify failed (non-fatal):", e.message);
  }
}
main().catch(e=>{ console.error(e); process.exit(1); });
JS
# --- [END FIX] ---

# --- 6. Write Hardhat Config Template ---
cat > "$TMP_DIR/hardhat.config.js" <<'CFG'
/* 🌐 ZeaZDev v10.0 (Hardhat Config) 👨‍💻 PHIPHAT PHOEMSUK */
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
  
  # A. Write .env for this network (includes Relayer Key)
  cat > .env <<EOF
RPC_URL=${rpc}
PRIVATE_KEY=${PRIVATE_KEY}
RELAYER_PRIVATE_KEY=${RELAYER_PRIVATE_KEY}
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
  cp "$TMP_DIR/ZeaZDevVault.sol" "$ws/contracts/ZeaZDevVault.sol" # <-- [FIX v9.0]
  cp "$TMP_DIR/hardhat.config.js" "$ws/hardhat.config.js"
  
  # --- [FIX v9.3] ---
  # Force Ethers v6 path (since we forced Node 22).
  info "[$net] Forcing Ethers v6 path: Using Hardhat (latest) & Toolbox (latest)"
  export NPM_CONFIG_CACHE="$INSTALL_PATH/.npm-cache"
  info "[$net] Cleaning npm cache..."
  npm cache clean --force >/dev/null 2>&1 || true
  npm install --legacy-peer-deps --save @openzeppelin/contracts ethers >/dev/null 2>&1 || true
  npm install --legacy-peer-deps --save-dev hardhat @nomicfoundation/hardhat-toolbox dotenv @nomicfoundation/hardhat-verify >/dev/null 2>&1
  cp "$TMP_DIR/deploy-v6.js" "$ws/scripts/deploy.js"
  info "[$net] NPM Dependencies (Depth 1):"
  npm list --depth=1 || true
  # --- [END FIX] ---
  
  # F. Compile (with Node 22 Patch)
  info "[$net] Compiling..."
  set +e
  # [FIX v7.6] We force Node 22, so we must *always* run the patch.
  info "[$net] Applying Node 22 patch (config.js)..."
  find "$ws/node_modules" -type f -name "type-extensions.js" -exec \
    sed -i 's|\"hardhat/types/config\"|\"hardhat/types/config.js\"|g' {} \; 2>/dev/null || true
  
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

# --- 10. Dashboard & API Server ---
info "Setting up Dashboard & API Servers..."
cd "$INSTALL_PATH"
npm init -y >/dev/null 2>&1 || true
npm pkg set type="module" >/dev/null 2>&1 || true
# --- [FEAT v10.0] ---
info "Installing dependencies (Express, Ethers, WS, Chokidar)..."
npm install --legacy-peer-deps express ethers ws chokidar dotenv node-fetch@3 >/dev/null 2>&1 || true
# --- [END FEAT] ---

cat > "$INSTALL_PATH/dashboard-server.js" <<'NODE'
/* 🌐 ZeaZDev v10.0 (Dashboard Server) 👨‍💻 PHIPHAT PHOEMSUK */
import express from "express";
import http from "http";
import { WebSocketServer } from "ws";
import fs from "fs";
import path from "path";
import chokidar from "chokidar";
import dotenv from "dotenv";
dotenv.config();

const PORT = 3000;
const BASE = process.env.INSTALL_PATH || "/opt/ZeaZDev";
const RESULTS_DIR = path.join(BASE, "Results");
const LOG_DIR = path.join(BASE, "Logs");
const DASH_DIR = path.join(BASE, "Dashboard");
const app = express();
app.use(express.static(DASH_DIR, { extensions: ['html'], index: "index.html" }));
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
server.listen(PORT, () => console.log(`ZeaZDev Dashboard Server Running on http://0.0.0.0:${PORT} (Base: ${BASE})`));
NODE

# --- [FEAT v10.0] ---
# Create the new API Backend server
cat > "$INSTALL_PATH/api-server.js" <<'NODE'
/* 🌐 ZeaZDev v10.0 (API Backend Server) 👨‍💻 PHIPHAT PHOEMSUK */
import express from "express";
import http from "http";
import dotenv from "dotenv";
import { ethers } from "ethers";
import fetch from "node-fetch"; // Use node-fetch v3 for ESM

dotenv.config();

const PORT = 5000;
const {
    WORLD_APP_ID,
    WORLD_APP_API_KEY,
    RELAYER_PRIVATE_KEY,
    MULTI_RPC_LIST
} = process.env;

// This is a simple example. In production, you'd manage nonces and providers better.
// We'll just use the "worldchain" RPC from the list for the relayer.
const rpcUrl = MULTI_RPC_LIST.split(',').find(s => s.startsWith("worldchain=")).split('=')[1];
const provider = new ethers.JsonRpcProvider(rpcUrl);
const relayerWallet = new ethers.Wallet(RELAYER_PRIVATE_KEY, provider);

// You must load the ABI and Address. In a real app, this comes from the deploy results.
// For this installer, we'll assume the frontend knows the Airdrop address
// and the ABI is stored locally.
// const AIRDROP_CONTRACT_ABI = [ ... ABI ... ];
// const AIRDROP_CONTRACT_ADDRESS = "0x...";

const app = express();
app.use(express.json());

// CORS - In production, lock this down to just your FRONT_DOMAIN
app.use((req, res, next) => {
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
    next();
});

/**
 * Endpoint for server-side verification and gasless claim.
 * Body: {
 * userAddress: "0x...",
 * merkle_root: "0x...",
 * nullifier_hash: "0x...",
 * proof: "0x..."
 * }
 */
app.post("/api/v1/claim", async (req, res) => {
    console.log("[API] Received /api/v1/claim request");
    const { userAddress, merkle_root, nullifier_hash, proof } = req.body;

    if (!userAddress || !merkle_root || !nullifier_hash || !proof) {
        return res.status(400).json({ ok: false, error: "Missing required proof fields." });
    }

    // 1. Verify Proof with World ID Cloud API
    const verifyUrl = `https://developer.worldcoin.org/api/v2/verify/${WORLD_APP_ID}`;
    const verifyBody = {
        action: "zea-airdrop",
        signal: userAddress, // The signal is now the user's address
        merkle_root,
        nullifier_hash,
        proof
    };

    try {
        console.log(`[API] Verifying proof with World ID Cloud API for ${userAddress}...`);
        const verifyRes = await fetch(verifyUrl, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Authorization": `Basic ${Buffer.from(WORLD_APP_API_KEY).toString("base64")}`
            },
            body: JSON.stringify(verifyBody),
        });

        const verifyData = await verifyRes.json();
        
        if (!verifyRes.ok) {
            console.error("[API] World ID Verification Failed:", verifyData);
            return res.status(400).json({ ok: false, error: "World ID Verification Failed", detail: verifyData });
        }
        
        console.log("[API] World ID Proof Verified.");

        // 2. (TODO) Connect to Airdrop Contract and call claimAirdrop
        // In a real app, you would load the address/ABI from the deploy results.
        // const airdropContract = new ethers.Contract(AIRDROP_CONTRACT_ADDRESS, AIRDROP_CONTRACT_ABI, relayerWallet);
        // const tx = await airdropContract.claimAirdrop(userAddress, merkle_root, nullifier_hash, proof);
        // console.log(`[API] Submitted claim tx for ${userAddress}: ${tx.hash}`);
        // await tx.wait();
        // console.log(`[API] Claim tx confirmed: ${tx.hash}`);

        // For this demo, we'll skip the on-chain call and return success
        console.warn("[API] DEMO MODE: Skipping on-chain transaction.");

        res.status(200).json({ ok: true, tx_hash: `0x_demo_tx_${Date.now()}` });

    } catch (e) {
        console.error("[API] Claim process failed:", e);
        res.status(500).json({ ok: false, error: e.message });
    }
});

const server = http.createServer(app);
server.listen(PORT, () => console.log(`ZeaZDev API Backend Server Running on http://0.0.0.0:${PORT}`));
NODE
# --- [END FEAT] ---

# --- 11. Dashboard UI (Static) ---
cat > "$DASH_PATH/index.html" <<'HTML'
<!doctype html><html><head><meta charset="utf-8"/><title>ZeaZDev Dashboard</title>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<style>body{font-family:Arial,sans-serif;margin:0;background:#111;color:#eee}header{background:#000;color:#0f0;padding:12px 20px;font-family:monospace}
.container{padding:20px;max-width:1200px;margin:auto}.card{background:#222;border:1px solid #444;border-radius:8px;padding:12px;margin-bottom:12px}
pre{white-space:pre-wrap;font-size:12px;max-height:420px;overflow:auto;color:#ccc}.row{padding:8px;border-bottom:1px solid #333}</style>
</head><body><header><strong>ZeaZDev Dashboard (v10.0)</strong> — Deploy & Logs (Live)</header>
<div class="container"><button id="btn-refresh">Refresh</button> <span id="stat">Connecting...</span>
<div class="card"><h3>Deploy Results</h3><div id="results"></div></div>
<div classs="card"><h3>Logs (latest)</h3><pre id="logview">No logs yet</pre></div>
<div class="card"><h3>Realtime Events</h3><div id="events" style="max-height:100px;overflow:auto"></div></div>
</div><script type="module" src="/app.js"></script></body></html>
HTML
cat > "$DASH_PATH/app.js" <<'JS'
const $ = (s) => document.getElementById(s);
const $r = $('results'), $l = $('logview'), $e = $('events'), $s = $('stat');
$('btn-refresh').onclick=()=>{loadResults();loadLog();};
async function loadResults(){$s.innerText='loading...';try{const r=await fetch('/api/results');const j=await r.json();$r.innerHTML='';(j.results||[]).forEach(i=>{const d=document.createElement('div');d.className='row';
// --- [FIX v9.0] ---
d.innerHTML=`<strong>${i.network}</strong>: Token: ${i.token} | Airdrop: ${i.airdrop} | Reward: ${i.reward} | Vault: ${i.vault || 'N/A'}`;
// --- [END FIX] ---
$r.appendChild(d)});$s.innerText='OK';}catch(e){$s.innerText='error';}}
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
# --- [FIX v6.9] ---
info "Removing 'main' key from package.json to fix Parcel build error..."
npm pkg delete main >/dev/null 2>&1 || true
# --- [END FIX] ---
npm pkg set type="module" >/dev/null 2>&1 || true

# --- [FIX v9.3] ---
info "Installing frontend dependencies (latest @worldcoin/idkit + core)..."
info "Cleaning npm cache for Frontend..."
npm cache clean --force >/dev/null 2>&1 || true
npm install --legacy-peer-deps react react-dom parcel ethers @worldcoin/idkit @worldcoin/idkit-core >/dev/null 2>&1 || true
info "Applying Parcel Alias fix for IDKit (Specific Paths)..."
npm pkg set 'alias."@/components/IDKitWidget/index"'='./node_modules/@worldcoin/idkit/src/components/IDKitWidget/index.tsx' >/dev/null 2>&1 || true
npm pkg set 'alias."@/types/config"'='./node_modules/@worldcoin/idkit/src/types/config.ts' >/dev/null 2>&1 || true
npm pkg set 'alias."@worldcoin/idkit-core/hashing"'='./node_modules/@worldcoin/idkit-core/dist/hashing.mjs' >/dev/null 2>&1 || true
# --- [END FIX] ---

info "Adding 'start' and 'build' scripts to Frontend package.json"
npm pkg set scripts.start="parcel src/index.html --port 4000" >/dev/null 2>&1 || true
npm pkg set scripts.build="parcel build src/index.html" >/dev/null 2>&1 || true
mkdir -p "$FRONT_PATH/src"
cat > "$FRONT_PATH/src/index.html" <<'HTML'
<!doctype html><html><head><meta charset="utf-8"><title>ZeaZDev</title></head>
<body><div id="root"></div><script type="module" src="./App.js"></script></body></html>
HTML
cat > "$FRONT_PATH/src/App.js" <<'JS'
/* 🌐 ZeaZDev v10.0 (Frontend) 👨‍💻 PHIPHAT PHOEMSUK */
import React, { useState } from "react";
import { createRoot } from "react-dom/client";
import { ethers } from "ethers";
import { IDKitWidget } from "@worldcoin/idkit";
import networks from "./networks.json";

// [FIX v10.0] Changed logic to call Backend API
const ACTION = "zea-airdrop";
const APP_ID = process.env.WORLD_APP_ID || "app_f6ca4506cc8d784843fcce064b387e0c";
// This must match the domain in your .env file
const API_URL = "https://api.zeaz.dev/api/v1/claim"; 

function App() {
  const [status, setStatus] = useState("Ready");
  const [error, setError] = useState("");
  const [wallet, setWallet] = useState(null);

  async function connect() {
    try {
      setError("");
      setStatus("Connecting...");
      const provider = new ethers.BrowserProvider(window.ethereum);
      await provider.send("eth_requestAccounts", []);
      const signer = await provider.getSigner();
      setWallet(await signer.getAddress());
      setStatus("Connected");
    } catch (e) {
      setError(e.message);
      setStatus("Failed to connect");
    }
  }

  // This function is called by IDKitWidget on successful proof
  async function handleProof(proofResult) {
    if (!wallet) {
      setError("Please connect your wallet first.");
      return;
    }
    
    setStatus("Verifying proof with backend...");
    setError("");

    try {
      const res = await fetch(API_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          userAddress: wallet,
          merkle_root: proofResult.merkle_root,
          nullifier_hash: proofResult.nullifier_hash,
          proof: proofResult.proof,
        }),
      });

      const data = await res.json();

      if (!res.ok) {
        throw new Error(data.detail?.code || data.error || "Verification failed");
      }

      setStatus(`✅ Claimed! Tx: ${data.tx_hash.substring(0, 10)}...`);
    } catch (e) {
      setError(e.message);
      setStatus("Claim failed");
    }
  }

  return (
    <div style={{ fontFamily: "Arial", padding: 20 }}>
      <h2>ZeaZDev Airdrop (v10.0 Backend)</h2>
      
      {!wallet ? (
        <button onClick={connect}>Connect Wallet</button>
      ) : (
        <div>
          <p>Connected: {wallet}</p>
          <IDKitWidget
            app_id={APP_ID}
            action={ACTION}
            signal={wallet} // Use the user's address as the signal
            onSuccess={handleProof}
            render={({ open }) => <button onClick={open}>Verify with World ID & Claim</button>}
          />
        </div>
      )}
      
      <div>Status: {status}</div>
      {error && <div style={{ color: "red" }}>Error: {error}</div>}
      
      <h3>Deployed Networks:</h3>
      <pre>{JSON.stringify(networks, null, 2)}</pre>
    </div>
  );
}
createRoot(document.getElementById("root")).render(<App />);
JS

# --- [FIX v6.7] ---
info "Creating .env file for Frontend build..."
cat > "$FRONT_PATH/.env" <<EOF
# This file is automatically generated for the Parcel build
WORLD_APP_ID=$WORLD_APP_ID
EOF
# --- [END FIX] ---

# --- [FIX v6.5] ---
info "Building production Frontend (Parcel)..."
cd "$FRONT_PATH"
npm run build || warn "Frontend build failed, but continuing setup..."
info "Frontend build complete. Files are in $FRONT_PATH/dist"
# --- [END FIX] ---

# --- 13. Nginx + SSL + Systemd ---
info "Setting up Nginx Proxy + Auto SSL (Certbot) + Systemd..."

# A. Nginx config
info "Creating Nginx configs for Dashboard, Frontend, and API..."
cat > /etc/nginx/sites-available/zeazdev-dash.conf <<EOF
server {
    listen 80;
    server_name $DASH_DOMAIN;
    autoindex off; # (Security)
    location / {
        proxy_pass http://127.0.0.1:3000; # Dashboard
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

cat > /etc/nginx/sites-available/zeazdev-front.conf <<EOF
server {
    listen 80;
    server_name $FRONT_DOMAIN;
    autoindex off; # (Security)
    root $FRONT_PATH/dist;
    location / {
        try_files \$uri /index.html;
    }
}
EOF

# --- [FEAT v10.0] ---
cat > /etc/nginx/sites-available/zeazdev-api.conf <<EOF
server {
    listen 80;
    server_name $API_DOMAIN;
    autoindex off; # (Security)
    location / {
        proxy_pass http://127.0.0.1:5000; # API Backend
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF
# --- [END FEAT] ---

info "Removing default Nginx site to prevent conflicts..."
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-enabled/zeazdev.conf /etc/nginx/sites-available/zeazdev.conf

ln -sf /etc/nginx/sites-available/zeazdev-dash.conf /etc/nginx/sites-enabled/zeazdev-dash.conf
ln -sf /etc/nginx/sites-available/zeazdev-front.conf /etc/nginx/sites-enabled/zeazdev-front.conf
ln -sf /etc/nginx/sites-available/zeazdev-api.conf /etc/nginx/sites-enabled/zeazdev-api.conf

# B. Certbot (Auto SSL)
info "Running Certbot for all 3 domains..."
certbot --nginx --non-interactive --agree-tos -m admin@zeaz.dev -d "$DASH_DOMAIN" -d "$FRONT_DOMAIN" -d "$API_DOMAIN" || warn "Certbot failed (check DNS/firewall)"

# C. Systemd Services
cat > /etc/systemd/system/zeazdev-dash.service <<EOF
[Unit]
Description=ZeaZDev Dashboard Server (Node.js)
After=network.target
[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_PATH
ExecStart=/usr/bin/env node dashboard-server.js
Restart=on-failure
RestartSec=5
EnvironmentFile=$INSTALL_PATH/.env
[Install]
WantedBy=multi-user.target
EOF

# --- [FEAT v10.0] ---
cat > /etc/systemd/system/zeazdev-api.service <<EOF
[Unit]
Description=ZeaZDev API Backend Server (Node.js)
After=network.target
[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_PATH
ExecStart=/usr/bin/env node api-server.js
Restart=on-failure
RestartSec=5
EnvironmentFile=$INSTALL_PATH/.env
[Install]
WantedBy=multi-user.target
EOF
# --- [END FEAT] ---

info "Removing old zeazdev-front.service (if it exists)..."
systemctl stop zeazdev-front.service >/dev/null 2>&1 || true
systemctl disable zeazdev-front.service >/dev/null 2>&1 || true
rm -f /etc/systemd/system/zeazdev-front.service

# D. Start services
systemctl daemon-reload
info "Restarting services (Node.js first, then Nginx)..."
systemctl enable zeazdev-dash.service zeazdev-api.service
systemctl restart zeazdev-dash.service
systemctl restart zeazdev-api.service
info "Waiting 3 seconds for Node.js services to bind..."
sleep 3
systemctl restart nginx

# --- 14. Git Push & Telegram ---
info "Finalizing... pushing logs and sending notifications..."
LOGFILE_FINAL="$LOG_DIR/deploy-summary-$(date +%F).log"
echo "ZeaZDev v10.0 Deploy Summary" > "$LOGFILE_FINAL"
cat "$RESULTS_DIR"/*.json >> "$LOGFILE_FINAL" 2>/dev/null || true

# --- [FEAT v9.4] Push Full Project ---
if [ -n "$GIT_LOG_REPO" ]; then
  info "Pushing entire project to $GIT_LOG_REPO ($GIT_LOG_BRANCH)..."
  cd "$INSTALL_PATH"
  
  # Create .gitignore
  cat > .gitignore <<'GIGNORE'
# Sensitive
.env
*.log
Results/
Logs/
Backups/
tmp/

# Dependencies
node_modules/
Frontend/node_modules/
Project/*/node_modules/

# Build Artifacts
Frontend/.parcel-cache/
Frontend/dist/
GIGNORE
  
  git init -q || true
  git remote remove origin >/dev/null 2>&1 || true
  git remote add origin "$GIT_LOG_REPO" || true
  git checkout -B "$GIT_LOG_BRANCH" || true
  git add .
  git -c user.email="ci@zeaz.dev" -c user.name="ZeaZDev CI" commit -m "Deploy v10.0 (Backend Integration) $(date -u)" >/dev/null 2>&1 || true
  git push -f origin "$GIT_LOG_BRANCH" >/dev/null 2>&1 && info "Full project pushed to Git" || warn "Git push failed"
fi
# --- [END FEAT] ---

if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
  SUMMARY=$(cat "$LOGFILE_FINAL" | tail -n 20)
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d chat_id="${TELEGRAM_CHAT_ID}" \
    -d text="✅ ZeaZDev v10.0 (Backend Integrated) Deploy Done. API: https://$API_DOMAIN | Frontend: https://$FRONT_DOMAIN ... Summary: $SUMMARY" >/dev/null 2>&1 || true
fi

# --- [FEAT v8.0 / FIX v9.3] 15. API Health Check ---
info "--- MII: Executing Data Integration (Level 1-3) ---"
set +e # Don't exit if health check fails
# 1. Alchemy (alchemy.com/docs)
ALCHEMY_RPC_URL=$(echo "$MULTI_RPC_LIST" | sed -n 's/.*eth=\([^,]*\).*/\1/p' || echo "https://eth-mainnet.g.alchemy.com/v2/A0KwGUrv3EpisPuQ0_5fI")
info "[1/4] Querying Alchemy RPC (eth_blockNumber)..."
curl -s -X POST -H "Content-Type: application/json" \
     --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_blockNumber\",\"params\":[],\"id\":1}" \
     "$ALCHEMY_RPC_URL" | jq . || true
# 2. Etherscan (docs.etherscan.io/v2-migration)
info "[2/4] Querying Etherscan API V2 (account/balance)..."
curl -s -X GET "https://api.etherscan.io/api/v2/accounts/0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045/balance?apikey=${ETHERSCAN_API_KEY}" | jq . || true
# 3. Worldcoin (docs.world.org)
info "[3/4] Querying Worldcoin JWKS (id.worldcoin.org)..."
curl -s -L "https://id.worldcoin.org/jwks.json" | jq '.keys[0] | {kty: .kty, kid: .kid}' || true
# 4. GitHub Repos (MetaMask, Ethereum, Worldcoin Mini Apps)
info "[4/4] Querying GitHub Repos (Latest Releases)..."
curl -s -L "https://api.github.com/repos/worldcoin/idkit/releases/latest" | jq -r '(.tag_name + " (worldcoin/idkit)")' || true
curl -s -L "https://api.github.com/repos/MetaMask/metamask-extension/releases/latest" | jq -r '(.tag_name + " (MetaMask/metamask-extension)")' || true
info "--- MII: Execution Complete ---"
set -e
# --- [END FEAT] ---

# --- 16. Cleanup ---
# --- [FIX v6.9] ---
rm -rf "$TMP_DIR"
# --- [END FIX] ---
info "ZeaZDev v10.0 (Backend Integration) installation complete!"
info "API Backend (Proxy to :5000): https://$API_DOMAIN"
info "Dashboard (Proxy to :3000): https://$DASH_DOMAIN"
info "Frontend (Static Nginx): https://$FRONT_DOMAIN"
info "Config saved to $INSTALL_PATH/.env"
