import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Web Voice Agent Screen - UI Only (no server connection required)
class VoiceAgentScreenWeb extends StatefulWidget {
  final String? roomName;

  const VoiceAgentScreenWeb({
    super.key,
    this.roomName,
  });

  @override
  State<VoiceAgentScreenWeb> createState() => _VoiceAgentScreenWebState();
}

class _VoiceAgentScreenWebState extends State<VoiceAgentScreenWeb> {
  bool _isMuted = false;
  String _agentState = 'listening';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      resizeToAvoidBottomInset: false,
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final bubbleSize = isMobile ? 160.0 : 200.0;

        return SingleChildScrollView(
          child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        isMobile ? AppSpacing.large : AppSpacing.extraLarge * 2,
                    vertical: AppSpacing.large,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                      Text(
                        'CNT Voice Assistant',
                        style: AppTypography.heading3.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      SizedBox(
                          height: isMobile ? AppSpacing.xxl : AppSpacing.xxxl),

                      // Animated Voice Bubble
                      _AnimatedVoiceBubble(
                        agentState: _agentState,
                        size: bubbleSize,
                      ),

                      SizedBox(
                          height: isMobile ? AppSpacing.xxl : AppSpacing.xxxl),

                      // State label
                      Text(
                        _getStateText(_agentState),
                        style: AppTypography.heading2.copyWith(
                          color: AppColors.primaryMain,
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 20 : 28,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(
                          height:
                              isMobile ? AppSpacing.xxl : AppSpacing.xxxl * 2),

                      // Control buttons
                      Wrap(
                        spacing: AppSpacing.large,
                        runSpacing: AppSpacing.medium,
                        alignment: WrapAlignment.center,
                        children: [
                          // Mute button
                          _buildControlButton(
                            icon: _isMuted ? Icons.mic_off : Icons.mic,
                            label: _isMuted ? 'Unmute' : 'Mute',
                            onPressed: () => setState(() {
                              _isMuted = !_isMuted;
                              _agentState =
                                  _isMuted ? 'initializing' : 'listening';
                            }),
                            isDestructive: false,
                            isMobile: isMobile,
                          ),

                          // End Call button
                          _buildControlButton(
                            icon: Icons.call_end,
                            label: 'End Call',
                            onPressed: () => Navigator.pop(context),
                            isDestructive: true,
                            isMobile: isMobile,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isDestructive,
    required bool isMobile,
  }) {
    final buttonSize = isMobile ? 60.0 : 72.0;
    final iconSize = isMobile ? 28.0 : 32.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(buttonSize / 2),
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isDestructive ? AppColors.errorMain : AppColors.warmBrown,
                boxShadow: [
                  BoxShadow(
                    color: (isDestructive
                            ? AppColors.errorMain
                            : AppColors.warmBrown)
                        .withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, size: iconSize, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getStateText(String state) {
    switch (state.toLowerCase()) {
      case 'listening':
        return 'Listening...';
      case 'thinking':
        return 'Thinking...';
      case 'speaking':
        return 'Speaking...';
      case 'initializing':
        return 'Muted';
      default:
        return 'Ready';
    }
  }
}

/// Animated Voice Bubble with radiating waveforms
class _AnimatedVoiceBubble extends StatefulWidget {
  final String agentState;
  final double size;

  const _AnimatedVoiceBubble({required this.agentState, required this.size});

  @override
  State<_AnimatedVoiceBubble> createState() => _AnimatedVoiceBubbleState();
}

class _AnimatedVoiceBubbleState extends State<_AnimatedVoiceBubble>
    with TickerProviderStateMixin {
  late List<AnimationController> _waveControllers;

  @override
  void initState() {
    super.initState();
    _waveControllers = List.generate(4, (index) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 2000 + (index * 100)),
      );
      Future.delayed(Duration(milliseconds: index * 400), () {
        if (mounted) controller.repeat();
      });
      return controller;
    });
    _updateAnimations();
  }

  @override
  void didUpdateWidget(_AnimatedVoiceBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.agentState != widget.agentState) _updateAnimations();
  }

  void _updateAnimations() {
    final isActive =
        widget.agentState == 'speaking' || widget.agentState == 'listening';
    for (var controller in _waveControllers) {
      if (isActive) {
        if (!controller.isAnimating) controller.repeat();
      } else if (widget.agentState == 'thinking') {
        controller.duration = const Duration(milliseconds: 3000);
        if (!controller.isAnimating) controller.repeat();
      } else {
        controller.stop();
        controller.reset();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _waveControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.agentState == 'speaking' ||
        widget.agentState == 'listening' ||
        widget.agentState == 'thinking';

    return SizedBox(
      width: widget.size * 2.5,
      height: widget.size * 2.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isActive)
            ..._waveControllers.map((controller) {
              return AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  final progress = controller.value;
                  final scale = 1.0 + (progress * 1.2);
                  final opacity = (1.0 - progress) * 0.4;
                  return Container(
                    width: widget.size * scale,
                    height: widget.size * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryMain.withValues(alpha: opacity),
                        width: 2,
                      ),
                    ),
                  );
                },
              );
            }),
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryMain,
                  AppColors.primaryMain.withValues(alpha: 0.8),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.primaryMain.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: isActive ? 5 : 0,
                ),
              ],
            ),
            child: Icon(
              _getStateIcon(widget.agentState),
              size: widget.size * 0.4,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStateIcon(String state) {
    switch (state.toLowerCase()) {
      case 'listening':
        return Icons.mic;
      case 'speaking':
        return Icons.record_voice_over;
      case 'thinking':
        return Icons.psychology;
      default:
        return Icons.mic_none;
    }
  }
}
