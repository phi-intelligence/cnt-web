# Backend Files Update Guide - Manual SSH Process

## Current Setup

- **EC2 Instance**: 52.56.78.203 (eu-west-2)
- **SSH Key**: `christnew.pem`
- **User**: ubuntu
- **Backend Path**: `~/cnt-web-deployment/backend/`
- **Containers**: Running from Docker images (not using docker-compose)

## Manual SSH Update Process

### Step 1: Transfer Files to EC2

#### Option A: Transfer Individual Files (SCP)

```bash
# Transfer a single file
scp -i christnew.pem backend/app/main.py ubuntu@52.56.78.203:~/cnt-web-deployment/backend/app/main.py

# Transfer a directory
scp -i christnew.pem -r backend/app/routes ubuntu@52.56.78.203:~/cnt-web-deployment/backend/app/

# Transfer multiple files
scp -i christnew.pem backend/app/main.py backend/app/config.py ubuntu@52.56.78.203:~/cnt-web-deployment/backend/app/
```

#### Option B: Transfer Entire Backend Directory (rsync - Recommended)

```bash
# Sync entire backend directory (excludes .env, venv, __pycache__)
rsync -avz --exclude 'venv' --exclude '__pycache__' --exclude '*.pyc' --exclude '.env' \
  -e "ssh -i christnew.pem" \
  backend/ ubuntu@52.56.78.203:~/cnt-web-deployment/backend/
```

#### Option C: Transfer from Local Machine

```bash
# From your local machine (in cnt-web-deployment directory)
cd /home/phi/Phi-Intelligence/cnt-web-deployment

# Transfer specific file
scp -i christnew.pem backend/app/main.py ubuntu@52.56.78.203:~/cnt-web-deployment/backend/app/main.py

# Transfer entire backend (excluding sensitive files)
rsync -avz --exclude 'venv' --exclude '__pycache__' --exclude '*.pyc' --exclude '.env' \
  -e "ssh -i christnew.pem" \
  backend/ ubuntu@52.56.78.203:~/cnt-web-deployment/backend/
```

### Step 2: SSH into EC2 Instance

```bash
ssh -i christnew.pem ubuntu@52.56.78.203
```

### Step 3: Navigate to Backend Directory

```bash
cd ~/cnt-web-deployment/backend
```

### Step 4: Rebuild Docker Image (if code changes)

```bash
# Build new Docker image with updated code
docker build -t cnt-web-deployment_backend:latest .
```

**Note**: This step is required if you changed:
- Python dependencies (requirements.txt)
- Application code files
- Dockerfile

### Step 5: Restart Backend Container

```bash
# Stop and remove existing container
docker stop cnt-backend
docker rm cnt-backend

# Start new container with updated image
docker run -d \
  --name cnt-backend \
  --restart unless-stopped \
  -p 8000:8000 \
  --env-file .env \
  -v $(pwd):/app \
  cnt-web-deployment_backend:latest \
  uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 2
```

**Or use this simpler command (if code is mounted as volume):**

```bash
# If code changes don't require rebuilding (just Python files)
docker restart cnt-backend
```

### Step 6: Verify Deployment

```bash
# Check container status
docker ps | grep cnt-backend

# Check logs
docker logs cnt-backend --tail 50

# Test API health endpoint
curl http://localhost:8000/health
```

## Quick Update Script (One-Liner)

For quick updates of Python files (without dependency changes):

```bash
# From local machine
rsync -avz --exclude 'venv' --exclude '__pycache__' --exclude '*.pyc' --exclude '.env' \
  -e "ssh -i christnew.pem" \
  backend/ ubuntu@52.56.78.203:~/cnt-web-deployment/backend/ && \
ssh -i christnew.pem ubuntu@52.56.78.203 "cd ~/cnt-web-deployment/backend && docker restart cnt-backend"
```

## When to Rebuild vs Restart

### Rebuild Container (docker build) - Required When:
- ✅ Changed `requirements.txt` (dependencies)
- ✅ Changed `Dockerfile`
- ✅ Changed application code that requires container rebuild
- ✅ First time deployment

### Restart Container (docker restart) - Sufficient When:
- ✅ Changed Python files only (if code is mounted as volume)
- ✅ Changed configuration files
- ✅ Changed environment variables (need to recreate container with new env)

## Complete Update Process (Full Rebuild)

```bash
# 1. Transfer files
rsync -avz --exclude 'venv' --exclude '__pycache__' --exclude '*.pyc' --exclude '.env' \
  -e "ssh -i christnew.pem" \
  backend/ ubuntu@52.56.78.203:~/cnt-web-deployment/backend/

# 2. SSH and rebuild
ssh -i christnew.pem ubuntu@52.56.78.203 << 'EOF'
cd ~/cnt-web-deployment/backend
docker build -t cnt-web-deployment_backend:latest .
docker stop cnt-backend
docker rm cnt-backend
docker run -d \
  --name cnt-backend \
  --restart unless-stopped \
  -p 8000:8000 \
  --env-file .env \
  -v $(pwd):/app \
  cnt-web-deployment_backend:latest \
  uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 2
docker logs cnt-backend --tail 20
EOF
```

## Important Notes

1. **Never overwrite `.env` file** - It contains production secrets
2. **Backup before updating** - Consider backing up important files
3. **Test in staging first** - If possible, test changes before production
4. **Check logs after deployment** - Always verify logs for errors
5. **Database migrations** - If schema changes, run migrations separately:
   ```bash
   docker exec cnt-backend alembic upgrade head
   ```

## Troubleshooting

### Container won't start
```bash
# Check logs
docker logs cnt-backend

# Check if port is already in use
sudo netstat -tulpn | grep 8000

# Check container status
docker ps -a | grep cnt-backend
```

### Changes not reflected
- If code is mounted as volume, restart is enough
- If code is in image, rebuild is required
- Check if correct file was transferred
- Verify file permissions

### Permission issues
```bash
# Fix file permissions
ssh -i christnew.pem ubuntu@52.56.78.203 "cd ~/cnt-web-deployment/backend && sudo chown -R ubuntu:ubuntu ."
```

## Alternative: Git-Based Deployment (Future)

For automated deployments, you could:
1. Initialize git repository on EC2
2. Set up remote repository
3. Pull changes and rebuild:
   ```bash
   cd ~/cnt-web-deployment/backend
   git pull
   docker build -t cnt-web-deployment_backend:latest .
   docker restart cnt-backend
   ```

But for now, manual SSH/SCP is the current method.


