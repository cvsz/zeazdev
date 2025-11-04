#!/usr/bin/env bash
# =============================================================================
# 🌐 Developer & Project Information
# 💲 ZeaZDev — Zea Token ($ZEA)
# 📦 Version: Release — v5.6 (Auto SSL + Proxy Mode)
# 👨‍💻 Developer: PHIPHAT PHOEMSUK (ZeaZDev)
# 🏢 Organization: ZeaZDev — Ecosystem • Innovate • Connect • Grow
# 🌍 Website: https://app.zeaz.dev/
# 📧 Contact: admin@zeaz.dev, support@zeaz.dev
# 🔐 License: MIT
# =============================================================================
set -euo pipefail
trap 'echo "[ERROR] Unexpected error on line $LINENO"; exit 1' ERR

# Colors
GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; RESET="\e[0m"
info(){ echo -e "${GREEN}[INFO]${RESET} $*"; }
warn(){ echo -e "${YELLOW}[WARN]${RESET} $*"; }
err(){ echo -e "${RED}[ERROR]${RESET} $*"; }

# Defaults & paths
INSTALL_PATH="${INSTALL_PATH:-/opt/ZeaZDev}"
PROJECT_PATH="$INSTALL_PATH/Project"
FRONT_PATH="$INSTALL_PATH/Frontend"
DASH_PATH="$INSTALL_PATH/Dashboard"
RESULTS_DIR="$INSTALL_PATH/Results"
LOG_DIR="$INSTALL_PATH/Logs"
BACKUP_DIR="$INSTALL_PATH/Backups"
TMP_DIR="${TMP_DIR:-/tmp/zeazdev_v56}"
NODE_MIN_VER="${NODE_MIN_VER:-18}"

mkdir -p "$PROJECT_PATH" "$FRONT_PATH" "$DASH_PATH" "$RESULTS_DIR" "$LOG_DIR" "$BACKUP_DIR" "$TMP_DIR"

# Env (allow non-interactive)
: "${MULTI_RPC_LIST:=${MULTI_RPC_LIST:-}}"
: "${WORLD_APP_ID:=${WORLD_APP_ID:-}}"
: "${PRIVATE_KEY:=${PRIVATE_KEY:-}}"
: "${ETHERSCAN_API_KEY:=${ETHERSCAN_API_KEY:-}}"
: "${TELEGRAM_BOT_TOKEN:=${TELEGRAM_BOT_TOKEN:-}}"
: "${TELEGRAM_CHAT_ID:=${TELEGRAM_CHAT_ID:-}}"
: "${GIT_LOG_REPO:=${GIT_LOG_REPO:-}}"
: "${GIT_LOG_BRANCH:=${GIT_LOG_BRANCH:-deploy-logs}}"
: "${FRONT_DOMAIN:=${FRONT_DOMAIN:-localhost:3000}}"
: "${WORLD_ROUTER_FALLBACK:=0x7a5b8bC49D4D17a1aDe87E4E3fCB86B1fFb3D545}"

# Helper: require root
if [ "$EUID" -ne 0 ]; then
  warn "Not running as root. Some install steps may require sudo privileges. Re-run with sudo."
fi

# Interactive fallback for required vars
if [ -z "$MULTI_RPC_LIST" ] || [ -z "$WORLD_APP_ID" ] || [ -z "$PRIVATE_KEY" ]; then
  echo "Interactive setup: please enter missing values (or set as env variables before running)."
  read -p "Enter MULTI_RPC_LIST (e.g. sepolia=https://... ,worldchain=https://...): " I_MULTI_RPC_LIST
  MULTI_RPC_LIST="${MULTI_RPC_LIST:-$I_MULTI_RPC_LIST}"
  read -p "Enter WORLD_APP_ID: " I_WORLD_APP_ID
  WORLD_APP_ID="${WORLD_APP_ID:-$I_WORLD_APP_ID}"
  read -p "Enter PRIVATE_KEY (0x...): " I_PRIVATE_KEY
  PRIVATE_KEY="${PRIVATE_KEY:-$I_PRIVATE_KEY}"
  read -p "Enter FRONT_DOMAIN (example: app.zeaz.dev): " I_FRONT
  FRONT_DOMAIN="${FRONT_DOMAIN:-$I_FRONT}"
  read -p "Enter ETHERSCAN_API_KEY (optional): " I_ETH
  ETHERSCAN_API_KEY="${ETHERSCAN_API_KEY:-$I_ETH}"
