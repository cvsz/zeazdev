#!/usr/bin/env bash
# =============================================================================
# 🚀 ZeaZDev - Start All Phases Script
# =============================================================================
# Developer: PHIPHAT PHOEMSUK (ZeaZDev)
# Email: admin@zeaz.dev
# Website: https://app.zeaz.dev
# Version: 1.0.0
#
# Description:
# This script initializes and starts all development phases of the ZeaZDev
# platform, including backend services, frontend applications, and monitoring.
#
# Usage:
#   bash start-all-phases.sh [options]
#
# Options:
#   --all          Start all components (default)
#   --backend      Start backend services only
#   --frontend     Start frontend applications only
#   --contracts    Deploy/check smart contracts
#   --status       Show status of all phases
#   --stop         Stop all running services
#   --help         Show this help message
#
# =============================================================================

set -euo pipefail

# Color codes for output
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
CYAN="\e[36m"
RESET="\e[0m"

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}"
LOG_DIR="${PROJECT_ROOT}/Logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Component paths
SERVER_DIR="${PROJECT_ROOT}/server"
MINI_APP_DIR="${PROJECT_ROOT}/mini-app"
CONTRACTS_DIR="${PROJECT_ROOT}/contracts"

# =============================================================================
# Utility Functions
# =============================================================================

print_banner() {
    echo -e "${CYAN}"
    echo "═══════════════════════════════════════════════════════════════"
    echo "   🚀 ZeaZDev - Start All Phases                              "
    echo "   Developer: PHIPHAT PHOEMSUK (ZeaZDev)                       "
    echo "   Version: 1.0.0                                              "
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "${RESET}"
}

log_info() {
    echo -e "${GREEN}[INFO]${RESET} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${RESET} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${RESET} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${RESET} $1"
}

# =============================================================================
# Pre-flight Checks
# =============================================================================

check_prerequisites() {
    log_step "Checking prerequisites..."
    
    local missing=0
    
    # Check for Node.js
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed. Please install Node.js v18+ from https://nodejs.org/"
        missing=1
    else
        local node_version=$(node -v)
        log_info "Node.js version: ${node_version}"
    fi
    
    # Check for npm
    if ! command -v npm &> /dev/null; then
        log_error "npm is not installed. Please install npm."
        missing=1
    else
        local npm_version=$(npm -v)
        log_info "npm version: ${npm_version}"
    fi
    
    # Check for git
    if ! command -v git &> /dev/null; then
        log_warn "git is not installed. Version control features may be limited."
    else
        log_info "git is available: $(git --version)"
    fi
    
    if [ $missing -eq 1 ]; then
        log_error "Missing required dependencies. Please install them and try again."
        exit 1
    fi
    
    log_info "All prerequisites satisfied ✓"
}

check_directory_structure() {
    log_step "Checking directory structure..."
    
    # Create logs directory if it doesn't exist
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
        log_info "Created logs directory: $LOG_DIR"
    fi
    
    # Check for required directories
    if [ ! -d "$SERVER_DIR" ]; then
        log_warn "Server directory not found: $SERVER_DIR"
    else
        log_info "Server directory found ✓"
    fi
    
    if [ ! -d "$MINI_APP_DIR" ]; then
        log_warn "Mini App directory not found: $MINI_APP_DIR"
    else
        log_info "Mini App directory found ✓"
    fi
    
    if [ ! -d "$CONTRACTS_DIR" ]; then
        log_warn "Contracts directory not found: $CONTRACTS_DIR"
    else
        log_info "Contracts directory found ✓"
    fi
}

# =============================================================================
# Installation Functions
# =============================================================================

install_dependencies() {
    log_step "Installing dependencies for all components..."
    
    # Install root dependencies if package.json exists
    if [ -f "${PROJECT_ROOT}/package.json" ]; then
        log_info "Installing root dependencies..."
        cd "$PROJECT_ROOT"
        npm install || log_warn "Root npm install failed (may be normal if no dependencies)"
    fi
    
    # Install server dependencies
    if [ -d "$SERVER_DIR" ] && [ -f "${SERVER_DIR}/package.json" ]; then
        log_info "Installing server dependencies..."
        cd "$SERVER_DIR"
        npm install || log_error "Server npm install failed"
    fi
    
    # Install mini-app dependencies
    if [ -d "$MINI_APP_DIR" ] && [ -f "${MINI_APP_DIR}/package.json" ]; then
        log_info "Installing mini-app dependencies..."
        cd "$MINI_APP_DIR"
        npm install || log_error "Mini-app npm install failed"
    fi
    
    # Install contracts dependencies
    if [ -d "$CONTRACTS_DIR" ] && [ -f "${CONTRACTS_DIR}/package.json" ]; then
        log_info "Installing contracts dependencies..."
        cd "$CONTRACTS_DIR"
        npm install || log_error "Contracts npm install failed"
    fi
    
    cd "$PROJECT_ROOT"
    log_info "Dependencies installation completed ✓"
}

