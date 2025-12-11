# Manual Deployment Commands (Docker)

## **Quick Deploy (Copy & Paste)**

### **Step 1: Update SERVER_IP and run from local machine**

```bash
# Set your server IP
SERVER_IP="your-server-ip-here"

# Set PEM key permissions
chmod 400 christnew.pem

# Upload files
scp -i christnew.pem backend/app/routes/video_editing.py ubuntu@$SERVER_IP:/home/ubuntu/cnt-web-deployment/backend/app/routes/
scp -i christnew.pem backend/app/services/video_editing_service.py ubuntu@$SERVER_IP:/home/ubuntu/cnt-web-deployment/backend/app/services/

# Restart Docker container
ssh -i christnew.pem ubuntu@$SERVER_IP "docker restart backend"
```

---

## **Detailed Steps**

### **1. Set PEM Key Permissions**
```bash
chmod 400 christnew.pem
```

### **2. Upload video_editing.py**
```bash
scp -i christnew.pem \
    backend/app/routes/video_editing.py \
    ubuntu@YOUR_SERVER_IP:/home/ubuntu/cnt-web-deployment/backend/app/routes/
```

### **3. Upload video_editing_service.py**
```bash
scp -i christnew.pem \
    backend/app/services/video_editing_service.py \
    ubuntu@YOUR_SERVER_IP:/home/ubuntu/cnt-web-deployment/backend/app/services/
```

### **4. Restart Docker Container**
```bash
ssh -i christnew.pem ubuntu@YOUR_SERVER_IP "docker restart backend"
```

### **5. Verify Container is Running**
```bash
ssh -i christnew.pem ubuntu@YOUR_SERVER_IP "docker ps | grep backend"
```

### **6. Check Logs**
```bash
ssh -i christnew.pem ubuntu@YOUR_SERVER_IP "docker logs --tail 50 backend"
```

---

## **If Container Name is Different**

Find the container name first:
```bash
ssh -i christnew.pem ubuntu@YOUR_SERVER_IP "docker ps"
```

Then restart with the correct name:
```bash
ssh -i christnew.pem ubuntu@YOUR_SERVER_IP "docker restart <container-name>"
```

---

## **Test After Deployment**

### **From Mobile App:**
1. Open video editor
2. Rotate a video
3. Should work without 404 error ✅

### **From Command Line:**
```bash
# Test rotate endpoint
curl -X POST http://YOUR_SERVER_IP:8002/api/v1/video-editing/rotate \
  -F "video_file=@test_video.mp4" \
  -F "degrees=90"
```

---

## **Troubleshooting**

### **Container not restarting:**
```bash
# Check container status
ssh -i christnew.pem ubuntu@YOUR_SERVER_IP "docker ps -a | grep backend"

# Check logs for errors
ssh -i christnew.pem ubuntu@YOUR_SERVER_IP "docker logs backend"

# If needed, stop and start
ssh -i christnew.pem ubuntu@YOUR_SERVER_IP "docker stop backend && docker start backend"
```

### **Files not updating:**
```bash
# Verify files were uploaded
ssh -i christnew.pem ubuntu@YOUR_SERVER_IP "ls -lh /home/ubuntu/cnt-web-deployment/backend/app/routes/video_editing.py"
ssh -i christnew.pem ubuntu@YOUR_SERVER_IP "ls -lh /home/ubuntu/cnt-web-deployment/backend/app/services/video_editing_service.py"

# Check file timestamps
ssh -i christnew.pem ubuntu@YOUR_SERVER_IP "stat /home/ubuntu/cnt-web-deployment/backend/app/routes/video_editing.py"
```

---

## **Using the Automated Script**

```bash
# Edit the script first
nano DEPLOY_BACKEND_UPDATES.sh

# Update line 9: SERVER_IP="your-actual-ip"

# Make executable
chmod +x DEPLOY_BACKEND_UPDATES.sh

# Run
./DEPLOY_BACKEND_UPDATES.sh
```
