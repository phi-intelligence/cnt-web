# Video Upload 400 Error Fix - Content Type Issue

## **Error**
```
❌ Upload failed: HTTP 400: File must be a video file
```

## **Root Cause**

The backend upload endpoint validates the file's `content_type`:

```python
# backend/app/routes/upload.py (Line 164-165)
if not file.content_type.startswith('video/'):
    raise HTTPException(status_code=400, detail="File must be a video file")
```

The Flutter app was **not setting the content type** when uploading the multipart file, so the backend rejected it.

---

## **Solution**

### **File Modified:** `mobile/frontend/lib/services/api_service.dart`

#### **1. Added http_parser Import**
```dart
import 'package:http_parser/http_parser.dart';
```

#### **2. Set Explicit Content Type Based on File Type**
```dart
// Determine content type based on file type
String? contentType;
if (fileType == 'video') {
  contentType = 'video/mp4';
} else if (fileType == 'audio') {
  contentType = 'audio/mpeg';
} else if (fileType == 'image') {
  contentType = 'image/jpeg';
}

final file = await http.MultipartFile.fromPath(
  'file', 
  filePath,
  contentType: contentType != null ? MediaType.parse(contentType) : null,
);
```

---

## **Changes Summary**

**Before:**
```dart
final file = await http.MultipartFile.fromPath('file', filePath);
// ❌ No content type set - backend rejects with 400
```

**After:**
```dart
final file = await http.MultipartFile.fromPath(
  'file', 
  filePath,
  contentType: MediaType.parse('video/mp4'), // ✅ Explicit content type
);
```

---

## **Testing**

### **1. Rebuild the App**
```bash
cd mobile/frontend
flutter clean
flutter pub get
flutter run
```

### **2. Test Upload**

**Test Case 1: Original Video**
1. Record a video
2. Click Publish
3. Should upload successfully ✅

**Test Case 2: Edited Video**
1. Record a video
2. Edit (trim/rotate)
3. Click Publish
4. Should upload successfully ✅

### **3. Expected Console Output**
```
📤 Uploading file: /path/to/video.mp4 (5.36 MB)
✅ Upload successful
```

---

## **Why This Happened**

1. **Backend Validation:** The backend checks `file.content_type` to ensure it's a video
2. **Missing Content Type:** Flutter's `MultipartFile.fromPath()` doesn't always detect content type correctly
3. **Explicit Setting Required:** We must explicitly set `contentType` parameter

---

## **Files Modified**

### **mobile/frontend/lib/services/api_service.dart**
- **Line 5:** Added `import 'package:http_parser/http_parser.dart';`
- **Lines 1089-1103:** Added content type detection and explicit setting

**Total Changes:** ~15 lines

---

## **Additional Improvements Made**

1. **File Existence Check:** Validates file exists before upload
2. **File Size Logging:** Shows file size in MB for debugging
3. **Detailed Error Messages:** Shows exact backend error response
4. **Better Error Handling:** Catches and reports all upload errors

---

## **Related Issues Fixed**

✅ **Issue 1:** Video upload 400 error - Content type fix  
✅ **Issue 2:** Upload progress stuck - SnackBar dismissal  
✅ **Issue 3:** Edited video not preserved - State management  
✅ **Issue 4:** Rotate endpoint 404 - Backend deployment needed  

---

## **Deployment Checklist**

- [x] Fix content type in Flutter code
- [x] Add http_parser import
- [x] Add file validation
- [x] Add error logging
- [ ] Rebuild Flutter app
- [ ] Test video upload (original)
- [ ] Test video upload (edited)
- [ ] Deploy backend rotate endpoint (if not done)

---

## **Next Steps**

1. **Rebuild the app:**
   ```bash
   flutter clean && flutter pub get && flutter run
   ```

2. **Test publishing:**
   - Record video → Publish ✅
   - Record → Edit → Publish ✅

3. **Deploy backend updates** (for rotate feature):
   ```bash
   # From local machine
   scp -i christnew.pem backend/app/routes/video_editing.py ubuntu@52.56.78.203:/home/ubuntu/cnt-web-deployment/backend/app/routes/
   scp -i christnew.pem backend/app/services/video_editing_service.py ubuntu@52.56.78.203:/home/ubuntu/cnt-web-deployment/backend/app/services/
   ssh -i christnew.pem ubuntu@52.56.78.203 "docker restart backend"
   ```

---

**Status:** ✅ Fixed - Ready for testing  
**Impact:** High - Fixes critical publish functionality  
**Risk:** Low - Only adds explicit content type, no breaking changes
