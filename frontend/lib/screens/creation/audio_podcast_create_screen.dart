import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'audio_recording_screen.dart';
import 'audio_preview_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

/// Audio Podcast Create Screen
/// Shows options to record audio or upload file
class AudioPodcastCreateScreen extends StatelessWidget {
  const AudioPodcastCreateScreen({super.key});

  Future<void> _selectAudioFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null && context.mounted) {
        final audioPath = result.files.single.path!;
        final file = File(audioPath);
        final fileSize = await file.length();
        
        // Get audio duration - in production, use just_audio or similar
        // For now, use a default estimate
        int estimatedDuration = 180; // Default estimate
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AudioPreviewScreen(
              audioUri: audioPath,
              source: 'file',
              duration: estimatedDuration,
              fileSize: fileSize,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting audio file: $e'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(AppSpacing.large),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Create Audio Podcast',
                      style: AppTypography.heading4.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.large),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Record Audio Option
                      _buildOptionCard(
                        context,
                        icon: Icons.mic,
                        title: 'Record Audio',
                        description: 'Start recording your podcast with the microphone',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AudioRecordingScreen(),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: AppSpacing.extraLarge),
                      
                      // Upload Audio Option
                      _buildOptionCard(
                        context,
                        icon: Icons.audiotrack,
                        title: 'Upload Audio',
                        description: 'Select an existing audio file from your device',
                        onTap: () => _selectAudioFile(context),
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
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.extraLarge),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            Text(
              title,
              style: AppTypography.heading3.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              description,
              style: AppTypography.body.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