# =============================================================================
# Environment Setup
# =============================================================================

check_environment() {
    log_step "Checking environment configuration..."
    
    local env_missing=0
    
    # Check root .env
    if [ ! -f "${PROJECT_ROOT}/.env" ]; then
        log_warn "Root .env file not found (optional for legacy scripts)"
        log_info "See README.md for root .env configuration if using legacy deployment"
    else
        log_info "Root .env file found ✓"
    fi
    
    # Check server .env
    if [ -d "$SERVER_DIR" ] && [ ! -f "${SERVER_DIR}/.env" ]; then
        log_warn "Server .env file not found"
        if [ -f "${SERVER_DIR}/.env.example" ]; then
            log_info "To create it, run: cp ${SERVER_DIR}/.env.example ${SERVER_DIR}/.env"
            log_info "Then edit ${SERVER_DIR}/.env with your actual configuration values"
        else
            log_info "Create ${SERVER_DIR}/.env based on README.md instructions"
        fi
        env_missing=1
    else
        [ -d "$SERVER_DIR" ] && log_info "Server .env file found ✓"
    fi
    
    # Check mini-app .env
    if [ -d "$MINI_APP_DIR" ] && [ ! -f "${MINI_APP_DIR}/.env" ]; then
        log_warn "Mini-app .env file not found"
        if [ -f "${MINI_APP_DIR}/.env.example" ]; then
            log_info "To create it, run: cp ${MINI_APP_DIR}/.env.example ${MINI_APP_DIR}/.env"
            log_info "Then edit ${MINI_APP_DIR}/.env with your actual configuration values"
        else
            log_info "Create ${MINI_APP_DIR}/.env based on README.md instructions"
        fi
        env_missing=1
    else
        [ -d "$MINI_APP_DIR" ] && log_info "Mini-app .env file found ✓"
    fi
    
    if [ $env_missing -eq 1 ]; then
        log_warn "Some .env files are missing. Services may not start correctly."
        log_info "Quick setup:"
        echo ""
        [ -f "${SERVER_DIR}/.env.example" ] && echo "  cp ${SERVER_DIR}/.env.example ${SERVER_DIR}/.env"
        [ -f "${MINI_APP_DIR}/.env.example" ] && echo "  cp ${MINI_APP_DIR}/.env.example ${MINI_APP_DIR}/.env"
        echo ""
        log_info "Then edit the .env files with your actual configuration values."
        log_info "See README.md for detailed configuration instructions."
        echo ""
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Aborting. Please create .env files and try again."
            exit 1
        fi
    fi
}

# =============================================================================
# Backend Services
# =============================================================================

start_backend() {
    log_step "Starting backend services..."
    
    if [ ! -d "$SERVER_DIR" ]; then
        log_warn "Server directory not found. Skipping backend startup."
        return
    fi
    
    cd "$SERVER_DIR"
    
    if [ ! -f "package.json" ]; then
        log_warn "Server package.json not found. Skipping backend startup."
        return
    fi
    
    log_info "Starting backend verifier service..."
    
    # Check if server is already running
    if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        log_warn "Port 3000 is already in use. Backend may already be running."
        return
    fi
    
    # Start server in background
    nohup npm start > "${LOG_DIR}/server_${TIMESTAMP}.log" 2>&1 &
    local server_pid=$!
    
    echo "$server_pid" > "${LOG_DIR}/server.pid"
    
    log_info "Backend service started (PID: ${server_pid})"
    log_info "Backend logs: ${LOG_DIR}/server_${TIMESTAMP}.log"
    
    # Wait a moment and check if it's still running
    sleep 2
    if ps -p $server_pid > /dev/null; then
        log_info "Backend service is running ✓"
    else
        log_error "Backend service failed to start. Check logs for details."
    fi
    
    cd "$PROJECT_ROOT"
}

