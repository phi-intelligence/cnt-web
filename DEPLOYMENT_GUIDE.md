# CNT Media Platform - Deployment Guide

**Version:** 3.0  
**Date:** December 5, 2025

---

## Table of Contents

1. [Environment Setup](#1-environment-setup)
2. [Backend Deployment](#2-backend-deployment)
3. [Web Frontend Deployment](#3-web-frontend-deployment)
4. [Mobile App Deployment](#4-mobile-app-deployment)
5. [Database Setup](#5-database-setup)
6. [AWS Infrastructure](#6-aws-infrastructure)
7. [LiveKit Server Setup](#7-livekit-server-setup)
8. [Monitoring & Maintenance](#8-monitoring--maintenance)

---

## 1. Environment Setup

### 1.1 Backend Environment Variables

**File**: `backend/.env`

```env
# Database
DATABASE_URL=postgresql+asyncpg://user:password@host:5432/cntdb

# Security
SECRET_KEY=your_random_secret_key_here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# AWS S3
S3_BUCKET_NAME=cnt-web-media
CLOUDFRONT_URL=https://d126sja5o8ue54.cloudfront.net
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=eu-west-2

# LiveKit
LIVEKIT_WS_URL=wss://livekit.christnewtabernacle.com
LIVEKIT_HTTP_URL=https://livekit.christnewtabernacle.com
LIVEKIT_API_KEY=your_livekit_api_key
LIVEKIT_API_SECRET=your_livekit_api_secret

# AI Services
OPENAI_API_KEY=your_openai_api_key
DEEPGRAM_API_KEY=your_deepgram_api_key

# OAuth (Optional)
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret

# Payment Gateways (Optional)
STRIPE_SECRET_KEY=your_stripe_secret_key
STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key
PAYPAL_CLIENT_ID=your_paypal_client_id
PAYPAL_CLIENT_SECRET=your_paypal_client_secret

# Redis (Optional)
REDIS_URL=redis://localhost:6379

# CORS
CORS_ORIGINS=https://d1poes9tyirmht.amplifyapp.com,https://christnewtabernacle.com

# Environment
ENVIRONMENT=production
```

### 1.2 Web Frontend Environment (Amplify)

**Amplify Console → Environment Variables**:
```
API_BASE_URL=https://api.christnewtabernacle.com/api/v1
MEDIA_BASE_URL=https://d126sja5o8ue54.cloudfront.net
LIVEKIT_WS_URL=wss://livekit.christnewtabernacle.com
LIVEKIT_HTTP_URL=https://livekit.christnewtabernacle.com
WEBSOCKET_URL=wss://api.christnewtabernacle.com
```

### 1.3 Mobile App Environment

**File**: `mobile/frontend/.env`

```env
ENVIRONMENT=production
API_BASE_URL=https://api.christnewtabernacle.com/api/v1
WEBSOCKET_URL=wss://api.christnewtabernacle.com
MEDIA_BASE_URL=https://d126sja5o8ue54.cloudfront.net
LIVEKIT_WS_URL=wss://livekit.christnewtabernacle.com
LIVEKIT_HTTP_URL=https://livekit.christnewtabernacle.com
```

---

## 2. Backend Deployment

### 2.1 EC2 Server Setup

#### Initial Server Configuration
```bash
# SSH to EC2
ssh -i christnew.pem ubuntu@52.56.78.203

# Update system
sudo apt update && sudo apt upgrade -y

# Install Python 3.11
sudo apt install python3.11 python3.11-venv python3-pip -y

# Install FFmpeg
sudo apt install ffmpeg -y

# Install PostgreSQL client
sudo apt install postgresql-client -y

# Install system dependencies
sudo apt install build-essential libpq-dev -y
```

#### Application Setup
```bash
# Clone repository
cd ~
git clone https://github.com/your-org/cnt-web-deployment.git
cd cnt-web-deployment/backend

# Create virtual environment
python3.11 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Copy environment file
cp .env.example .env
# Edit .env with production values
nano .env
```

### 2.2 Systemd Service Configuration

**File**: `/etc/systemd/system/cnt-backend.service`

```ini
[Unit]
Description=CNT Backend API
After=network.target

[Service]
Type=notify
User=ubuntu
Group=ubuntu
WorkingDirectory=/home/ubuntu/cnt-web-deployment/backend
Environment="PATH=/home/ubuntu/cnt-web-deployment/backend/venv/bin"
ExecStart=/home/ubuntu/cnt-web-deployment/backend/venv/bin/gunicorn \
    -k uvicorn.workers.UvicornWorker \
    -w 4 \
    -b 0.0.0.0:8002 \
    --timeout 120 \
    --access-logfile /var/log/cnt-backend/access.log \
    --error-logfile /var/log/cnt-backend/error.log \
    app.main:app

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

#### Service Management
```bash
# Create log directory
sudo mkdir -p /var/log/cnt-backend
sudo chown ubuntu:ubuntu /var/log/cnt-backend

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable cnt-backend
sudo systemctl start cnt-backend

# Check status
sudo systemctl status cnt-backend

# View logs
sudo journalctl -u cnt-backend -f
```

### 2.3 Nginx Reverse Proxy

**File**: `/etc/nginx/sites-available/cnt-backend`

```nginx
server {
    listen 80;
    server_name api.christnewtabernacle.com;

    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.christnewtabernacle.com;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/api.christnewtabernacle.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.christnewtabernacle.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Proxy settings
    location / {
        proxy_pass http://127.0.0.1:8002;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # File upload size limit
    client_max_body_size 500M;
}
```

#### Enable Nginx Configuration
```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/cnt-backend /etc/nginx/sites-enabled/

# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

### 2.4 SSL Certificate Setup

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Obtain SSL certificate
sudo certbot --nginx -d api.christnewtabernacle.com

# Auto-renewal (already configured by Certbot)
sudo certbot renew --dry-run
```

### 2.5 Database Migrations

```bash
# Navigate to backend directory
cd /home/ubuntu/cnt-web-deployment/backend
source venv/bin/activate

# Run migrations
alembic upgrade head

# Create admin user (if needed)
python create_admin_user.py
```

### 2.6 Deployment Script

**File**: `backend/deploy.sh`

```bash
#!/bin/bash

# Pull latest code
git pull origin main

# Activate virtual environment
source venv/bin/activate

# Install/update dependencies
pip install -r requirements.txt

# Run database migrations
alembic upgrade head

# Restart service
sudo systemctl restart cnt-backend

# Check status
sudo systemctl status cnt-backend

echo "Deployment complete!"
```

---

## 3. Web Frontend Deployment

### 3.1 AWS Amplify Setup

#### Initial Setup
1. **Connect Repository**
   - Go to AWS Amplify Console
   - Click "New app" → "Host web app"
   - Connect GitHub repository
   - Select branch: `main`

2. **Build Settings**
   - Amplify auto-detects `amplify.yml`
   - Verify build configuration

3. **Environment Variables**
   - Add all required environment variables (see section 1.2)

4. **Deploy**
   - Amplify automatically builds and deploys
   - Domain: `https://d1poes9tyirmht.amplifyapp.com`

### 3.2 Build Configuration

**File**: `amplify.yml`

```yaml
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - git clone https://github.com/flutter/flutter.git -b stable
        - export PATH="$PATH:`pwd`/flutter/bin"
        - flutter precache
        - flutter doctor
    build:
      commands:
        - cd web/frontend
        - flutter pub get
        - flutter build web --release --no-source-maps \
            --dart-define=API_BASE_URL=$API_BASE_URL \
            --dart-define=MEDIA_BASE_URL=$MEDIA_BASE_URL \
            --dart-define=LIVEKIT_WS_URL=$LIVEKIT_WS_URL \
            --dart-define=LIVEKIT_HTTP_URL=$LIVEKIT_HTTP_URL \
            --dart-define=WEBSOCKET_URL=$WEBSOCKET_URL \
            --dart-define=ENVIRONMENT=production
  artifacts:
    baseDirectory: web/frontend/build/web
    files:
      - '**/*'
  cache:
    paths:
      - flutter/**/*
```

### 3.3 Custom Domain Setup

1. **Add Custom Domain**
   - Amplify Console → Domain management
   - Add domain: `christnewtabernacle.com`
   - Add subdomain: `www.christnewtabernacle.com`

2. **DNS Configuration (Route 53)**
   ```
   A     christnewtabernacle.com        → Amplify
   CNAME www.christnewtabernacle.com   → d1poes9tyirmht.amplifyapp.com
   ```

3. **SSL Certificate**
   - Amplify automatically provisions SSL certificate
   - Wait for DNS propagation (up to 48 hours)

### 3.4 Continuous Deployment

- **Automatic**: Push to `main` branch triggers build
- **Manual**: Amplify Console → Redeploy this version

---

## 4. Mobile App Deployment

### 4.1 Android Deployment

#### Build APK
```bash
cd mobile/frontend

# Ensure .env is configured for production
cat .env

# Build release APK
flutter build apk --release --dart-define=ENVIRONMENT=production

# Output: build/app/outputs/flutter-apk/app-release.apk
```

#### Build App Bundle (Google Play)
```bash
flutter build appbundle --release --dart-define=ENVIRONMENT=production

# Output: build/app/outputs/bundle/release/app-release.aab
```

#### Google Play Console
1. Create app listing
2. Upload app bundle
3. Complete store listing
4. Submit for review

### 4.2 iOS Deployment

#### Build iOS App
```bash
cd mobile/frontend

# Ensure .env is configured for production
cat .env

# Build iOS app
flutter build ios --release --dart-define=ENVIRONMENT=production
```

#### Xcode Configuration
1. Open `ios/Runner.xcworkspace` in Xcode
2. Configure signing & capabilities
3. Select "Any iOS Device"
4. Product → Archive

#### TestFlight/App Store
1. Upload to App Store Connect
2. TestFlight testing
3. Submit for App Store review

---

## 5. Database Setup

### 5.1 AWS RDS PostgreSQL

#### RDS Instance Configuration
```
Engine: PostgreSQL 14.x
Instance Class: db.t3.medium (or higher)
Storage: 100 GB SSD (auto-scaling enabled)
Multi-AZ: No (for cost savings) / Yes (for production)
Public Access: No
VPC: Same as EC2 instance
Security Group: Allow 5432 from EC2 security group
```

#### Database Creation
```sql
-- Connect to RDS
psql -h cntdb.c9gukkkmamkh.eu-west-2.rds.amazonaws.com -U postgres

-- Create database
CREATE DATABASE cntdb;

-- Create user
CREATE USER cntuser WITH PASSWORD 'secure_password';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE cntdb TO cntuser;
```

### 5.2 Database Initialization

```bash
# On EC2 server
cd /home/ubuntu/cnt-web-deployment/backend
source venv/bin/activate

# Run initialization script
python init_db.py

# This creates:
# - All 21 tables
# - Default categories
# - Admin user
# - Holy Bible document
```

### 5.3 Database Backup

#### Automated Backup (RDS)
- RDS automatic backups enabled
- Retention period: 7 days
- Backup window: 03:00-04:00 UTC

#### Manual Backup
```bash
# Dump database
pg_dump -h cntdb.c9gukkkmamkh.eu-west-2.rds.amazonaws.com \
        -U cntuser -d cntdb > backup_$(date +%Y%m%d).sql

# Restore database
psql -h cntdb.c9gukkkmamkh.eu-west-2.rds.amazonaws.com \
     -U cntuser -d cntdb < backup_20251205.sql
```

---

## 6. AWS Infrastructure

### 6.1 S3 Bucket Setup

#### Create Bucket
```bash
aws s3 mb s3://cnt-web-media --region eu-west-2
```

#### Apply Bucket Policy
```bash
aws s3api put-bucket-policy \
    --bucket cnt-web-media \
    --policy file://s3-bucket-policy.json
```

#### Apply CORS Configuration
```bash
aws s3api put-bucket-cors \
    --bucket cnt-web-media \
    --cors-configuration file://s3-cors-config.json
```

### 6.2 CloudFront Distribution

#### Create Distribution
1. AWS Console → CloudFront → Create Distribution
2. Origin: `cnt-web-media.s3.eu-west-2.amazonaws.com`
3. Origin Access: Origin Access Control (OAC)
4. Viewer Protocol Policy: Redirect HTTP to HTTPS
5. Allowed HTTP Methods: GET, HEAD, OPTIONS
6. Cache Policy: CachingOptimized
7. Price Class: Use Only North America and Europe

#### Update S3 Bucket Policy
- Add CloudFront OAC to bucket policy
- Distribution ARN: `arn:aws:cloudfront::649159624630:distribution/E3ER061DLFYFK8`

### 6.3 Route 53 DNS

#### DNS Records
```
A     christnewtabernacle.com        → Amplify (alias)
CNAME www.christnewtabernacle.com   → d1poes9tyirmht.amplifyapp.com
CNAME api.christnewtabernacle.com   → EC2 Public IP
CNAME livekit.christnewtabernacle.com → LiveKit Server
```

---

## 7. LiveKit Server Setup

### 7.1 LiveKit Installation

```bash
# Install LiveKit
curl -sSL https://get.livekit.io | bash

# Create configuration file
sudo nano /etc/livekit.yaml
```

### 7.2 LiveKit Configuration

**File**: `/etc/livekit.yaml`

```yaml
port: 7880
rtc:
  port_range_start: 50000
  port_range_end: 60000
  use_external_ip: true
redis:
  address: localhost:6379
keys:
  your_api_key: your_api_secret
```

### 7.3 LiveKit Systemd Service

**File**: `/etc/systemd/system/livekit.service`

```ini
[Unit]
Description=LiveKit Server
After=network.target

[Service]
Type=simple
User=livekit
ExecStart=/usr/local/bin/livekit-server --config /etc/livekit.yaml
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable livekit
sudo systemctl start livekit
```

---

## 8. Monitoring & Maintenance

### 8.1 Log Monitoring

#### Backend Logs
```bash
# Service logs
sudo journalctl -u cnt-backend -f

# Access logs
tail -f /var/log/cnt-backend/access.log

# Error logs
tail -f /var/log/cnt-backend/error.log
```

#### Nginx Logs
```bash
# Access logs
tail -f /var/log/nginx/access.log

# Error logs
tail -f /var/log/nginx/error.log
```

### 8.2 Performance Monitoring

#### System Resources
```bash
# CPU and memory
htop

# Disk usage
df -h

# Database connections
psql -h cntdb.c9gukkkmamkh.eu-west-2.rds.amazonaws.com \
     -U cntuser -d cntdb \
     -c "SELECT count(*) FROM pg_stat_activity;"
```

### 8.3 Maintenance Tasks

#### Weekly Tasks
- Check disk space
- Review error logs
- Monitor database size
- Check S3 storage costs

#### Monthly Tasks
- Update dependencies
- Security patches
- Database optimization
- Backup verification

---

**Document Status**: Complete deployment guide for CNT Media Platform
