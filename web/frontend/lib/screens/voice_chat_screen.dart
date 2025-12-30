import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/voice/responsive_voice_bubble.dart';
import '../widgets/voice/voice_responsive_layout.dart';

class VoiceChatScreen extends StatefulWidget {
  const VoiceChatScreen({super.key});

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen> {
  bool _isListening = false;
  bool _isProcessing = false;
  String _transcript = '';
  String _aiResponse = '';
  final List<Map<String, String>> _conversationHistory = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, AppColors.backgroundPrimary,
      body: VoiceResponsiveLayout(
        agentState: _isListening ? 'listening' : _isProcessing ? 'thinking' : 'ready',
        isLoading: _isProcessing,
        voiceBubble: ResponsiveVoiceBubble(
          isActive: _isListening || _isProcessing,
          enableAnimations: true,
          onPressed: _toggleListening,
          label: _isListening ? 'Listening...' : 'Tap to speak',
        ),
        transcriptSection: ResponsiveTranscript(
          transcript: _getFullTranscript(),
          isLoading: _isProcessing,
        ),
        controlsSection: ResponsiveControls(
          onEndCall: () => Navigator.of(context).pop(),
          isLoading: _isProcessing,
        ),
        statusSection: _buildStatusSection(),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderPrimary,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isListening 
                  ? AppColors.primaryMain 
                  : _isProcessing 
                      ? AppColors.warningMain 
                      : AppColors.successMain,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _isListening 
                ? 'Listening...' 
                : _isProcessing 
                    ? 'Processing...' 
                    : 'Ready',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getFullTranscript() {
    final buffer = StringBuffer();
    
    if (_transcript.isNotEmpty) {
      buffer.writeln('You: $_transcript');
      buffer.writeln();
    }
    
    if (_aiResponse.isNotEmpty) {
      buffer.writeln('AI: $_aiResponse');
      buffer.writeln();
    }
    
    // Add conversation history
    for (final entry in _conversationHistory.reversed.take(5)) {
      if (entry['user'] != null) {
        buffer.writeln('You: ${entry['user']}');
      } else if (entry['ai'] != null) {
        buffer.writeln('AI: ${entry['ai']}');
      }
      buffer.writeln();
    }
    
    return buffer.toString().trim();
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
      
      if (_isListening) {
        // Start listening
        // TODO: Connect to WebSocket
      } else {
        // Stop listening and process
        _isProcessing = true;
        // Simulate processing
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isProcessing = false;
              _transcript = 'Sample transcript from user';
              _aiResponse = 'This is a sample response from the AI assistant.';
              
              // Add to conversation history
              _conversationHistory.add({
                'user': _transcript,
                'ai': _aiResponse,
              });
              
              // Clear current transcript
              _transcript = '';
              _aiResponse = '';
            });
          }
        });
      }
    });
  }
}

