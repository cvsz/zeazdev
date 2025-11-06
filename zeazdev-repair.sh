#!/bin/bash
# ============================================================
# ZeaZDev Auto Repair Utility v9.3-R1
# Author: Meta-Intelligence Interface (MII)
# Purpose: Fix Frontend Build, Hardhat Job, and API Integration
# ============================================================

LOG_FILE="/opt/ZeaZDev/logs/zeazdev-repair-$(date +%Y%m%d-%H%M%S).log"
FRONT_DIR="/opt/ZeaZDev/Frontend"
WORLD_DIR="/opt/ZeaZDev/Project/worldchain"
ENV_FILE="/opt/ZeaZDev/.env"

echo -e "\033[32m[INFO]\033[0m ZeaZDev Repair Utility Started"
echo -e "\033[38;5;79m[INIT] Logging to $LOG_FILE\033[0m"
mkdir -p "$(dirname "$LOG_FILE")"

# 1️⃣ FRONTEND REPAIR
echo -e "\n\033[1;34m[1/4] Fixing Frontend Build (IDKit Issue)...\033[0m" | tee -a "$LOG_FILE"
cd "$FRONT_DIR" || exit 1
rm -rf node_modules package-lock.json
npm install @worldcoin/idkit@^1.3.6 --legacy-peer-deps >>"$LOG_FILE" 2>&1
npm install >>"$LOG_FILE" 2>&1
npm run build >>"$LOG_FILE" 2>&1
if [ $? -eq 0 ]; then
  echo -e "\033[32m[OK]\033[0m Frontend rebuilt successfully."
else
  echo -e "\033[33m[WARN]\033[0m Frontend build failed again. Check $LOG_FILE"
fi

# 2️⃣ HARHDAT JOB REPAIR
echo -e "\n\033[1;34m[2/4] Repairing Hardhat Worldchain Job...\033[0m" | tee -a "$LOG_FILE"
cd "$WORLD_DIR" || exit 1
npm ci >>"$LOG_FILE" 2>&1
npm install ethers@5.7.2 >>"$LOG_FILE" 2>&1
npx hardhat compile >>"$LOG_FILE" 2>&1
npx hardhat test >>"$LOG_FILE" 2>&1
if [ $? -eq 0 ]; then
  echo -e "\033[32m[OK]\033[0m Hardhat compile & test successful."
else
  echo -e "\033[33m[WARN]\033[0m Hardhat job still has errors. Check $LOG_FILE"
fi

# 3️⃣ ETHERSCAN API FIX
echo -e "\n\033[1;34m[3/4] Verifying Etherscan API Key...\033[0m" | tee -a "$LOG_FILE"
if grep -q "ETHERSCAN_API_KEY" "$ENV_FILE"; then
  echo -e "\033[32m[INFO]\033[0m API Key found in .env"
else
  echo -e "\033[33m[WARN]\033[0m Missing ETHERSCAN_API_KEY in .env"
  echo "ETHERSCAN_API_KEY=your_valid_api_key" >>"$ENV_FILE"
  echo -e "\033[38;5;79m[FIXED]\033[0m Placeholder key added. Replace it with a valid one."
fi

# 4️⃣ SYSTEM SERVICE RESTART
echo -e "\n\033[1;34m[4/4] Restarting Services (Dashboard + Nginx)...\033[0m" | tee -a "$LOG_FILE"
systemctl daemon-reload
systemctl restart zeazdev-dashboard.service nginx
sleep 3

echo -e "\033[32m[INFO]\033[0m Checking service statuses...\n"
systemctl is-active --quiet zeazdev-dashboard.service && echo -e "\033[32m[OK]\033[0m Dashboard active" || echo -e "\033[31m[FAIL]\033[0m Dashboard not running"
systemctl is-active --quiet nginx && echo -e "\033[32m[OK]\033[0m Nginx active" || echo -e "\033[31m[FAIL]\033[0m Nginx not running"

echo -e "\n\033[1;32m[✅ COMPLETE]\033[0m ZeaZDev v9.3 Repair Routine finished."
echo -e "Log file saved at: $LOG_FILE"
