import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' if (dart.library.html) '../../utils/file_stub.dart' as io;
import 'package:file_picker/file_picker.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../utils/editor_responsive.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../services/audio_editing_service.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/state_persistence.dart';
import '../../utils/unsaved_changes_guard.dart';
import '../../models/content_draft.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:html' if (dart.library.io) '../../utils/file_stub.dart' as html;
import 'dart:async';
import 'package:http/http.dart' as http;

/// Audio Editor Screen
/// Allows users to edit audio: trim, merge
class AudioEditorScreen extends StatefulWidget {
  final String audioPath;
  final String? title;
  final Duration? duration; // Optional duration from backend (FFprobe)

  const AudioEditorScreen({
    super.key,
    required this.audioPath,
    this.title,
    this.duration,
  });

  @override
  State<AudioEditorScreen> createState() => _AudioEditorScreenState();
}

class _AudioEditorScreenState extends State<AudioEditorScreen> {
  AudioPlayer? _player;
  final AudioEditingService _editingService = AudioEditingService();
  
  bool _isInitializing = true;
  bool _isEditing = false;
  bool _hasError = false;
  String? _errorMessage;
  
  Duration _audioDuration = Duration.zero;
  Duration _trimStart = Duration.zero;
  Duration _trimEnd = Duration.zero;
  
  List<String> _filesToMerge = [];
  String? _editedAudioPath;
  String? _persistedAudioPath; // Track the persisted path (backend URL if blob was uploaded)
  final ApiService _apiService = ApiService();
  
