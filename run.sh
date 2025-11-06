#!/usr/bin/env bash
# =============================================================================
# 🌐 ZeaZDev v10.1 (Execution Wrapper)
# 👨‍💻 Developer: PHIPHAT PHOEMSUK (ZeaZDev)
#
#    ( 1 )  รัน 'sudo bash run.sh' ครั้งแรก (สคริปต์จะสร้าง .env)
#    ( 2 )  แก้ไขไฟล์ '.env' ที่ถูกสร้างขึ้น
#    ( 3 )  รัน 'sudo bash run.sh' อีกครั้งเพื่อติดตั้ง
# =============================================================================

set -euo pipefail

# --- Execution Logic ---
GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; RESET="\e[0m"
ENV_FILE=".env"
INSTALLER_SCRIPT="ZeaZDev-Release-v10.1.sh" # <-- (FIX v10.1)

if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}[ERROR]${RESET} สคริปต์นี้ต้องรันด้วย sudo"
  echo "        กรุณารัน: sudo bash $0"
  exit 1
fi

if [ ! -f "$INSTALLER_SCRIPT" ]; then
    echo -e "${RED}[ERROR]${RESET} ไม่พบไฟล์ Installer หลัก: $INSTALLER_SCRIPT"
    echo "        กรุณาดาวน์โหลดไฟล์ทั้ง 2 (run.sh และ $INSTALLER_SCRIPT) ให้อยู่ในโฟลเดอร์เดียวกัน"
    exit 1
fi

# --- [FIX v9.1] .env File Handling ---
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}[WARN]${RESET} ไม่พบไฟล์ '$ENV_FILE'"
    echo -e "${GREEN}[INFO]${RESET} กำลังสร้างไฟล์ '$ENV_FILE' เริ่มต้นให้คุณ..."
    
cat > "$ENV_FILE" <<EOF
# === ZeaZDev v10.1 Configuration ===
# กรุณากรอกค่าที่จำเป็นทั้งหมดด้านล่าง

# 1. Networks (ต้องมี)
# (คั่นด้วย comma, ห้ามมีเว้นวรรค)
MULTI_RPC_LIST="worldchain=https://...,base=https://...,sepolia=https://..."

# 2. Deployer & Relayer Keys (ต้องมี)
# (Deployer Key: ใช้ Deploy สัญญา, เป็น Owner ของ Vault)
PRIVATE_KEY="0x..."
# (Relayer Key: Hot Wallet ของ Backend, ใช้จ่าย Gas ให้ผู้ใช้)
RELAYER_PRIVATE_KEY="0x..."

# 3. WorldID (ต้องมี)
# (Public App ID: สำหรับ Frontend/IDKit, e.g., app_...)
WORLD_APP_ID="app_..."
# (Secret API Key: สำหรับ Backend/Verify API, e.g., api_...)
WORLD_APP_API_KEY="api_..."

# 4. Domains (ต้องมีสำหรับ Nginx/SSL)
FRONT_DOMAIN="app.zeaz.dev"
DASH_DOMAIN="dash.zeaz.dev"
API_DOMAIN="api.zeaz.dev"

# 5. Verification (Optional)
ETHERSCAN_API_KEY=""

# 6. Notifications (Optional)
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""
# (FEAT v9.4)
# (หากต้องการ Push โปรเจกต์ทั้งหมด (ยกเว้น .env) ไปยัง Git)
GIT_LOG_REPO=""
GIT_LOG_BRANCH="main"

# 7. (Optional) Invalid keys (จะถูกข้ามโดยอัตโนมัติ)
# GHCR-Push-Token=...
EOF

    echo -e "${RED}[ACTION REQUIRED]${RESET} แก้ไขไฟล์ '$ENV_FILE' ด้วย Keys และ RPCs ของคุณ"
    echo "                 จากนั้น รัน 'sudo bash run.sh' อีกครั้งเพื่อเริ่มการติดตั้ง"
    exit 1
else
    echo -e "${GREEN}[INFO]${RESET} ZeaZDev Wrapper: พบ '$ENV_FILE'"
fi

echo -e "${GREEN}[INFO]${RESET} ZeaZDev Wrapper: ตรวจสอบ Root... OK"
echo -e "${GREEN}[INFO]${RESET} ZeaZDev Wrapper: ส่งออก (Export) ตัวแปรจาก .env..."

# --- [FIX v9.2] Safe .env Parser ---
set -a # Automatically export all variables declared
while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip comments and empty lines
    if [[ "$line" =~ ^\s*# ]] || [[ -z "$line" ]]; then
        continue
    fi
    # Check for valid BASH identifier (no hyphens)
    if [[ "$line" =~ ^[a-zA-Z_][a-zA-Z0-9_]*= ]]; then
        eval "export $line"
    else
        echo -e "${YELLOW}[WARN]${RESET} Ignoring invalid line in .env (contains spaces or hyphens): $line"
    fi
done < "$ENV_FILE"
set +a # Stop auto-exporting
# --- [END FIX] ---

echo -e "${GREEN}[INFO]${RESET} ZeaZDev Wrapper: เริ่มการทำงาน $INSTALLER_SCRIPT..."
echo "------------------------------------------------------------------"

# รัน Installer หลัก (ซึ่งจะรับ ENV Vars ที่ export ไว้)
bash "$INSTALLER_SCRIPT"

echo "------------------------------------------------------------------"
echo -e "${GREEN}[INFO]${RESET} ZeaZDev Wrapper: การทำงานเสร็จสิ้น"
