import 'dart:async';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import '../../services/livekit_voice_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../services/logger_service.dart';

/// Web Voice Agent Screen - Redesigned to match app styling
/// Follows Netflix-style design with consistent app components
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
  final LiveKitVoiceService _service = LiveKitVoiceService();
  final ApiService _apiService = ApiService();
  String _agentState = 'initializing';
  String _transcript = '';
  bool _isConnecting = true;
  String? _error;
  String _connectionStatus = 'Connecting to Christ New Tabernacle voice assistant...';
  
  @override
  void initState() {
    super.initState();
    LoggerService.i('🎤 VoiceAgentScreenWeb: Initializing...');
    _setupListeners();
    // Start connection after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectToRoom();
    });
  }
  
  Future<void> _connectToRoom() async {
    try {
      setState(() {
        _isConnecting = true;
        _error = null;
        _connectionStatus = 'Connecting to Christ New Tabernacle voice assistant...';
      });
      
      // Generate room name if not provided
      final roomName = widget.roomName ?? 'voice-agent-${DateTime.now().millisecondsSinceEpoch}';
      
      // Step 1: Create room (mandatory - agent needs room to exist)
      setState(() {
        _connectionStatus = 'Connecting to Christ New Tabernacle voice assistant...';
      });
      
      try {
        await _apiService.createLiveKitRoom(roomName).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Room creation timed out after 10 seconds');
          },
        );
        LoggerService.i('✅ Room created: $roomName');
        setState(() {
          _connectionStatus = 'Connecting to Christ New Tabernacle voice assistant...';
        });
      } catch (e) {
        // Check if error is because room already exists
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('already exists') || errorMsg.contains('duplicate')) {
          LoggerService.i('ℹ️ Room already exists: $roomName');
          setState(() {
            _connectionStatus = 'Connecting to Christ New Tabernacle voice assistant...';
          });
        } else {
          String detailedError = 'Failed to create room: $e';
          final apiBase = ApiService.baseUrl;
          if (errorMsg.contains('network') || errorMsg.contains('connection')) {
            detailedError = 'Cannot connect to backend server. Please ensure the backend is running at ${apiBase.replaceAll('/api/v1', '')}';
          } else if (errorMsg.contains('timeout')) {
            detailedError = 'Request timed out. The backend server may not be responding at $apiBase';
          } else if (errorMsg.contains('500') || errorMsg.contains('internal server')) {
            detailedError = 'Backend server error. Check backend logs for details. Error: $e';
          } else if (errorMsg.contains('cors')) {
            detailedError = 'CORS error. Please check backend CORS configuration.';
          }
          LoggerService.e('❌ Room creation error: $detailedError');
          throw Exception(detailedError);
        }
      }
      
      // Step 2: Wait a moment for room to be fully initialized
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Step 3: Connect to room
      setState(() {
        _connectionStatus = 'Connecting to Christ New Tabernacle voice assistant...';
      });
      
      await _service.connectToRoom(roomName: roomName);
      
      // Step 4: Wait for agent to join
      setState(() {
        _connectionStatus = 'Connecting to Christ New Tabernacle voice assistant...';
      });
      
      // Wait up to 30 seconds for agent to join
      bool agentJoined = false;
      final stopwatch = Stopwatch()..start();
      while (!agentJoined && stopwatch.elapsedMilliseconds < 30000) {
        await Future.delayed(const Duration(milliseconds: 500));
        
        final room = _service.room;
        if (room != null) {
          final hasAgent = room.remoteParticipants.values
              .any((p) => p.kind == lk.ParticipantKind.AGENT);
          if (hasAgent) {
            agentJoined = true;
            LoggerService.i('✅ Agent joined the room');
            break;
          }
        }
        
        if (mounted) {
          setState(() {
            _connectionStatus = 'Connecting to Christ New Tabernacle voice assistant...';
          });
        }
      }
      
      if (!agentJoined) {
        throw Exception('Agent did not join the room within 30 seconds. Please ensure the agent worker is running.');
      }
      
      setState(() {
        _isConnecting = false;
        _connectionStatus = 'Connected';
      });
    } on TimeoutException catch (e) {
      setState(() {
        _isConnecting = false;
        _error = e.message ?? 'Connection timed out. Please check your network and try again.';
        _connectionStatus = 'Connection failed';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection timeout: ${e.message}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _error = _getErrorMessage(e);
        _connectionStatus = 'Connection failed';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error: ${_getErrorMessage(e)}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _connectToRoom,
            ),
          ),
        );
      }
    }
  }
  
  String _getErrorMessage(dynamic error) {
    final errorMsg = error.toString().toLowerCase();
    
    if (errorMsg.contains('timeout')) {
      return 'Connection timed out. Please check your network connection and try again.';
    } else if (errorMsg.contains('network') || errorMsg.contains('socket')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorMsg.contains('token')) {
      return 'Authentication failed. Please try again.';
    } else if (errorMsg.contains('room')) {
      return 'Failed to create or access room. Please try again.';
    } else if (errorMsg.contains('agent')) {
      return 'Voice assistant is not available. Please try again.';
    } else if (errorMsg.contains('livekit')) {
      return 'Unable to connect. Please try again.';
    }
    
    return 'Failed to connect: $error';
  }
  
  void _setupListeners() {
    _service.agentState.listen((state) {
      if (mounted) {
        setState(() => _agentState = state);
      }
    });
    
    _service.transcript.listen((text) {
      if (mounted) {
        setState(() => _transcript = text);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: _buildSimplifiedBody(),
      ),
    );
  }
  
  /// Simplified body with only voice bubble, End Call, and Mute buttons
  Widget _buildSimplifiedBody() {
    // Handle error state
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.extraLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.errorMain),
              const SizedBox(height: AppSpacing.large),
              Text(
                'Connection Error',
                style: AppTypography.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.medium),
              Text(
                _error!,
                style: AppTypography.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.extraLarge),
              StyledPillButton(
                label: 'Retry',
                icon: Icons.refresh,
                onPressed: _connectToRoom,
              ),
            ],
          ),
        ),
      );
    }
    
    // Handle connecting state
    if (_isConnecting) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryMain),
            ),
            const SizedBox(height: AppSpacing.large),
            Text(
              _connectionStatus,
              style: AppTypography.heading3,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    // Connected state - simplified UI with only voice bubble and controls
    return StreamBuilder<lk.ConnectionState>(
      stream: _service.connectionState,
      initialData: lk.ConnectionState.disconnected,
      builder: (context, snapshot) {
        final connectionState = snapshot.data ?? lk.ConnectionState.disconnected;
        
        if (connectionState != lk.ConnectionState.connected) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryMain),
                ),
                const SizedBox(height: AppSpacing.large),
                Text(
                  _getConnectionStateText(connectionState),
                  style: AppTypography.heading3,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        // Main connected UI - responsive layout
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final bubbleSize = isMobile ? 160.0 : 200.0;
            
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? AppSpacing.large : AppSpacing.extraLarge * 2,
                  vertical: AppSpacing.large,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Voice Bubble with animation
                    _AnimatedVoiceBubble(
                      agentState: _agentState,
                      size: bubbleSize,
                    ),
                    
                    SizedBox(height: isMobile ? AppSpacing.xxl : AppSpacing.xxxl),
                    
                    // Agent State Text
                    Text(
                      _getStateText(_agentState),
                      style: AppTypography.heading2.copyWith(
                        color: AppColors.primaryMain,
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 20 : 28,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: isMobile ? AppSpacing.xxl : AppSpacing.xxxl * 2),
                    
                    // Control Buttons - Mute and End Call
                    Wrap(
                      spacing: AppSpacing.large,
                      runSpacing: AppSpacing.medium,
                      alignment: WrapAlignment.center,
                      children: [
                        // Mute Button
                        _buildControlButton(
                          icon: _service.isMuted ? Icons.mic_off : Icons.mic,
                          label: _service.isMuted ? 'Unmute' : 'Mute',
                          onPressed: () async {
                            await _service.toggleMute();
                            if (mounted) setState(() {});
                          },
                          isDestructive: false,
                          isMobile: isMobile,
                        ),
                        
                        // End Call Button
                        _buildControlButton(
                          icon: Icons.call_end,
                          label: 'End Call',
                          onPressed: () async {
                            await _service.disconnect();
                            if (mounted) Navigator.pop(context);
                          },
                          isDestructive: true,
                          isMobile: isMobile,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  /// Build a control button (Mute or End Call)
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
                color: isDestructive ? AppColors.errorMain : AppColors.warmBrown,
                boxShadow: [
                  BoxShadow(
                    color: (isDestructive ? AppColors.errorMain : AppColors.warmBrown)
                        .withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: Colors.white,
              ),
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
  
  String _getConnectionStateText(lk.ConnectionState state) {
    switch (state) {
      case lk.ConnectionState.connecting:
        return 'Connecting to Christ New Tabernacle voice assistant...';
      case lk.ConnectionState.connected:
        return 'Connected';
      case lk.ConnectionState.disconnected:
        return 'Disconnected';
      case lk.ConnectionState.reconnecting:
        return 'Reconnecting to Christ New Tabernacle voice assistant...';
    }
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
  
  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

/// Animated Voice Bubble Widget with Radiating Waveforms
/// Shows microphone icon inside bubble with waveforms emanating outward
class _AnimatedVoiceBubble extends StatefulWidget {
  final String agentState;
  final double size;
  
  const _AnimatedVoiceBubble({
    required this.agentState,
    required this.size,
  });
  
  @override
  State<_AnimatedVoiceBubble> createState() => _AnimatedVoiceBubbleState();
}

class _AnimatedVoiceBubbleState extends State<_AnimatedVoiceBubble> 
    with TickerProviderStateMixin {
  late List<AnimationController> _waveControllers;
  
  @override
  void initState() {
    super.initState();
    // Create 4 wave controllers with staggered timing
    _waveControllers = List.generate(4, (index) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 2000 + (index * 100)),
      );
      // Stagger the start of each wave
      Future.delayed(Duration(milliseconds: index * 400), () {
        if (mounted) {
          controller.repeat();
        }
      });
      return controller;
    });
    
    _updateAnimations();
  }
  
  @override
  void didUpdateWidget(_AnimatedVoiceBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.agentState != widget.agentState) {
      _updateAnimations();
    }
  }
  
  void _updateAnimations() {
    final isActive = widget.agentState == 'speaking' || 
                     widget.agentState == 'listening';
    
    for (var controller in _waveControllers) {
      if (isActive) {
        if (!controller.isAnimating) {
          controller.repeat();
        }
      } else if (widget.agentState == 'thinking') {
        // Slower animation for thinking
        controller.duration = const Duration(milliseconds: 3000);
        if (!controller.isAnimating) {
          controller.repeat();
        }
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
      width: widget.size * 2.5, // Extra space for waveforms
      height: widget.size * 2.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radiating waveforms (behind bubble)
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
          
          // Main voice bubble with microphone icon
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