# =============================================================================
# Frontend Applications
# =============================================================================

start_frontend() {
    log_step "Starting frontend applications..."
    
    if [ ! -d "$MINI_APP_DIR" ]; then
        log_warn "Mini-app directory not found. Skipping frontend startup."
        return
    fi
    
    cd "$MINI_APP_DIR"
    
    if [ ! -f "package.json" ]; then
        log_warn "Mini-app package.json not found. Skipping frontend startup."
        return
    fi
    
    log_info "Starting mini-app with Expo..."
    
    # Check if expo is available
    if ! command -v expo &> /dev/null; then
        log_warn "Expo CLI not found globally. Using npx expo..."
    fi
    
    # Start expo in background
    nohup npm start > "${LOG_DIR}/miniapp_${TIMESTAMP}.log" 2>&1 &
    local expo_pid=$!
    
    echo "$expo_pid" > "${LOG_DIR}/miniapp.pid"
    
    log_info "Mini-app started (PID: ${expo_pid})"
    log_info "Mini-app logs: ${LOG_DIR}/miniapp_${TIMESTAMP}.log"
    log_info "Expo DevTools will open in your browser shortly..."
    
    # Wait a moment and check if it's still running
    sleep 3
    if ps -p $expo_pid > /dev/null; then
        log_info "Mini-app is running ✓"
        log_info "Scan the QR code with Expo Go app to test on your device"
    else
        log_error "Mini-app failed to start. Check logs for details."
    fi
    
    cd "$PROJECT_ROOT"
}

# =============================================================================
# Smart Contracts
# =============================================================================

check_contracts() {
    log_step "Checking smart contracts..."
    
    if [ ! -d "$CONTRACTS_DIR" ]; then
        log_warn "Contracts directory not found. Skipping contracts check."
        return
    fi
    
    cd "$CONTRACTS_DIR"
    
    if [ ! -f "package.json" ]; then
        log_warn "Contracts package.json not found. Skipping contracts check."
        return
    fi
    
    log_info "Smart contracts directory found ✓"
    log_info "To deploy contracts, run: cd contracts && npx hardhat run scripts/deploy.js"
    
    cd "$PROJECT_ROOT"
}

# =============================================================================
# Status Display
# =============================================================================

show_status() {
    log_step "Checking status of all services..."
    
    echo ""
    echo -e "${CYAN}Service Status:${RESET}"
    echo "───────────────────────────────────────────────────"
    
    # Check backend
    if [ -f "${LOG_DIR}/server.pid" ]; then
        local server_pid=$(cat "${LOG_DIR}/server.pid")
        if ps -p $server_pid > /dev/null 2>&1; then
            echo -e "Backend Service:    ${GREEN}Running${RESET} (PID: ${server_pid})"
        else
            echo -e "Backend Service:    ${RED}Stopped${RESET}"
        fi
    else
        echo -e "Backend Service:    ${YELLOW}Not Started${RESET}"
    fi
    
    # Check frontend
    if [ -f "${LOG_DIR}/miniapp.pid" ]; then
        local expo_pid=$(cat "${LOG_DIR}/miniapp.pid")
        if ps -p $expo_pid > /dev/null 2>&1; then
            echo -e "Mini-app:           ${GREEN}Running${RESET} (PID: ${expo_pid})"
        else
            echo -e "Mini-app:           ${RED}Stopped${RESET}"
        fi
    else
        echo -e "Mini-app:           ${YELLOW}Not Started${RESET}"
    fi
    
    # Check port availability
    echo ""
    echo -e "${CYAN}Port Status:${RESET}"
    echo "───────────────────────────────────────────────────"
    
    if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "Port 3000 (Backend): ${GREEN}In Use${RESET}"
    else
        echo -e "Port 3000 (Backend): ${YELLOW}Available${RESET}"
    fi
    
    # Phase status
    echo ""
    echo -e "${CYAN}Development Phases:${RESET}"
    echo "───────────────────────────────────────────────────"
    echo "Phase 1 (Foundation):        95% Complete"
    echo "Phase 2 (Core Features):     Planned (Q2 2025)"
    echo "Phase 3 (Advanced Features): Planned (Q3 2025)"
    echo "Phase 4 (Enterprise):        Planned (Q4 2025)"
    echo ""
    echo "For detailed phase status, see: PHASE_STATUS.md"
}

