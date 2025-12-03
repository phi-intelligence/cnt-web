import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/voice_responsive.dart';

/// Responsive layout builder for voice screens
class VoiceResponsiveLayout extends StatelessWidget {
  final Widget voiceBubble;
  final Widget? transcriptSection;
  final Widget? controlsSection;
  final Widget? statusSection;
  final String agentState;
  final bool isLoading;
  final String? error;

  const VoiceResponsiveLayout({
    super.key,
    required this.voiceBubble,
    this.transcriptSection,
    this.controlsSection,
    this.statusSection,
    this.agentState = 'ready',
    this.isLoading = false,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (VoiceBreakpoints.isMobile(context)) {
      return _buildMobileLayout(context);
    } else if (VoiceBreakpoints.isTablet(context)) {
      return _buildTabletLayout(context);
    } else {
      return _buildDesktopLayout(context);
    }
  }

  /// Mobile Layout: Full-screen with bottom controls
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Status bar at top
            if (statusSection != null)
              Container(
                padding: const EdgeInsets.all(16),
                child: statusSection,
              ),
            
            // Main voice bubble area
            Expanded(
              flex: 3,
              child: Center(
                child: voiceBubble,
              ),
            ),
            
            // Agent state indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _getStateText(agentState),
                style: AppTypography.bodyMedium.copyWith(
                  color: _getStateColor(agentState),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Transcript section (collapsible on mobile)
            if (transcriptSection != null) ...[
              Container(
                height: VoiceResponsiveSize.getTranscriptHeight(context) * 0.6,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: transcriptSection,
              ),
            ],
            
            // Controls at bottom for easy thumb access
            if (controlsSection != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: controlsSection,
              ),
          ],
        ),
      ),
    );
  }

  /// Tablet Layout: Centered with side panels
  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: VoiceResponsiveSize.getScreenPadding(context),
          child: Column(
            children: [
              // Status section
              if (statusSection != null) ...[
                statusSection!,
                const SizedBox(height: AppSpacing.large),
              ],
              
              // Main content area
              Expanded(
                child: Row(
                  children: [
                    // Voice bubble and state
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          voiceBubble,
                          const SizedBox(height: AppSpacing.extraLarge),
                          Text(
                            _getStateText(agentState),
                            style: AppTypography.heading3.copyWith(
                              color: _getStateColor(agentState),
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: AppSpacing.extraLarge),
                    
                    // Right panel: Transcript and controls
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          // Transcript
                          if (transcriptSection != null) ...[
                            Expanded(
                              flex: 3,
                              child: transcriptSection!,
                            ),
                            const SizedBox(height: AppSpacing.large),
                          ],
                          
                          // Controls
                          if (controlsSection != null)
                            controlsSection!,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Desktop Layout: Two-column with enhanced features
  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: VoiceResponsiveSize.getScreenPadding(context),
          child: Column(
            children: [
              // Status section
              if (statusSection != null) ...[
                statusSection!,
                const SizedBox(height: AppSpacing.extraLarge),
              ],
              
              // Main content area
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left side: Voice bubble with animations
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          voiceBubble,
                          const SizedBox(height: AppSpacing.xxxl),
                          Text(
                            _getStateText(agentState),
                            style: AppTypography.heading2.copyWith(
                              color: _getStateColor(agentState),
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: AppSpacing.xxxl),
                    
                    // Right side: Enhanced controls and transcript
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          // Connection status
                          _buildConnectionStatus(),
                          const SizedBox(height: AppSpacing.large),
                          
                          // Transcript
                          if (transcriptSection != null) ...[
                            Expanded(
                              flex: 3,
                              child: transcriptSection!,
                            ),
                            const SizedBox(height: AppSpacing.large),
                          ],
                          
                          // Controls
                          if (controlsSection != null)
                            controlsSection!,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
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
              color: isLoading 
                  ? AppColors.warningMain 
                  : error != null 
                      ? AppColors.errorMain 
                      : AppColors.successMain,
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Text(
            isLoading 
                ? 'Connecting...' 
                : error != null 
                    ? 'Connection Error' 
                    : 'Connected',
            style: AppTypography.bodyMedium.copyWith(
              color: isLoading 
                  ? AppColors.warningMain 
                  : error != null 
                      ? AppColors.errorMain 
                      : AppColors.successMain,
            ),
          ),
        ],
      ),
    );
  }

  String _getStateText(String state) {
    switch (state.toLowerCase()) {
      case 'initializing':
        return 'Initializing...';
      case 'listening':
        return 'Listening...';
      case 'thinking':
        return 'Thinking...';
      case 'speaking':
        return 'Speaking...';
      case 'disconnected':
        return 'Disconnected';
      default:
        return 'Ready';
    }
  }

  Color _getStateColor(String state) {
    switch (state.toLowerCase()) {
      case 'listening':
        return AppColors.primaryMain;
      case 'thinking':
        return AppColors.warningMain;
      case 'speaking':
        return AppColors.successMain;
      case 'initializing':
        return AppColors.textSecondary;
      case 'disconnected':
        return AppColors.errorMain;
      default:
        return AppColors.primaryMain;
    }
  }
}

/// Responsive transcript widget
class ResponsiveTranscript extends StatelessWidget {
  final String transcript;
  final bool isLoading;

  const ResponsiveTranscript({
    super.key,
    this.transcript = '',
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final height = VoiceResponsiveSize.getTranscriptHeight(context);
    
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderPrimary,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.chat,
                  size: 20,
                  color: AppColors.primaryMain,
                ),
                const SizedBox(width: AppSpacing.small),
                Text(
                  'Transcript',
                  style: AppTypography.heading4.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryMain),
                    ),
                  ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isLoading 
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryMain),
                      ),
                    )
                  : transcript.isNotEmpty
                      ? SingleChildScrollView(
                          child: Text(
                            transcript,
                            style: AppTypography.body.copyWith(
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            'Conversation transcript will appear here...',
                            style: AppTypography.body.copyWith(
                              color: AppColors.textPlaceholder,
                            ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Responsive controls widget
class ResponsiveControls extends StatelessWidget {
  final VoidCallback? onEndCall;
  final VoidCallback? onMuteToggle;
  final bool isMuted;
  final bool isLoading;

  const ResponsiveControls({
    super.key,
    this.onEndCall,
    this.onMuteToggle,
    this.isMuted = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = VoiceResponsiveSize.getTouchTargetSize(context);
    final spacing = AppSpacing.medium * VoiceResponsiveSize.getSpacingMultiplier(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mute button (if available)
        if (onMuteToggle != null) ...[
          SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: ElevatedButton(
              onPressed: isLoading ? null : onMuteToggle,
              style: ElevatedButton.styleFrom(
                backgroundColor: isMuted ? AppColors.errorMain : AppColors.backgroundSecondary,
                foregroundColor: isMuted ? Colors.white : AppColors.textPrimary,
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
              ),
              child: Icon(
                isMuted ? Icons.mic_off : Icons.mic,
                size: buttonSize * 0.4,
              ),
            ),
          ),
          SizedBox(height: spacing),
        ],
        
        // End call button
        SizedBox(
          width: buttonSize * 1.2,
          height: buttonSize * 1.2,
          child: ElevatedButton(
            onPressed: isLoading ? null : onEndCall,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorMain,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
            ),
            child: Icon(
              Icons.call_end,
              size: buttonSize * 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
