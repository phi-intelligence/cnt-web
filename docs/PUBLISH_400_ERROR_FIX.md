# Publish 400 Error - Debugging & Fix

## **Error**
```
FAILED TO UPLOAD HTTP ERROR 400
```

## **Root Cause Analysis**

The 400 error during publish can be caused by several issues:

1. **File doesn't exist** - Edited video path is invalid
2. **File path issue** - Temporary file was deleted
3. **Backend validation** - File size, type, or format issue
4. **Missing authentication** - Auth headers not sent
5. **Backend endpoint issue** - Upload endpoint not working

---

## **Changes Made**

### **1. Better Error Reporting** ✅

**File:** `mobile/frontend/lib/services/api_service.dart`

Added detailed error messages to show the actual backend error:

```dart
// Get error details from response
final errorResponse = await http.Response.fromStream(streamedResponse);
String errorMessage = 'HTTP ${streamedResponse.statusCode}';
try {
  final errorData = json.decode(errorResponse.body);
  if (errorData is Map && errorData.containsKey('detail')) {
    errorMessage += ': ${errorData['detail']}';
  } else {
    errorMessage += ': ${errorResponse.body}';
  }
} catch (_) {
  errorMessage += ': ${errorResponse.body}';
}

print('❌ Upload failed: $errorMessage');
throw Exception('Failed to upload file: $errorMessage');
```

### **2. File Existence Check** ✅

Added validation before upload:

```dart
// Verify file exists before uploading
final fileToUpload = File(filePath);
if (!await fileToUpload.exists()) {
  throw Exception('File not found at path: $filePath');
}

final fileSize = await fileToUpload.length();
print('📤 Uploading file: $filePath (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)');
```

---

## **Testing Steps**

### **1. Rebuild the App**
```bash
cd mobile/frontend
flutter clean
flutter pub get
flutter run
```

### **2. Test Publish Flow**

**Without Editing:**
1. Record a video
2. Click Publish
3. Check console logs for detailed error

**With Editing:**
1. Record a video
2. Edit (trim/rotate)
3. Click Publish
4. Check console logs

### **3. Check Console Output**

Look for these logs:
```
📤 Uploading file: /path/to/video.mp4 (XX.XX MB)
❌ Upload failed: HTTP 400: <detailed error message>
```

Or:
```
❌ Upload error: File not found at path: /path/to/video.mp4
```

---

## **Common 400 Error Causes & Solutions**

### **1. File Not Found**
**Error:** `File not found at path: ...`

**Solution:**
- Edited video file was deleted
- Check if `/tmp/video_editing/` files are being cleaned up too early
- Ensure edited video is saved to persistent location

### **2. File Too Large**
**Error:** `HTTP 400: File size exceeds maximum allowed`

**Solution:**
- Backend has file size limit (check nginx/FastAPI config)
- Compress video before upload
- Increase backend limits

### **3. Invalid File Type**
**Error:** `HTTP 400: Invalid file type`

**Solution:**
- Backend expects specific video formats
- Check backend upload endpoint validation
- Ensure video is .mp4 format

### **4. Missing Auth Token**
**Error:** `HTTP 401: Unauthorized` or `HTTP 400: Invalid token`

**Solution:**
- Check if user is logged in
- Verify auth token is being sent in headers
- Token might have expired

### **5. Backend Endpoint Issue**
**Error:** `HTTP 404: Not Found` or `HTTP 500: Internal Server Error`

**Solution:**
- Check backend logs
- Verify upload endpoint is working
- Restart backend service

---

## **Next Steps**

1. **Rebuild and test** the app to see the detailed error message
2. **Share the console logs** showing the exact 400 error details
3. **Check backend logs** if needed:
   ```bash
   ssh -i christnew.pem ubuntu@52.56.78.203 "docker logs --tail 100 backend"
   ```

---

## **Temporary Workaround**

If the issue is with edited videos, try publishing without editing first:

1. Record video
2. **Skip editing** - go straight to publish
3. If this works, the issue is with the edited video file path

---

## **Backend Logs to Check**

```bash
# Check backend logs for upload errors
ssh -i christnew.pem ubuntu@52.56.78.203 "docker logs --tail 100 backend | grep -i 'upload\|error\|400'"

# Check nginx logs
ssh -i christnew.pem ubuntu@52.56.78.203 "tail -100 /var/log/nginx/error.log"
```

---

**Status:** Awaiting detailed error message from console logs after rebuild
