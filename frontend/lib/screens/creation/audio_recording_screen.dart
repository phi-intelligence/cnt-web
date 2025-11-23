import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'audio_preview_screen.dart';

/// Audio Recording Screen - Record audio podcasts
class AudioRecordingScreen extends StatefulWidget {
  const AudioRecordingScreen({super.key});

  @override
  State<AudioRecordingScreen> createState() => _AudioRecordingScreenState();
}

class _AudioRecordingScreenState extends State<AudioRecordingScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isPaused = false;
  int _recordingDuration = 0;
  int _pausedDuration = 0;
  String? _recordingPath;
  DateTime? _recordingStartTime;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = '${directory.path}/recording_$timestamp.m4a';
        
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );
        
        setState(() {
          _isRecording = true;
          _isPaused = false;
          _recordingPath = path;
          _recordingStartTime = DateTime.now();
        });
        _updateDuration();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission denied')),
          );
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
      final path = await _recorder.stop();
      if (path != null && mounted) {
        final file = File(path);
        final fileSize = await file.length();
        
        setState(() {
          _isRecording = false;
        });
        
        // Navigate to audio preview screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AudioPreviewScreen(
              audioUri: path,
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
    setState(() {
      _isRecording = false;
      _recordingDuration = 0;
      _pausedDuration = 0;
    });
    Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
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
                    icon: const Icon(Icons.play_arrow, color: AppColors.primaryMain),
                    onPressed: _resumeRecording,
                  )
                else
                  IconButton(
                    iconSize: 48,
                    icon: const Icon(Icons.pause, color: AppColors.primaryMain),
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

