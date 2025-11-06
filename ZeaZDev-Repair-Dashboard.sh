#!/bin/bash
# ============================================================
# ZeaZDev-Repair-Dashboard.sh
# Purpose: Auto-rebuild & restore ZeaZDev Dashboard (Vault Integration v9.4)
# Author: Meta-Intelligence Interface (MII)
# ============================================================

DASH_DIR="/opt/ZeaZDev/Dashboard"
ENV_FILE="/opt/ZeaZDev/.env"
LOG_FILE="/opt/ZeaZDev/logs/repair-dashboard-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$(dirname "$LOG_FILE")"

echo -e "\033[1;32m[INFO]\033[0m Starting ZeaZDev Dashboard Repair..."
echo -e "\033[38;5;79m[LOG]\033[0m Saving to $LOG_FILE"

# 1️⃣ ตรวจสอบว่ามีโฟลเดอร์ Dashboard หรือไม่
if [ ! -d "$DASH_DIR" ]; then
  echo -e "\033[31m[ERROR]\033[0m Missing Dashboard directory. Creating..."
  mkdir -p "$DASH_DIR"
fi

cd "$DASH_DIR" || exit 1

# 2️⃣ ตรวจสอบว่ามี server.js หรือไม่
if [ ! -f "$DASH_DIR/server.js" ]; then
  echo -e "\033[33m[WARN]\033[0m server.js not found. Rebuilding default server..."
  cat <<'EOF' | tee "$DASH_DIR/server.js" > /dev/null
/**
 * ZeaZDev Dashboard Server (Vault Integration Edition)
 */
import express from "express";
import path from "path";
import { fileURLToPath } from "url";
import dotenv from "dotenv";
import { WebSocketServer } from "ws";

dotenv.config({ path: "/opt/ZeaZDev/.env" });

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(express.static(path.join(__dirname, "public")));

// Healthcheck
app.get("/api/health", (_, res) => {
  res.json({ status: "ok", version: "9.4", uptime: process.uptime() });
});

// Vault endpoint placeholder
app.get("/api/vault", (_, res) => {
  res.status(501).json({ error: "Vault module not yet initialized." });
});

// Start HTTP server
const server = app.listen(PORT, "0.0.0.0", () => {
  console.log(`[ZeaZDev] Dashboard running on http://0.0.0.0:${PORT}`);
});

// WebSocket bridge
const wss = new WebSocketServer({ server });
wss.on("connection", (ws) => {
  ws.send(JSON.stringify({ event: "welcome", message: "Connected to ZeaZDev Dashboard WebSocket" }));
});

process.on("uncaughtException", (err) => console.error("[FATAL]", err));
EOF
fi

# 3️⃣ ตรวจสอบ package.json
if [ ! -f "$DASH_DIR/package.json" ]; then
  echo -e "\033[33m[WARN]\033[0m package.json not found. Creating..."
  cat <<'EOF' | tee "$DASH_DIR/package.json" > /dev/null
{
  "name": "zeazdev-dashboard",
  "version": "9.4.0",
  "main": "server.js",
  "type": "module",
  "dependencies": {
    "express": "^4.21.1",
    "ws": "^8.18.0",
    "dotenv": "^16.4.5"
  }
}
EOF
fi

# 4️⃣ ติดตั้ง dependencies
echo -e "\033[38;5;79m[INSTALL]\033[0m Installing dependencies..."
npm install --omit=dev >>"$LOG_FILE" 2>&1

# 5️⃣ ตรวจสอบว่า .env มี PORT หรือไม่
if ! grep -q "PORT=" "$ENV_FILE"; then
  echo -e "\033[33m[WARN]\033[0m Missing PORT in .env. Adding default PORT=3000"
  echo "PORT=3000" >>"$ENV_FILE"
fi

# 6️⃣ ทดสอบการรัน
echo -e "\033[38;5;79m[TEST]\033[0m Testing Dashboard Server..."
node server.js &
PID=$!
sleep 3

if curl -s http://127.0.0.1:3000/api/health | grep -q "ok"; then
  echo -e "\033[32m[OK]\033[0m Dashboard responded successfully on port 3000"
else
  echo -e "\033[31m[FAIL]\033[0m Dashboard test failed. Check $LOG_FILE"
fi

kill $PID >/dev/null 2>&1

# 7️⃣ Restart services
echo -e "\033[38;5;79m[RESTART]\033[0m Restarting services..."
systemctl daemon-reload
systemctl restart zeazdev-dashboard.service nginx

sleep 3
if systemctl is-active --quiet zeazdev-dashboard.service; then
  echo -e "\033[32m[SUCCESS]\033[0m ZeaZDev Dashboard restored and running."
else
  echo -e "\033[31m[ERROR]\033[0m Dashboard service still not active. Check systemctl logs."
fi

echo -e "\n\033[1;32m[COMPLETE]\033[0m ZeaZDev Dashboard Repair finished."
echo "Log saved at: $LOG_FILE"
