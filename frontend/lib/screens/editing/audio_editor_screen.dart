import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../services/audio_editing_service.dart';
import 'package:just_audio/just_audio.dart';

/// Audio Editor Screen
/// Allows users to edit audio: trim, merge, fade effects
class AudioEditorScreen extends StatefulWidget {
  final String audioPath;
  final String? title;

  const AudioEditorScreen({
    super.key,
    required this.audioPath,
    this.title,
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
  
  Duration _fadeInDuration = Duration.zero;
  Duration _fadeOutDuration = Duration.zero;
  
  List<String> _filesToMerge = [];
  String? _editedAudioPath;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _player = AudioPlayer();
      
      // Check if path is network or local file
      final isNetwork = widget.audioPath.startsWith('http');
      
      if (isNetwork) {
        await _player!.setUrl(widget.audioPath);
      } else {
        await _player!.setFilePath(widget.audioPath);
      }
      
      _audioDuration = _player!.duration ?? Duration.zero;
      
      setState(() {
        _isInitializing = false;
        _trimEnd = _audioDuration;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _applyTrim() async {
    if (_trimStart >= _trimEnd) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start time must be less than end time')),
      );
      return;
    }

    setState(() {
      _isEditing = true;
      _hasError = false;
    });

    final outputPath = await _editingService.trimAudio(
      widget.audioPath,
      _trimStart,
      _trimEnd,
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
      });
      await _reloadPlayer(outputPath);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio trimmed successfully')),
      );
    }
  }

  Future<void> _selectAudioFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _filesToMerge = result.files.map((file) => file.path!).whereType<String>().toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_filesToMerge.length} file(s) selected for merge')),
        );
      }
    } catch (e) {
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
      await _reloadPlayer(outputPath);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio files merged successfully')),
      );
    }
  }

  Future<void> _applyFadeIn() async {
    if (_fadeInDuration == Duration.zero) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set fade in duration')),
      );
      return;
    }

    final inputPath = _editedAudioPath ?? widget.audioPath;

    setState(() {
      _isEditing = true;
      _hasError = false;
    });

    final outputPath = await _editingService.applyFadeIn(
      inputPath,
      _fadeInDuration,
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
      });
      await _reloadPlayer(outputPath);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fade in applied successfully')),
      );
    }
  }

  Future<void> _applyFadeOut() async {
    if (_fadeOutDuration == Duration.zero) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set fade out duration')),
      );
      return;
    }

    final inputPath = _editedAudioPath ?? widget.audioPath;
    final currentDuration = _editedAudioPath != null ? _player!.duration : _audioDuration;

    setState(() {
      _isEditing = true;
      _hasError = false;
    });

    final outputPath = await _editingService.applyFadeOut(
      inputPath,
      _fadeOutDuration,
      audioDuration: currentDuration,
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
      });
      await _reloadPlayer(outputPath);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fade out applied successfully')),
      );
    }
  }

  Future<void> _applyFadeInOut() async {
    if (_fadeInDuration == Duration.zero || _fadeOutDuration == Duration.zero) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set both fade in and fade out durations')),
      );
      return;
    }

    final inputPath = _editedAudioPath ?? widget.audioPath;
    final currentDuration = _editedAudioPath != null ? _player!.duration : _audioDuration;

    setState(() {
      _isEditing = true;
      _hasError = false;
    });

    final outputPath = await _editingService.applyFadeInOut(
      inputPath,
      _fadeInDuration,
      _fadeOutDuration,
      audioDuration: currentDuration,
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
      });
      await _reloadPlayer(outputPath);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fade in/out applied successfully')),
      );
    }
  }

  Future<void> _reloadPlayer(String path) async {
    await _player?.dispose();
    _player = AudioPlayer();
    await _player!.setFilePath(path);
    _audioDuration = _player!.duration ?? Duration.zero;
    setState(() {
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

    // Return edited audio path to caller
    Navigator.pop(context, _editedAudioPath);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                        
                        // Trim Start
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start: ${_formatDuration(_trimStart)}',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                            Slider(
                              value: _trimStart.inSeconds.toDouble(),
                              min: 0,
                              max: _audioDuration.inSeconds.toDouble(),
                              onChanged: (value) {
                                setState(() {
                                  _trimStart = Duration(seconds: value.toInt());
                                  if (_trimStart >= _trimEnd) {
                                    _trimEnd = Duration(seconds: (value + 1).toInt());
                                  }
                                });
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
                              value: _trimEnd.inSeconds.toDouble(),
                              min: 0,
                              max: _audioDuration.inSeconds.toDouble(),
                              onChanged: (value) {
                                setState(() {
                                  _trimEnd = Duration(seconds: value.toInt());
                                  if (_trimEnd <= _trimStart) {
                                    _trimStart = Duration(seconds: (value - 1).toInt());
                                  }
                                });
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

                        // Fade Effects Section
                        Text(
                          'Fade Effects',
                          style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        
                        // Fade In
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fade In: ${_fadeInDuration.inSeconds}s',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                            Slider(
                              value: _fadeInDuration.inSeconds.toDouble(),
                              min: 0,
                              max: 10,
                              divisions: 20,
                              onChanged: (value) {
                                setState(() {
                                  _fadeInDuration = Duration(seconds: value.toInt());
                                });
                              },
                            ),
                          ],
                        ),
                        
                        // Fade Out
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fade Out: ${_fadeOutDuration.inSeconds}s',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                            Slider(
                              value: _fadeOutDuration.inSeconds.toDouble(),
                              min: 0,
                              max: 10,
                              divisions: 20,
                              onChanged: (value) {
                                setState(() {
                                  _fadeOutDuration = Duration(seconds: value.toInt());
                                });
                              },
                            ),
                          ],
                        ),
                        
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isEditing || _fadeInDuration == Duration.zero
                                    ? null
                                    : _applyFadeIn,
                                icon: const Icon(Icons.trending_up),
                                label: const Text('Fade In'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryMain,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.small),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isEditing || _fadeOutDuration == Duration.zero
                                    ? null
                                    : _applyFadeOut,
                                icon: const Icon(Icons.trending_down),
                                label: const Text('Fade Out'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryMain,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: AppSpacing.small),
                        
                        ElevatedButton.icon(
                          onPressed: _isEditing ||
                                  _fadeInDuration == Duration.zero ||
                                  _fadeOutDuration == Duration.zero
                              ? null
                              : _applyFadeInOut,
                          icon: _isEditing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.swap_horiz),
                          label: Text(_isEditing ? 'Applying...' : 'Apply Both'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentMain,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

