import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/voice_responsive.dart';

/// Unified Responsive Voice Bubble Component
/// Optimized for all screen sizes with performance-aware animations
class ResponsiveVoiceBubble extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isActive;
  final String label;
  final String? heroTag;
  final bool enableHero;
  final Color? labelColor;
  final double? customSize;
  final bool enableAnimations;

  const ResponsiveVoiceBubble({
    super.key,
    this.onPressed,
    this.isActive = false,
    this.label = 'Voice Assistant',
    this.heroTag,
    this.enableHero = true,
    this.labelColor,
    this.customSize,
    this.enableAnimations = true,
  });

  @override
  State<ResponsiveVoiceBubble> createState() => _ResponsiveVoiceBubbleState();
}

class _ResponsiveVoiceBubbleState extends State<ResponsiveVoiceBubble> 
    with TickerProviderStateMixin {
  late List<AnimationController> _waveControllers;
  late AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }
  
  void _initializeAnimations() {
    if (!widget.enableAnimations) return;
    
    final waveCount = VoicePerformance.getWaveCount(context);
    final duration = VoicePerformance.getAnimationDuration(context);
    
    // Create wave controllers with staggered timing
    _waveControllers = List.generate(waveCount, (index) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: duration.inMilliseconds + (index * 100)),
      );
      
      // Stagger the start of each wave
      Future.delayed(Duration(milliseconds: index * 400), () {
        if (mounted && widget.isActive) {
          controller.repeat();
        }
      });
      
      return controller;
    });
    
    // Create pulse controller for thinking state
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _updateAnimations();
  }
  
  @override
  void didUpdateWidget(ResponsiveVoiceBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enableAnimations && oldWidget.isActive != widget.isActive) {
      _updateAnimations();
    }
  }
  
  void _updateAnimations() {
    if (!widget.enableAnimations) return;
    
    final isSpeaking = widget.isActive;
    final isThinking = widget.isActive; // Simplified for demo
    
    for (var controller in _waveControllers) {
      if (isSpeaking) {
        if (!controller.isAnimating) {
          controller.repeat();
        }
      } else {
        controller.stop();
        controller.reset();
      }
    }
    
    if (isThinking) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }
  
  @override
  void dispose() {
    for (var controller in _waveControllers) {
      controller.dispose();
    }
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final bubbleSize = widget.customSize ?? VoiceResponsiveSize.getBubbleSize(context);
    final iconSize = VoiceResponsiveSize.getIconSize(context);
    final touchTargetSize = VoiceResponsiveSize.getTouchTargetSize(context);
    
    Widget bubble = GestureDetector(
      onTap: widget.onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Voice bubble with animations
          SizedBox(
            width: touchTargetSize,
            height: touchTargetSize,
            child: Center(
              child: _buildVoiceBubble(bubbleSize, iconSize),
            ),
          ),
          
          // Label
          if (widget.label.isNotEmpty) ...[
            SizedBox(height: AppSpacing.small * VoiceResponsiveSize.getSpacingMultiplier(context)),
            Text(
              widget.isActive ? 'Tap to stop' : widget.label,
              style: TextStyle(
                color: widget.labelColor ?? AppColors.textPrimary,
                fontSize: VoiceBreakpoints.isMobile(context) ? 12 : 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );

    if (widget.enableHero) {
      bubble = Hero(
        tag: widget.heroTag ?? 'responsive-voice-bubble',
        child: Material(
          color: Colors.transparent,
          child: bubble,
        ),
      );
    }

    return bubble;
  }
  
  Widget _buildVoiceBubble(double bubbleSize, double iconSize) {
    if (!widget.enableAnimations || !VoicePerformance.enableComplexAnimations(context)) {
      // Simple static bubble for performance
      return _buildStaticBubble(bubbleSize, iconSize);
    }
    
    // Animated bubble with waves
    return SizedBox(
      width: bubbleSize * 2.5,
      height: bubbleSize * 2.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radiating waveforms (behind bubble)
          if (widget.isActive) ..._buildWaveforms(bubbleSize),
          
          // Main voice bubble
          _buildMainBubble(bubbleSize, iconSize),
        ],
      ),
    );
  }
  
  List<Widget> _buildWaveforms(double bubbleSize) {
    return _waveControllers.map((controller) {
      return AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final progress = controller.value;
          final scale = 1.0 + (progress * 1.2);
          final opacity = (1.0 - progress) * 0.4;
          
          return Container(
            width: bubbleSize * scale,
            height: bubbleSize * scale,
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
    }).toList();
  }
  
  Widget _buildMainBubble(double bubbleSize, double iconSize) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseScale = 1.0 + (_pulseController.value * 0.1);
        
        return Transform.scale(
          scale: pulseScale,
          child: Container(
            width: bubbleSize,
            height: bubbleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.isActive ? AppColors.primaryMain : AppColors.warmBrown,
                  widget.isActive 
                      ? AppColors.primaryMain.withValues(alpha: 0.8)
                      : AppColors.warmBrown.withValues(alpha: 0.8),
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
                if (widget.isActive)
                  BoxShadow(
                    color: AppColors.primaryMain.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
              ],
            ),
            child: Icon(
              _getStateIcon(),
              size: iconSize,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildStaticBubble(double bubbleSize, double iconSize) {
    return Container(
      width: bubbleSize,
      height: bubbleSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.isActive ? AppColors.primaryMain : AppColors.warmBrown,
            widget.isActive 
                ? AppColors.primaryMain.withValues(alpha: 0.8)
                : AppColors.warmBrown.withValues(alpha: 0.8),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        _getStateIcon(),
        size: iconSize,
        color: Colors.white,
      ),
    );
  }
  
  IconData _getStateIcon() {
    // Simplified state detection - can be enhanced with actual agent state
    if (widget.isActive) {
      return Icons.mic;
    }
    return Icons.mic_none;
  }
}
