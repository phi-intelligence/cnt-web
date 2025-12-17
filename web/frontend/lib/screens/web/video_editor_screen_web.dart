import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' if (dart.library.io) 'dart:html' as html;
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../services/video_editing_service.dart';
import '../../services/api_service.dart';
import '../../models/text_overlay.dart';
import '../../models/content_draft.dart';
import '../../utils/state_persistence.dart';
import '../../utils/unsaved_changes_guard.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../utils/responsive_utils.dart';
import 'video_preview_screen_web.dart';

/// Web Video Editor Screen - Professional Video Editing UI for Web
/// Features: Multi-track timeline, text overlays, trimming, filters, audio tracks
/// Handles blob URLs and network URLs properly
class VideoEditorScreenWeb extends StatefulWidget {
  final String videoPath;
  final String? title;
  final Duration? duration;

  const VideoEditorScreenWeb({
    super.key,
    required this.videoPath,
    this.title,
    this.duration,
  });

  @override
  State<VideoEditorScreenWeb> createState() => _VideoEditorScreenWebState();
}

class _VideoEditorScreenWebState extends State<VideoEditorScreenWeb> with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  final VideoEditingService _editingService = VideoEditingService();
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  
  bool _isInitializing = true;
  bool _isEditing = false;
  bool _hasError = false;
  String? _errorMessage;
  
  // Video metadata
  String? _projectTitle;
  String _resolution = '1440p';
  double _fps = 30.0;
  Duration _videoDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  bool _isPlaying = false;
  Duration? _providedDuration;
  
  // Editing state
  Duration _trimStart = Duration.zero;
  Duration _trimEnd = Duration.zero;
  bool _audioRemoved = false;
  String? _audioFilePath;
  
  // Text overlays
  List<TextOverlay> _textOverlays = [];
  TextOverlay? _selectedTextOverlay;
  
  // Timeline state
  double _playheadPosition = 0.0; // 0.0 to 1.0
  bool _isDraggingPlayhead = false;
  
  // Controls visibility for video preview
  bool _showVideoControls = true;
  Timer? _hideVideoControlsTimer;
  bool _isMouseOverVideo = false;
  
  String? _editedVideoPath;
  String? _persistedVideoPath; // Track the persisted path (backend URL if blob was uploaded)
  final _uuid = const Uuid();
  
  // Draft state
  int? _draftId;
  bool _isSavingDraft = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 3 tabs: Trim, Music, Text
    _providedDuration = widget.duration;
    
    if (kIsWeb) {
      // Add beforeunload warning for unsaved changes
      html.window.onBeforeUnload.listen((event) {
        if (_editedVideoPath != null || _hasUnsavedChanges()) {
          final beforeUnloadEvent = event as html.BeforeUnloadEvent;
          beforeUnloadEvent.returnValue = 'You have unsaved changes. Are you sure you want to leave?';
        }
      });
    }
    
    _initializeFromSavedState();
  }

  /// Check if there are unsaved changes
  bool _hasUnsavedChanges() {
    return _trimStart != Duration.zero || 
           (_trimEnd != Duration.zero && _trimEnd != _videoDuration) ||
           _audioRemoved ||
           _audioFilePath != null ||
           _textOverlays.isNotEmpty;
  }

  /// Save current editing state as a draft
  Future<bool> _saveDraft() async {
    if (_isSavingDraft) return false;
    
    setState(() {
      _isSavingDraft = true;
    });
    
    try {
      // Prepare editing state
      final editingState = <String, dynamic>{
        'trim_start': _trimStart.inMilliseconds,
        'trim_end': _trimEnd.inMilliseconds,
        'audio_removed': _audioRemoved,
        'audio_file_path': _audioFilePath,
        'text_overlays': _textOverlays.map((o) => o.toJson()).toList(),
        'resolution': _resolution,
        'fps': _fps,
      };
      
      final draftData = {
        'draft_type': DraftType.videoPodcast.value,
        'title': _projectTitle ?? widget.title ?? 'Video Draft',
        'original_media_url': _persistedVideoPath ?? widget.videoPath,
        'edited_media_url': _editedVideoPath,
        'editing_state': editingState,
        'duration': _videoDuration.inSeconds,
        'status': DraftStatus.editing.value,
      };
      
      Map<String, dynamic> result;
      
      if (_draftId != null) {
        // Update existing draft
        result = await _apiService.updateDraft(_draftId!, draftData);
      } else {
        // Create new draft
        result = await _apiService.createDraft(draftData);
        _draftId = result['id'] as int?;
      }
      
      if (!mounted) return false;
      
      UnsavedChangesGuard.showDraftSavedToast(context);
      return true;
    } catch (e) {
      print('Error saving draft: $e');
      if (mounted) {
        UnsavedChangesGuard.showDraftErrorToast(context, message: 'Failed to save draft: $e');
      }
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isSavingDraft = false;
        });
      }
    }
  }

  /// Handle back button with unsaved changes confirmation
  Future<bool> _handleBackPressed() async {
    if (!_hasUnsavedChanges() && _editedVideoPath == null) {
      return true; // Allow navigation
    }
    
    final result = await UnsavedChangesGuard.showUnsavedChangesDialog(context);
    
    if (result == null) {
      // User cancelled - stay on page
      return false;
    } else if (result) {
      // User wants to save draft
      final saved = await _saveDraft();
      return saved; // Navigate only if save was successful
    } else {
      // User wants to discard
      return true;
    }
  }

  /// Initialize editor from saved state or widget parameters
  Future<void> _initializeFromSavedState() async {
    try {
      final savedState = await StatePersistence.loadVideoEditorState();
      if (savedState != null && mounted) {
        final savedVideoPath = savedState['videoPath'] as String?;
        final savedEditedPath = savedState['editedVideoPath'] as String?;
        final trimStartMs = savedState['trimStart'] as int?;
        final trimEndMs = savedState['trimEnd'] as int?;
        final audioRemoved = savedState['audioRemoved'] as bool?;
        final audioFilePath = savedState['audioFilePath'] as String?;

        if (savedVideoPath != null) {
          // Validate saved path is compatible with current environment
          // Clear stale localhost URLs when in production
          final isProduction = !_apiService.getMediaUrl('test').contains('localhost');
          final isLocalhostUrl = savedVideoPath.contains('localhost');
          
          if (isProduction && isLocalhostUrl) {
            print('⚠️ Clearing stale localhost URL from saved state (production environment)');
            await StatePersistence.clearVideoEditorState();
            // Don't use stale saved state
          } else {
            // Use saved path (which should be backend URL if blob was uploaded)
            _persistedVideoPath = savedVideoPath;
          
          // Restore trim values
          if (trimStartMs != null) {
            _trimStart = Duration(milliseconds: trimStartMs);
          }
          if (trimEndMs != null) {
            _trimEnd = Duration(milliseconds: trimEndMs);
          }

          // Restore other state
          if (audioRemoved != null) {
            _audioRemoved = audioRemoved;
          }
          if (audioFilePath != null) {
            _audioFilePath = audioFilePath;
          }

          // Restore edited path if exists
          if (savedEditedPath != null) {
            _editedVideoPath = savedEditedPath;
          }

          print('✅ Restored video editor state from saved state');
          }
        }
      }

      // If we have a blob URL in widget.videoPath, upload it first
      String videoPathToUse = widget.videoPath;
      if (kIsWeb && widget.videoPath.startsWith('blob:')) {
        try {
          print('📤 Uploading blob URL to backend for persistence...');
          final uploadResult = await _apiService.uploadTemporaryMedia(widget.videoPath, 'video');
          if (uploadResult != null) {
            final backendUrl = uploadResult['url'] as String?;
            if (backendUrl != null) {
              // Convert relative backend path to full URL
              final fullUrl = _apiService.getMediaUrl(backendUrl);
              videoPathToUse = fullUrl;
              _persistedVideoPath = fullUrl;
              print('✅ Blob URL uploaded to backend: $backendUrl');
              print('✅ Full media URL: $fullUrl');
              // Save state with full URL
              await StatePersistence.saveVideoEditorState(
                videoPath: fullUrl,
                editedVideoPath: _editedVideoPath,
                trimStart: _trimStart,
                trimEnd: _trimEnd,
                audioRemoved: _audioRemoved,
                audioFilePath: _audioFilePath,
              );
            }
          }
        } catch (e) {
          print('⚠️ Failed to upload blob URL, using original: $e');
        }
      } else if (_persistedVideoPath == null) {
        // If not a blob URL, ensure it's a full URL
        if (!widget.videoPath.startsWith('http://') && !widget.videoPath.startsWith('https://') && !widget.videoPath.startsWith('blob:')) {
          // It's a relative path from backend, convert to full URL
          videoPathToUse = _apiService.getMediaUrl(widget.videoPath);
          print('🔗 Converted relative path to full URL: $videoPathToUse');
        }
        _persistedVideoPath = videoPathToUse;
      }

      // Use persisted path or widget path
      final finalPath = _persistedVideoPath ?? videoPathToUse;
      print('🎬 Initializing video player with: $finalPath');
      await _initializePlayer(finalPath);
    } catch (e) {
      print('❌ Error initializing from saved state: $e');
      await _initializePlayer(widget.videoPath);
    }
  }

  /// Get duration from blob URL using HTML5 video element directly
  /// This is a workaround for WebM videos that don't expose duration immediately
  Future<Duration?> _getDurationFromBlobUrl(String blobUrl) async {
    if (!kIsWeb) return null;
    
    try {
      final videoElement = html.VideoElement()
        ..src = blobUrl
        ..preload = 'metadata';
      
      // Wait for metadata to load
      final completer = Completer<Duration?>();
      
      void checkDuration() {
        if (videoElement.readyState >= html.MediaElement.HAVE_METADATA) {
          final durationSeconds = videoElement.duration;
          if (durationSeconds != null && 
              !durationSeconds.isNaN && 
              durationSeconds.isFinite &&
              durationSeconds > 0) {
            completer.complete(Duration(milliseconds: (durationSeconds * 1000).round()));
            return;
          }
        }
      }
      
      videoElement.onLoadedMetadata.listen((_) {
        checkDuration();
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });
      
      videoElement.onError.listen((_) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });
      
      // Load the video
      videoElement.load();
      
      // Check immediately in case metadata is already loaded
      checkDuration();
      
      // Wait for metadata with timeout
      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          // Try one more time
          checkDuration();
          final durationSeconds = videoElement.duration;
          if (durationSeconds != null && 
              !durationSeconds.isNaN && 
              durationSeconds.isFinite &&
              durationSeconds > 0) {
            return Duration(milliseconds: (durationSeconds * 1000).round());
          }
          return null;
        },
      );
    } catch (e) {
      print('⚠️ Error getting duration from blob URL: $e');
      return null;
    }
  }

  String _extractFileName(String path) {
    // Handle blob URLs, network URLs, and file paths
    if (path.startsWith('blob:')) {
      return 'Video Recording';
    } else if (path.startsWith('http://') || path.startsWith('https://')) {
      final uri = Uri.parse(path);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        final fileName = segments.last;
        return fileName.split('.').first;
      }
      return 'Video';
    } else {
      // Fallback for file paths (shouldn't happen on web, but handle gracefully)
      final parts = path.split('/');
      if (parts.isNotEmpty) {
        return parts.last.split('.').first;
      }
      return 'Video';
    }
  }

  Future<void> _initializePlayer(String videoPath) async {
    try {
      // On web, all paths should be URLs (blob URLs or network URLs)
      final isNetworkUrl = videoPath.startsWith('http://') || 
                          videoPath.startsWith('https://');
      final isBlobUrl = videoPath.startsWith('blob:');
      
      // Use networkUrl for both blob URLs and network URLs
      if (isNetworkUrl || isBlobUrl) {
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(videoPath),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: false,
            allowBackgroundPlayback: false,
          ),
        );
      } else {
        // Fallback: treat as network URL
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(videoPath),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: false,
            allowBackgroundPlayback: false,
          ),
        );
      }
      
      await _controller!.initialize();
      
      // Wait for video to be ready and duration to be available
      if (!_controller!.value.isInitialized) {
        throw Exception('Video failed to initialize');
      }
      
      // For WebM videos from MediaRecorder, duration may not be immediately available
      // Try to trigger metadata loading by seeking or playing briefly
      Duration? duration = _controller!.value.duration;
      
      // If duration is not available, try to load metadata by seeking
      if (duration == null || duration == Duration.zero || duration.inMilliseconds <= 0) {
        try {
          // Try to seek to a large position to trigger metadata loading
          await _controller!.seekTo(const Duration(seconds: 999999));
          await Future.delayed(const Duration(milliseconds: 200));
          // Seek back to start
          await _controller!.seekTo(Duration.zero);
          await Future.delayed(const Duration(milliseconds: 200));
          duration = _controller!.value.duration;
        } catch (e) {
          // If seeking fails, try playing briefly
          try {
            await _controller!.play();
            await Future.delayed(const Duration(milliseconds: 500));
            await _controller!.pause();
            await Future.delayed(const Duration(milliseconds: 200));
            duration = _controller!.value.duration;
          } catch (e2) {
            print('⚠️ Could not trigger metadata load: $e2');
          }
        }
      }
      
      // Wait with multiple attempts for duration to become available
      int attempts = 0;
      while ((duration == null || duration == Duration.zero || duration.inMilliseconds <= 0) && attempts < 30) {
        await Future.delayed(const Duration(milliseconds: 200));
        duration = _controller!.value.duration;
        attempts++;
      }
      
      // Final check - if still no duration, try one more time after a longer wait
      if ((duration == null || duration == Duration.zero || duration.inMilliseconds <= 0)) {
        await Future.delayed(const Duration(seconds: 1));
        duration = _controller!.value.duration;
      }
      
      // Check if provided duration is available (from backend - more reliable for WebM)
      // WebM files from MediaRecorder often have wrong/missing duration metadata
      // The backend uses FFprobe re-encoding to get accurate duration
      if (_providedDuration != null && _providedDuration!.inMilliseconds > 0) {
        // If controller duration is missing, invalid, or suspiciously different from provided,
        // prefer the backend-provided duration
        final bool controllerDurationInvalid = duration == null || 
            duration == Duration.zero || 
            duration.inMilliseconds <= 0;
        final bool controllerDurationSuspicious = duration != null && 
            duration.inMilliseconds > 0 &&
            (_providedDuration!.inMilliseconds / duration.inMilliseconds > 2 ||
             duration.inMilliseconds / _providedDuration!.inMilliseconds > 2);
        
        if (controllerDurationInvalid || controllerDurationSuspicious) {
          print('🔄 Controller duration: ${duration?.inSeconds}s, Provided: ${_providedDuration!.inSeconds}s');
          print('✅ Using backend-provided duration: ${_providedDuration!.inSeconds}s (more reliable for WebM)');
          duration = _providedDuration;
        }
      } else if (duration == null || duration == Duration.zero || duration.inMilliseconds <= 0) {
        // No provided duration - try fallback methods for blob URLs
        if (widget.videoPath.startsWith('blob:')) {
          try {
            // Use a workaround: create a temporary video element to get duration
            final durationFromElement = await _getDurationFromBlobUrl(widget.videoPath);
            if (durationFromElement != null && durationFromElement.inMilliseconds > 0) {
              duration = durationFromElement;
            }
          } catch (e) {
            print('⚠️ Could not get duration from blob URL: $e');
          }
        }
        
        if (duration == null || duration == Duration.zero || duration.inMilliseconds <= 0) {
          throw Exception('Video duration is not available. The video may be corrupted or in an unsupported format. Please try recording again.');
        }
      }
      
      _controller!.addListener(_videoListener);
      
      // Extract project title from filename
      final fileName = _extractFileName(widget.videoPath);
      _projectTitle = widget.title ?? fileName;
      
      // Extract video metadata
      final size = _controller!.value.size;
      _resolution = _getResolutionFromSize(size);
      _fps = _controller!.value.size.height > 720 ? 30.0 : 29.97; // Estimate, video_player doesn't expose FPS directly
      
      setState(() {
        _isInitializing = false;
        _videoDuration = duration!;
        _trimEnd = _videoDuration;
        _trimStart = Duration.zero;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _hasError = true;
        _errorMessage = _formatVideoError(e);
      });
    }
  }

  /// Format video errors into user-friendly messages
  String _formatVideoError(dynamic error) {
    final errorStr = error.toString();

    // MEDIA_ERR_SRC_NOT_SUPPORTED - format not supported by browser
    if (errorStr.contains('MEDIA_ERR_SRC_NOT_SUPPORTED') ||
        errorStr.contains('Format error') ||
        errorStr.contains('format not supported')) {
      return 'This video format is not supported by your browser.\n\n'
             'Tip: Try converting your video to MP4 format (H.264 codec) for best compatibility.';
    }

    // Network/loading errors
    if (errorStr.contains('MEDIA_ERR_NETWORK') ||
        errorStr.contains('network') ||
        errorStr.contains('Failed to load')) {
      return 'Failed to load video. Please check your internet connection and try again.';
    }

    // Decode errors
    if (errorStr.contains('MEDIA_ERR_DECODE') || errorStr.contains('decode')) {
      return 'This video file appears to be corrupted or uses an unsupported codec.\n\n'
             'Tip: Try re-encoding the video or use a different file.';
    }

    // Timeout errors
    if (errorStr.contains('TimeoutException') || errorStr.contains('timeout')) {
      return 'Video took too long to load. Please try again or use a smaller file.';
    }

    // Blob URL errors
    if (errorStr.contains('blob:') || errorStr.contains('Blob')) {
      return 'Unable to process recorded video. Please try recording again.';
    }

    // Generic error with original message
    return 'Error loading video: $errorStr';
  }

  String _getResolutionFromSize(Size size) {
    final height = size.height;
    if (height >= 2160) return '4K';
    if (height >= 1440) return '1440p';
    if (height >= 1080) return '1080p';
    if (height >= 720) return '720p';
    if (height >= 480) return '480p';
    return '360p';
  }

  void _videoListener() {
    if (mounted && _controller != null) {
      setState(() {
        _currentPosition = _controller!.value.position;
        _isPlaying = _controller!.value.isPlaying;
        if (!_isDraggingPlayhead) {
          _playheadPosition = _currentPosition.inMilliseconds / _videoDuration.inMilliseconds;
          _playheadPosition = _playheadPosition.clamp(0.0, 1.0);
        }
      });
    }
  }

  Future<void> _togglePlayPause() async {
    if (_controller == null) return;
    
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
    
    // Show controls and manage timer
    _showVideoControlsWithAutoHide();
  }

  Future<void> _seekToPosition(double position) async {
    if (_controller == null || _videoDuration == Duration.zero) return;
    
    final targetPosition = Duration(
      milliseconds: (position * _videoDuration.inMilliseconds).toInt(),
    );
    await _controller!.seekTo(targetPosition);
    if (mounted) {
      setState(() {
        _playheadPosition = position;
      });
    }
  }

  void _onPlayheadDragStart() {
    setState(() {
      _isDraggingPlayhead = true;
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      }
    });
  }

  void _onPlayheadDragUpdate(double position) {
    final clampedPosition = position.clamp(0.0, 1.0);
    setState(() {
      _playheadPosition = clampedPosition;
    });
    // Don't seek during drag - only update visual position
    // Seek will happen on drag end
  }

  void _onPlayheadDragEnd() {
    // Seek to final position when drag ends
    _seekToPosition(_playheadPosition);
    setState(() {
      _isDraggingPlayhead = false;
    });
  }
  
  void _onVideoMouseEnter() {
    setState(() {
      _isMouseOverVideo = true;
    });
    _showVideoControlsWithAutoHide();
  }

  void _onVideoMouseExit() {
    setState(() {
      _isMouseOverVideo = false;
    });
    if (_controller?.value.isPlaying ?? false) {
      _hideVideoControls();
    }
  }

  void _onVideoMouseMove() {
    if (_isMouseOverVideo) {
      _showVideoControlsWithAutoHide();
    }
  }

  void _showVideoControlsWithAutoHide() {
    _hideVideoControlsTimer?.cancel();
    setState(() {
      _showVideoControls = true;
    });
    
    if (_controller?.value.isPlaying ?? false) {
      _startVideoControlsTimer();
    }
  }

  void _startVideoControlsTimer() {
    _hideVideoControlsTimer?.cancel();
    if (_controller?.value.isPlaying ?? false) {
      _hideVideoControlsTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && (_controller?.value.isPlaying ?? false)) {
          setState(() {
            _showVideoControls = false;
          });
        }
      });
    }
  }

  void _hideVideoControls() {
    _hideVideoControlsTimer?.cancel();
    if (mounted && (_controller?.value.isPlaying ?? false)) {
      setState(() {
        _showVideoControls = false;
      });
    }
  }

  void _addTextOverlay() {
    final overlay = TextOverlay(
      id: _uuid.v4(),
      text: 'New Text',
      startTime: _currentPosition,
      endTime: _currentPosition + const Duration(seconds: 5),
    );
    setState(() {
      _textOverlays.add(overlay);
      _selectedTextOverlay = overlay;
    });
    _showTextOverlayEditor(overlay);
  }

  void _editTextOverlay(TextOverlay overlay) {
    setState(() {
      _selectedTextOverlay = overlay;
    });
    _showTextOverlayEditor(overlay);
  }

  void _showTextOverlayEditor(TextOverlay overlay) {
    final textController = TextEditingController(text: overlay.text);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    // State variables for editing
    Duration startTime = overlay.startTime;
    Duration endTime = overlay.endTime;
    double xPosition = overlay.x;
    double yPosition = overlay.y;
    double fontSize = overlay.fontSize;
    int textColor = overlay.color;
    TextAlign textAlign = overlay.textAlign;
    String? backgroundColor = overlay.backgroundColor;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.9,
        maxWidth: isMobile ? screenWidth : 700,
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.9,
            maxWidth: isMobile ? screenWidth : 700,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLarge),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.large),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.warmBrown.withOpacity(0.1),
                        AppColors.accentMain.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.radiusLarge),
                    ),
                    border: Border(
                      bottom: BorderSide(color: AppColors.borderPrimary),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.small),
                        decoration: BoxDecoration(
                          color: AppColors.warmBrown.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Icon(
                          Icons.text_fields,
                          color: AppColors.warmBrown,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.medium),
                      Expanded(
                        child: Text(
                          'Edit Text Overlay',
                          style: AppTypography.heading3.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
                
                // Content - Scrollable
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.large),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Text input
                        Text(
                          'Text Content',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.small),
                        TextField(
                          controller: textController,
                          maxLines: 4,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter text to display on video',
                            hintStyle: AppTypography.body.copyWith(
                              color: AppColors.textPlaceholder,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: AppColors.borderPrimary),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: AppColors.borderPrimary),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(
                                color: AppColors.warmBrown,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.backgroundSecondary,
                            contentPadding: const EdgeInsets.all(AppSpacing.medium),
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.large),
                        
                        // Time Range Section
                        _buildSectionHeader('Time Range', Icons.access_time),
                        const SizedBox(height: AppSpacing.small),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.large),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: AppColors.borderPrimary),
                          ),
                          child: Column(
                            children: [
                              // Start Time
                              _buildTimeSlider(
                                'Start Time',
                                startTime,
                                Duration.zero,
                                endTime,
                                (value) {
                                  setModalState(() {
                                    startTime = value;
                                    if (startTime >= endTime) {
                                      endTime = Duration(
                                        milliseconds: (startTime.inMilliseconds + 1000).clamp(
                                          0,
                                          _videoDuration.inMilliseconds,
                                        ),
                                      );
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: AppSpacing.large),
                              // End Time
                              _buildTimeSlider(
                                'End Time',
                                endTime,
                                startTime,
                                _videoDuration,
                                (value) {
                                  setModalState(() {
                                    endTime = value;
                                    if (endTime <= startTime) {
                                      startTime = Duration(
                                        milliseconds: (endTime.inMilliseconds - 1000).clamp(0, _videoDuration.inMilliseconds),
                                      );
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.large),
                        
                        // Position Section
                        _buildSectionHeader('Position', Icons.open_with),
                        const SizedBox(height: AppSpacing.small),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.large),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: AppColors.borderPrimary),
                          ),
                          child: Column(
                            children: [
                              // X Position
                              _buildPositionSlider(
                                'Horizontal Position (X)',
                                xPosition,
                                0.0,
                                1.0,
                                (value) {
                                  setModalState(() {
                                    xPosition = value;
                                  });
                                },
                              ),
                              const SizedBox(height: AppSpacing.large),
                              // Y Position
                              _buildPositionSlider(
                                'Vertical Position (Y)',
                                yPosition,
                                0.0,
                                1.0,
                                (value) {
                                  setModalState(() {
                                    yPosition = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.large),
                        
                        // Style Section
                        _buildSectionHeader('Style', Icons.format_paint),
                        const SizedBox(height: AppSpacing.small),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.large),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: AppColors.borderPrimary),
                          ),
                          child: Column(
                            children: [
                              // Font Size
                              _buildFontSizeSlider(
                                fontSize,
                                (value) {
                                  setModalState(() {
                                    fontSize = value;
                                  });
                                },
                              ),
                              const SizedBox(height: AppSpacing.large),
                              // Text Color
                              _buildColorPicker(
                                'Text Color',
                                Color(textColor),
                                (color) {
                                  setModalState(() {
                                    textColor = color.value;
                                  });
                                },
                              ),
                              const SizedBox(height: AppSpacing.large),
                              // Background Color (Optional)
                              _buildColorPicker(
                                'Background Color (Optional)',
                                backgroundColor != null
                                    ? Color(int.parse(backgroundColor!.replaceFirst('#', '0xff')))
                                    : null,
                                (color) {
                                  setModalState(() {
                                    backgroundColor = '#${color.value.toRadixString(16).substring(2)}';
                                  });
                                },
                                isOptional: true,
                                onClear: () {
                                  setModalState(() {
                                    backgroundColor = null;
                                  });
                                },
                              ),
                              const SizedBox(height: AppSpacing.large),
                              // Text Alignment
                              _buildTextAlignmentSelector(
                                textAlign,
                                (align) {
                                  setModalState(() {
                                    textAlign = align;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Action Buttons - Fixed at bottom
                Container(
                  padding: const EdgeInsets.all(AppSpacing.large),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    border: Border(
                      top: BorderSide(color: AppColors.borderPrimary),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _textOverlays.removeWhere((o) => o.id == overlay.id);
                              if (_selectedTextOverlay?.id == overlay.id) {
                                _selectedTextOverlay = null;
                              }
                            });
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.errorMain,
                            side: BorderSide(color: AppColors.errorMain, width: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.large,
                              vertical: AppSpacing.medium,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.medium),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              final index = _textOverlays.indexWhere((o) => o.id == overlay.id);
                              if (index != -1) {
                                _textOverlays[index] = overlay.copyWith(
                                  text: textController.text,
                                  startTime: startTime,
                                  endTime: endTime,
                                  x: xPosition,
                                  y: yPosition,
                                  fontSize: fontSize,
                                  color: textColor,
                                  textAlign: textAlign,
                                  backgroundColor: backgroundColor,
                                );
                              }
                            });
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Save Changes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warmBrown,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.large,
                              vertical: AppSpacing.medium,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.warmBrown, size: 20),
        const SizedBox(width: AppSpacing.small),
        Text(
          title,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlider(
    String label,
    Duration value,
    Duration min,
    Duration max,
    ValueChanged<Duration> onChanged,
  ) {
    final maxSeconds = max.inSeconds.toDouble();
    final minSeconds = min.inSeconds.toDouble();
    final valueSeconds = value.inSeconds.toDouble();
    final safeMax = maxSeconds > minSeconds ? maxSeconds : minSeconds + 1.0;
    final safeValue = valueSeconds.clamp(minSeconds, safeMax);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.medium,
                vertical: AppSpacing.small,
              ),
              decoration: BoxDecoration(
                color: AppColors.warmBrown.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.warmBrown.withOpacity(0.3)),
              ),
              child: Text(
                _formatTime(value),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.warmBrown,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        if (safeMax > minSeconds)
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              activeTrackColor: AppColors.warmBrown,
              inactiveTrackColor: AppColors.borderPrimary,
              thumbColor: AppColors.warmBrown,
            ),
            child: Slider(
              value: safeValue,
              min: minSeconds,
              max: safeMax,
              onChanged: (val) {
                onChanged(Duration(seconds: val.toInt()));
              },
            ),
          )
        else
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.borderPrimary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }

  Widget _buildPositionSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.medium,
                vertical: AppSpacing.small,
              ),
              decoration: BoxDecoration(
                color: AppColors.warmBrown.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.warmBrown.withOpacity(0.3)),
              ),
              child: Text(
                '${(value * 100).toStringAsFixed(0)}%',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.warmBrown,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            activeTrackColor: AppColors.warmBrown,
            inactiveTrackColor: AppColors.borderPrimary,
            thumbColor: AppColors.warmBrown,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildFontSizeSlider(
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Font Size',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.medium,
                vertical: AppSpacing.small,
              ),
              decoration: BoxDecoration(
                color: AppColors.warmBrown.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.warmBrown.withOpacity(0.3)),
              ),
              child: Text(
                '${value.toInt()}px',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.warmBrown,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            activeTrackColor: AppColors.warmBrown,
            inactiveTrackColor: AppColors.borderPrimary,
            thumbColor: AppColors.warmBrown,
          ),
          child: Slider(
            value: value.clamp(12.0, 72.0),
            min: 12.0,
            max: 72.0,
            divisions: 60,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildColorPicker(
    String label,
    Color? currentColor,
    ValueChanged<Color> onChanged, {
    bool isOptional = false,
    VoidCallback? onClear,
  }) {
    final predefinedColors = [
      Colors.white,
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.cyan,
      Colors.brown,
      Colors.grey,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isOptional && currentColor != null && onClear != null)
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.errorMain,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            ...predefinedColors.map((color) {
              final isSelected = currentColor != null &&
                  currentColor.value == color.value;
              return GestureDetector(
                onTap: () => onChanged(color),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.warmBrown
                          : AppColors.borderPrimary,
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.warmBrown.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              );
            }),
            // Custom color picker button
            GestureDetector(
              onTap: () async {
                final color = await showDialog<Color>(
                  context: context,
                  builder: (context) => _ColorPickerDialog(
                    initialColor: currentColor ?? Colors.white,
                  ),
                );
                if (color != null) {
                  onChanged(color);
                }
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red,
                      Colors.orange,
                      Colors.yellow,
                      Colors.green,
                      Colors.blue,
                      Colors.indigo,
                      Colors.purple,
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.borderPrimary,
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.color_lens,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextAlignmentSelector(
    TextAlign currentAlign,
    ValueChanged<TextAlign> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Text Alignment',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        Row(
          children: [
            Expanded(
              child: _buildAlignmentButton(
                TextAlign.left,
                Icons.format_align_left,
                currentAlign,
                onChanged,
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: _buildAlignmentButton(
                TextAlign.center,
                Icons.format_align_center,
                currentAlign,
                onChanged,
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: _buildAlignmentButton(
                TextAlign.right,
                Icons.format_align_right,
                currentAlign,
                onChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlignmentButton(
    TextAlign align,
    IconData icon,
    TextAlign currentAlign,
    ValueChanged<TextAlign> onChanged,
  ) {
    final isSelected = currentAlign == align;
    return GestureDetector(
      onTap: () => onChanged(align),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.medium),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.warmBrown.withOpacity(0.1)
              : AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? AppColors.warmBrown
                : AppColors.borderPrimary,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? AppColors.warmBrown
              : AppColors.textSecondary,
          size: 24,
        ),
      ),
    );
  }

  Future<void> _applyTrim() async {
    // Validate video duration
    if (_videoDuration == Duration.zero || _videoDuration.inSeconds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Video duration is not available. Please wait for video to load.'),
          backgroundColor: AppColors.errorMain,
        ),
      );
      return;
    }

    // Validate trim range
    if (_trimStart >= _trimEnd) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Start time must be less than end time'),
          backgroundColor: AppColors.errorMain,
        ),
      );
      return;
    }

    // Validate trim values are within video duration
    if (_trimStart < Duration.zero || _trimEnd > _videoDuration) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Trim values must be within video duration'),
          backgroundColor: AppColors.errorMain,
        ),
      );
      return;
    }

    setState(() {
      _isEditing = true;
      _hasError = false;
    });

    try {
      // Use _persistedVideoPath (full URL) or _editedVideoPath, not widget.videoPath (may be relative)
      final inputPath = _editedVideoPath ?? _persistedVideoPath ?? widget.videoPath;
      print('🎬 Trimming video with path: $inputPath');
      final outputPath = await _editingService.trimVideo(
        inputPath,
        _trimStart,
        _trimEnd,
        onProgress: (progress) {},
        onError: (error) {
          setState(() {
            _isEditing = false;
            _hasError = true;
            _errorMessage = error;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error trimming video: $error'),
                backgroundColor: AppColors.errorMain,
              ),
            );
          }
        },
      );

      if (outputPath != null) {
        setState(() {
          _editedVideoPath = outputPath;
          _isEditing = false;
        });
        
        // Save state after successful trim
        await StatePersistence.saveVideoEditorState(
          videoPath: _persistedVideoPath ?? widget.videoPath,
          editedVideoPath: outputPath,
          trimStart: _trimStart,
          trimEnd: _trimEnd,
          audioRemoved: _audioRemoved,
          audioFilePath: _audioFilePath,
        );
        
        await _reloadPlayer(outputPath);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Video trimmed successfully'),
              backgroundColor: AppColors.successMain,
            ),
          );
        }
      } else {
        setState(() {
          _isEditing = false;
          _hasError = true;
          _errorMessage = 'Failed to trim video - no output path returned';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to trim video. Please try again.'),
              backgroundColor: AppColors.errorMain,
            ),
          );
        }
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
            content: Text('Error trimming video: $e'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
    }
  }

  Future<void> _removeAudio() async {
    // Use _persistedVideoPath (full URL) or _editedVideoPath, not widget.videoPath (may be relative)
    final inputPath = _editedVideoPath ?? _persistedVideoPath ?? widget.videoPath;
    print('🎬 Removing audio from video with path: $inputPath');
    
    setState(() {
      _isEditing = true;
      _hasError = false;
    });

    final outputPath = await _editingService.removeAudioTrack(
      inputPath,
      onProgress: (progress) {},
      onError: (error) {
        setState(() {
          _isEditing = false;
          _hasError = true;
          _errorMessage = error;
        });
      },
    );

    if (outputPath != null) {
      setState(() {
        _editedVideoPath = outputPath;
        _audioRemoved = true;
        _isEditing = false;
      });
      
      // Save state after successful audio removal
      await StatePersistence.saveVideoEditorState(
        videoPath: _persistedVideoPath ?? widget.videoPath,
        editedVideoPath: outputPath,
        trimStart: _trimStart,
        trimEnd: _trimEnd,
        audioRemoved: _audioRemoved,
        audioFilePath: _audioFilePath,
      );
      
      await _reloadPlayer(outputPath);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Audio removed successfully'),
          backgroundColor: AppColors.successMain,
        ),
      );
    }
  }

  Future<void> _selectAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.single;
      
      if (file.bytes != null) {
        // On web, FilePicker returns bytes instead of path
        // Upload the audio file to backend to get URL
        setState(() {
          _isEditing = true;
        });

        try {
          // Get filename from file name or use default
          final fileName = file.name.isNotEmpty 
              ? file.name 
              : 'audio_${DateTime.now().millisecondsSinceEpoch}.mp3';
          
          // Upload audio file
          final uploadResult = await _apiService.uploadAudioFromBytes(
            file.bytes!,
            fileName,
          );

          // Get the URL from upload response
          final audioUrl = uploadResult['url'] ?? uploadResult['file_path'] ?? '';
          
          if (audioUrl.isEmpty) {
            throw Exception('No URL returned from audio upload');
          }

          // Use the uploaded audio URL
          await _addAudioTrack(audioUrl);
        } catch (e) {
          setState(() {
            _isEditing = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error uploading audio file: $e'),
                backgroundColor: AppColors.errorMain,
              ),
            );
          }
        }
      } else if (file.path != null) {
        // Fallback for mobile (shouldn't happen on web, but handle gracefully)
        final audioPath = file.path!;
        await _addAudioTrack(audioPath);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Unable to read audio file. Please try again.'),
              backgroundColor: AppColors.errorMain,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isEditing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting audio file: $e'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
    }
  }

  Future<void> _addAudioTrack(String audioPath) async {
    // Use _persistedVideoPath (full URL) or _editedVideoPath, not widget.videoPath (may be relative)
    final inputPath = _editedVideoPath ?? _persistedVideoPath ?? widget.videoPath;
    print('🎬 Adding audio to video with path: $inputPath');
    
    setState(() {
      _isEditing = true;
      _hasError = false;
    });

    final outputPath = await _editingService.addAudioTrack(
      inputPath,
      audioPath,
      onProgress: (progress) {},
      onError: (error) {
        setState(() {
          _isEditing = false;
          _hasError = true;
          _errorMessage = error;
        });
      },
    );

    if (outputPath != null) {
      setState(() {
        _editedVideoPath = outputPath;
        _audioFilePath = audioPath;
        _audioRemoved = false;
        _isEditing = false;
      });
      await _reloadPlayer(outputPath);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Audio track added successfully'),
          backgroundColor: AppColors.successMain,
        ),
      );
    }
  }

  Future<void> _reloadPlayer(String path) async {
    await _controller?.dispose();
    
    // On web, path should be a URL (blob URL or network URL)
    final isNetworkUrl = path.startsWith('http://') || path.startsWith('https://');
    final isBlobUrl = path.startsWith('blob:');
    
    if (isNetworkUrl || isBlobUrl) {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(path),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );
    } else {
      // Fallback: treat as network URL
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(path),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );
    }
    
    await _controller!.initialize();
    
    // Wait for video to be ready and duration to be available
    if (!_controller!.value.isInitialized) {
      print('⚠️ Video failed to initialize after reload');
      return;
    }
    
    // Wait a bit for duration to be available
    Duration? duration = _controller!.value.duration;
    int attempts = 0;
    while ((duration == null || duration == Duration.zero || duration.inMilliseconds <= 0) && attempts < 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      duration = _controller!.value.duration;
      attempts++;
    }
    
    // Calculate expected duration from trim values (before reset)
    final expectedDuration = _trimEnd - _trimStart;
    print('🔄 Reloading video: controller duration=${duration?.inSeconds}s, expected=${expectedDuration.inSeconds}s');
    
    // If controller duration is missing or suspiciously different, use expected duration
    if (duration == null || duration == Duration.zero || duration.inMilliseconds <= 0) {
      if (expectedDuration.inMilliseconds > 0) {
        duration = expectedDuration;
        print('✅ Using expected duration from trim: ${duration.inSeconds}s');
      } else {
        print('⚠️ Video duration is not available after reload');
        return;
      }
    } else if (expectedDuration.inMilliseconds > 0) {
      // Check if controller duration is suspiciously different (more than 50% difference)
      final ratio = duration.inMilliseconds / expectedDuration.inMilliseconds;
      if (ratio < 0.5 || ratio > 2.0) {
        print('⚠️ Controller duration ${duration.inSeconds}s differs significantly from expected ${expectedDuration.inSeconds}s, using expected');
        duration = expectedDuration;
      }
    }
    
    _controller!.addListener(_videoListener);
    
    setState(() {
      _videoDuration = duration!;
      _trimEnd = _videoDuration;
      // Reset trim start to zero when reloading
      _trimStart = Duration.zero;
    });
    print('✅ Video reloaded with duration: ${_videoDuration.inSeconds}s');
  }

  Future<void> _handleSave() async {
    setState(() {
      _isEditing = true;
      _hasError = false;
    });

    try {
      // Get the starting video path (edited or original) - use full URL
      String currentVideoPath = _editedVideoPath ?? _persistedVideoPath ?? widget.videoPath;
      print('🎬 Saving video starting with path: $currentVideoPath');

      // Step 1: Apply trim if needed
      final needsTrim = _trimStart > Duration.zero || _trimEnd < _videoDuration;
      if (needsTrim) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Applying trim...'),
            duration: Duration(seconds: 1),
          ),
        );
        
        final trimmedPath = await _editingService.trimVideo(
          currentVideoPath,
          _trimStart,
          _trimEnd,
          onProgress: (progress) {},
          onError: (error) {
            setState(() {
              _isEditing = false;
              _hasError = true;
              _errorMessage = error;
            });
            throw Exception(error);
          },
        );
        
        if (trimmedPath != null) {
          currentVideoPath = trimmedPath;
        } else {
          throw Exception('Failed to trim video');
        }
      }

      // Step 2: Apply audio changes if needed
      if (_audioRemoved && _audioFilePath == null) {
        // Audio was removed, need to apply removal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removing audio...'),
            duration: Duration(seconds: 1),
          ),
        );
        
        final noAudioPath = await _editingService.removeAudioTrack(
          currentVideoPath,
          onProgress: (progress) {},
          onError: (error) {
            setState(() {
              _isEditing = false;
              _hasError = true;
              _errorMessage = error;
            });
            throw Exception(error);
          },
        );
        
        if (noAudioPath != null) {
          currentVideoPath = noAudioPath;
        } else {
          throw Exception('Failed to remove audio');
        }
      } else if (_audioFilePath != null && !_audioRemoved) {
        // Audio was added, need to apply addition
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Adding audio track...'),
            duration: Duration(seconds: 1),
          ),
        );
        
        final withAudioPath = await _editingService.addAudioTrack(
          currentVideoPath,
          _audioFilePath!,
          onProgress: (progress) {},
          onError: (error) {
            setState(() {
              _isEditing = false;
              _hasError = true;
              _errorMessage = error;
            });
            throw Exception(error);
          },
        );
        
        if (withAudioPath != null) {
          currentVideoPath = withAudioPath;
        } else {
          throw Exception('Failed to add audio');
        }
      }

      // Step 3: Apply text overlays if any exist
      if (_textOverlays.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Applying ${_textOverlays.length} text overlay(s)...'),
            duration: const Duration(seconds: 1),
          ),
        );
        
        final withTextPath = await _editingService.addTextOverlays(
          currentVideoPath,
          _textOverlays,
          onProgress: (progress) {},
          onError: (error) {
            setState(() {
              _isEditing = false;
              _hasError = true;
              _errorMessage = error;
            });
            throw Exception(error);
          },
        );
        
        if (withTextPath != null) {
          currentVideoPath = withTextPath;
        } else {
          throw Exception('Failed to add text overlays');
        }
      }

      // All edits applied successfully
      setState(() {
        _isEditing = false;
      });

      // Clear saved state after successful save
      await StatePersistence.clearVideoEditorState();

      // Navigate to preview page with final video
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All edits applied successfully!'),
            backgroundColor: AppColors.successMain,
            duration: Duration(seconds: 2),
          ),
        );
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPreviewScreenWeb(
              videoUri: currentVideoPath,
              source: 'editor',
              duration: _videoDuration.inSeconds,
              fileSize: 0,
            ),
          ),
        );
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
            content: Text('Error saving video: $e'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
    }
  }

  String _formatTime(Duration duration) {
    // Handle invalid durations
    if (duration == Duration.zero || duration.isNegative || duration.inSeconds < 0) {
      return '00:00';
    }
    final totalSeconds = duration.inSeconds;
    if (totalSeconds.isNaN || totalSeconds.isInfinite) {
      return '00:00';
    }
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _hideVideoControlsTimer?.cancel();
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Container(
          padding: ResponsiveGridDelegate.getResponsivePadding(context),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primaryMain),
                const SizedBox(height: AppSpacing.medium),
                Text(
                  'Loading video editor...',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Container(
          padding: ResponsiveGridDelegate.getResponsivePadding(context),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: StyledPageHeader(
                      title: 'Video Editor',
                      size: StyledPageHeaderSize.h2,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.errorMain,
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      Text(
                        'Error loading video',
                        style: AppTypography.heading3.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.small),
                        Padding(
                          padding: EdgeInsets.all(AppSpacing.medium),
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handleBackPressed();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Container(
          padding: EdgeInsets.all(isMobile ? AppSpacing.medium : AppSpacing.large),
          child: Column(
            children: [
              // Header - Fixed at top
              _buildHeader(),
              const SizedBox(height: AppSpacing.large),
              
              // Main Content Area
              Expanded(
                child: isMobile
                    ? SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildMobileLayout(),
                            const SizedBox(height: AppSpacing.large),
                            _buildTimelineSection(),
                            _buildEditingToolsPanel(),
                            const SizedBox(height: AppSpacing.extraLarge),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // Desktop Layout (Row with Expanded - needs proper constraints)
                          Expanded(
                            child: _buildDesktopLayout(),
                          ),
                          const SizedBox(height: AppSpacing.large),
                          // Timeline Section (fixed height)
                          _buildTimelineSection(),
                          // Editing Tools Panel
                          _buildEditingToolsPanel(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.warmBrown),
            onPressed: () async {
              final shouldPop = await _handleBackPressed();
              if (shouldPop && mounted) {
                Navigator.of(context).pop();
              }
            },
            tooltip: 'Back',
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _projectTitle ?? 'Video Editor',
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_videoDuration != Duration.zero)
                  Text(
                    '${_resolution} • ${_fps.toStringAsFixed(0)}fps • ${_formatTime(_videoDuration)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Action buttons - scrollable on mobile
          if (isMobile)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.small),
                      child: _buildHeaderButton(
                        icon: Icons.undo,
                        tooltip: 'Undo',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Undo feature coming soon'),
                              backgroundColor: AppColors.infoMain,
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.small),
                      child: _buildHeaderButton(
                        icon: Icons.redo,
                        tooltip: 'Redo',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Redo feature coming soon'),
                              backgroundColor: AppColors.infoMain,
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.small),
                      child: IntrinsicWidth(
                        child: OutlinedButton.icon(
                          onPressed: (_isSavingDraft || _isEditing) ? null : _saveDraft,
                          icon: _isSavingDraft
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.warmBrown,
                                  ),
                                )
                              : Icon(Icons.bookmark_border, size: 18),
                          label: Text(_isSavingDraft ? 'Saving...' : 'Save Draft'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.warmBrown,
                            side: BorderSide(color: AppColors.warmBrown),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.small),
                      child: IntrinsicWidth(
                        child: StyledPillButton(
                          label: _isEditing ? 'Processing...' : 'Save & Continue',
                          icon: Icons.save,
                          onPressed: _isEditing ? null : _handleSave,
                          isLoading: _isEditing,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // Desktop: buttons in a Row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.small),
                  child: _buildHeaderButton(
                    icon: Icons.undo,
                    tooltip: 'Undo',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Undo feature coming soon'),
                          backgroundColor: AppColors.infoMain,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.medium),
                  child: _buildHeaderButton(
                    icon: Icons.redo,
                    tooltip: 'Redo',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Redo feature coming soon'),
                          backgroundColor: AppColors.infoMain,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.small),
                  child: IntrinsicWidth(
                    child: OutlinedButton.icon(
                      onPressed: (_isSavingDraft || _isEditing) ? null : _saveDraft,
                      icon: _isSavingDraft
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.warmBrown,
                              ),
                            )
                          : Icon(Icons.bookmark_border, size: 18),
                      label: Text(_isSavingDraft ? 'Saving...' : 'Save Draft'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warmBrown,
                        side: BorderSide(color: AppColors.warmBrown),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.small),
                  child: IntrinsicWidth(
                    child: StyledPillButton(
                      label: _isEditing ? 'Processing...' : 'Save & Continue',
                      icon: Icons.save,
                      onPressed: _isEditing ? null : _handleSave,
                      isLoading: _isEditing,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.borderPrimary),
        ),
        child: IconButton(
          icon: Icon(icon, color: AppColors.warmBrown, size: 20),
          onPressed: onPressed,
          padding: const EdgeInsets.all(AppSpacing.small),
          constraints: const BoxConstraints(),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Video Preview Section (Left - 60%)
            Expanded(
              flex: 60,
              child: _buildVideoPreview(constraints.maxHeight),
            ),
            const SizedBox(width: AppSpacing.medium),
            // Controls Panel (Right - 40%) - More space for editing tools
            Expanded(
              flex: 40,
              child: _buildControlsPanel(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildVideoPreview(400), // Fixed height for mobile
          const SizedBox(height: AppSpacing.large),
          _buildControlsPanel(),
        ],
      ),
    );
  }

  Widget _buildVideoPreview(double maxHeight) {
    // Calculate video preview height - use most of available space minus playback controls
    final videoHeight = (maxHeight - 80).clamp(200.0, maxHeight); // 80px for controls bar
    
    return Container(
      height: maxHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Video Player - Takes remaining space
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: MouseRegion(
                onEnter: (_) => _onVideoMouseEnter(),
                onExit: (_) => _onVideoMouseExit(),
                onHover: (_) => _onVideoMouseMove(),
                child: Container(
                  color: Colors.black,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Video player
                      if (_controller != null && _controller!.value.isInitialized)
                        Center(
                          child: AspectRatio(
                            aspectRatio: _controller!.value.aspectRatio,
                            child: VideoPlayer(_controller!),
                          ),
                        )
                      else
                        Center(
                          child: CircularProgressIndicator(
                            color: AppColors.warmBrown,
                          ),
                        ),
                      
                      // Text overlays
                      ..._textOverlays.where((overlay) {
                        final currentTime = _currentPosition;
                        return currentTime >= overlay.startTime && currentTime <= overlay.endTime;
                      }).map((overlay) => Positioned(
                        left: overlay.x * MediaQuery.of(context).size.width - 100,
                        top: overlay.y * MediaQuery.of(context).size.height - 20,
                        child: GestureDetector(
                          onTap: () => _editTextOverlay(overlay),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: overlay.backgroundColor != null
                                  ? Color(int.parse(overlay.backgroundColor!.replaceFirst('#', '0xff')))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              overlay.text,
                              style: TextStyle(
                                color: Color(overlay.color),
                                fontSize: overlay.fontSize,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: overlay.textAlign,
                            ),
                          ),
                        ),
                      )),
                      
                      // Controls Overlay
                      if (_controller != null && _controller!.value.isInitialized)
                        AnimatedOpacity(
                          opacity: _showVideoControls ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.2),
                                  Colors.black.withOpacity(0.6),
                                ],
                                stops: const [0.0, 0.7, 1.0],
                              ),
                            ),
                            child: Stack(
                              children: [
                                // Center Play/Pause Button
                                if (!_controller!.value.isPlaying || _isMouseOverVideo)
                                  Center(
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: _togglePlayPause,
                                        child: Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppColors.warmBrown,
                                                AppColors.accentMain,
                                              ],
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.warmBrown.withOpacity(0.4),
                                                blurRadius: 16,
                                                offset: const Offset(0, 4),
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            _controller!.value.isPlaying
                                                ? Icons.pause
                                                : Icons.play_arrow,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Playback Controls Bar
          _buildPlaybackControlsBar(),
        ],
      ),
    );
  }

  Widget _buildPlaybackControlsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium, vertical: AppSpacing.small),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: AppColors.borderPrimary),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress Bar
          if (_controller != null && _controller!.value.isInitialized)
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: AppColors.warmBrown,
                inactiveTrackColor: AppColors.borderPrimary,
                thumbColor: AppColors.warmBrown,
              ),
              child: Slider(
                value: _playheadPosition.clamp(0.0, 1.0),
                min: 0.0,
                max: 1.0,
                onChanged: (value) {
                  _onPlayheadDragStart();
                  _onPlayheadDragUpdate(value);
                  _onPlayheadDragEnd();
                },
                onChangeStart: (_) => _onPlayheadDragStart(),
                onChangeEnd: (_) => _onPlayheadDragEnd(),
              ),
            ),
          
          // Time and Controls
          Row(
            children: [
              Text(
                _formatTime(_currentPosition),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Text(
                '/ ${_formatTime(_videoDuration)}',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              // Play/Pause button
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.warmBrown,
                        AppColors.accentMain,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.warmBrown.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlsPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Tab Bar with header integrated
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium, vertical: AppSpacing.small),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.warmBrown.withOpacity(0.08),
                  AppColors.accentMain.withOpacity(0.03),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusLarge),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.tune, color: AppColors.warmBrown, size: 20),
                const SizedBox(width: AppSpacing.small),
                Text(
                  'Edit',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Compact Tab Bar
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderPrimary),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.warmBrown,
              indicatorWeight: 2,
              labelColor: AppColors.warmBrown,
              unselectedLabelColor: AppColors.textSecondary,
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              labelStyle: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.content_cut, size: 18), text: 'Trim'),
                Tab(icon: Icon(Icons.music_note, size: 18), text: 'Audio'),
                Tab(icon: Icon(Icons.text_fields, size: 18), text: 'Text'),
              ],
            ),
          ),
          
          // Tab Content - Takes all remaining space
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEditPanel(),
                _buildMusicPanel(),
                _buildTextPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    // Simplified controls - replacing complex timeline with clean pill-shaped UI
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.medium),
      padding: EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Playback Progress Bar
          _buildSimplifiedProgressBar(),
          const SizedBox(height: AppSpacing.medium),
          // Editing Controls Row
          _buildSimplifiedEditingControls(),
        ],
      ),
    );
  }

  /// Simplified progress bar with current position
  Widget _buildSimplifiedProgressBar() {
    return Column(
      children: [
        // Time display
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.medium, vertical: AppSpacing.small),
              decoration: BoxDecoration(
                color: AppColors.warmBrown.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                _formatTime(_currentPosition),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.warmBrown,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.medium, vertical: AppSpacing.small),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                _formatTime(_videoDuration),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        // Progress slider
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.warmBrown,
            inactiveTrackColor: AppColors.warmBrown.withOpacity(0.2),
            thumbColor: AppColors.warmBrown,
            overlayColor: AppColors.warmBrown.withOpacity(0.1),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: _videoDuration.inMilliseconds > 0
                ? (_currentPosition.inMilliseconds / _videoDuration.inMilliseconds).clamp(0.0, 1.0)
                : 0.0,
            onChanged: (value) {
              final newPosition = Duration(milliseconds: (value * _videoDuration.inMilliseconds).round());
              _controller?.seekTo(newPosition);
              setState(() {
                _currentPosition = newPosition;
                _playheadPosition = value;
              });
            },
          ),
        ),
      ],
    );
  }

  /// Simplified editing controls
  Widget _buildSimplifiedEditingControls() {
    return Wrap(
      spacing: AppSpacing.medium,
      runSpacing: AppSpacing.medium,
      alignment: WrapAlignment.center,
      children: [
        // Trim Start
        _buildControlPill(
          icon: Icons.content_cut,
          label: 'Trim Start',
          value: _formatTime(_trimStart),
          onTap: () => _showTrimStartPicker(),
        ),
        // Trim End
        _buildControlPill(
          icon: Icons.content_cut,
          label: 'Trim End',
          value: _formatTime(_trimEnd != Duration.zero ? _trimEnd : _videoDuration),
          onTap: () => _showTrimEndPicker(),
        ),
        // Audio Toggle
        _buildTogglePill(
          icon: _audioRemoved ? Icons.volume_off : Icons.volume_up,
          label: _audioRemoved ? 'Audio Removed' : 'Audio On',
          isActive: !_audioRemoved,
          onTap: () {
            setState(() {
              _audioRemoved = !_audioRemoved;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_audioRemoved ? 'Audio removed from video' : 'Audio restored'),
                backgroundColor: AppColors.warmBrown,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            );
          },
        ),
        // Play/Pause
        _buildActionPill(
          icon: _isPlaying ? Icons.pause : Icons.play_arrow,
          label: _isPlaying ? 'Pause' : 'Play',
          isPrimary: true,
          onTap: _togglePlayPause,
        ),
      ],
    );
  }

  Widget _buildControlPill({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.medium, vertical: AppSpacing.small),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.borderPrimary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.warmBrown, size: 18),
            const SizedBox(width: AppSpacing.small),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTogglePill({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.medium, vertical: AppSpacing.small),
        decoration: BoxDecoration(
          color: isActive ? AppColors.warmBrown.withOpacity(0.1) : AppColors.errorMain.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isActive ? AppColors.warmBrown : AppColors.errorMain,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.warmBrown : AppColors.errorMain,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.small),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isActive ? AppColors.warmBrown : AppColors.errorMain,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.large, vertical: AppSpacing.small + 4),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(
                  colors: [AppColors.warmBrown, AppColors.accentMain],
                )
              : null,
          color: isPrimary ? null : AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.warmBrown.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.white : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.small),
            Text(
              label,
              style: AppTypography.button.copyWith(
                color: isPrimary ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTrimStartPicker() {
    _showTimePicker(
      title: 'Set Trim Start',
      initialTime: _trimStart,
      maxTime: _trimEnd != Duration.zero ? _trimEnd : _videoDuration,
      onTimeSelected: (time) {
        setState(() {
          _trimStart = time;
        });
        _controller?.seekTo(time);
      },
    );
  }

  void _showTrimEndPicker() {
    _showTimePicker(
      title: 'Set Trim End',
      initialTime: _trimEnd != Duration.zero ? _trimEnd : _videoDuration,
      minTime: _trimStart,
      maxTime: _videoDuration,
      onTimeSelected: (time) {
        setState(() {
          _trimEnd = time;
        });
      },
    );
  }

  void _showTimePicker({
    required String title,
    required Duration initialTime,
    Duration? minTime,
    Duration? maxTime,
    required Function(Duration) onTimeSelected,
  }) {
    final minutes = initialTime.inMinutes;
    final seconds = initialTime.inSeconds % 60;
    int selectedMinutes = minutes;
    int selectedSeconds = seconds;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        title: Text(title, style: AppTypography.heading3),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Minutes
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Minutes', style: AppTypography.caption),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: DropdownButton<int>(
                    value: selectedMinutes,
                    underline: const SizedBox(),
                    isExpanded: true,
                    items: List.generate(
                      (maxTime?.inMinutes ?? 60) + 1,
                      (i) => DropdownMenuItem(value: i, child: Center(child: Text('$i'))),
                    ),
                    onChanged: (v) {
                      if (v != null) selectedMinutes = v;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Text(':', style: AppTypography.heading2),
            const SizedBox(width: 16),
            // Seconds
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Seconds', style: AppTypography.caption),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: DropdownButton<int>(
                    value: selectedSeconds,
                    underline: const SizedBox(),
                    isExpanded: true,
                    items: List.generate(
                      60,
                      (i) => DropdownMenuItem(value: i, child: Center(child: Text('${i.toString().padLeft(2, '0')}'))),
                    ),
                    onChanged: (v) {
                      if (v != null) selectedSeconds = v;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final time = Duration(minutes: selectedMinutes, seconds: selectedSeconds);
              onTimeSelected(time);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warmBrown,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('Apply', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEditingToolsPanel() {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.medium),
      height: 0,
      child: const SizedBox.shrink(),
    );
  }

  Widget _buildTimelineHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final markerCount = (_videoDuration.inSeconds ~/ 5).clamp(5, 20);
        return Container(
          height: 30,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.backgroundTertiary,
                AppColors.backgroundSecondary,
              ],
            ),
            border: Border(
              bottom: BorderSide(color: AppColors.borderPrimary, width: 2),
            ),
          ),
          child: Stack(
            children: [
              // Time markers
              Row(
                children: List.generate(
                  markerCount + 1,
                  (index) => Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: AppColors.borderPrimary,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 1,
                            height: 8,
                            color: AppColors.warmBrown,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(Duration(seconds: index * 5)),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Playhead
              Positioned(
                left: (_playheadPosition * constraints.maxWidth).clamp(0.0, constraints.maxWidth - 2),
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onPanStart: (_) => _onPlayheadDragStart(),
                  onPanUpdate: (details) {
                    final localPosition = details.localPosition;
                    final width = constraints.maxWidth;
                    final position = (localPosition.dx / width).clamp(0.0, 1.0);
                    _onPlayheadDragUpdate(position);
                  },
                  onPanEnd: (_) => _onPlayheadDragEnd(),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeLeftRight,
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: AppColors.warmBrown,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.warmBrown.withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -10,
                            left: -8,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.warmBrown,
                                    AppColors.accentMain,
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.warmBrown.withOpacity(0.4),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextTrack() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.backgroundPrimary,
            border: Border(
              bottom: BorderSide(color: AppColors.borderPrimary),
            ),
          ),
          child: Row(
            children: [
          // Track label
          Container(
            width: 80,
            padding: const EdgeInsets.all(AppSpacing.small),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              border: Border(
                right: BorderSide(color: AppColors.borderPrimary),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.text_fields, color: AppColors.warmBrown, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Text',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
              // Track content
              Expanded(
                child: Stack(
                  children: [
                    // Text overlay bars
                    ..._textOverlays.map((overlay) {
                      final startPosition = overlay.startTime.inMilliseconds / _videoDuration.inMilliseconds;
                      final duration = overlay.endTime.inMilliseconds - overlay.startTime.inMilliseconds;
                      final width = (duration / _videoDuration.inMilliseconds) * constraints.maxWidth;
                      
                      return Positioned(
                            left: (startPosition * constraints.maxWidth).clamp(0.0, constraints.maxWidth - width),
                        top: 4,
                        child: GestureDetector(
                          onTap: () => _editTextOverlay(overlay),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Container(
                              width: width.clamp(40.0, double.infinity),
                              height: 24,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.accentMain,
                                    AppColors.accentDark,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accentMain.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    child: const Icon(Icons.text_fields, color: Colors.white, size: 14),
                                  ),
                                  Expanded(
                                    child: Text(
                                      overlay.text,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoTrack() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        border: Border(
          bottom: BorderSide(color: AppColors.borderPrimary),
        ),
      ),
      child: Row(
        children: [
          // Track label
          Container(
            width: 80,
            padding: const EdgeInsets.all(AppSpacing.small),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              border: Border(
                right: BorderSide(color: AppColors.borderPrimary),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam, color: AppColors.warmBrown, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Video',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Track content
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.warmBrown.withOpacity(0.2),
                    AppColors.primaryMain.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.warmBrown.withOpacity(0.3),
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_circle_outline, color: AppColors.warmBrown, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Main Video Track',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioTrack() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
      ),
      child: Row(
        children: [
          // Track label
          Container(
            width: 80,
            padding: const EdgeInsets.all(AppSpacing.small),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              border: Border(
                right: BorderSide(color: AppColors.borderPrimary),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.music_note, color: AppColors.warmBrown, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Audio',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Track content
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _audioFilePath != null
                      ? [
                          AppColors.accentMain.withOpacity(0.2),
                          AppColors.accentDark.withOpacity(0.1),
                        ]
                      : _audioRemoved
                          ? [
                              AppColors.errorMain.withOpacity(0.1),
                              AppColors.errorMain.withOpacity(0.05),
                            ]
                          : [
                              AppColors.backgroundTertiary,
                              AppColors.backgroundSecondary,
                            ],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _audioFilePath != null
                      ? AppColors.accentMain.withOpacity(0.3)
                      : AppColors.borderPrimary,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _audioFilePath != null
                          ? Icons.volume_up
                          : _audioRemoved
                              ? Icons.volume_off
                              : Icons.music_off,
                      color: _audioFilePath != null
                          ? AppColors.accentMain
                          : AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _audioFilePath != null
                          ? 'Audio track loaded'
                          : _audioRemoved
                              ? 'Audio removed'
                              : 'No audio track',
                      style: AppTypography.bodySmall.copyWith(
                        color: _audioFilePath != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: _audioFilePath != null ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEditPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Section Header
          Row(
            children: [
              Icon(Icons.content_cut, color: AppColors.warmBrown, size: 18),
              const SizedBox(width: AppSpacing.small),
              Text(
                'Trim Video',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          
          // Trim Controls - Only show if video duration is valid
          if (_videoDuration == Duration.zero || 
              _videoDuration.inSeconds <= 0 || 
              _videoDuration.inMilliseconds <= 0 ||
              _videoDuration.inSeconds.isNaN ||
              _videoDuration.inSeconds.isInfinite)
            Container(
              padding: const EdgeInsets.all(AppSpacing.large),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.errorMain.withOpacity(0.3)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppColors.errorMain),
                    const SizedBox(height: AppSpacing.medium),
                    Text(
                      'Video duration is not available',
                      style: AppTypography.heading4.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      'Please wait for the video to load completely.\nThe video may be in an unsupported format or corrupted.',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.borderPrimary),
              ),
              child: Column(
                children: [
                // Start Time - Compact
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Start',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.small,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warmBrown.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            _formatTime(_trimStart),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.warmBrown,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Builder(
                      builder: (context) {
                        // Get duration and ensure it's valid
                        final durationSeconds = _videoDuration.inSeconds;
                        final maxValue = durationSeconds > 0 
                            ? durationSeconds.toDouble() 
                            : 1.0;
                        final trimStartValue = _trimStart.inSeconds.toDouble().clamp(0.0, maxValue);
                        
                        // Only show slider if duration is valid
                        if (maxValue <= 0 || maxValue.isNaN || maxValue.isInfinite) {
                          return Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.borderPrimary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }
                        
                        return SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 6,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                            activeTrackColor: AppColors.warmBrown,
                            inactiveTrackColor: AppColors.borderPrimary,
                            thumbColor: AppColors.warmBrown,
                          ),
                          child: Slider(
                            value: trimStartValue,
                            min: 0.0,
                            max: maxValue,
                            onChanged: (value) {
                              if (maxValue > 0 && durationSeconds > 0) {
                                final clampedValue = value.clamp(0.0, maxValue);
                                setState(() {
                                  _trimStart = Duration(seconds: clampedValue.toInt());
                                  if (_trimStart >= _trimEnd) {
                                    final newEndSeconds = (clampedValue + 1).toInt();
                                    _trimEnd = Duration(seconds: newEndSeconds.clamp(0, durationSeconds));
                                  }
                                });
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.medium),
                
                // End Time - Compact
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'End',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.small,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warmBrown.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            _formatTime(_trimEnd),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.warmBrown,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Builder(
                      builder: (context) {
                        // Get duration and ensure it's valid
                        final durationSeconds = _videoDuration.inSeconds;
                        final maxValue = durationSeconds > 0 
                            ? durationSeconds.toDouble() 
                            : 1.0;
                        final trimEndValue = _trimEnd.inSeconds.toDouble().clamp(0.0, maxValue);
                        
                        // Only show slider if duration is valid
                        if (maxValue <= 0 || maxValue.isNaN || maxValue.isInfinite) {
                          return Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.borderPrimary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }
                        
                        return SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 6,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                            activeTrackColor: AppColors.warmBrown,
                            inactiveTrackColor: AppColors.borderPrimary,
                            thumbColor: AppColors.warmBrown,
                          ),
                          child: Slider(
                            value: trimEndValue,
                            min: 0.0,
                            max: maxValue,
                            onChanged: (value) {
                              if (maxValue > 0 && durationSeconds > 0) {
                                final clampedValue = value.clamp(0.0, maxValue);
                                setState(() {
                                  _trimEnd = Duration(seconds: clampedValue.toInt());
                                  if (_trimEnd <= _trimStart) {
                                    final newStartSeconds = (clampedValue - 1).toInt();
                                    _trimStart = Duration(seconds: newStartSeconds.clamp(0, durationSeconds));
                                  }
                                });
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.medium),
          
          // Apply Button - Compact
          if (_videoDuration != Duration.zero && 
              _videoDuration.inSeconds > 0 && 
              _videoDuration.inMilliseconds > 0 &&
              !_videoDuration.inSeconds.isNaN &&
              !_videoDuration.inSeconds.isInfinite)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isEditing ? null : _applyTrim,
                icon: Icon(Icons.check_circle, size: 18),
                label: Text(
                  _isEditing ? 'Processing...' : 'Apply Trim',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warmBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.medium,
                    vertical: AppSpacing.small,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMusicPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.small),
                decoration: BoxDecoration(
                  color: AppColors.warmBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  Icons.music_note,
                  color: AppColors.warmBrown,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Text(
                'Audio Track',
                style: AppTypography.heading4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          
          // Audio Status Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.large),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.borderPrimary),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  decoration: BoxDecoration(
                    color: _audioFilePath != null
                        ? AppColors.accentMain.withOpacity(0.1)
                        : _audioRemoved
                            ? AppColors.errorMain.withOpacity(0.1)
                            : AppColors.backgroundTertiary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _audioFilePath != null
                        ? Icons.volume_up
                        : _audioRemoved
                            ? Icons.volume_off
                            : Icons.music_off,
                    color: _audioFilePath != null
                        ? AppColors.accentMain
                        : _audioRemoved
                            ? AppColors.errorMain
                            : AppColors.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _audioFilePath != null
                            ? 'Audio Track Loaded'
                            : _audioRemoved
                                ? 'Audio Removed'
                                : 'No Audio Track',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _audioFilePath != null
                            ? 'Custom audio track is active'
                            : _audioRemoved
                                ? 'Original audio has been removed'
                                : 'Video has original audio track',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.large),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isEditing || _audioRemoved ? null : _removeAudio,
                  icon: const Icon(Icons.volume_off),
                  label: const Text('Remove Audio'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.errorMain,
                    side: BorderSide(color: AppColors.errorMain, width: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.large,
                      vertical: AppSpacing.medium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isEditing ? null : _selectAudioFile,
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Add Audio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warmBrown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.large,
                      vertical: AppSpacing.medium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.small),
                decoration: BoxDecoration(
                  color: AppColors.warmBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  Icons.text_fields,
                  color: AppColors.warmBrown,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Text(
                'Text Overlays',
                style: AppTypography.heading4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          
          // Add Text Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addTextOverlay,
              icon: const Icon(Icons.add_circle),
              label: const Text('Add Text Overlay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warmBrown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.extraLarge,
                  vertical: AppSpacing.medium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 2,
              ),
            ),
          ),
          
          // Text Overlays List
          if (_textOverlays.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.large),
            Text(
              'Active Overlays (${_textOverlays.length})',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            ..._textOverlays.map((overlay) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.small),
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _selectedTextOverlay?.id == overlay.id
                      ? AppColors.warmBrown
                      : AppColors.borderPrimary,
                  width: _selectedTextOverlay?.id == overlay.id ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.small),
                    decoration: BoxDecoration(
                      color: AppColors.accentMain.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(
                      Icons.text_fields,
                      color: AppColors.accentMain,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          overlay.text,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatTime(overlay.startTime)} - ${_formatTime(overlay.endTime)}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: AppColors.warmBrown,
                      size: 20,
                    ),
                    onPressed: () => _editTextOverlay(overlay),
                    tooltip: 'Edit',
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

}

/// Simple Color Picker Dialog
class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;

  const _ColorPickerDialog({required this.initialColor});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick a Color'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Color preview
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: _selectedColor,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.borderPrimary),
              ),
              child: Center(
                child: Text(
                  '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}',
                  style: TextStyle(
                    color: _selectedColor.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            // RGB sliders
            _buildColorSlider(
              'Red',
              _selectedColor.red,
              (value) {
                setState(() {
                  _selectedColor = Color.fromRGBO(
                    value.toInt(),
                    _selectedColor.green,
                    _selectedColor.blue,
                    1.0,
                  );
                });
              },
              Colors.red,
            ),
            const SizedBox(height: AppSpacing.medium),
            _buildColorSlider(
              'Green',
              _selectedColor.green,
              (value) {
                setState(() {
                  _selectedColor = Color.fromRGBO(
                    _selectedColor.red,
                    value.toInt(),
                    _selectedColor.blue,
                    1.0,
                  );
                });
              },
              Colors.green,
            ),
            const SizedBox(height: AppSpacing.medium),
            _buildColorSlider(
              'Blue',
              _selectedColor.blue,
              (value) {
                setState(() {
                  _selectedColor = Color.fromRGBO(
                    _selectedColor.red,
                    _selectedColor.green,
                    value.toInt(),
                    1.0,
                  );
                });
              },
              Colors.blue,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedColor),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warmBrown,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text('Select'),
        ),
      ],
    );
  }

  Widget _buildColorSlider(
    String label,
    int value,
    ValueChanged<double> onChanged,
    Color trackColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value.toString(),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            activeTrackColor: trackColor,
            inactiveTrackColor: trackColor.withOpacity(0.3),
            thumbColor: trackColor,
          ),
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            divisions: 255,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

