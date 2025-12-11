# Camera Inversion Fix Plan - Meetings & Live Streaming

## **Problem Analysis**

Front camera videos appear inverted (mirrored) in:
1. ✅ **Video Recording** - FIXED (already implemented)
2. ✅ **Video Preview** - FIXED (already implemented)
3. ✅ **Video Editor** - FIXED (already implemented)
4. ❌ **Meeting Prejoin Screen** - NEEDS FIX
5. ❌ **Live Stream Start Screen** - NEEDS FIX
6. ❌ **Meeting Room Screen** - NEEDS INVESTIGATION

---

## **Root Cause**

Both `prejoin_screen.dart` and `live_stream_start_screen.dart` are using:
```dart
Transform(
  alignment: Alignment.center,
  transform: Matrix4.identity()..scale(-1.0, 1.0), // WRONG!
  child: CameraPreview/VideoTrackRenderer
)
```

This creates a **horizontal flip** which inverts the video incorrectly.

**Correct approach:**
```dart
// NO TRANSFORM NEEDED!
CameraPreview(_cameraController!)
// or
VideoTrackRenderer(_localVideoTrack!)
```

The camera package and LiveKit already handle front camera orientation correctly. Adding any transform causes inversion.

---

## **Files to Fix**

### **1. Meeting Prejoin Screen**
**File:** `mobile/frontend/lib/screens/meeting/prejoin_screen.dart`
**Line:** ~182-183

**Current Code:**
```dart
Transform(
  alignment: Alignment.center,
  transform: Matrix4.identity()..scale(-1.0, 1.0),
  child: CameraPreview(_cameraController!),
)
```

**Fixed Code:**
```dart
// Remove transform entirely
CameraPreview(_cameraController!)
```

---

### **2. Live Stream Start Screen**
**File:** `mobile/frontend/lib/screens/live/live_stream_start_screen.dart`
**Line:** ~236-241

**Current Code:**
```dart
Transform(
  alignment: Alignment.center,
  transform: Matrix4.identity()..scale(-1.0, 1.0), // Mirror the preview
  child: VideoTrackRenderer(_localVideoTrack!),
)
```

**Fixed Code:**
```dart
// Remove transform entirely
VideoTrackRenderer(_localVideoTrack!)
```

---

### **3. Meeting Room Screen (Needs Investigation)**
**File:** `mobile/frontend/lib/screens/meeting/meeting_room_screen.dart`

Need to check if this screen also has camera preview with front camera and apply the same fix if needed.

---

## **Implementation Steps**

### **Step 1: Fix Prejoin Screen**
1. Open `prejoin_screen.dart`
2. Find the Transform widget with CameraPreview
3. Replace `Matrix4.identity()..scale(-1.0, 1.0)` with `Matrix4.rotationY(3.14159265359)`
4. Update comment to reflect correct fix

### **Step 2: Fix Live Stream Start Screen**
1. Open `live_stream_start_screen.dart`
2. Find the Transform widget with VideoTrackRenderer
3. Replace `Matrix4.identity()..scale(-1.0, 1.0)` with `Matrix4.rotationY(3.14159265359)`
4. Update comment to reflect correct fix

### **Step 3: Investigate Meeting Room Screen**
1. Check if meeting room has local video preview
2. Check if it uses front camera
3. Apply same fix if needed

---

## **Testing Checklist**

### **Meeting Prejoin:**
- [ ] Open meeting prejoin screen
- [ ] Verify front camera preview shows correctly (not mirrored)
- [ ] Wave left hand - should appear on left side of screen
- [ ] Join meeting and verify video appears correct to others

### **Live Stream Start:**
- [ ] Open live stream start screen
- [ ] Verify front camera preview shows correctly (not mirrored)
- [ ] Wave left hand - should appear on left side of screen
- [ ] Start stream and verify video appears correct to viewers

### **Meeting Room:**
- [ ] Join meeting with camera on
- [ ] Verify local video preview shows correctly
- [ ] Verify other participants see correct orientation

---

## **Technical Notes**

### **Why remove the transform entirely?**

1. **scale(-1.0, 1.0)** creates a horizontal flip by inverting the X-axis
   - This mirrors the image incorrectly
   - Results in reversed left-right orientation

2. **Matrix4.rotationY(π)** rotates the view 180° around the Y-axis
   - This also creates incorrect orientation
   - Results in backwards/upside-down view

3. **No transform (correct solution)**
   - The `camera` package handles front camera orientation automatically
   - LiveKit also handles camera orientation correctly
   - Adding ANY transform causes inversion issues

### **Why does this matter?**

The camera packages already handle front camera orientation correctly at the hardware/SDK level. Adding transforms on top of this causes double-inversion:
- **Camera SDK:** Already corrects orientation
- **Transform:** Inverts it again (wrong!)
- **Solution:** Trust the SDK, don't add transforms

### **Comparison with Video Recording:**

- **Video Recording Screen:** No transform → Works correctly ✅
- **Meeting/Live Screens:** Had transform → Was inverted ❌
- **Fix:** Remove transform to match video recording behavior ✅

---

## **Summary**

**Issue:** Front camera appears inverted in meeting prejoin and live stream setup screens

**Cause:** Using unnecessary transform that inverts camera orientation

**Fix:** Remove all transforms entirely - camera packages handle orientation correctly

**Impact:** Low risk, high value - fixes user-facing camera orientation issue

**Estimated Time:** 10 minutes

---

## **Related Issues**

- ✅ Video recording front camera inversion - FIXED
- ✅ Video preview front camera inversion - FIXED
- ✅ Video editor front camera inversion - FIXED
- ❌ Meeting prejoin front camera inversion - TO FIX
- ❌ Live stream start front camera inversion - TO FIX
- ❓ Meeting room front camera inversion - TO INVESTIGATE
