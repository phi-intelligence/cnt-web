# Video Editor Fix Implementation Plan

**Date:** December 10, 2025  
**Priority:** HIGH  
**Scope:** Mobile Application Video Editor Fixes

---

## Issues Identified

### 1. **Front Camera Video Inversion Issue** 🔴 CRITICAL
**Problem:** Videos recorded with front camera appear mirrored/inverted in preview and editor screens (left hand appears on right side)

**Root Cause:**
- Front-facing camera naturally mirrors the preview during recording (like a mirror)
- After recording, the saved video file retains this mirrored orientation
- Video player shows the video as-is without applying mirror transformation

**Current Behavior:**
- ✅ Recording preview: Correct (mirrored like a selfie camera)
- ❌ Video preview screen: Inverted (left/right flipped)
- ❌ Video editor screen: Inverted (left/right flipped)
- ❌ Published video: Inverted (left/right flipped)

**Expected Behavior:**
- ✅ Recording preview: Mirrored (natural selfie view)
- ✅ Video preview screen: Correct orientation (unmirrored)
- ✅ Video editor screen: Correct orientation (unmirrored)
- ✅ Published video: Correct orientation (unmirrored)

---

### 2. **Video Editor Trim Function Not Working Properly** 🔴 CRITICAL
**Problem:** Trim functionality is not applying changes correctly

**Current Issues:**
- Trim sliders may not be properly synchronized with video playback
- Edited video path not being properly updated after trim
- Potential issues with start/end time validation
- No visual feedback during trim operation

---

### 3. **Remove Audio / Add Audio Features Not Fully Implemented** 🔴 CRITICAL
**Problem:** Audio manipulation features are partially implemented but not fully functional

**Current Issues:**
- Remove audio button exists but may not properly update video
- Add audio file picker works but edited video may not reload properly
- State management issues (audioRemoved, audioFilePath flags)
- No proper validation of audio file formats
- Edited video not being reloaded in player after audio changes

---

### 4. **Rotate Screen Feature Missing** 🟡 MEDIUM
**Problem:** Video rotation feature is partially implemented but not exposed in UI

**Current State:**
- Rotation state variable exists (`_rotation`)
- Transform.rotate widget is present in video preview
- No UI controls to trigger rotation
- No save/apply rotation functionality

---

## Implementation Plan

---

## **PHASE 1: Front Camera Inversion Fix** 🔴

### Files to Modify:
1. `mobile/frontend/lib/screens/creation/video_recording_screen.dart`
2. `mobile/frontend/lib/screens/creation/video_preview_screen.dart`
3. `mobile/frontend/lib/screens/editing/video_editor_screen.dart`
4. `backend/app/services/video_editing_service.py` (add flip/mirror function)
5. `backend/app/routes/video_editing.py` (add flip endpoint)

### Solution Approach:

#### **Option A: Detect and Auto-Flip Front Camera Videos (RECOMMENDED)**

**Step 1:** Detect front camera usage during recording
```dart
// In video_recording_screen.dart
bool _isFrontCamera = false;

Future<void> _initializeCamera() async {
  final cameras = await availableCameras();
  if (cameras.isNotEmpty) {
    _camera = cameras.first;
    _isFrontCamera = _camera!.lensDirection == CameraLensDirection.front;
    // ... rest of initialization
  }
}
```

**Step 2:** Pass camera orientation metadata to preview
```dart
// When navigating to preview
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => VideoPreviewScreen(
      videoUri: video.path,
      source: 'camera',
      duration: _recordingDuration,
      fileSize: fileSize,
      isFrontCamera: _isFrontCamera, // NEW PARAMETER
    ),
  ),
);
```

**Step 3:** Apply horizontal flip transformation in preview/editor
```dart
// In video_preview_screen.dart and video_editor_screen.dart
Widget build(BuildContext context) {
  return Transform(
    alignment: Alignment.center,
    transform: widget.isFrontCamera 
        ? Matrix4.rotationY(3.14159) // Flip horizontally
        : Matrix4.identity(),
    child: VideoPlayer(_controller!),
  );
}
```

**Step 4:** Add backend flip endpoint for permanent fix
```python
# backend/app/services/video_editing_service.py
def flip_video_horizontal(self, input_path: str) -> Optional[str]:
    """Flip video horizontally (mirror effect)"""
    try:
        output_path = self._get_output_path(input_path, "flipped")
        
        # FFmpeg command to flip horizontally
        (
            ffmpeg
            .input(input_path)
            .filter('hflip')  # Horizontal flip filter
            .output(output_path, vcodec='libx264', acodec='copy')
            .overwrite_output()
            .run(capture_stdout=True, capture_stderr=True)
        )
        
        return output_path
    except Exception as e:
        print(f"Error flipping video: {e}")
        return None
```