fi

# sanitize multi rpc
MULTI_RPC_LIST=$(echo "${MULTI_RPC_LIST}" | sed 's/ //g')
if [ -z "$MULTI_RPC_LIST" ]; then err "MULTI_RPC_LIST required"; exit 1; fi

info "Install path: $INSTALL_PATH"
info "Frontend domain (requested): $FRONT_DOMAIN"

# -----------------------
# 1) Ensure node & npm available & version check
# -----------------------
if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
  warn "node/npm not found. Attempting to install node (curl + setup) for Debian/Ubuntu..."
  # Only attempt apt-based install (common VPS). User can skip if using other OS.
  if command -v apt-get >/dev/null 2>&1; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - || true
    apt-get update -y && apt-get install -y nodejs build-essential || true
  else
    warn "Manual install required for node/npm on your OS."
  fi
fi

NODE_VER=$(node -v 2>/dev/null || echo "v0")
info "Detected Node.js version: $NODE_VER"

# -----------------------
# 2) Install nginx & certbot (if user requested domain)
# -----------------------
install_nginx_and_certbot(){
  if command -v nginx >/dev/null 2>&1; then
    info "nginx found"
  else
    info "Installing nginx..."
    if command -v apt-get >/dev/null 2>&1; then
      apt-get update -y
      apt-get install -y nginx
    else
      warn "Non-apt system detected. Please install nginx manually."
    fi
  fi

  if command -v certbot >/dev/null 2>&1; then
    info "certbot found"
  else
    info "Installing certbot + python3-certbot-nginx..."
    if command -v apt-get >/dev/null 2>&1; then
      apt-get update -y
      apt-get install -y certbot python3-certbot-nginx
    else
      warn "Non-apt system detected. Please install certbot manually."
    fi
  fi
}