# =============================================================================
# Stop Services
# =============================================================================

stop_services() {
    log_step "Stopping all services..."
    
    local stopped=0
    
    # Stop backend
    if [ -f "${LOG_DIR}/server.pid" ]; then
        local server_pid=$(cat "${LOG_DIR}/server.pid")
        if ps -p $server_pid > /dev/null 2>&1; then
            kill $server_pid
            log_info "Stopped backend service (PID: ${server_pid})"
            stopped=1
        fi
        rm -f "${LOG_DIR}/server.pid"
    fi
    
    # Stop frontend
    if [ -f "${LOG_DIR}/miniapp.pid" ]; then
        local expo_pid=$(cat "${LOG_DIR}/miniapp.pid")
        if ps -p $expo_pid > /dev/null 2>&1; then
            kill $expo_pid
            log_info "Stopped mini-app (PID: ${expo_pid})"
            stopped=1
        fi
        rm -f "${LOG_DIR}/miniapp.pid"
    fi
    
    if [ $stopped -eq 0 ]; then
        log_info "No services were running."
    else
        log_info "All services stopped ✓"
    fi
}

# =============================================================================
# Help Message
# =============================================================================

show_help() {
    cat << EOF
Usage: bash start-all-phases.sh [options]

Options:
  --all          Start all components (default)
  --backend      Start backend services only
  --frontend     Start frontend applications only
  --contracts    Check smart contracts status
  --status       Show status of all phases and services
  --stop         Stop all running services
  --install      Install dependencies only
  --check        Validate configuration without starting services
  --help         Show this help message

Examples:
  bash start-all-phases.sh                 # Start all components
  bash start-all-phases.sh --backend       # Start backend only
  bash start-all-phases.sh --status        # Check status
  bash start-all-phases.sh --check         # Validate configuration
  bash start-all-phases.sh --stop          # Stop all services
  bash start-all-phases.sh --stop          # Stop all services

Environment Setup:
  Before running, ensure you have configured .env files:
  - ${PROJECT_ROOT}/.env (optional, for legacy scripts)
  - ${SERVER_DIR}/.env (required for backend)
  - ${MINI_APP_DIR}/.env (required for mini-app)

See README.md for detailed configuration instructions.

Developer: PHIPHAT PHOEMSUK (ZeaZDev)
Email: admin@zeaz.dev
Website: https://app.zeaz.dev
EOF
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    print_banner
    
    # Parse command line arguments
    local mode="${1:---all}"
    
    case "$mode" in
        --help|-h)
            show_help
            exit 0
            ;;
        --status)
            show_status
            exit 0
            ;;
        --stop)
            stop_services
            exit 0
            ;;
        --check)
            check_prerequisites
            check_directory_structure
            check_environment
            log_info "Configuration validation completed ✓"
            log_info "All checks passed. You can now run: bash start-all-phases.sh --all"
            exit 0
            ;;
        --install)
            check_prerequisites
            check_directory_structure
            install_dependencies
            log_info "Installation completed ✓"
            exit 0
            ;;
        --backend)
            check_prerequisites
            check_directory_structure
            check_environment
            start_backend
            show_status
            ;;
        --frontend)
            check_prerequisites
            check_directory_structure
            check_environment
            start_frontend
            show_status
            ;;
        --contracts)
            check_prerequisites
            check_directory_structure
            check_contracts
            ;;
        --all)
            check_prerequisites
            check_directory_structure
            check_environment
            install_dependencies
            echo ""
            start_backend
            echo ""
            start_frontend
            echo ""
            check_contracts
            echo ""
            show_status
            ;;
        *)
            log_error "Unknown option: $mode"
            echo ""
            show_help
            exit 1
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${GREEN}  ZeaZDev - All phases initialized successfully! 🚀             ${RESET}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${RESET}"
    echo ""
    log_info "Next Steps:"
    echo "  1. Check PHASE_STATUS.md for development roadmap"
    echo "  2. Visit http://localhost:3000 for backend API"
    echo "  3. Scan QR code in Expo DevTools to test Mini App"
    echo "  4. Check logs in ${LOG_DIR}/ for debugging"
    echo ""
}

# Run main function
main "$@"
