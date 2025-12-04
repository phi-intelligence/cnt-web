import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:just_audio/just_audio.dart';
import 'dart:io' if (dart.library.html) '../../utils/file_stub.dart' as io;
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../utils/bank_details_helper.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../widgets/thumbnail_selector.dart';
import '../../services/api_service.dart';
import '../../utils/state_persistence.dart';
import '../editing/audio_editor_screen.dart';

/// Audio Preview Screen
/// Shows recorded/uploaded audio with playback and metadata form
class AudioPreviewScreen extends StatefulWidget {
  final String audioUri;
  final String source; // 'recording' or 'file'
  final int duration;
  final int fileSize;

  const AudioPreviewScreen({
    super.key,
    required this.audioUri,
    required this.source,
    this.duration = 0,
    this.fileSize = 0,
  });

  @override
  State<AudioPreviewScreen> createState() => _AudioPreviewScreenState();
}

class _AudioPreviewScreenState extends State<AudioPreviewScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitializing = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  final TextEditingController _titleController = TextEditingController(text: 'My Audio Podcast');
  final TextEditingController _descriptionController = TextEditingController(text: 'A wonderful audio podcast about faith and spirituality');
  final TextEditingController _tagsController = TextEditingController(text: 'podcast, faith, spirituality');
  String? _selectedThumbnail;

  @override
  void initState() {
    super.initState();
    _loadSavedState();
    _initializePlayer();
    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });
    _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration ?? Duration.zero;
        });
      }
    });
    _audioPlayer.playingStream.listen((playing) {
      if (mounted) {
        setState(() {});
      }
    });
  }
  
  Future<void> _loadSavedState() async {
    try {
      final savedState = await StatePersistence.loadAudioPreviewState();
      if (savedState != null && mounted) {
        // Restore form controllers
        final savedTitle = savedState['title'] as String?;
        final savedDescription = savedState['description'] as String?;
        final savedThumbnail = savedState['thumbnailUrl'] as String?;
        
        if (savedTitle != null && savedTitle.isNotEmpty) {
          _titleController.text = savedTitle;
        }
        if (savedDescription != null && savedDescription.isNotEmpty) {
          _descriptionController.text = savedDescription;
        }
        if (savedThumbnail != null && savedThumbnail.isNotEmpty) {
          _selectedThumbnail = savedThumbnail;
        }
        
        print('✅ Restored audio preview state from saved state');
      }
    } catch (e) {
      print('❌ Error loading audio preview state: $e');
    }
  }
  
  Future<void> _saveState() async {
    try {
      // Convert blob URL to backend URL before saving if needed
      String audioUriToSave = widget.audioUri;
      if (kIsWeb && widget.audioUri.startsWith('blob:')) {
        // If blob URL, try to get backend URL from saved state
        final savedState = await StatePersistence.loadAudioPreviewState();
        if (savedState != null) {
          final savedUri = savedState['audioUri'] as String?;
          if (savedUri != null && !savedUri.startsWith('blob:')) {
            audioUriToSave = savedUri;
          }
        }
      }
      
      await StatePersistence.saveAudioPreviewState(
        audioUri: audioUriToSave,
        source: widget.source,
        title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : null,
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        duration: widget.duration > 0 ? widget.duration : null,
        fileSize: widget.fileSize > 0 ? widget.fileSize : null,
      );
    } catch (e) {
      print('⚠️ Error saving audio preview state: $e');
    }
  }

  Future<void> _initializePlayer() async {
    try {
      if (kIsWeb) {
        // Web: Use network URL (blob URLs work with networkUrl)
        await _audioPlayer.setUrl(widget.audioUri);
      } else {
        // Mobile: Use file path
        await _audioPlayer.setFilePath(widget.audioUri);
      }
      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _handleBack() {
    Navigator.pop(context);
  }

  Future<void> _handlePlayPause() async {
    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: $e')),
        );
      }
    }
  }

  void _handleEdit() async {
    // If blob URL, upload to backend first for persistence
    String audioPathToUse = widget.audioUri;
    Duration? providedDuration;
    
    if (kIsWeb && widget.audioUri.startsWith('blob:')) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preparing audio for editing...')),
        );
        final uploadResult = await ApiService().uploadTemporaryMedia(widget.audioUri, 'audio');
        if (uploadResult != null) {
          // Extract URL and duration from upload response
          final backendUrl = uploadResult['url'] as String?;
          final durationSeconds = uploadResult['duration'] as int?;
          
          if (backendUrl != null) {
            // Convert relative path to full URL using getMediaUrl
            audioPathToUse = ApiService().getMediaUrl(backendUrl);
            print('✅ Converted temporary upload path to full URL: $audioPathToUse');
            
            // Extract duration if available (from FFprobe on backend)
            if (durationSeconds != null && durationSeconds > 0) {
              providedDuration = Duration(seconds: durationSeconds);
              print('✅ Duration from upload response: ${providedDuration.inSeconds}s');
            }
          }
        }
      } catch (e) {
        print('⚠️ Failed to upload blob before editor: $e');
        // Continue with blob URL - editor will handle it
      }
    } else if (!widget.audioUri.startsWith('http://') && !widget.audioUri.startsWith('https://') && !widget.audioUri.startsWith('blob:')) {
      // If it's a relative path (not already a full URL or blob), convert it
      audioPathToUse = ApiService().getMediaUrl(widget.audioUri);
    }
    
    // Save state before navigating to editor
    await _saveState();
    
    // Navigate to AudioEditorScreen with duration if available
    final editedPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => AudioEditorScreen(
          audioPath: audioPathToUse,
          title: _titleController.text.isNotEmpty ? _titleController.text : null,
          duration: providedDuration,
        ),
      ),
    );

    if (editedPath != null && mounted) {
      // Update audio path with edited version
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio edited successfully')),
      );
      // TODO: Update audio URI to edited path
    }
  }

  void _handleAddCaptions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add captions feature')),
    );
  }

  Future<void> _handlePublish() async {
    // Check bank details before publishing
    final hasBankDetails = await checkBankDetailsAndNavigate(context);
    if (!hasBankDetails || !mounted) {
      return; // User cancelled or navigated away
    }

    // Validate required fields
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title for your podcast'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload audio file first
      final audioUploadResponse = await ApiService().uploadAudio(widget.audioUri);
      final audioUrl = audioUploadResponse['url'] as String;

      // Create podcast with thumbnail
      await ApiService().createPodcast(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        audioUrl: audioUrl,
        coverImage: _selectedThumbnail,
        useDefaultThumbnail: _selectedThumbnail == null,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      
      // Clear saved state after successful publish
      await StatePersistence.clearAudioPreviewState();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio podcast published successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to home
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to publish podcast: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes == 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    
    final k = 1024;
    final sizes = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double size = bytes.toDouble();
    
    // Calculate the correct unit index
    while (size >= k && i < sizes.length - 1) {
      size /= k;
      i++;
    }
    
    // Clamp index to valid range
    i = i.clamp(0, sizes.length - 1);
    
    return '${size.toStringAsFixed(2)} ${sizes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Web version with horizontal layout matching VideoPreviewScreenWeb
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Container(
          padding: ResponsiveGridDelegate.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: _handleBack,
                  ),
                  Expanded(
                    child: StyledPageHeader(
                      title: 'Preview Audio Podcast',
                      size: StyledPageHeaderSize.h2,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: AppColors.errorMain),
                    onPressed: () {
                      // Delete functionality - can be implemented later
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Delete feature coming soon')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.extraLarge),

              // Main Content: Horizontal Layout
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // On smaller screens, stack vertically; on larger screens, use horizontal layout
                    final useHorizontalLayout = constraints.maxWidth > 1024;
                    
                    if (useHorizontalLayout) {
                      // Horizontal Layout: Audio player on left, controls on right
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Audio Player Section (Left - 60-70%)
                          Expanded(
                            flex: 3,
                            child: SectionContainer(
                              showShadow: true,
                              padding: EdgeInsets.zero,
                              child: _buildAudioPlayer(),
                            ),
                          ),
                          SizedBox(width: AppSpacing.large),
                          // Controls & Form Section (Right - 30-40%)
                          Expanded(
                            flex: 2,
                            child: SectionContainer(
                              showShadow: true,
                              child: _buildControlsAndForm(),
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Vertical Layout for smaller screens
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionContainer(
                              showShadow: true,
                              padding: EdgeInsets.zero,
                              child: _buildAudioPlayer(),
                            ),
                            const SizedBox(height: AppSpacing.large),
                            SectionContainer(
                              showShadow: true,
                              child: _buildControlsAndForm(),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Mobile version (original design with gradient)
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _handleBack,
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryMain,
                AppColors.accentMain,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.large),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.extraLarge),
                    
                    // Action buttons at top
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.edit,
                          label: 'Edit Audio',
                          onPressed: _handleEdit,
                        ),
                        _buildActionButton(
                          icon: Icons.closed_caption,
                          label: 'Add Captions',
                          onPressed: _handleAddCaptions,
                        ),
                        _buildActionButton(
                          icon: Icons.publish,
                          label: _isLoading ? 'Publishing...' : 'Publish',
                          onPressed: _isLoading ? null : _handlePublish,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.extraLarge),

                    // Audio Player Section
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.extraLarge),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          // Audio Icon
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.audiotrack,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          Text(
                            'Audio Podcast',
                            style: AppTypography.heading3.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: AppSpacing.tiny),
                          Text(
                            _duration != Duration.zero
                                ? '${_formatTime(_duration.inSeconds)} • ${_formatFileSize(widget.fileSize)}'
                                : '${_formatTime(widget.duration)} • ${_formatFileSize(widget.fileSize)}',
                            style: AppTypography.body.copyWith(color: Colors.white.withOpacity(0.8)),
                          ),
                          const SizedBox(height: AppSpacing.large),

                          if (_isInitializing)
                            const CircularProgressIndicator(color: Colors.white)
                          else if (_hasError)
                            Column(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Error loading audio',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            )
                          else ...[
                            // Play Button
                            GestureDetector(
                              onTap: _handlePlayPause,
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: StreamBuilder<bool>(
                                  stream: _audioPlayer.playingStream,
                                  builder: (context, snapshot) {
                                    final isPlaying = snapshot.data ?? false;
                                    return Icon(
                                      isPlaying ? Icons.pause : Icons.play_arrow,
                                      size: 32,
                                      color: Colors.white,
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.medium),

                            // Progress Bar
                            StreamBuilder<Duration>(
                              stream: _audioPlayer.positionStream,
                              builder: (context, positionSnapshot) {
                                final position = positionSnapshot.data ?? Duration.zero;
                                return StreamBuilder<Duration?>(
                                  stream: _audioPlayer.durationStream,
                                  builder: (context, durationSnapshot) {
                                    final duration = durationSnapshot.data ?? _duration;
                                    return Row(
                                      children: [
                                        SizedBox(
                                          width: 50,
                                          child: Text(
                                            _formatTime(position.inSeconds),
                                            style: const TextStyle(color: Colors.white, fontSize: 12),
                                          ),
                                        ),
                                        Expanded(
                                          child: Slider(
                                            value: duration != Duration.zero
                                                ? position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble())
                                                : 0.0,
                                            min: 0,
                                            max: duration != Duration.zero
                                                ? duration.inSeconds.toDouble()
                                                : widget.duration.toDouble(),
                                            activeColor: Colors.white,
                                            inactiveColor: Colors.white.withOpacity(0.3),
                                            onChanged: (value) {
                                              _audioPlayer.seek(Duration(seconds: value.toInt()));
                                            },
                                          ),
                                        ),
                                        SizedBox(
                                          width: 50,
                                          child: Text(
                                            _formatTime((duration != Duration.zero ? duration : Duration(seconds: widget.duration)).inSeconds),
                                            style: const TextStyle(color: Colors.white, fontSize: 12),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.large),

                    // Metadata Form
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.large),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Podcast Details',
                            style: AppTypography.heading3.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: AppSpacing.large),
                          
                          // Title
                          _buildTextField(
                            label: 'Title',
                            controller: _titleController,
                            hint: 'Enter podcast title',
                            onChanged: (_) => _saveState(), // Auto-save on change
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          
                          // Description
                          _buildTextField(
                            label: 'Description',
                            controller: _descriptionController,
                            hint: 'Enter podcast description',
                            maxLines: 3,
                            onChanged: (_) => _saveState(), // Auto-save on change
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          
                          // Tags
                          _buildTextField(
                            label: 'Tags',
                            controller: _tagsController,
                            hint: 'Enter tags (comma separated)',
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          
                          // Thumbnail Selection
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.medium),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: ThumbnailSelector(
                              isVideo: false,
                              onThumbnailSelected: (thumbnailUrl) {
                                setState(() {
                                  _selectedThumbnail = thumbnailUrl;
                                });
                              },
                              initialThumbnail: _selectedThumbnail,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.extraLarge),

                    // Loading Overlay
                    if (_isLoading)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.extraLarge),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.publish, size: 32, color: Colors.white),
                            SizedBox(height: AppSpacing.medium),
                            Text(
                              'Publishing your podcast...',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildAudioPlayer() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.extraLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isInitializing)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primaryMain),
                const SizedBox(height: AppSpacing.medium),
                Text(
                  'Loading audio...',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            )
          else if (_hasError)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.errorMain,
                ),
                const SizedBox(height: AppSpacing.medium),
                Text(
                  'Error loading audio',
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
            )
          else ...[
            // Audio Icon
            Container(
              width: 120,
              height: 120,
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
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.audiotrack,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            Text(
              'Audio Podcast',
              style: AppTypography.heading2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              _duration != Duration.zero
                  ? '${_formatTime(_duration.inSeconds)} • ${_formatFileSize(widget.fileSize)}'
                  : '${_formatTime(widget.duration)} • ${_formatFileSize(widget.fileSize)}',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.extraLarge),

            // Play/Pause Button
            GestureDetector(
              onTap: _handlePlayPause,
              child: Container(
                width: 80,
                height: 80,
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
                child: StreamBuilder<bool>(
                  stream: _audioPlayer.playingStream,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data ?? false;
                    return Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 48,
                      color: Colors.white,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.large),

            // Progress Bar
            StreamBuilder<Duration>(
              stream: _audioPlayer.positionStream,
              builder: (context, positionSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;
                return StreamBuilder<Duration?>(
                  stream: _audioPlayer.durationStream,
                  builder: (context, durationSnapshot) {
                    final duration = durationSnapshot.data ?? _duration;
                    final totalDuration = duration != Duration.zero
                        ? duration
                        : Duration(seconds: widget.duration);
                    
                    return Column(
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 60,
                              child: Text(
                                _formatTime(position.inSeconds),
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '/ ${_formatTime(totalDuration.inSeconds)}',
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
                              _audioPlayer.seek(Duration(seconds: value.toInt()));
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
        ],
      ),
    );
  }

  Widget _buildControlsAndForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action buttons
          Row(
            children: [
              Expanded(
                child: StyledPillButton(
                  label: 'Edit Audio',
                  icon: Icons.edit,
                  onPressed: _handleEdit,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: StyledPillButton(
                  label: 'Add Captions',
                  icon: Icons.closed_caption,
                  onPressed: _handleAddCaptions,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          SizedBox(
            width: double.infinity,
            child: StyledPillButton(
              label: _isLoading ? 'Publishing...' : 'Publish',
              icon: Icons.publish,
              onPressed: _isLoading ? null : _handlePublish,
              isLoading: _isLoading,
            ),
          ),
          const SizedBox(height: AppSpacing.extraLarge),

          // Podcast Details Section
          Text(
            'Podcast Details',
            style: AppTypography.heading3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          
          // Title
          _buildTextField(
            label: 'Title',
            controller: _titleController,
            hint: 'Enter podcast title',
            onChanged: (_) => _saveState(), // Auto-save on change
          ),
          const SizedBox(height: AppSpacing.medium),
          
          // Description
          _buildTextField(
            label: 'Description',
            controller: _descriptionController,
            hint: 'Enter podcast description',
            maxLines: 3,
            onChanged: (_) => _saveState(), // Auto-save on change
          ),
          const SizedBox(height: AppSpacing.medium),
          
          // Tags
          _buildTextField(
            label: 'Tags',
            controller: _tagsController,
            hint: 'Enter tags (comma separated)',
          ),
          const SizedBox(height: AppSpacing.medium),
          
          // Thumbnail Selection
          Text(
            'Thumbnail',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Container(
            padding: EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(
                color: AppColors.borderPrimary,
                width: 1,
              ),
            ),
            child: ThumbnailSelector(
              isVideo: false,
              onThumbnailSelected: (thumbnailUrl) {
                setState(() {
                  _selectedThumbnail = thumbnailUrl;
                });
                _saveState(); // Save when thumbnail changes
              },
              initialThumbnail: _selectedThumbnail,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    if (kIsWeb) {
      // Web version - not used, handled by StyledPillButton
      return const SizedBox.shrink();
    } else {
      // Mobile version
      return Expanded(
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.medium),
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.small),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(height: AppSpacing.tiny),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    if (kIsWeb) {
      // Web version
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          TextField(
            controller: controller,
            onChanged: onChanged,
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimary,
            ),
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTypography.body.copyWith(
                color: AppColors.textTertiary,
              ),
              filled: true,
              fillColor: AppColors.backgroundSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                borderSide: BorderSide(color: AppColors.borderPrimary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                borderSide: BorderSide(color: AppColors.borderPrimary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                borderSide: BorderSide(color: AppColors.primaryMain, width: 2),
              ),
              contentPadding: EdgeInsets.all(AppSpacing.medium),
            ),
          ),
        ],
      );
    } else {
      // Mobile version
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: AppSpacing.tiny),
          TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(AppSpacing.medium),
            ),
          ),
        ],
      );
    }
  }
}