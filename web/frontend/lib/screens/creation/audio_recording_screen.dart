import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/web/section_container.dart';
import 'audio_preview_screen.dart';
import '../../widgets/web/section_container.dart';
import 'audio_preview_screen.dart';
import '../../utils/web_audio_recorder.dart';
import '../../utils/unsaved_changes_guard.dart';
// Conditional imports - mobile only
import 'package:record/record.dart'
    if (dart.library.html) '../../utils/record_stub.dart' as record;
import 'package:path_provider/path_provider.dart'
    if (dart.library.html) '../../utils/path_provider_stub.dart' as path;
import 'dart:io' if (dart.library.html) '../../utils/file_stub.dart' as io;

/// Audio Recording Screen - Record audio podcasts
/// Supports both web (using MediaRecorder) and mobile (using record package)
class AudioRecordingScreen extends StatefulWidget {
  const AudioRecordingScreen({super.key});

  @override
  State<AudioRecordingScreen> createState() => _AudioRecordingScreenState();
}

class _AudioRecordingScreenState extends State<AudioRecordingScreen>
    with SingleTickerProviderStateMixin {
  dynamic _recorder; // WebAudioRecorder on web, AudioRecorder on mobile
  bool _isRecording = false;
  bool _isPaused = false;
  int _recordingDuration = 0;
  int _pausedDuration = 0;
  String? _recordingPath;
  DateTime? _recordingStartTime;

  // Animation for waveform
  late AnimationController _waveController;
  final List<double> _waveHeights = [];
  final int _waveCount = 30;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller for waveform
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(_updateWaveform);

    // Initialize wave heights
    for (int i = 0; i < _waveCount; i++) {
      _waveHeights.add(0.2);
    }

    if (kIsWeb) {
      _recorder = WebAudioRecorder();
    } else {
      _recorder = record.AudioRecorder();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _recorder?.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (kIsWeb) {
        // Web: Use WebAudioRecorder
        final hasPermission = await _recorder.hasPermission();
        if (!hasPermission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Microphone permission denied')),
            );
          }
          return;
        }

        final path = await _recorder.start();
        if (path != null) {
          setState(() {
            _isRecording = true;
            _isPaused = false;
            _recordingPath = path;
            _recordingStartTime = DateTime.now();
          });
          _waveController.repeat();
          _updateDuration();
        }
      } else {
        // Mobile: Use AudioRecorder package
        if (await _recorder.hasPermission()) {
          final directory = await path.getApplicationDocumentsDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final filePath = '${directory.path}/recording_$timestamp.m4a';

          await _recorder.start(
            const record.RecordConfig(
              encoder: record.AudioEncoder.aacLc,
              bitRate: 128000,
              sampleRate: 44100,
            ),
            path: filePath,
          );

          setState(() {
            _isRecording = true;
            _isPaused = false;
            _recordingPath = filePath;
            _recordingStartTime = DateTime.now();
          });
          _waveController.repeat();
          _updateDuration();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Microphone permission denied')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting recording: $e')),
        );
      }
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _recorder.pause();
      _waveController.stop();
      setState(() {
        _isPaused = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error pausing recording: $e')),
        );
      }
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _recorder.resume();
      _waveController.repeat();
      setState(() {
        _isPaused = false;
      });
      _updateDuration();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resuming recording: $e')),
        );
      }
    }
  }

  Future<void> _stopAndSave() async {
    try {
      _waveController.stop();
      String? path;
      int fileSize = 0;

      if (kIsWeb) {
        // Web: Get blob URL from WebAudioRecorder
        path = await _recorder.stop();
        if (path != null) {
          // Get bytes from blob URL to calculate file size
          final bytes = await _recorder.getBytes(path);
          fileSize = bytes?.length ?? 0;
        }
      } else {
        // Mobile: Get file path from AudioRecorder
        path = await _recorder.stop();
        if (path != null) {
          final file = io.File(path);
          fileSize = await file.length();
        }
      }

      if (path != null && mounted) {
        setState(() {
          _isRecording = false;
        });

        // Navigate to audio preview screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AudioPreviewScreen(
              audioUri: path!, // path is non-null here
              source: 'recording',
              duration: _recordingDuration,
              fileSize: fileSize,
            ),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No recording saved')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping recording: $e')),
        );
      }
    }
  }

  void _discardRecording() {
    _waveController.stop();
    setState(() {
      _isRecording = false;
      _recordingDuration = 0;
      _pausedDuration = 0;
    });
    if (kIsWeb) {
      _recorder?.stop();
    } else {
      _recorder?.stop();
    }
    Navigator.pop(context);
  }

  void _updateWaveform() {
    if (_isRecording && !_isPaused && mounted) {
      setState(() {
        // Shift waves to the left and add new wave on right
        for (int i = 0; i < _waveCount - 1; i++) {
          _waveHeights[i] = _waveHeights[i + 1];
        }
        // Generate new random wave height
        _waveHeights[_waveCount - 1] =
            0.2 + (DateTime.now().millisecond % 60) / 100.0;
      });
    }
  }

  void _updateDuration() {
    if (_isRecording && !_isPaused) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _isRecording && !_isPaused) {
          setState(() {
            _recordingDuration++;
          });
          _updateDuration();
        }
      });
    }
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildSoundbar({required bool isRecording, required bool isPaused}) {
    // Create animated brown soundbar visualization with smooth animation
    final bars = List.generate(_waveCount, (index) {
      final height = _waveHeights[index] * 80;
      final animatedHeight = height.clamp(8.0, 80.0);

      return AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        width: 4,
        height: animatedHeight,
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isRecording && !isPaused
                ? [
                    AppColors.warmBrown,
                    AppColors.warmBrown.withOpacity(0.8),
                    AppColors.accentMain.withOpacity(0.6),
                  ]
                : [
                    AppColors.warmBrown.withOpacity(0.3),
                    AppColors.warmBrown.withOpacity(0.2),
                  ],
          ),
          borderRadius: BorderRadius.circular(2),
        ),
      );
    });

    return Container(
      width: double.infinity,
      height: 120,
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.large),
      padding: EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.warmBrown.withOpacity(0.05),
            AppColors.accentMain.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: AppColors.warmBrown.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.warmBrown.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: bars,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Web version with web design system
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          if (_isRecording) {
            final shouldDiscard = await UnsavedChangesGuard.showDiscardConfirmation(
              context,
              title: 'Discard Recording?',
              message: 'Recording in progress. Are you sure you want to discard it?',
            );
            if (shouldDiscard && mounted) {
              _discardRecording();
            }
          } else {
            // No recording in progress, just pop
            Navigator.pop(context);
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.backgroundPrimary,
          resizeToAvoidBottomInset: false,
          body: Container(
            padding: ResponsiveGridDelegate.getResponsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warm brown gradient header section
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppSpacing.extraLarge),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.warmBrown,
                        AppColors.warmBrown.withOpacity(0.85),
                        AppColors.primaryMain.withOpacity(0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.warmBrown.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () async {
                          if (_isRecording) {
                            final shouldDiscard =
                                await UnsavedChangesGuard.showDiscardConfirmation(
                              context,
                              title: 'Discard Recording?',
                              message:
                                  'Recording in progress. Are you sure you want to discard it?',
                            );
                            if (shouldDiscard && mounted) {
                              _discardRecording();
                            }
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Record Audio Podcast',
                            style: AppTypography.heading2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: AppSpacing.tiny),
                          Text(
                            'Create inspiring audio content',
                            style: AppTypography.body.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.extraLarge),

              // Recording Section
              Expanded(
                child: SectionContainer(
                  showShadow: true,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Recording status badge with brown styling
                      if (_isRecording)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.large,
                            vertical: AppSpacing.small,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.warmBrown,
                                AppColors.accentMain,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.warmBrown.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.small),
                              Text(
                                _isPaused ? 'PAUSED' : 'RECORDING',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_isRecording)
                        const SizedBox(height: AppSpacing.large),

                      // Timer display
                      Text(
                        _formatDuration(_recordingDuration),
                        style: AppTypography.heading1.copyWith(
                          color: AppColors.warmBrown,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.extraLarge),

                      // Brown soundbar visualization
                      _buildSoundbar(
                        isRecording: _isRecording,
                        isPaused: _isPaused,
                      ),

                      const SizedBox(height: AppSpacing.extraLarge * 1.5),

                      // Control buttons with brown pill design
                      Builder(
                        builder: (context) {
                          final isMobile = ResponsiveUtils.isMobile(context);
                          final buttonSize = isMobile ? 40.0 : 48.0;
                          final largeButtonSize = isMobile ? 56.0 : 64.0;
                          final spacing =
                              isMobile ? AppSpacing.small : AppSpacing.large;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!_isRecording)
                                Container(
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
                                        color: AppColors.warmBrown
                                            .withOpacity(0.4),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    iconSize: largeButtonSize,
                                    icon: const Icon(Icons.mic,
                                        color: Colors.white),
                                    onPressed: _startRecording,
                                  ),
                                )
                              else ...[
                                // Pause/Resume button
                                Container(
                                  decoration: BoxDecoration(
                                    color: _isPaused
                                        ? AppColors.warmBrown
                                        : AppColors.accentMain,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_isPaused
                                                ? AppColors.warmBrown
                                                : AppColors.accentMain)
                                            .withOpacity(0.4),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    iconSize: buttonSize,
                                    icon: Icon(
                                      _isPaused
                                          ? Icons.play_arrow
                                          : Icons.pause,
                                      color: Colors.white,
                                    ),
                                    onPressed: _isPaused
                                        ? _resumeRecording
                                        : _pauseRecording,
                                  ),
                                ),
                                SizedBox(width: spacing),
                                // Stop/Save button
                                Container(
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
                                        color: AppColors.warmBrown
                                            .withOpacity(0.4),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    iconSize: largeButtonSize,
                                    icon: const Icon(Icons.check,
                                        color: Colors.white),
                                    onPressed: _stopAndSave,
                                  ),
                                ),
                                SizedBox(width: spacing),
                                // Delete button
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.errorMain,
                                      width: 2,
                                    ),
                                  ),
                                  child: IconButton(
                                    iconSize: buttonSize,
                                    icon: const Icon(Icons.delete,
                                        color: AppColors.errorMain),
                                    onPressed: _discardRecording,
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Record Audio'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Timer display
            Text(
              _formatDuration(_recordingDuration),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.medium),

            // Recording indicator
            if (_isRecording)
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
              ),
            const SizedBox(height: AppSpacing.extraLarge),

            // Waveform visualization (placeholder)
            Container(
              width: double.infinity,
              height: 100,
              margin: EdgeInsets.symmetric(horizontal: AppSpacing.large),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Center(
                child: Icon(
                  Icons.graphic_eq,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.extraLarge),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isRecording)
                  IconButton(
                    iconSize: 64,
                    icon: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.successMain,
                      ),
                      child: const Icon(Icons.mic, color: Colors.white),
                    ),
                    onPressed: _startRecording,
                  )
                else ...[
                  if (_isPaused)
                    IconButton(
                      iconSize: 48,
                      icon: const Icon(Icons.play_arrow,
                          color: AppColors.primaryMain),
                      onPressed: _resumeRecording,
                    )
                  else
                    IconButton(
                      iconSize: 48,
                      icon:
                          const Icon(Icons.pause, color: AppColors.primaryMain),
                      onPressed: _pauseRecording,
                    ),
                  const SizedBox(width: AppSpacing.medium),
                  IconButton(
                    iconSize: 64,
                    icon: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.successMain,
                      ),
                      child: const Icon(Icons.check, color: Colors.white),
                    ),
                    onPressed: _stopAndSave,
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  IconButton(
                    iconSize: 48,
                    icon: const Icon(Icons.delete, color: AppColors.errorMain),
                    onPressed: _discardRecording,
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }
  }
}
