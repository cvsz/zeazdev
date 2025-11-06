#!/bin/bash
# ============================================================
# ZeaZDev Auto Repair Utility v9.3-R1
# Author: Meta-Intelligence Interface (MII)
# Purpose: Fix Frontend Build, Hardhat Job, and API Integration
# ============================================================

# ANSI color codes
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
BLUE='\033[1;34m'
CYAN='\033[38;5;79m'
BOLD='\033[1;32m'
RESET='\033[0m'

LOG_FILE="/opt/ZeaZDev/logs/zeazdev-repair-$(date +%Y%m%d-%H%M%S).log"
FRONT_DIR="/opt/ZeaZDev/Frontend"
WORLD_DIR="/opt/ZeaZDev/Project/worldchain"
ENV_FILE="/opt/ZeaZDev/.env"

# Check for root (privileged) user
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[ERROR]${RESET} This script must be run as root (use sudo)." >&2
  exit 1
fi

echo -e "${GREEN}[INFO]${RESET} ZeaZDev Repair Utility Started"
echo -e "${CYAN}[INIT] Logging to $LOG_FILE${RESET}"
mkdir -p "$(dirname "$LOG_FILE")"

# 1️⃣ FRONTEND REPAIR
echo -e "\n${BLUE}[1/4] Fixing Frontend Build (IDKit Issue)...${RESET}" | tee -a "$LOG_FILE"
cd "$FRONT_DIR"
if [ $? -ne 0 ]; then
  echo -e "${RED}[ERROR]${RESET} Failed to enter Frontend directory ($FRONT_DIR)." | tee -a "$LOG_FILE"
  echo -e "${RED}[FAIL]${RESET} ZeaZDev Repair aborted; unable to continue. See $LOG_FILE for details." | tee -a "$LOG_FILE"
  exit 1
fi
# Safety check: Ensure we're in $FRONT_DIR before using rm -rf
if [ "$(pwd)" != "$FRONT_DIR" ]; then
  echo -e "${RED}[ERROR]${RESET} Not in expected directory ($FRONT_DIR). Aborting rm -rf." | tee -a "$LOG_FILE"
  exit 2
fi
rm -rf node_modules package-lock.json
npm install @worldcoin/idkit@^1.3.6 --legacy-peer-deps >>"$LOG_FILE" 2>&1
npm install >>"$LOG_FILE" 2>&1
npm run build >>"$LOG_FILE" 2>&1
if [ $? -eq 0 ]; then
  echo -e "${GREEN}[OK]${RESET} Frontend rebuilt successfully."
else
  echo -e "${YELLOW}[WARN]${RESET} Frontend build failed again. Check $LOG_FILE"
fi

# 2️⃣ HARDHAT JOB REPAIR
echo -e "\n${BLUE}[2/4] Repairing Hardhat Worldchain Job...${RESET}" | tee -a "$LOG_FILE"
cd "$WORLD_DIR" || exit 1
npm ci >>"$LOG_FILE" 2>&1
npm install ethers@5.7.2 >>"$LOG_FILE" 2>&1
npx hardhat compile >>"$LOG_FILE" 2>&1
npx hardhat test >>"$LOG_FILE" 2>&1
if [ $? -eq 0 ]; then
  echo -e "${GREEN}[OK]${RESET} Hardhat compile & test successful."
else
  echo -e "${YELLOW}[WARN]${RESET} Hardhat job still has errors. Check $LOG_FILE"
fi

# 3️⃣ ETHERSCAN API FIX
echo -e "\n${BLUE}[3/4] Verifying Etherscan API Key...${RESET}" | tee -a "$LOG_FILE"
if grep -q "ETHERSCAN_API_KEY" "$ENV_FILE"; then
  echo -e "${GREEN}[INFO]${RESET} API Key found in .env"
else
  echo -e "${YELLOW}[WARN]${RESET} Missing ETHERSCAN_API_KEY in .env"
  echo "ETHERSCAN_API_KEY=your_valid_api_key" >>"$ENV_FILE"
  echo -e "${CYAN}[FIXED]${RESET} Placeholder key added. Replace it with a valid one."
fi

# 4️⃣ SYSTEM SERVICE RESTART
echo -e "\n${BLUE}[4/4] Restarting Services (Dashboard + Nginx)...${RESET}" | tee -a "$LOG_FILE"
systemctl daemon-reload
systemctl restart zeazdev-dashboard.service nginx
sleep 3

echo -e "${GREEN}[INFO]${RESET} Checking service statuses...\n"
systemctl is-active --quiet zeazdev-dashboard.service && echo -e "${GREEN}[OK]${RESET} Dashboard active" || echo -e "${RED}[FAIL]${RESET} Dashboard not running"
systemctl is-active --quiet nginx && echo -e "${GREEN}[OK]${RESET} Nginx active" || echo -e "${RED}[FAIL]${RESET} Nginx not running"

echo -e "\n${BOLD}[✅ COMPLETE]${RESET} ZeaZDev v9.3 Repair Routine finished."
echo -e "Log file saved at: $LOG_FILE"