# -----------------------
# 3) Configure Nginx reverse proxy
# -----------------------
configure_nginx_proxy(){
  local domain="$1"
  info "Configuring nginx reverse proxy for $domain -> http://127.0.0.1:3000"

  local site_conf="/etc/nginx/sites-available/zeazdev.conf"
  cat > "$site_conf" <<NGCONF
server {
    listen 80;
    server_name ${domain};

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
NGCONF

  ln -sf "$site_conf" /etc/nginx/sites-enabled/zeazdev.conf
  nginx -t && systemctl restart nginx || { warn "nginx config test failed"; return 1; }
  info "nginx proxy file written: $site_conf"
  return 0
}

# -----------------------
# 4) Try Let's Encrypt (certbot --nginx)
# -----------------------
request_ssl(){
  local domain="$1"
  if ! command -v certbot >/dev/null 2>&1; then
    warn "certbot not available; skipping SSL request"
    return 1
  fi
  info "Requesting Let's Encrypt certificate for: $domain"
  # non-interactive; uses webroot via nginx plugin
  certbot --nginx -d "$domain" --redirect --non-interactive --agree-tos -m "admin@${domain#*.}" || {
    warn "certbot run failed for $domain"
    return 1
  }
  info "SSL certificate installed for $domain"
  return 0
}

# -----------------------
# 5) Create systemd services for dashboard & frontend
# -----------------------
create_systemd_services(){
  info "Creating systemd services for ZeaZDev dashboard and frontend"

  # Dashboard service: runs node server.js (assumes $INSTALL_PATH/server.js exists)
  cat > /etc/systemd/system/zeazdev-dashboard.service <<'UNIT'
[Unit]
Description=ZeaZDev Dashboard (Node server)
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ZeaZDev
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=5
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=zeazdev-dashboard

[Install]
WantedBy=multi-user.target
UNIT

  # Frontend service: run parcel dev server (assumes package.json scripts prepared)
  cat > /etc/systemd/system/zeazdev-frontend.service <<'UNIT'
[Unit]
Description=ZeaZDev Frontend (Parcel dev server)
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ZeaZDev/Frontend
ExecStart=/usr/bin/env npx parcel src/index.html --port 3000
Restart=on-failure
RestartSec=5
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=zeazdev-frontend

[Install]
WantedBy=multi-user.target
UNIT

  systemctl daemon-reload
  systemctl enable --now zeazdev-dashboard.service || warn "Failed enabling zeazdev-dashboard"
  systemctl enable --now zeazdev-frontend.service || warn "Failed enabling zeazdev-frontend"
  info "systemd services created and started (if possible)."
}

# -----------------------
# 6) Basic Project files (minimal safe bootstrap)
# -----------------------
bootstrap_project_files(){
  info "Bootstrapping minimal project files..."
  # .env.EXAMPLE
  cat > "$INSTALL_PATH/.env.EXAMPLE" <<ENVEX
# ZeaZDev v5.6 .env example
MULTI_RPC_LIST=${MULTI_RPC_LIST}
WORLD_APP_ID=${WORLD_APP_ID}
PRIVATE_KEY=${PRIVATE_KEY}
ETHERSCAN_API_KEY=${ETHERSCAN_API_KEY}
TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
TELEGRAM_CHAT_ID=${TELEGRAM_CHAT_ID}
FRONT_DOMAIN=${FRONT_DOMAIN}
ENVEX

  # Minimal dashboard server.js (if not exists)
  if [ ! -f "$INSTALL_PATH/server.js" ]; then
    cat > "$INSTALL_PATH/server.js" <<'NODE'
/* ZeaZDev Dashboard Server (auto-generated)
   Developer: PHIPHAT PHOEMSUK (ZeaZDev)
*/
import express from "express";
import http from "http";
import { WebSocketServer } from "ws";
import fs from "fs";
import path from "path";
const PORT = process.env.DASH_PORT ? Number(process.env.DASH_PORT) : 3000;
const BASE = process.env.PROJECT_DIR || "/opt/ZeaZDev";
const RESULTS_DIR = path.join(BASE,"Results");
const LOG_DIR = path.join(BASE,"Logs");
const DASH_DIR = path.join(BASE,"Dashboard");
const app = express();
app.use(express.json());
app.use(express.static(DASH_DIR));
app.get("/api/results", (req,res)=>{ try{ const files = fs.existsSync(RESULTS_DIR)?fs.readdirSync(RESULTS_DIR):[]; const data=[]; for(const f of files){ if(f.endsWith(".json")){ try{ data.push(JSON.parse(fs.readFileSync(path.join(RESULTS_DIR,f),"utf8"))); }catch(e){} } } res.json({ok:true,results:data}); }catch(e){ res.status(500).json({ok:false,error:e.message}); }});
app.get("/api/logtail",(req,res)=>{ try{ const lines = parseInt(req.query.lines||"200",10); if(!fs.existsSync(LOG_DIR)) return res.json({ok:true,log:""}); const files = fs.readdirSync(LOG_DIR).filter(f=>f.endsWith(".log")).sort(); if(files.length===0) return res.json({ok:true,log:""}); const latest = files[files.length-1]; const raw = fs.readFileSync(path.join(LOG_DIR,latest),"utf8"); const arr = raw.split(/\r?\n/).slice(-lines).join("\n"); res.json({ok:true,file:latest,log:arr}); }catch(e){ res.status(500).json({ok:false,error:e.message}); }});
const server = http.createServer(app);
const wss = new WebSocketServer({server,path:"/ws"});
wss.on("connection", ws => ws.send(JSON.stringify({type:"hello",ts:Date.now()})));
server.listen(PORT,()=>console.log(`Dashboard Server Running on http://0.0.0.0:${PORT}`));
NODE
    info "server.js created"
  else
    info "server.js already exists - leaving intact"
  fi

  # Minimal Frontend (if not exists)
  mkdir -p "$FRONT_PATH/src" "$DASH_PATH"
  if [ ! -f "$FRONT_PATH/src/index.html" ]; then
    cat > "$FRONT_PATH/src/index.html" <<HTML
<!doctype html><html><head><meta charset="utf-8"><title>ZeaDev</title></head><body><div id="root"></div><script type="module" src="./App.js"></script></body></html>
HTML
  fi
  if [ ! -f "$FRONT_PATH/src/App.js" ]; then
    cat > "$FRONT_PATH/src/App.js" <<'JS'
import { createRoot } from "react-dom/client";
async function main(){ try{ const res = await fetch('./networks.json'); const data = await res.json(); document.body.innerHTML = `<h2>ZeaDev Multi Deploy (aggregated)</h2><pre>${JSON.stringify(data,null,2)}</pre>`; } catch(e) { document.body.innerHTML = `<pre>Error loading networks.json: ${e}</pre>`; } }
main();
JS
  fi

  # Minimal Dashboard static UI
  if [ ! -f "$DASH_PATH/index.html" ]; then
    cat > "$DASH_PATH/index.html" <<'HTML'
<!doctype html><html><head><meta charset="utf-8"/><title>ZeaZDev Dashboard</title></head><body><h1>ZeaZDev Dashboard</h1><div id="app">Loading...</div><script>fetch('/api/results').then(r=>r.json()).then(j=>document.getElementById('app').innerText=JSON.stringify(j,null,2)).catch(e=>document.getElementById('app').innerText='Error');</script></body></html>
HTML
  fi

  info "Project bootstrap complete"
}

# -----------------------
# 7) Start services & confirm
# -----------------------
start_services_and_confirm(){
  # start node server directly if systemd not available
  if ! command -v systemctl >/dev/null 2>&1; then
    info "systemctl not available - launching node server and parcel in background..."
    (cd "$INSTALL_PATH" && node server.js &>/tmp/zeazdev_dashboard.log & echo $! > /tmp/zeazdev_dashboard.pid) || true
    (cd "$FRONT_PATH" && npx parcel src/index.html --port 3000 &>/tmp/zeazdev_parcel.log & echo $! > /tmp/zeazdev_parcel.pid) || true
    sleep 2
    info "Processes started (background mode). Check /tmp/zeazdev_dashboard.log and /tmp/zeazdev_parcel.log"
  else
    info "systemd available - expecting services already enabled"
    systemctl restart zeazdev-dashboard.service || true
    systemctl restart zeazdev-frontend.service || true
    sleep 2
  fi
}

# -----------------------
# 8) Run installer flow
# -----------------------
main_flow(){
  info "Starting ZeaZDev v5.6 installer (Auto SSL + Proxy Mode)"

  # 1) Bootstrap project files
  bootstrap_project_files

  # 2) Install nginx + certbot if domain not localhost
  if [ "$FRONT_DOMAIN" = "localhost" ] || [ "$FRONT_DOMAIN" = "127.0.0.1" ] || [[ "$FRONT_DOMAIN" =~ :[0-9]+$ ]]; then
    info "FRONT_DOMAIN looks local; skipping nginx/certbot auto-install"
  else
    install_nginx_and_certbot
    # attempt DNS resolution
    host_only="${FRONT_DOMAIN%%:*}"
    if ping -c1 -W1 "$host_only" >/dev/null 2>&1; then
      configure_nginx_proxy "$host_only" || warn "nginx proxy config may have failed"
      request_ssl "$host_only" || warn "SSL request failed - please check DNS and port 80 access"
    else
      warn "Domain $host_only does not resolve to this host (or ping blocked). Skipping SSL. Use HTTP or fix DNS."
    fi
  fi

  # 3) create systemd units & start
  create_systemd_services

  # 4) start services if systemd not available
  start_services_and_confirm

  info "ZeaZDev v5.6 setup complete."
  if [ "$FRONT_DOMAIN" = "localhost" ] || [[ "$FRONT_DOMAIN" =~ :[0-9]+$ ]]; then
    info "Dashboard running at http://localhost:3000"
  else
    info "Dashboard running at https://${FRONT_DOMAIN} (if SSL installed)"
  fi

  info "Results directory: $RESULTS_DIR - Logs: $LOG_DIR - Project: $PROJECT_PATH"
  info "To commit code to GitHub manually, see instructions at the end of this script."
}

# Run main
main_flow

# -----------------------
# Git push helper instructions
# -----------------------
cat <<'INSTR'

===========================================
NEXT STEPS: Commit & push to GitHub (manual)
===========================================

I cannot push to GitHub automatically. To push this change to your repo:
1) init repo (if not already) and add files:
   cd /opt/ZeaZDev
   git init
   git add .
   git commit -m "chore: zeazdev v5.6 auto-ssl/proxy bootstrap"
2) Create branch and push (use your GH PAT or set remote)
   git branch -M v5.6-auto-ssl
   git remote add origin https://github.com/ZeaZDev/ZeaZDev.git
   # Use credential helper or environment:
   # Example (uses github cli or export GITHUB_TOKEN to environment)
   git push -u origin v5.6-auto-ssl

If you want the script to auto-push, set environment variable:
   export GITHUB_REMOTE="https://<GH_PAT>@github.com/USERNAME/REPO.git"
and then run:
   git remote add origin "$GITHUB_REMOTE" && git push -u origin v5.6-auto-ssl

===========================================
END OF SCRIPT
===========================================
INSTR