**Step 5:** Auto-apply flip when publishing front camera videos
```dart
// In video_preview_screen.dart _handlePublish()
if (widget.isFrontCamera) {
  _showUploadProgress('Correcting camera orientation...');
  final flippedPath = await api.flipVideo(widget.videoUri);
  if (flippedPath != null) {
    videoPathToUpload = flippedPath;
  }
}
```

#### **Option B: Manual Flip Toggle (Alternative)**
Add a flip button in video editor for user control

---

## **PHASE 2: Fix Trim Functionality** 🔴

### Files to Modify:
1. `mobile/frontend/lib/screens/editing/video_editor_screen.dart`
2. `mobile/frontend/lib/services/video_editing_service.dart`

### Implementation Steps:

**Step 1:** Fix trim validation
```dart
// In video_editor_screen.dart
Future<void> _applyTrim() async {
  // Validate trim range
  if (_trimStart >= _trimEnd) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Start time must be less than end time'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
  
  // Validate minimum duration (at least 1 second)
  if ((_trimEnd - _trimStart).inSeconds < 1) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trimmed video must be at least 1 second long'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
  
  setState(() {
    _isEditing = true;
    _hasError = false;
  });
  
  try {
    final outputPath = await _editingService.trimVideo(
      widget.videoPath,
      _trimStart,
      _trimEnd,
      onProgress: (progress) {
        // Show progress indicator
        print('Trim progress: $progress%');
      },
      onError: (error) {
        setState(() {
          _isEditing = false;
          _hasError = true;
          _errorMessage = error;
        });
      },
    );

    if (outputPath != null && mounted) {
      setState(() {
        _editedVideoPath = outputPath;
        _isEditing = false;
      });
      
      // Reload player with trimmed video
      await _reloadPlayer(outputPath);
      
      // Update trim markers to match new video duration
      _trimStart = Duration.zero;
      _trimEnd = _controller!.value.duration;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Video trimmed successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      throw Exception('Trim operation returned null');
    }
  } catch (e) {
    setState(() {
      _isEditing = false;
      _hasError = true;
      _errorMessage = e.toString();
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to trim video: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

**Step 2:** Fix _reloadPlayer to properly dispose and reinitialize
```dart
Future<void> _reloadPlayer(String path) async {
  try {
    // Pause and dispose current controller
    if (_controller != null) {
      await _controller!.pause();
      _controller!.removeListener(_videoListener);
      await _controller!.dispose();
    }
    
    // Initialize new controller with edited video
    final isNetwork = path.startsWith('http');
    if (isNetwork) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(path));
    } else {
      _controller = VideoPlayerController.file(File(path));
    }
    
    await _controller!.initialize();
    _controller!.addListener(_videoListener);
    
    setState(() {
      _videoDuration = _controller!.value.duration;
      _currentPosition = Duration.zero;
      _isPlaying = false;
    });
    
    print('✓ Video player reloaded successfully with duration: ${_videoDuration.inSeconds}s');
  } catch (e) {
    print('Error reloading player: $e');
    setState(() {
      _hasError = true;
      _errorMessage = 'Failed to reload video: $e';
    });
  }
}
```

**Step 3:** Add visual feedback during trim
```dart
// Show loading overlay during trim operation
if (_isEditing)
  Container(
    color: Colors.black54,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.warmBrown),
          const SizedBox(height: 16),
          Text(
            'Trimming video...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    ),
  ),
