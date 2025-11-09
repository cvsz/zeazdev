/**
 * ============================================================================
 * ZeaZDev - Full Omega Ultimate DevOps Professional Enterprises
 * ============================================================================
 * 
 * Project: ZeaZDev Deployment & Installation Guide
 * File: DEPLOYMENT.md
 * Version: 1.0.0
 * 
 * Developer: PHIPHAT PHOEMSUK (ZeaZDev)
 * Email: admin@zeaz.dev
 * Website: https://app.zeaz.dev
 * GitHub: https://github.com/ZeaZDev
 * 
 * Description:
 * Complete automated deployment guide for all platforms including
 * Docker, Kubernetes, cloud providers, and automated installation scripts.
 * 
 * License: MIT
 * Copyright (c) 2025 PHIPHAT PHOEMSUK
 * 
 * Last Updated: 2025-01-09
 * ============================================================================
 */

# 🚀 ZeaZDev Deployment & Installation Guide

## 📋 Table of Contents
1. [System Requirements](#system-requirements)
2. [Quick Start (Development)](#quick-start-development)
3. [Docker Deployment](#docker-deployment)
4. [Kubernetes Deployment](#kubernetes-deployment)
5. [Cloud Deployment](#cloud-deployment)
6. [Automated Installation Scripts](#automated-installation-scripts)
7. [Environment Configuration](#environment-configuration)
8. [SSL/TLS Setup](#ssltls-setup)
9. [Monitoring & Health Checks](#monitoring--health-checks)
10. [Troubleshooting](#troubleshooting)

---

## 💻 System Requirements

### Minimum Requirements (Development)

| Component | Specification |
|-----------|--------------|
| **OS** | Ubuntu 22.04 LTS / macOS 12+ / Windows 11 + WSL2 |
| **CPU** | 4 cores @ 2.0 GHz |
| **RAM** | 8 GB |
| **Storage** | 50 GB SSD |
| **Network** | 10 Mbps |

### Recommended Requirements (Production)

| Component | Specification |
|-----------|--------------|
| **OS** | Ubuntu 22.04 LTS |
| **CPU** | 16 cores @ 3.0 GHz |
| **RAM** | 64 GB |
| **Storage** | 500 GB NVMe SSD |
| **Network** | 1 Gbps |
| **Redundancy** | 3+ nodes (high availability) |

### Software Prerequisites

```bash
# Required
- Node.js 18.x LTS
- npm 10.x or yarn 1.22.x
- Docker 24.x
- Docker Compose 2.x
- Git 2.40.x
- PostgreSQL 15.x
- MongoDB 6.x
- Redis 7.x

# Optional
- Kubernetes 1.28.x
- Helm 3.x
- Terraform 1.6.x
- Ansible 2.15.x
```

---

## ⚡ Quick Start (Development)

### 1. Clone Repository

```bash
# Clone the repository
git clone https://github.com/ZeaZDev/ZeaZDev.git
cd ZeaZDev

# Create environment file
cp .env.example .env
```

### 2. Configure Environment

Edit `.env` file:

```bash
# === Core Configuration ===
NODE_ENV=development
PORT=3000

# === Database ===
DATABASE_URL=postgresql://zeazdev:password@localhost:5432/zeazdev_main
MONGODB_URI=mongodb://localhost:27017/zeazdev_logs
REDIS_URL=redis://localhost:6379

# === Blockchain ===
RPC_URL=https://worldchain-mainnet.g.alchemy.com/v2/YOUR_KEY
RELAYER_PRIVATE_KEY=0xYOUR_RELAYER_PRIVATE_KEY
DEPLOYER_PRIVATE_KEY=0xYOUR_DEPLOYER_PRIVATE_KEY

# === World ID ===
WORLD_APP_ID=app_staging_YOUR_APP_ID
WORLD_APP_API_KEY=api_YOUR_API_KEY
WORLD_ACTION_ID=verify-humanity

# === JWT ===
JWT_SECRET=your-super-secret-jwt-key
JWT_REFRESH_SECRET=your-super-secret-refresh-key

# === Contract Addresses ===
WORLD_ID_REWARDS_CONTRACT=0x...
ZEA_TOKEN_CONTRACT=0x...
ZEAZ_TOKEN_CONTRACT=0x...
```

### 3. Install Dependencies

```bash
# Install root dependencies
npm install

# Install server dependencies
cd server
npm install
cd ..

# Install mini-app dependencies
cd mini-app
npm install
cd ..

# Install smart contract dependencies
cd contracts
npm install
cd ..
```

### 4. Setup Databases

```bash
# Start databases with Docker
docker-compose up -d postgres mongodb redis

# Wait for databases to be ready
sleep 10

# Run database migrations
npm run db:migrate

# Seed database (optional)
npm run db:seed
```

### 5. Deploy Smart Contracts (Testnet)

```bash
cd contracts

# Compile contracts
npx hardhat compile

# Deploy to Sepolia testnet
npx hardhat run scripts/deploy.js --network sepolia

# Save deployed addresses to .env
# Update WORLD_ID_REWARDS_CONTRACT, ZEA_TOKEN_CONTRACT, ZEAZ_TOKEN_CONTRACT

cd ..
```

### 6. Start Services

```bash
# Terminal 1: Start backend API
cd server
npm run dev

# Terminal 2: Start mini-app
cd mini-app
expo start

# Terminal 3: Start worker (optional)
cd server
npm run worker
```

### 7. Access Applications

- **Backend API**: http://localhost:3000
- **Mini App**: Scan QR code with Expo Go
- **API Docs**: http://localhost:3000/api-docs
- **Health Check**: http://localhost:3000/health

---

## 🐳 Docker Deployment

### Single Server Deployment

#### 1. Create `docker-compose.yml`

```yaml
version: '3.8'

services:
  # PostgreSQL Database
  postgres:
    image: postgres:15-alpine
    container_name: zeazdev-postgres
    environment:
      POSTGRES_DB: zeazdev_main
      POSTGRES_USER: zeazdev
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_INITDB_ARGS: "-E UTF8"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-scripts/postgres:/docker-entrypoint-initdb.d
    ports:
      - "5432:5432"
    networks:
      - zeazdev-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U zeazdev"]
      interval: 10s
      timeout: 5s
      retries: 5

  # MongoDB
  mongodb:
    image: mongo:6
    container_name: zeazdev-mongodb
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD}
      MONGO_INITDB_DATABASE: zeazdev_logs
    volumes:
      - mongodb_data:/data/db
      - ./init-scripts/mongo:/docker-entrypoint-initdb.d
    ports:
      - "27017:27017"
    networks:
      - zeazdev-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis
  redis:
    image: redis:7-alpine
    container_name: zeazdev-redis
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    networks:
      - zeazdev-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

  # Backend API
  api:
    build:
      context: ./server
      dockerfile: Dockerfile
      args:
        NODE_ENV: production
    container_name: zeazdev-api
    environment:
      NODE_ENV: production
      PORT: 3000
      DATABASE_URL: postgresql://zeazdev:${DB_PASSWORD}@postgres:5432/zeazdev_main
      MONGODB_URI: mongodb://admin:${MONGO_PASSWORD}@mongodb:27017/zeazdev_logs?authSource=admin
      REDIS_URL: redis://:${REDIS_PASSWORD}@redis:6379
    env_file:
      - .env
    ports:
      - "3000:3000"
    depends_on:
      postgres:
        condition: service_healthy
      mongodb:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - zeazdev-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G

  # Background Worker
  worker:
    build:
      context: ./server
      dockerfile: Dockerfile
    container_name: zeazdev-worker
    command: npm run worker
    environment:
      NODE_ENV: production
      DATABASE_URL: postgresql://zeazdev:${DB_PASSWORD}@postgres:5432/zeazdev_main
      MONGODB_URI: mongodb://admin:${MONGO_PASSWORD}@mongodb:27017/zeazdev_logs?authSource=admin
      REDIS_URL: redis://:${REDIS_PASSWORD}@redis:6379
    env_file:
      - .env
    depends_on:
      - postgres
      - mongodb
      - redis
    networks:
      - zeazdev-network
    restart: unless-stopped
    deploy:
      replicas: 2

  # Nginx Reverse Proxy
  nginx:
    image: nginx:alpine
    container_name: zeazdev-nginx
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - api
    networks:
      - zeazdev-network
    restart: unless-stopped

networks:
  zeazdev-network:
    driver: bridge

volumes:
  postgres_data:
  mongodb_data:
  redis_data:
```

#### 2. Build and Run

```bash
# Build images
docker-compose build

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Check status
docker-compose ps

# Stop services
docker-compose down

# Stop and remove volumes (WARNING: deletes data)
docker-compose down -v
```

#### 3. Scale Services

```bash
# Scale API to 3 instances
docker-compose up -d --scale api=3 --scale worker=5

# Or use docker-compose.override.yml
cat > docker-compose.override.yml << EOF
version: '3.8'
services:
  api:
    deploy:
      replicas: 3
  worker:
    deploy:
      replicas: 5
EOF

docker-compose up -d
```

---

## ☸️ Kubernetes Deployment

### Production-Ready K8s Manifests

#### 1. Namespace
```yaml
# namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: zeazdev
  labels:
    name: zeazdev
    environment: production
```

#### 2. Secrets
```yaml
# secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: zeazdev-secrets
  namespace: zeazdev
type: Opaque
stringData:
  DATABASE_URL: postgresql://zeazdev:password@postgres:5432/zeazdev_main
  MONGODB_URI: mongodb://admin:password@mongodb:27017/zeazdev_logs
  REDIS_URL: redis://:password@redis:6379
  JWT_SECRET: your-super-secret-jwt-key
  RELAYER_PRIVATE_KEY: 0x...
  WORLD_APP_API_KEY: api_...
```

#### 3. ConfigMaps
```yaml
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: zeazdev-config
  namespace: zeazdev
data:
  NODE_ENV: "production"
  PORT: "3000"
  WORLD_APP_ID: "app_staging_..."
  WORLD_ACTION_ID: "verify-humanity"
  RPC_URL: "https://worldchain-mainnet.g.alchemy.com/v2/..."
```

#### 4. PostgreSQL StatefulSet
```yaml
# postgres-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: zeazdev
spec:
  serviceName: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        ports:
        - containerPort: 5432
          name: postgres
        env:
        - name: POSTGRES_DB
          value: zeazdev_main
        - name: POSTGRES_USER
          value: zeazdev
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: zeazdev-secrets
              key: DB_PASSWORD
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 50Gi
      storageClassName: fast-ssd
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: zeazdev
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
  clusterIP: None
```

#### 5. API Deployment
```yaml
# api-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: zeazdev-api
  namespace: zeazdev
spec:
  replicas: 3
  selector:
    matchLabels:
      app: zeazdev-api
  template:
    metadata:
      labels:
        app: zeazdev-api
        version: v1
    spec:
      containers:
      - name: api
        image: zeazdev/api:latest
        ports:
        - containerPort: 3000
        envFrom:
        - configMapRef:
            name: zeazdev-config
        - secretRef:
            name: zeazdev-secrets
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: zeazdev-api
  namespace: zeazdev
spec:
  selector:
    app: zeazdev-api
  ports:
  - port: 80
    targetPort: 3000
  type: LoadBalancer
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: zeazdev-api-hpa
  namespace: zeazdev
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: zeazdev-api
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

#### 6. Ingress (with SSL)
```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: zeazdev-ingress
  namespace: zeazdev
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - api.zeaz.dev
    secretName: zeazdev-tls
  rules:
  - host: api.zeaz.dev
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: zeazdev-api
            port:
              number: 80
```

#### 7. Deploy to Kubernetes

```bash
# Apply all manifests
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/postgres-statefulset.yaml
kubectl apply -f k8s/mongodb-statefulset.yaml
kubectl apply -f k8s/redis-deployment.yaml
kubectl apply -f k8s/api-deployment.yaml
kubectl apply -f k8s/worker-deployment.yaml
kubectl apply -f k8s/ingress.yaml

# Or apply all at once
kubectl apply -f k8s/

# Check status
kubectl get all -n zeazdev

# View logs
kubectl logs -f deployment/zeazdev-api -n zeazdev

# Scale deployment
kubectl scale deployment/zeazdev-api --replicas=5 -n zeazdev
```

---

## ☁️ Cloud Deployment

### AWS Deployment (Terraform)

#### 1. Install Terraform

```bash
# Download Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Verify installation
terraform version
```

#### 2. AWS Infrastructure Configuration

```hcl
# terraform/main.tf
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket = "zeazdev-terraform-state"
    key    = "production/terraform.tfstate"
    region = "ap-southeast-1"
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "zeazdev-vpc"
    Environment = "production"
  }
}

# Subnets
resource "aws_subnet" "public" {
  count             = 3
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  tags = {
    Name = "zeazdev-public-subnet-${count.index + 1}"
  }
}

# RDS PostgreSQL
resource "aws_db_instance" "postgres" {
  identifier           = "zeazdev-postgres"
  engine               = "postgres"
  engine_version       = "15.4"
  instance_class       = "db.t3.large"
  allocated_storage    = 100
  storage_type         = "gp3"
  storage_encrypted    = true
  
  db_name  = "zeazdev_main"
  username = var.db_username
  password = var.db_password
  
  multi_az               = true
  publicly_accessible    = false
  backup_retention_period = 7
  skip_final_snapshot    = false
  
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  tags = {
    Name = "zeazdev-postgres"
  }
}

# ElastiCache Redis
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "zeazdev-redis"
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = "cache.t3.medium"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [aws_security_group.redis.id]
  
  tags = {
    Name = "zeazdev-redis"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "zeazdev-cluster"
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  
  tags = {
    Name = "zeazdev-ecs-cluster"
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "api" {
  family                   = "zeazdev-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn
  
  container_definitions = jsonencode([
    {
      name  = "api"
      image = "${var.ecr_repository_url}:latest"
      
      portMappings = [{
        containerPort = 3000
        protocol      = "tcp"
      }]
      
      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "PORT"
          value = "3000"
        }
      ]
      
      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = aws_secretsmanager_secret.db_url.arn
        },
        {
          name      = "JWT_SECRET"
          valueFrom = aws_secretsmanager_secret.jwt_secret.arn
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/zeazdev-api"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "api" {
  name            = "zeazdev-api-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 3
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }
  
  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = 3000
  }
  
  depends_on = [aws_lb_listener.https]
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "zeazdev-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
  
  enable_deletion_protection = true
  
  tags = {
    Name = "zeazdev-alb"
  }
}

# Target Group
resource "aws_lb_target_group" "api" {
  name        = "zeazdev-api-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  
  health_check {
    enabled             = true
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }
}

# HTTPS Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.acm_certificate_arn
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

# Auto Scaling
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 10
  min_capacity       = 3
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.api.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}
```

#### 3. Deploy to AWS

```bash
# Initialize Terraform
cd terraform
terraform init

# Plan deployment
terraform plan -out=tfplan

# Apply deployment
terraform apply tfplan

# Get outputs
terraform output

# Destroy (when needed)
terraform destroy
```

---

## 🤖 Automated Installation Scripts

### One-Command Installation Script

Create `install.sh`:

```bash
#!/bin/bash

###############################################################################
# ZeaZDev Automated Installation Script
# Version: 1.0.0
# Author: PHIPHAT PHOEMSUK
# Description: Automated installation for all platforms
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

check_os() {
    print_info "Detecting operating system..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO=$ID
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        print_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
    
    print_success "OS: $OS ${DISTRO:-}"
}

check_requirements() {
    print_info "Checking system requirements..."
    
    # Check CPU cores
    if [[ "$OS" == "linux" ]]; then
        CORES=$(nproc)
    else
        CORES=$(sysctl -n hw.ncpu)
    fi
    
    if [ "$CORES" -lt 4 ]; then
        print_error "Minimum 4 CPU cores required, found: $CORES"
        exit 1
    fi
    
    # Check RAM
    if [[ "$OS" == "linux" ]]; then
        RAM=$(free -g | awk '/^Mem:/{print $2}')
    else
        RAM=$(sysctl hw.memsize | awk '{print int($2/1024/1024/1024)}')
    fi
    
    if [ "$RAM" -lt 8 ]; then
        print_error "Minimum 8GB RAM required, found: ${RAM}GB"
        exit 1
    fi
    
    print_success "System requirements met (Cores: $CORES, RAM: ${RAM}GB)"
}

install_dependencies() {
    print_info "Installing dependencies..."
    
    if [[ "$OS" == "linux" ]]; then
        if [[ "$DISTRO" == "ubuntu" ]] || [[ "$DISTRO" == "debian" ]]; then
            sudo apt-get update
            sudo apt-get install -y curl wget git build-essential
        elif [[ "$DISTRO" == "centos" ]] || [[ "$DISTRO" == "rhel" ]]; then
            sudo yum update -y
            sudo yum install -y curl wget git gcc gcc-c++ make
        fi
    elif [[ "$OS" == "macos" ]]; then
        # Install Homebrew if not installed
        if ! command -v brew &> /dev/null; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install curl wget git
    fi
    
    print_success "Dependencies installed"
}

install_nodejs() {
    print_info "Installing Node.js..."
    
    if ! command -v node &> /dev/null; then
        # Install NVM
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        
        # Load NVM
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        # Install Node.js 18
        nvm install 18
        nvm use 18
        nvm alias default 18
    fi
    
    NODE_VERSION=$(node -v)
    print_success "Node.js installed: $NODE_VERSION"
}

install_docker() {
    print_info "Installing Docker..."
    
    if ! command -v docker &> /dev/null; then
        if [[ "$OS" == "linux" ]]; then
            curl -fsSL https://get.docker.com | sh
            sudo usermod -aG docker $USER
        elif [[ "$OS" == "macos" ]]; then
            brew install --cask docker
        fi
        
        # Install Docker Compose
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi
    
    DOCKER_VERSION=$(docker --version)
    print_success "Docker installed: $DOCKER_VERSION"
}

clone_repository() {
    print_info "Cloning ZeaZDev repository..."
    
    if [ ! -d "ZeaZDev" ]; then
        git clone https://github.com/ZeaZDev/ZeaZDev.git
    fi
    
    cd ZeaZDev
    print_success "Repository cloned"
}

setup_environment() {
    print_info "Setting up environment..."
    
    if [ ! -f ".env" ]; then
        cp .env.example .env
        
        # Generate secrets
        JWT_SECRET=$(openssl rand -hex 32)
        JWT_REFRESH_SECRET=$(openssl rand -hex 32)
        SESSION_SECRET=$(openssl rand -hex 32)
        
        # Update .env
        sed -i "s/your-super-secret-jwt-key/$JWT_SECRET/g" .env
        sed -i "s/your-super-secret-refresh-key/$JWT_REFRESH_SECRET/g" .env
        sed -i "s/your-super-secret-session-key/$SESSION_SECRET/g" .env
    fi
    
    print_success "Environment configured"
}

install_project_dependencies() {
    print_info "Installing project dependencies..."
    
    # Root
    npm install
    
    # Server
    cd server && npm install && cd ..
    
    # Mini-app
    cd mini-app && npm install && cd ..
    
    # Contracts
    cd contracts && npm install && cd ..
    
    print_success "Project dependencies installed"
}

start_services() {
    print_info "Starting services..."
    
    # Start Docker services
    docker-compose up -d
    
    # Wait for databases
    sleep 15
    
    # Run migrations
    npm run db:migrate
    
    print_success "Services started"
}

print_completion() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║            ZeaZDev Installation Complete! 🎉              ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Next steps:"
    echo "1. Configure your .env file with API keys"
    echo "2. Deploy smart contracts: cd contracts && npx hardhat run scripts/deploy.js"
    echo "3. Start backend: cd server && npm run dev"
    echo "4. Start mini-app: cd mini-app && expo start"
    echo ""
    echo "Documentation: https://github.com/ZeaZDev/ZeaZDev#readme"
    echo "Support: admin@zeaz.dev"
    echo ""
}

# Main execution
main() {
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║        ZeaZDev Automated Installation Script v1.0.0       ║"
    echo "║                  Full DevOps Enterprise                    ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    check_os
    check_requirements
    install_dependencies
    install_nodejs
    install_docker
    clone_repository
    setup_environment
    install_project_dependencies
    start_services
    print_completion
}

# Run main function
main
```

Make it executable and run:

```bash
chmod +x install.sh
./install.sh
```

---

**Last Updated**: 2025-01-09  
**Version**: 1.0.0  
**Maintained by**: PHIPHAT PHOEMSUK (ZeaZDev)