  // Draft state
  int? _draftId;
  bool _isSavingDraft = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Add beforeunload warning for unsaved changes
      html.window.onBeforeUnload.listen((event) {
        if (_editedAudioPath != null || _hasUnsavedChanges()) {
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
           (_trimEnd != Duration.zero && _trimEnd != _audioDuration) ||
           _filesToMerge.isNotEmpty;
  }

  /// Save current editing state as a draft
  Future<bool> _saveDraft() async {
    if (_isSavingDraft) return false;
    
    setState(() {
      _isSavingDraft = true;
    });
    
    try {
      final editingState = <String, dynamic>{
        'trim_start': _trimStart.inMilliseconds,
        'trim_end': _trimEnd.inMilliseconds,
        'files_to_merge': _filesToMerge,
      };
      
      final draftData = {
        'draft_type': DraftType.audioPodcast.value,
        'title': widget.title ?? 'Audio Draft',
        'original_media_url': _persistedAudioPath ?? widget.audioPath,
        'edited_media_url': _editedAudioPath,
        'editing_state': editingState,
        'duration': _audioDuration.inSeconds,
        'status': DraftStatus.editing.value,
      };
      
      Map<String, dynamic> result;
      
      if (_draftId != null) {
        result = await _apiService.updateDraft(_draftId!, draftData);
      } else {
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
    if (!_hasUnsavedChanges() && _editedAudioPath == null) {
      return true;
    }
    
    final result = await UnsavedChangesGuard.showUnsavedChangesDialog(context);
    
    if (result == null) {
      return false;
    } else if (result) {
      final saved = await _saveDraft();
      return saved;
    } else {
      return true;
    }
  }

  /// Initialize editor from saved state or widget parameters
  /// 
  /// This method handles:
  /// 1. Loading saved state from localStorage (if available and not expired)
  /// 2. Validating saved state is compatible with current environment
  /// 3. Uploading blob URLs to backend for persistence
  /// 4. Converting relative paths to full URLs based on environment
  /// 5. Restoring all editor settings (trim, merge files)
  /// 
  /// Environment Handling:
  /// - Clears stale localhost URLs when running in production
  /// - Preserves state when environment matches
  /// 
  /// Blob URL Handling:
  /// - Detects blob URLs from MediaRecorder
  /// - Uploads to backend via uploadTemporaryMedia()
  /// - Converts to full backend URL for editing operations
  Future<void> _initializeFromSavedState() async {
    try {
      final savedState = await StatePersistence.loadAudioEditorState();
      if (savedState != null && mounted) {
        final savedAudioPath = savedState['audioPath'] as String?;
        final savedEditedPath = savedState['editedAudioPath'] as String?;
        final trimStartMs = savedState['trimStart'] as int?;
        final trimEndMs = savedState['trimEnd'] as int?;

        if (savedAudioPath != null) {
          // Use saved path (which should be backend URL if blob was uploaded)
          _persistedAudioPath = savedAudioPath;
          
          // Restore trim values
          if (trimStartMs != null) {
            _trimStart = Duration(milliseconds: trimStartMs);
          }
          if (trimEndMs != null) {
            _trimEnd = Duration(milliseconds: trimEndMs);
          }

          // Restore edited path if exists
          if (savedEditedPath != null) {
            _editedAudioPath = savedEditedPath;
          }

          print('✅ Restored audio editor state from saved state');
        }
      }

      // If we have a blob URL in widget.audioPath, upload it first
      String audioPathToUse = widget.audioPath;
      if (kIsWeb && widget.audioPath.startsWith('blob:')) {
        try {
          print('📤 Uploading blob URL to backend for persistence...');
          final uploadResult = await _apiService.uploadTemporaryMedia(widget.audioPath, 'audio');
          if (uploadResult != null) {
            final backendUrl = uploadResult['url'] as String?;
            if (backendUrl != null) {
              // Convert relative path to full URL
              audioPathToUse = _apiService.getMediaUrl(backendUrl);
              _persistedAudioPath = backendUrl; // Save original path for state persistence
              // Save state with backend URL (relative path)
              await StatePersistence.saveAudioEditorState(
                audioPath: backendUrl,
                editedAudioPath: _editedAudioPath,
                trimStart: _trimStart,
                trimEnd: _trimEnd,
              );
              print('✅ Blob URL uploaded to backend: $audioPathToUse (from $backendUrl)');
            }
          }
        } catch (e) {
          print('⚠️ Failed to upload blob URL, using original: $e');
        }
      } else if (_persistedAudioPath == null) {
        _persistedAudioPath = audioPathToUse;
      }

      // Use persisted path or widget path - convert to full URL if needed
      final pathToLoad = _persistedAudioPath ?? audioPathToUse;
      // Convert to full URL if it's a relative path (not already http/https/blob)
      final finalPath = (pathToLoad.startsWith('http://') || 
                         pathToLoad.startsWith('https://') || 
                         pathToLoad.startsWith('blob:'))
          ? pathToLoad 
          : _apiService.getMediaUrl(pathToLoad);
      
      // Use provided duration from widget if available (from backend FFprobe)
      final durationToUse = widget.duration;
      await _initializePlayer(finalPath, providedDuration: durationToUse);
    } catch (e) {
      print('❌ Error initializing from saved state: $e');
      await _initializePlayer(widget.audioPath, providedDuration: widget.duration);
    }
  }

  /// Check if URL is from CloudFront (production)
  bool _isCloudFrontUrl(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return false;
    }
    // Check for CloudFront domain
    if (url.contains('cloudfront.net')) {
      return true;
    }
    // Check if mediaBaseUrl is CloudFront (production)
    final mediaBase = ApiService.mediaBaseUrl;
    if (mediaBase.isNotEmpty && 
        (mediaBase.contains('cloudfront.net') || 
         mediaBase.contains('.amazonaws.com'))) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        final host = uri.host;
        if (host.contains('cloudfront.net') || host.contains('.amazonaws.com')) {
          return true;
        }
      }
    }
    return false;
  }

  /// Get duration using Web Audio API (decodes entire file - expensive, use as last resort)
  /// This is a final fallback when other methods fail
  /// Note: Full implementation requires dart:js_interop - simplified version for now
  Future<Duration?> _getDurationFromWebAudioApi(String audioUrl) async {
    if (!kIsWeb) return null;
    
    // Skip CloudFront URLs - they have CORS issues
    if (_isCloudFrontUrl(audioUrl)) {
      print('⏭️ Skipping Web Audio API for CloudFront URL (CORS issues)');
      return null;
    }
    
    try {
      print('🎵 Attempting Web Audio API fallback for duration (this may take a moment - loading entire file)...');
      
      // Fetch audio file as bytes
      // Get auth headers for authenticated requests
      final authService = AuthService();
      final headers = await authService.getAuthHeaders();
      final response = await http.get(Uri.parse(audioUrl), headers: headers);
      if (response.statusCode != 200) {
        print('❌ Failed to fetch audio for Web Audio API: HTTP ${response.statusCode}');
        return null;
      }
      
      // Note: Full Web Audio API implementation requires dart:js_interop or package:js
      // Since backend FFprobe is more reliable and already implemented, 
      // we skip Web Audio API for now to avoid complexity
      // If needed in future, can implement using:
      // - package:js for JS interop
      // - AudioContext.decodeAudioData() to get AudioBuffer
      // - AudioBuffer.duration to get duration
      
      print('⚠️ Web Audio API fallback not fully implemented - backend FFprobe should be used instead');
      return null;
    } catch (e) {
      print('❌ Error getting duration from Web Audio API: $e');
      return null;
    }
  }

  /// Get duration from audio URL using HTML5 audio element directly
  /// This is a workaround for WebM audio files that don't expose duration immediately via just_audio
  Future<Duration?> _getDurationFromAudioUrl(String audioUrl) async {
    if (!kIsWeb) return null;
    
    // Skip CloudFront URLs - they have CORS issues with HTML5 AudioElement
    if (_isCloudFrontUrl(audioUrl)) {
      print('⏭️ Skipping HTML5 AudioElement for CloudFront URL (CORS issues)');
      return null;
    }
    
    try {
      print('🎵 Attempting to get duration from HTML5 AudioElement for: $audioUrl');
      
      // First, verify the file is accessible by making a HEAD request
      try {
        final response = await http.head(Uri.parse(audioUrl));
        print('📡 File accessibility check - Status: ${response.statusCode}, Content-Type: ${response.headers['content-type']}');
        if (response.statusCode != 200) {
          print('❌ File not accessible - HTTP ${response.statusCode}');
          return null;
        }
      } catch (e) {
        print('⚠️ Could not verify file accessibility: $e');
        // Continue anyway - might be CORS issue but file could still load
      }
      
      final audioElement = html.AudioElement()
        ..src = audioUrl
        ..preload = 'metadata'
        ..crossOrigin = 'anonymous'; // Important for CORS
      
      // Wait for metadata to load
      final completer = Completer<Duration?>();
      
      void checkDuration() {
        if (audioElement.readyState >= html.MediaElement.HAVE_METADATA) {
          final durationSeconds = audioElement.duration;
          
          // Check for Infinity or invalid duration values
          if (durationSeconds != null) {
            if (durationSeconds.isInfinite) {
              print('⚠️ HTML5 AudioElement reports Infinity duration - WebM file may not have duration metadata');
              // Don't complete with Infinity - return null to trigger fallback
              return;
            }
            if (durationSeconds.isNaN) {
              print('⚠️ HTML5 AudioElement reports NaN duration');
              return;
            }
            if (!durationSeconds.isFinite) {
              print('⚠️ HTML5 AudioElement reports non-finite duration: $durationSeconds');
              return;
            }
            if (durationSeconds <= 0) {
              print('⚠️ HTML5 AudioElement reports invalid duration: $durationSeconds');
              return;
            }
            
            // Valid duration
            final duration = Duration(milliseconds: (durationSeconds * 1000).round());
            print('✅ HTML5 AudioElement duration detected: ${duration.inSeconds}s');
            completer.complete(duration);
            return;
          }
        }
      }
      
      audioElement.onLoadedMetadata.listen((_) {
        checkDuration();
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });
      
      audioElement.onError.listen((event) {
        final errorCode = audioElement.error?.code;
        final errorMessage = audioElement.error?.message ?? "Unknown error";
        print('❌ HTML5 AudioElement error - Code: $errorCode, Message: $errorMessage');
        print('❌ AudioElement src: ${audioElement.src}');
        print('❌ AudioElement readyState: ${audioElement.readyState}');
        print('❌ AudioElement networkState: ${audioElement.networkState}');
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });
      
      // Also listen for network state changes to debug loading issues
      audioElement.onCanPlay.listen((_) {
        print('✅ HTML5 AudioElement can play - duration: ${audioElement.duration}');
      });
      
      audioElement.onLoadedData.listen((_) {
        print('✅ HTML5 AudioElement data loaded - duration: ${audioElement.duration}');
        checkDuration(); // Check duration when data is loaded
      });
      
      // Load the audio
      audioElement.load();
      
      // Check immediately in case metadata is already loaded
      checkDuration();
      
      // Wait for metadata with timeout
      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          // Try one more time
          checkDuration();
          final durationSeconds = audioElement.duration;
          print('⏱️ HTML5 AudioElement timeout check - duration: $durationSeconds, readyState: ${audioElement.readyState}, networkState: ${audioElement.networkState}');
          
          // Check for Infinity or invalid duration
          if (durationSeconds != null) {
            if (durationSeconds.isInfinite) {
              print('⚠️ HTML5 AudioElement reports Infinity duration (timeout) - WebM file lacks duration metadata');
              return null; // Trigger backend fallback
            }
            if (durationSeconds.isNaN || !durationSeconds.isFinite || durationSeconds <= 0) {
              print('⚠️ HTML5 AudioElement reports invalid duration: $durationSeconds');
              return null;
            }
            
            // Valid duration
            final duration = Duration(milliseconds: (durationSeconds * 1000).round());
            print('✅ HTML5 AudioElement duration detected (timeout): ${duration.inSeconds}s');
            return duration;
          }
          
          print('⚠️ HTML5 AudioElement duration not available after timeout');
          print('⚠️ Final state - readyState: ${audioElement.readyState}, networkState: ${audioElement.networkState}, error: ${audioElement.error?.message ?? "none"}');
          return null;
        },
      );
    } catch (e) {
      print('❌ Error getting duration from HTML5 AudioElement: $e');
      return null;
    }
  }

  /// Initialize player with given path
  /// [providedDuration] - Duration from backend (FFprobe) - most reliable source
  Future<void> _initializePlayer(String audioPath, {Duration? providedDuration}) async {
    print('🎵 Initializing audio player with path: $audioPath');
    
    // Use provided duration first (from backend FFprobe) - most reliable
    Duration? duration = providedDuration;
    if (duration != null && duration != Duration.zero && duration.inMilliseconds > 0) {
      print('✅ Using provided duration from backend (FFprobe): ${duration.inSeconds}s');
      _audioDuration = duration;
      if (_trimEnd == Duration.zero) {
        _trimEnd = _audioDuration;
      }
      setState(() {
        _isInitializing = false;
      });
      
      // Still initialize player for playback, but we already have duration
      try {
        _player = AudioPlayer();
        final isNetwork = audioPath.startsWith('http') || audioPath.startsWith('blob:');
        if (isNetwork || kIsWeb) {
          await _player!.setUrl(audioPath);
        } else {
          await _player!.setFilePath(audioPath);
        }
      } catch (e) {
        print('⚠️ Error initializing player (but duration is available): $e');
      }
      return; // Early return - we have duration, no need to detect
    }
    
    try {
      _player = AudioPlayer();
      
      // Check if path is network URL, blob URL, or local file
      final isNetwork = audioPath.startsWith('http') || audioPath.startsWith('blob:');
      
      if (isNetwork || kIsWeb) {
        // On web or for network URLs, use setUrl
        print('🌐 Loading audio from URL: $audioPath');
        
        // Listen for player state changes to catch errors
        _player!.playerStateStream.listen((state) {
          print('🎵 just_audio player state: ${state.processingState}, playing: ${state.playing}');
          // Check for error states (idle after loading usually means error)
          if (state.processingState == ProcessingState.idle && state.playing == false) {
            // This might indicate an error, but we'll rely on durationStream for actual detection
            print('⚠️ just_audio in idle state - may indicate loading issue');
          }
        });
        
        await _player!.setUrl(audioPath);
      } else {
        // On mobile, use setFilePath for local files
        print('📱 Loading audio from file path: $audioPath');
        await _player!.setFilePath(audioPath);
      }
      
      // Try to get duration from just_audio using durationStream
      try {
        print('⏳ Waiting for duration from just_audio...');
        duration = await _player!.durationStream
            .where((d) => d != null && d != Duration.zero && d.inMilliseconds > 0)
            .timeout(const Duration(seconds: 2))
            .first
            .catchError((e) {
              print('⚠️ just_audio duration not available after 2 seconds, trying HTML5 fallback...');
              return null;
            });
        
        if (duration != null && duration != Duration.zero && duration.inMilliseconds > 0) {
          print('✅ Duration from just_audio: ${duration.inSeconds}s');
        }
      } catch (e) {
        print('⚠️ Could not get duration from just_audio: $e');
        duration = null;
      }
      
      // If just_audio didn't provide duration, try HTML5 AudioElement fallback
      // BUT skip for CloudFront URLs (CORS issues)
      if (duration == null || duration == Duration.zero || duration.inMilliseconds <= 0) {
        if (kIsWeb && (audioPath.startsWith('http') || audioPath.startsWith('blob:'))) {
          // Skip HTML5 AudioElement for CloudFront URLs (CORS issues)
          if (!_isCloudFrontUrl(audioPath)) {
            print('🔄 Attempting HTML5 AudioElement fallback for duration detection...');
            final html5Duration = await _getDurationFromAudioUrl(audioPath);
            if (html5Duration != null && html5Duration != Duration.zero && html5Duration.inMilliseconds > 0) {
              duration = html5Duration;
              print('✅ Duration from HTML5 AudioElement: ${duration.inSeconds}s');
            } else {
              print('❌ HTML5 AudioElement also failed to get duration');
            }
          } else {
            print('⏭️ Skipping HTML5 AudioElement for CloudFront URL (CORS issues)');
          }
        }
      }
      
      // If still no duration, try backend endpoint (FFprobe) - most reliable for WebM files
      // This works with both local files and S3/CloudFront URLs
      if (duration == null || duration == Duration.zero || duration.inMilliseconds <= 0) {
        // Extract path from URL for backend call
        String? mediaPath;
        if (audioPath.startsWith('http://') || audioPath.startsWith('https://')) {
          // For CloudFront URLs, extract the path part (e.g., /audio/temp_xxx.webm)
          final uri = Uri.parse(audioPath);
          mediaPath = uri.path; // e.g., /audio/temp_xxx.webm
          // Remove leading slash for backend
          if (mediaPath.startsWith('/')) {
            mediaPath = mediaPath.substring(1);
          }
        } else if (audioPath.startsWith('/media/')) {
          mediaPath = audioPath.substring(7); // Remove /media/ prefix
        } else if (audioPath.startsWith('media/')) {
          mediaPath = audioPath.substring(6); // Remove media/ prefix
        } else if (!audioPath.startsWith('blob:')) {
          // Assume it's a relative path
          mediaPath = audioPath.startsWith('/') ? audioPath.substring(1) : audioPath;
        }
        
        if (mediaPath != null && !mediaPath.startsWith('blob:')) {
          print('🔄 Attempting backend duration endpoint (FFprobe)...');
          try {
            final durationSeconds = await _apiService.getMediaDuration(mediaPath);
            if (durationSeconds != null && durationSeconds > 0) {
              duration = Duration(seconds: durationSeconds);
              print('✅ Duration from backend (FFprobe): ${duration.inSeconds}s');
            }
          } catch (e) {
            print('⚠️ Backend duration endpoint failed: $e');
          }
        }
      }
      
      // If we still don't have duration, try one more time with just_audio (wait longer)
      if (duration == null || duration == Duration.zero || duration.inMilliseconds <= 0) {
        print('⏳ Final attempt: waiting up to 3 more seconds for just_audio duration...');
        int attempts = 0;
        while ((duration == null || duration == Duration.zero || duration.inMilliseconds <= 0) && attempts < 30) {
          await Future.delayed(const Duration(milliseconds: 100));
          duration = _player!.duration;
          attempts++;
        }
        
        if (duration != null && duration != Duration.zero && duration.inMilliseconds > 0) {
          print('✅ Duration from just_audio (delayed): ${duration.inSeconds}s');
        }
      }
      
      // Final fallback: Web Audio API - skip for CloudFront URLs
      if (duration == null || duration == Duration.zero || duration.inMilliseconds <= 0) {
        if (kIsWeb && audioPath.startsWith('http') && !audioPath.startsWith('blob:')) {
          // Skip Web Audio API for CloudFront URLs (CORS issues)
          if (!_isCloudFrontUrl(audioPath)) {
            print('🔄 Attempting Web Audio API as final fallback...');
            final webAudioDuration = await _getDurationFromWebAudioApi(audioPath);
            if (webAudioDuration != null && webAudioDuration != Duration.zero && webAudioDuration.inMilliseconds > 0) {
              duration = webAudioDuration;
              print('✅ Duration from Web Audio API: ${duration.inSeconds}s');
            }
          } else {
            print('⏭️ Skipping Web Audio API for CloudFront URL (CORS issues)');
          }
        }
      }
      
      // Set duration if we got it
      if (duration != null && duration != Duration.zero && duration.inMilliseconds > 0) {
        _audioDuration = duration;
        if (_trimEnd == Duration.zero) {
          _trimEnd = _audioDuration;
        }
        print('✅ Audio duration set: ${_audioDuration.inSeconds}s');
      } else {
        print('❌ Could not determine audio duration after all attempts');
        print('💡 This is common for WebM files from MediaRecorder. The file may need to be processed to add duration metadata.');
        setState(() {
          _hasError = true;
          _errorMessage = 'Could not load audio duration. This is common for WebM files recorded in the browser. Please try recording again or use a different audio format.';
        });
      }
      
      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      print('❌ Error initializing audio player: $e');
      setState(() {
        _isInitializing = false;
        _hasError = true;
        _errorMessage = 'Failed to load audio: ${e.toString()}';
      });
    }
  }

  Future<void> _applyTrim() async {
    // Validate audio duration
    if (_audioDuration == Duration.zero || _audioDuration.inSeconds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Audio duration is not available. Please wait for audio to load.'),
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

    // Validate trim values are within audio duration
    if (_trimStart < Duration.zero || _trimEnd > _audioDuration) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Trim values must be within audio duration'),
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
      final inputPath = _editedAudioPath ?? widget.audioPath;
      final outputPath = await _editingService.trimAudio(
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
                content: Text('Error trimming audio: $error'),
                backgroundColor: AppColors.errorMain,
              ),
            );
          }
        },
      );

      if (outputPath != null) {
        setState(() {
          _editedAudioPath = outputPath;
          _isEditing = false;
        });
        
        // Save state after successful trim
        await StatePersistence.saveAudioEditorState(
          audioPath: _persistedAudioPath ?? widget.audioPath,
          editedAudioPath: outputPath,
          trimStart: _trimStart,
          trimEnd: _trimEnd,
        );
        
        await _reloadPlayer(outputPath);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Audio trimmed successfully'),
              backgroundColor: AppColors.successMain,
            ),
          );
        }
      } else {
        setState(() {
          _isEditing = false;
          _hasError = true;
          _errorMessage = 'Failed to trim audio - no output path returned';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to trim audio. Please try again.'),
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
            content: Text('Error trimming audio: $e'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
    }
  }

  Future<void> _selectAudioFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
        withData: true, // Required on web to get bytes
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _isEditing = true;
        });
        
        final List<String> uploadedPaths = [];
        
        for (final file in result.files) {
          if (kIsWeb) {
            // On web, upload bytes to get URL
            if (file.bytes != null) {
              try {
                // Create blob URL from bytes for upload
                final blob = html.Blob([file.bytes!], 'audio/${file.extension ?? 'webm'}');
                final blobUrl = html.Url.createObjectUrlFromBlob(blob);
                
                // Upload to get backend URL
                final uploadResult = await _apiService.uploadTemporaryMedia(blobUrl, 'audio');
                if (uploadResult != null && uploadResult['url'] != null) {
                  uploadedPaths.add(uploadResult['url'] as String);
                }
                
                // Revoke blob URL to free memory
                html.Url.revokeObjectUrl(blobUrl);
              } catch (e) {
                print('Error uploading audio file: $e');
              }
            }
          } else {
            // On mobile/desktop, use file path
            if (file.path != null) {
              uploadedPaths.add(file.path!);
            }
          }
        }
        
        setState(() {
          _filesToMerge = uploadedPaths;
          _isEditing = false;
        });
        
        if (uploadedPaths.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${uploadedPaths.length} file(s) selected for merge')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No files could be processed')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting files: $e')),
      );
    }
  }

  Future<void> _mergeAudioFiles() async {
    if (_filesToMerge.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one audio file to merge')),
      );
      return;
    }

    final inputFiles = [_editedAudioPath ?? widget.audioPath, ..._filesToMerge];

    setState(() {
      _isEditing = true;
      _hasError = false;
    });

    final outputPath = await _editingService.mergeAudioFiles(
      inputFiles,
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
        _editedAudioPath = outputPath;
        _isEditing = false;
        _filesToMerge = []; // Clear after merge
      });
      
      // Save state after successful merge
      await StatePersistence.saveAudioEditorState(
        audioPath: _persistedAudioPath ?? widget.audioPath,
        editedAudioPath: outputPath,
        trimStart: _trimStart,
        trimEnd: _trimEnd,
      );
      
      await _reloadPlayer(outputPath);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio files merged successfully')),
      );
    }
  }

  // Fade methods removed - feature not in mobile

  Future<void> _reloadPlayer(String path) async {
    await _player?.dispose();
    _player = AudioPlayer();
    
    // Check if path is network URL, blob URL, or local file
    final isNetwork = path.startsWith('http') || path.startsWith('blob:');
    
    if (isNetwork || kIsWeb) {
      // On web or for network URLs, use setUrl
      await _player!.setUrl(path);
    } else {
      // On mobile, use setFilePath for local files
      await _player!.setFilePath(path);
    }
    
    // Wait for duration to be available (same as video editor)
    Duration? duration = _player!.duration;
    int attempts = 0;
    while ((duration == null || duration == Duration.zero || duration.inMilliseconds <= 0) && attempts < 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      duration = _player!.duration;
      attempts++;
    }
    
    if (duration == null || duration == Duration.zero || duration.inMilliseconds <= 0) {
      print('⚠️ Audio duration is not available after reload');
      // Don't update _audioDuration if we can't get it
      return;
    }
    
    setState(() {
      _audioDuration = duration!;
      _trimEnd = _audioDuration;
    });
  }

  void _handleExport() {
    if (_editedAudioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No edits to export')),
      );
      return;
    }

    // Clear saved state after export
    StatePersistence.clearAudioEditorState();

    // Return edited audio path to caller
    Navigator.pop(context, _editedAudioPath);
  }
  
  @override
  void dispose() {
    // Don't clear state on dispose - let it persist for refresh recovery
    _player?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }


  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Web version with design system
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
          padding: ResponsiveGridDelegate.getResponsivePadding(context),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ResponsiveGridDelegate.getMaxContentWidth(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with back button
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                        onPressed: () async {
                          final shouldPop = await _handleBackPressed();
                          if (shouldPop && mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        tooltip: 'Back',
                      ),
                      Expanded(
                        child: StyledPageHeader(
                          title: widget.title ?? 'Edit Audio',
                          size: StyledPageHeaderSize.h2,
                        ),
                      ),
                      // Save Draft button
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
                      if (_editedAudioPath != null)
                        Flexible(
                          child: StyledPillButton(
                            label: 'Export',
                            icon: Icons.download,
                            onPressed: _handleExport,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.extraLarge),
                  
                  // Content
                  if (_isInitializing)
                    SectionContainer(
                      showShadow: true,
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  else if (_hasError)
                    SectionContainer(
                      showShadow: true,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: AppColors.errorMain),
                            const SizedBox(height: AppSpacing.large),
                            Text(
                              'Error loading audio',
                              style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
                            ),
                            if (_errorMessage != null)
                              Padding(
                                padding: EdgeInsets.all(AppSpacing.medium),
                                child: Text(
                                  _errorMessage!,
                                  style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  else
                    _buildWebContent(),
                ],
              ),
            ),
          ),
        ),
      ),
      );
    } else {
      // Mobile version (original design)
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Edit Audio',
            style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
          ),
          actions: [
            if (_editedAudioPath != null)
              TextButton(
                onPressed: _handleExport,
                child: Text(
                  'Export',
                  style: AppTypography.body.copyWith(
                    color: AppColors.primaryMain,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: 16),
          ],
        ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: AppColors.errorMain),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading audio',
                        style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
                      ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.large),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Audio Player Section
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.large),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.audiotrack, size: 64, color: AppColors.primaryMain),
                              const SizedBox(height: AppSpacing.medium),
                              Text(
                                widget.title ?? 'Audio File',
                                style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: AppSpacing.small),
                              Text(
                                _formatDuration(_audioDuration),
                                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: AppSpacing.medium),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.play_arrow),
                                    onPressed: () => _player?.play(),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.pause),
                                    onPressed: () => _player?.pause(),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.stop),
                                    onPressed: () => _player?.stop(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.extraLarge),

                        // Trim Section
                        Text(
                          'Trim Audio',
                          style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        
                        // Only show trim controls when duration is loaded
                        if (_audioDuration == Duration.zero || _audioDuration.inSeconds <= 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.large),
                            child: Center(
                              child: Column(
                                children: [
                                  const CircularProgressIndicator(
                                    color: AppColors.primaryMain,
                                  ),
                                  const SizedBox(height: AppSpacing.medium),
                                  Text(
                                    'Loading audio duration...',
                                    style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else ...[
                          // Trim Start
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start: ${_formatDuration(_trimStart)}',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                              ),
                              Slider(
                                value: _trimStart.inSeconds.toDouble().clamp(0.0, _audioDuration.inSeconds.toDouble()),
                                min: 0.0,
                                max: _audioDuration.inSeconds.toDouble(),
                                onChanged: (value) {
                                  if (_audioDuration.inSeconds > 0) {
                                    setState(() {
                                      final newStart = Duration(seconds: value.toInt().clamp(0, _audioDuration.inSeconds));
                                      _trimStart = newStart;
                                      if (_trimStart >= _trimEnd) {
                                        _trimEnd = Duration(seconds: (value.toInt() + 1).clamp(0, _audioDuration.inSeconds));
                                      }
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          
                          // Trim End
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'End: ${_formatDuration(_trimEnd)}',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                              ),
                              Slider(
                                value: _trimEnd.inSeconds.toDouble().clamp(0.0, _audioDuration.inSeconds.toDouble()),
                                min: 0.0,
                                max: _audioDuration.inSeconds.toDouble(),
                                onChanged: (value) {
                                  if (_audioDuration.inSeconds > 0) {
                                    setState(() {
                                      final newEnd = Duration(seconds: value.toInt().clamp(0, _audioDuration.inSeconds));
                                      _trimEnd = newEnd;
                                      if (_trimEnd <= _trimStart) {
                                        _trimStart = Duration(seconds: (value.toInt() - 1).clamp(0, _audioDuration.inSeconds));
                                      }
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          
                          ElevatedButton.icon(
                            onPressed: _isEditing ? null : _applyTrim,
                            icon: _isEditing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.content_cut),
                            label: Text(_isEditing ? 'Trimming...' : 'Apply Trim'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryMain,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],

                        const SizedBox(height: AppSpacing.extraLarge),

                        // Merge Section
                        Text(
                          'Merge Audio Files',
                          style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _selectAudioFiles,
                                icon: const Icon(Icons.file_upload),
                                label: const Text('Select Files'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryMain,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            if (_filesToMerge.isNotEmpty) ...[
                              const SizedBox(width: AppSpacing.medium),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isEditing ? null : _mergeAudioFiles,
                                  icon: _isEditing
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.merge_type),
                                  label: Text(_isEditing ? 'Merging...' : 'Merge'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accentMain,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        
                        if (_filesToMerge.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.small),
                            child: Text(
                              '${_filesToMerge.length} file(s) selected',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ),

                        const SizedBox(height: AppSpacing.extraLarge),

                      ],
                    ),
                  ),
                ),
      );
    }
  }

  Widget _buildWebContent() {
    // Responsive layout: Stack on mobile, side-by-side on desktop
    if (EditorResponsive.isMobile(context)) {
      // Mobile: Vertical layout
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Audio Player Section (Top)
          _buildAudioPlayerSection(),
          const SizedBox(height: AppSpacing.large),
          // Editing Tools Panel (Bottom)
          _buildEditingToolsPanel(),
        ],
      );
    } else if (EditorResponsive.isTablet(context)) {
      // Tablet: Side-by-side with different ratios, centered
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1200),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Audio Player Section (Left - 35%)
              Expanded(
                flex: 35,
                child: _buildAudioPlayerSection(),
              ),
              const SizedBox(width: AppSpacing.large),
              // Editing Tools Panel (Right - 65%)
              Expanded(
                flex: 65,
                child: _buildEditingToolsPanel(),
              ),
            ],
          ),
        ),
      );
    } else {
      // Desktop: Centered layout
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1400),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Audio Player Section (Left - 40%)
              Expanded(
                flex: 40,
                child: _buildAudioPlayerSection(),
              ),
              const SizedBox(width: AppSpacing.large),
              // Editing Tools Panel (Right - 60%)
              Expanded(
                flex: 60,
                child: _buildEditingToolsPanel(),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildAudioPlayerSection() {
    final iconSize = EditorResponsive.isMobile(context) ? 80 : 120;
    final buttonSize = EditorResponsive.getPlayButtonSize(context);
    final textSize = EditorResponsive.getControlTextSize(context);
    
    return SectionContainer(
      showShadow: true,
      child: Container(
        padding: EditorResponsive.getSectionPadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Audio Icon - Responsive size
            Container(
              width: iconSize.toDouble(),
              height: iconSize.toDouble(),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.warmBrown,
                    AppColors.accentMain,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warmBrown.withOpacity(0.3),
                    blurRadius: iconSize * 0.15,
                    spreadRadius: iconSize * 0.04,
                  ),
                ],
              ),
              child: Icon(
                Icons.audiotrack,
                size: iconSize * 0.5,
                color: Colors.white,
              ),
            ),
            SizedBox(height: EditorResponsive.isMobile(context) ? AppSpacing.medium : AppSpacing.large),
            Text(
              widget.title ?? 'Audio File',
              style: AppTypography.heading2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: textSize + 4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              _formatDuration(_audioDuration),
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
                fontSize: textSize,
              ),
            ),
            SizedBox(height: EditorResponsive.isMobile(context) ? AppSpacing.large : AppSpacing.extraLarge),

            // Play/Pause Button - Responsive size
            GestureDetector(
              onTap: () {
                if (_player?.playing ?? false) {
                  _player?.pause();
                } else {
                  _player?.play();
                }
              },
              child: Container(
                width: buttonSize,
                height: buttonSize,
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
                      blurRadius: buttonSize * 0.2,
                      offset: const Offset(0, 4),
                      spreadRadius: buttonSize * 0.025,
                    ),
                  ],
                ),
                child: Icon(
                  (_player?.playing ?? false) ? Icons.pause : Icons.play_arrow,
                  size: buttonSize * 0.5,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.large),

            // Progress Bar
            StreamBuilder<Duration>(
              stream: _player?.positionStream ?? const Stream<Duration>.empty(),
              builder: (context, positionSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;
                return StreamBuilder<Duration?>(
                  stream: _player?.durationStream ?? const Stream<Duration?>.empty(),
                  builder: (context, durationSnapshot) {
                    final duration = durationSnapshot.data ?? _audioDuration;
                    final totalDuration = duration != Duration.zero ? duration : _audioDuration;
                    
                    return Column(
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 60,
                              child: Text(
                                _formatDuration(position),
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '/ ${_formatDuration(totalDuration)}',
                              style: AppTypography.body.copyWith(
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
                            activeTrackColor: AppColors.warmBrown,
                            inactiveTrackColor: AppColors.borderPrimary,
                            thumbColor: AppColors.warmBrown,
                          ),
                          child: Slider(
                            value: totalDuration != Duration.zero
                                ? position.inSeconds.toDouble().clamp(0.0, totalDuration.inSeconds.toDouble())
                                : 0.0,
                            min: 0.0,
                            max: totalDuration.inSeconds.toDouble() > 0
                                ? totalDuration.inSeconds.toDouble()
                                : 1.0,
                            onChanged: (value) {
                              _player?.seek(Duration(seconds: value.toInt()));
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditingToolsPanel() {
    final textSize = EditorResponsive.getControlTextSize(context);
    final iconSize = EditorResponsive.getIconButtonSize(context);
    
    return SectionContainer(
      showShadow: true,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Panel Header
            Container(
              padding: EditorResponsive.getSectionPadding(context),
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
                  Icon(
                    Icons.tune,
                    color: AppColors.warmBrown,
                    size: iconSize,
                  ),
                  SizedBox(width: EditorResponsive.isMobile(context) ? AppSpacing.small : AppSpacing.small),
                  Text(
                    'Editing Tools',
                    style: AppTypography.heading3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: textSize + 2,
                    ),
                  ),
                ],
              ),
            ),
            
            // Editing Tools Content
            Padding(
              padding: EditorResponsive.getSectionPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trim Section
                  _buildTrimSection(),
                  const SizedBox(height: AppSpacing.large),
                  
                  // Merge Section
                  _buildMergeSection(),
                  const SizedBox(height: AppSpacing.large),
                  
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrimSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.content_cut, color: AppColors.warmBrown, size: 20),
            const SizedBox(width: AppSpacing.small),
            Text(
              'Trim Audio',
              style: AppTypography.heading4.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.large),
        
        // Trim Start
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Start Time',
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
                    _formatDuration(_trimStart),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.warmBrown,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            _audioDuration == Duration.zero || _audioDuration.inSeconds <= 0
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
                    child: Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(
                            color: AppColors.primaryMain,
                            strokeWidth: 2,
                          ),
                          const SizedBox(height: AppSpacing.small),
                          Text(
                            'Loading audio...',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                      activeTrackColor: AppColors.warmBrown,
                      inactiveTrackColor: AppColors.borderPrimary,
                      thumbColor: AppColors.warmBrown,
                    ),
                    child: Slider(
                      value: _trimStart.inSeconds.toDouble().clamp(0.0, _audioDuration.inSeconds.toDouble()),
                      min: 0.0,
                      max: _audioDuration.inSeconds.toDouble(),
                      onChanged: (value) {
                        if (_audioDuration.inSeconds > 0) {
                          setState(() {
                            final newStart = Duration(seconds: value.toInt().clamp(0, _audioDuration.inSeconds));
                            _trimStart = newStart;
                            if (_trimStart >= _trimEnd) {
                              _trimEnd = Duration(seconds: (value.toInt() + 1).clamp(0, _audioDuration.inSeconds));
                            }
                          });
                        }
                      },
                    ),
                  ),
          ],
        ),
        const SizedBox(height: AppSpacing.large),
        
        // Trim End
        if (_audioDuration == Duration.zero || _audioDuration.inSeconds <= 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.large),
            child: Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(
                    color: AppColors.primaryMain,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Text(
                    'Loading audio duration...',
                    style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'End Time',
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
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                      border: Border.all(color: AppColors.warmBrown.withOpacity(0.3)),
                    ),
                    child: Text(
                      _formatDuration(_trimEnd),
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
                  value: _trimEnd.inSeconds.toDouble().clamp(0.0, _audioDuration.inSeconds.toDouble()),
                  min: 0.0,
                  max: _audioDuration.inSeconds.toDouble(),
                  onChanged: (value) {
                    if (_audioDuration.inSeconds > 0) {
                      setState(() {
                        final newEnd = Duration(seconds: value.toInt().clamp(0, _audioDuration.inSeconds));
                        _trimEnd = newEnd;
                        if (_trimEnd <= _trimStart) {
                          _trimStart = Duration(seconds: (value.toInt() - 1).clamp(0, _audioDuration.inSeconds));
                        }
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        const SizedBox(height: AppSpacing.medium),
        SizedBox(
          width: double.infinity,
          child: StyledPillButton(
            label: _isEditing ? 'Trimming...' : 'Apply Trim',
            icon: Icons.content_cut,
            onPressed: (_isEditing || _audioDuration == Duration.zero || _audioDuration.inSeconds <= 0) ? null : _applyTrim,
            isLoading: _isEditing,
          ),
        ),
      ],
    );
  }

  Widget _buildMergeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.merge_type, color: AppColors.warmBrown, size: 20),
            const SizedBox(width: AppSpacing.small),
            Text(
              'Merge Audio Files',
              style: AppTypography.heading4.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        Row(
          children: [
            Expanded(
              child: StyledPillButton(
                label: 'Select Files',
                icon: Icons.file_upload,
                onPressed: _selectAudioFiles,
              ),
            ),
            if (_filesToMerge.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: StyledPillButton(
                  label: _isEditing ? 'Merging...' : 'Merge',
                  icon: Icons.merge_type,
                  onPressed: _isEditing ? null : _mergeAudioFiles,
                  isLoading: _isEditing,
                ),
              ),
            ],
          ],
        ),
        if (_filesToMerge.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.small),
          Text(
            '${_filesToMerge.length} file(s) selected',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  // Fade effects section removed - feature not in mobile
}