```

---

## **PHASE 3: Fix Remove/Add Audio Features** 🔴

### Files to Modify:
1. `mobile/frontend/lib/screens/editing/video_editor_screen.dart`
2. `mobile/frontend/lib/services/video_editing_service.dart`

### Implementation Steps:

**Step 1:** Fix Remove Audio function
```dart
Future<void> _removeAudio() async {
  // Get current video path (use edited version if available)
  final inputPath = _editedVideoPath ?? widget.videoPath;
  
  setState(() {
    _isEditing = true;
    _hasError = false;
  });

  try {
    final outputPath = await _editingService.removeAudioTrack(
      inputPath,
      onProgress: (progress) {
        print('Remove audio progress: $progress%');
      },
      onError: (error) {
        throw Exception(error);
      },
    );

    if (outputPath != null && mounted) {
      setState(() {
        _editedVideoPath = outputPath;
        _audioRemoved = true;
        _audioFilePath = null; // Clear any added audio
        _isEditing = false;
      });
      
      // Reload player with audio-removed video
      await _reloadPlayer(outputPath);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Audio removed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      throw Exception('Remove audio operation returned null');
    }
  } catch (e) {
    setState(() {
      _isEditing = false;
      _hasError = true;
      _errorMessage = e.toString();
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove audio: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

**Step 2:** Fix Add Audio function with file validation
```dart
Future<void> _selectAudioFile() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final audioPath = result.files.single.path!;
      final audioFile = File(audioPath);
      
      // Validate file exists
      if (!await audioFile.exists()) {
        throw Exception('Selected audio file not found');
      }
      
      // Validate file size (max 50MB)
      final fileSize = await audioFile.length();
      if (fileSize > 50 * 1024 * 1024) {
        throw Exception('Audio file too large (max 50MB)');
      }
      
      await _addAudioTrack(audioPath);
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error selecting audio: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Future<void> _addAudioTrack(String audioPath) async {
  // Get current video path (use edited version if available)
  final inputPath = _editedVideoPath ?? widget.videoPath;
  
  setState(() {
    _isEditing = true;
    _hasError = false;
  });

  try {
    final outputPath = await _editingService.addAudioTrack(
      inputPath,
      audioPath,
      onProgress: (progress) {
        print('Add audio progress: $progress%');
      },
      onError: (error) {
        throw Exception(error);
      },
    );

    if (outputPath != null && mounted) {
      setState(() {
        _editedVideoPath = outputPath;
        _audioFilePath = audioPath;
        _audioRemoved = false; // Clear removed flag
        _isEditing = false;
      });
      
      // Reload player with new audio
      await _reloadPlayer(outputPath);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Audio track added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      throw Exception('Add audio operation returned null');
    }
  } catch (e) {
    setState(() {
      _isEditing = false;
      _hasError = true;
      _errorMessage = e.toString();
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add audio: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

**Step 3:** Add Reset to Original Audio button
```dart
// In _buildMusicPanel()
if (_audioFilePath != null || _audioRemoved)
  TextButton.icon(
    onPressed: () async {
      setState(() {
        _isEditing = true;
      });
      
      // Reload original video
      await _reloadPlayer(widget.videoPath);
      
      setState(() {
        _audioFilePath = null;
        _audioRemoved = false;
        _editedVideoPath = null;
        _isEditing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Reset to original audio'),
          backgroundColor: Colors.blue,
        ),
      );
    },
    icon: Icon(Icons.refresh, size: 16),
    label: Text('Reset to Original'),
  ),
```

---

## **PHASE 4: Add Rotate Feature** 🟡

### Files to Modify:
1. `mobile/frontend/lib/screens/editing/video_editor_screen.dart`
2. `backend/app/services/video_editing_service.py`
3. `backend/app/routes/video_editing.py`

### Implementation Steps:

**Step 1:** Add Rotate tab to TabBar
```dart
// Update TabController length from 3 to 4
_tabController = TabController(length: 4, vsync: this); // Trim, Audio, Text, Rotate

// In _buildBottomToolbar()
TabBar(
  controller: _tabController,
  tabs: const [
    Tab(icon: Icon(Icons.content_cut), text: 'Trim'),
    Tab(icon: Icon(Icons.music_note), text: 'Audio'),
    Tab(icon: Icon(Icons.text_fields), text: 'Text'),
    Tab(icon: Icon(Icons.rotate_right), text: 'Rotate'), // NEW TAB
  ],
),
```

**Step 2:** Add Rotate panel UI
```dart
Widget _buildRotatePanel() {
  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.warmBrown.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.rotate_right, color: AppColors.warmBrown, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              'Rotate Video',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Current rotation display
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderPrimary),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.rotate_right, color: AppColors.warmBrown),
              const SizedBox(width: 8),
              Text(
                'Current Rotation: $_rotation°',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Rotation buttons
        Row(
          children: [
            Expanded(
              child: _buildRotateButton(
                label: 'Rotate Left',
                icon: Icons.rotate_left,
                degrees: -90,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRotateButton(
                label: 'Rotate Right',
                icon: Icons.rotate_right,
                degrees: 90,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Reset and Apply buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _rotation != 0 ? () {
                  setState(() {
                    _rotation = 0;
                  });
                } : null,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warmBrown,
                  side: BorderSide(color: AppColors.warmBrown),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _rotation != 0 && !_isEditing ? _applyRotation : null,
                icon: Icon(_isEditing ? Icons.hourglass_empty : Icons.check_circle, size: 16),
                label: Text(_isEditing ? 'Processing...' : 'Apply'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warmBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildRotateButton({
  required String label,
  required IconData icon,
  required int degrees,
}) {
  return ElevatedButton.icon(
    onPressed: () {
      setState(() {
        _rotation = (_rotation + degrees) % 360;
        if (_rotation < 0) _rotation += 360;
      });
    },
    icon: Icon(icon, size: 18),
    label: Text(label),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.warmBrown,
      side: BorderSide(color: AppColors.borderPrimary),
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
```

**Step 3:** Add rotation apply function
```dart
Future<void> _applyRotation() async {
  if (_rotation == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No rotation to apply')),
    );
    return;
  }
  
  final inputPath = _editedVideoPath ?? widget.videoPath;
  
  setState(() {
    _isEditing = true;
    _hasError = false;
  });

  try {
    final outputPath = await _editingService.rotateVideo(
      inputPath,
      _rotation,
      onProgress: (progress) {
        print('Rotate progress: $progress%');
      },
      onError: (error) {
        throw Exception(error);
      },
    );

    if (outputPath != null && mounted) {
      setState(() {
        _editedVideoPath = outputPath;
        _rotation = 0; // Reset rotation after applying
        _isEditing = false;
      });
      
      await _reloadPlayer(outputPath);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Video rotated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      throw Exception('Rotate operation returned null');
    }
  } catch (e) {
    setState(() {
      _isEditing = false;
      _hasError = true;
      _errorMessage = e.toString();
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to rotate video: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

**Step 4:** Add rotate function to video_editing_service.dart
```dart
/// Rotate video by specified degrees (90, 180, 270)
Future<String?> rotateVideo(
  String inputPath,
  int degrees, {
  Function(int)? onProgress,
  Function(String)? onError,
}) async {
  try {
    final result = await _apiService.rotateVideo(inputPath, degrees);

    final outputUrl = result['url'] ?? result['path'] ?? '';
    if (outputUrl.isEmpty) {
      onError?.call('No output URL returned from server');
      return null;
    }

    // Handle web vs mobile (same as other functions)
    if (kIsWeb) {
      final fullUrl = outputUrl.startsWith('http') 
          ? outputUrl 
          : ApiService.mediaBaseUrl + outputUrl;
      return fullUrl;
    }

    // Download for mobile
    final tempDir = await getTemporaryDirectory();
    final fileName = outputUrl.split('/').last;
    final savePath = '${tempDir.path}/$fileName';
    
    final fullUrl = outputUrl.startsWith('http') 
        ? outputUrl 
        : ApiService.mediaBaseUrl + outputUrl;
    
    final response = await http.get(Uri.parse(fullUrl));
    if (response.statusCode == 200) {
      final file = io.File(savePath);
      await file.writeAsBytes(response.bodyBytes);
      return savePath;
    }

    onError?.call('Failed to download rotated video');
    return null;
  } catch (e) {
    onError?.call('Error rotating video: $e');
    return null;
  }
}
```

**Step 5:** Add backend rotate endpoint
```python
# backend/app/services/video_editing_service.py
def rotate_video(self, input_path: str, degrees: int) -> Optional[str]:
    """Rotate video by specified degrees (90, 180, 270)"""
    try:
        output_path = self._get_output_path(input_path, f"rotated_{degrees}")
        
        # Map degrees to FFmpeg transpose values
        # 0 = 90° clockwise + vertical flip
        # 1 = 90° clockwise
        # 2 = 90° counter-clockwise
        # 3 = 90° counter-clockwise + vertical flip
        
        if degrees == 90:
            transpose_value = 1
        elif degrees == 180:
            transpose_value = "transpose=1,transpose=1"
        elif degrees == 270:
            transpose_value = 2
        else:
            raise ValueError(f"Invalid rotation degrees: {degrees}. Must be 90, 180, or 270")
        
        if degrees == 180:
            # For 180°, apply transpose twice
            (
                ffmpeg
                .input(input_path)
                .filter('transpose', 1)
                .filter('transpose', 1)
                .output(output_path, vcodec='libx264', acodec='copy')
                .overwrite_output()
                .run(capture_stdout=True, capture_stderr=True)
            )
        else:
            (
                ffmpeg
                .input(input_path)
                .filter('transpose', transpose_value)
                .output(output_path, vcodec='libx264', acodec='copy')
                .overwrite_output()
                .run(capture_stdout=True, capture_stderr=True)
            )
        
        return output_path
    except Exception as e:
        print(f"Error rotating video: {e}")
        return None

# backend/app/routes/video_editing.py
@router.post("/rotate")
async def rotate_video(
    video_file: UploadFile = File(...),
    degrees: int = Form(...),
):
    """Rotate video by specified degrees (90, 180, 270)"""
    try:
        if degrees not in [90, 180, 270]:
            raise HTTPException(status_code=400, detail="Degrees must be 90, 180, or 270")
        
        temp_dir = Path("/tmp/video_editing")
        temp_dir.mkdir(parents=True, exist_ok=True)
        
        temp_input = temp_dir / f"temp_{os.urandom(8).hex()}.mp4"
        with open(temp_input, "wb") as f:
            content = await video_file.read()
            f.write(content)
        
        try:
            output_path = video_editing_service.rotate_video(str(temp_input), degrees)
            
            if not output_path:
                raise HTTPException(status_code=500, detail="Failed to rotate video")
            
            return await _upload_to_s3_if_production(output_path, "video")
            
        finally:
            if temp_input.exists():
                temp_input.unlink()
                
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

---

## **PHASE 5: Testing & Validation** ✅

### Test Cases:

#### **Front Camera Inversion:**
1. Record video with front camera
2. Verify preview shows correct orientation (not mirrored)
3. Open editor and verify video is not mirrored
4. Publish video and verify final output is correct

#### **Trim Function:**
1. Load video in editor
2. Set trim start and end times
3. Apply trim
4. Verify video player reloads with trimmed video
5. Verify duration is updated correctly
6. Verify can trim multiple times sequentially

#### **Remove Audio:**
1. Load video with audio in editor
2. Click "Remove Audio"
3. Verify video reloads without audio
4. Verify audio status indicator shows "Audio Removed"
5. Verify can reset to original audio

#### **Add Audio:**
1. Load video in editor
2. Click "Add Audio" and select audio file
3. Verify video reloads with new audio
4. Verify audio status shows "Custom Audio Active"
5. Verify can replace audio multiple times

#### **Rotate:**
1. Load video in editor
2. Rotate left/right
3. Verify preview shows rotation
4. Apply rotation
5. Verify video reloads with permanent rotation
6. Verify can rotate multiple times

---

## **Implementation Priority**

### **IMMEDIATE (Day 1-2):**
1. ✅ Front camera inversion fix (CRITICAL for user experience)
2. ✅ Trim function fixes (CRITICAL for basic editing)

### **HIGH (Day 3-4):**
3. ✅ Remove/Add audio fixes (CRITICAL for audio editing)

### **MEDIUM (Day 5):**
4. ✅ Rotate feature implementation (Nice to have)

---

## **Files Summary**

### **Frontend Files to Modify:**
1. `mobile/frontend/lib/screens/creation/video_recording_screen.dart` - Add front camera detection
2. `mobile/frontend/lib/screens/creation/video_preview_screen.dart` - Add flip transformation
3. `mobile/frontend/lib/screens/editing/video_editor_screen.dart` - Fix trim, audio, add rotate
4. `mobile/frontend/lib/services/video_editing_service.dart` - Add rotate function

### **Backend Files to Modify:**
1. `backend/app/services/video_editing_service.py` - Add flip and rotate functions
2. `backend/app/routes/video_editing.py` - Add flip and rotate endpoints

---

## **Success Criteria**

✅ **Front camera videos display correctly (not mirrored) in all screens**  
✅ **Trim function properly cuts video and reloads player**  
✅ **Remove audio completely removes audio track**  
✅ **Add audio properly adds custom audio track**  
✅ **Rotate feature allows 90°, 180°, 270° rotation**  
✅ **All edited videos can be saved and published**  
✅ **No crashes or errors during editing operations**  
✅ **Proper error messages for failed operations**  
✅ **Loading indicators during processing**  

---

## **Notes**

- All backend video processing uses FFmpeg
- Edited videos are temporarily stored in `/tmp/video_editing/`
- In production, edited videos are uploaded to S3 and served via CloudFront
- Mobile app downloads edited videos to temp directory for local playback
- Video player must be properly disposed and reinitialized after each edit
- State management is critical - track `_editedVideoPath`, `_audioRemoved`, `_audioFilePath`, `_rotation`

---

**END OF IMPLEMENTATION PLAN**
