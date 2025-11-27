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
  String _connectionStatus = 'Preparing...';
  
  @override
  void initState() {
    super.initState();
    print('🎤 VoiceAgentScreenWeb: Initializing...');
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
        _connectionStatus = 'Preparing connection...';
      });
      
      // Generate room name if not provided
      final roomName = widget.roomName ?? 'voice-agent-${DateTime.now().millisecondsSinceEpoch}';
      
      // Step 1: Create room (mandatory - agent needs room to exist)
      setState(() {
        _connectionStatus = 'Creating room...';
      });
      
      try {
        await _apiService.createLiveKitRoom(roomName).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Room creation timed out after 10 seconds');
          },
        );
        print('✅ Room created: $roomName');
        setState(() {
          _connectionStatus = 'Room created, connecting...';
        });
      } catch (e) {
        // Check if error is because room already exists
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('already exists') || errorMsg.contains('duplicate')) {
          print('ℹ️ Room already exists: $roomName');
          setState(() {
            _connectionStatus = 'Room exists, connecting...';
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
          print('❌ Room creation error: $detailedError');
          throw Exception(detailedError);
        }
      }
      
      // Step 2: Wait a moment for room to be fully initialized
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Step 3: Connect to room
      setState(() {
        _connectionStatus = 'Connecting to LiveKit server...';
      });
      
      await _service.connectToRoom(roomName: roomName);
      
      // Step 4: Wait for agent to join
      setState(() {
        _connectionStatus = 'Waiting for agent to join...';
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
            print('✅ Agent joined the room');
            break;
          }
        }
        
        if (mounted) {
          setState(() {
            _connectionStatus = 'Waiting for agent... (${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(0)}s)';
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
      return 'Connection timed out. Check your network connection and ensure the LiveKit server is running.';
    } else if (errorMsg.contains('network') || errorMsg.contains('socket')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorMsg.contains('token')) {
      return 'Authentication failed. Please try again.';
    } else if (errorMsg.contains('room')) {
      return 'Failed to create or access room. Please try again.';
    } else if (errorMsg.contains('agent')) {
      return 'Agent is not available. Please ensure the agent worker is running.';
    } else if (errorMsg.contains('livekit')) {
      return 'LiveKit server error. Please check server status.';
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
    final padding = ResponsiveGridDelegate.getResponsivePadding(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate available space after padding
          final availableWidth = constraints.maxWidth - padding.horizontal;
          final availableHeight = constraints.maxHeight - padding.vertical;
          
          return Container(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header (matching app styling) - with bounded width constraints
                SizedBox(
                  width: availableWidth,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: StyledPageHeader(
                          title: 'AI Voice Assistant',
                          size: StyledPageHeaderSize.h2,
                        ),
                      ),
                      StreamBuilder<lk.ConnectionState>(
                        stream: _service.connectionState,
                        initialData: lk.ConnectionState.disconnected,
                        builder: (context, snapshot) {
                          final isConnected = snapshot.data == lk.ConnectionState.connected;
                          if (!_isConnecting && isConnected) {
                            return StyledPillButton(
                              label: _service.isMuted ? 'Unmute' : 'Mute',
                              icon: _service.isMuted ? Icons.mic_off : Icons.mic,
                              onPressed: () async {
                                await _service.toggleMute();
                                if (mounted) setState(() {});
                              },
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.extraLarge),
                
                // Main Content - Use remaining constraints after header
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, expandedConstraints) {
                      return _buildBody(BoxConstraints(
                        maxWidth: expandedConstraints.maxWidth,
                        maxHeight: expandedConstraints.maxHeight,
                      ));
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildBody(BoxConstraints constraints) {
    // Always show loading/error state first
    if (_error != null) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth > 600 ? 600 : constraints.maxWidth,
            maxHeight: constraints.maxHeight,
          ),
          child: SingleChildScrollView(
            child: SectionContainer(
              padding: EdgeInsets.all(AppSpacing.extraLarge),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.errorMain),
                  const SizedBox(height: AppSpacing.large),
                  Text(
                    'Connection Error',
                    style: AppTypography.heading2,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Text(
                    _error!,
                    style: AppTypography.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.extraLarge),
                  StyledPillButton(
                    label: 'Retry Connection',
                    icon: Icons.refresh,
                    onPressed: _connectToRoom,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    // Show loading state while connecting
    if (_isConnecting) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth > 600 ? 600 : constraints.maxWidth,
            maxHeight: constraints.maxHeight,
          ),
          child: SingleChildScrollView(
            child: SectionContainer(
              padding: EdgeInsets.all(AppSpacing.extraLarge),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
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
                  if (_connectionStatus.contains('Waiting for agent'))
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.medium),
                      child: Text(
                        'This may take up to 30 seconds...',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    // Use StreamBuilder for connection state updates
    return StreamBuilder<lk.ConnectionState>(
      stream: _service.connectionState,
      initialData: lk.ConnectionState.disconnected,
      builder: (context, snapshot) {
        final connectionState = snapshot.data ?? lk.ConnectionState.disconnected;
        
        // Still connecting or not connected - show loading/status
        if (connectionState != lk.ConnectionState.connected) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth > 600 ? 600 : constraints.maxWidth,
                maxHeight: constraints.maxHeight,
              ),
              child: SingleChildScrollView(
                child: SectionContainer(
                  padding: EdgeInsets.all(AppSpacing.extraLarge),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
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
                ),
              ),
            ),
          );
        }
        
        // Connected State - Main Voice Interface
        // Use responsive design based on constraints
        final isWideScreen = constraints.maxWidth > 1024;
            
        if (isWideScreen) {
          // Desktop: Two-column layout with bounded constraints
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Side - Voice Bubble with Animation
                Expanded(
                  flex: 2,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight,
                    ),
                    child: SectionContainer(
                      padding: EdgeInsets.all(AppSpacing.xxxl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated Voice Bubble
                          _AnimatedVoiceBubble(
                            agentState: _agentState,
                            size: 200.0,
                          ),
                          const SizedBox(height: AppSpacing.extraLarge),
                          // Agent State Text
                          Text(
                            _getStateText(_agentState),
                            style: AppTypography.heading2.copyWith(
                              color: _getStateColor(_agentState),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: AppSpacing.extraLarge),
                
                // Right Side - Controls and Transcript
                Expanded(
                  flex: 1,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      children: [
                        // Connection Status
                        SectionContainer(
                          padding: EdgeInsets.all(AppSpacing.large),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.successMain,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.medium),
                              Text(
                                'Connected',
                                style: AppTypography.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.medium),
                        
                        // Transcript Section - Use explicit height calculation
                        Expanded(
                          child: SectionContainer(
                            padding: EdgeInsets.all(AppSpacing.large),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Transcript',
                                  style: AppTypography.heading3,
                                ),
                                const SizedBox(height: AppSpacing.medium),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Text(
                                      _transcript.isNotEmpty 
                                          ? _transcript 
                                          : 'Conversation transcript will appear here...',
                                      style: AppTypography.body,
                                      textAlign: TextAlign.start,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.medium),
                        
                        // End Call Button
                        SizedBox(
                          width: double.infinity,
                          child: StyledPillButton(
                            label: 'End Call',
                            icon: Icons.call_end,
                            variant: StyledPillButtonVariant.filled,
                            onPressed: () async {
                              await _service.disconnect();
                              if (mounted) Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Tablet/Mobile: Stacked layout
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.medium),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Voice Bubble Section
                  SectionContainer(
                    padding: EdgeInsets.all(AppSpacing.extraLarge),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated Voice Bubble
                        _AnimatedVoiceBubble(
                          agentState: _agentState,
                          size: 150.0,
                        ),
                        const SizedBox(height: AppSpacing.large),
                        // Agent State Text
                        Text(
                          _getStateText(_agentState),
                          style: AppTypography.heading2.copyWith(
                            color: _getStateColor(_agentState),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.large),
                  
                  // Connection Status
                  SectionContainer(
                    padding: EdgeInsets.all(AppSpacing.large),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.successMain,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.medium),
                        Text(
                          'Connected',
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.large),
                  
                  // Transcript Section
                  SectionContainer(
                    padding: EdgeInsets.all(AppSpacing.large),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Transcript',
                          style: AppTypography.heading3,
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        SizedBox(
                          height: 200,
                          child: SingleChildScrollView(
                            child: Text(
                              _transcript.isNotEmpty 
                                  ? _transcript 
                                  : 'Conversation transcript will appear here...',
                              style: AppTypography.body,
                              textAlign: TextAlign.start,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.large),
                  
                  // End Call Button
                  SizedBox(
                    width: double.infinity,
                    child: StyledPillButton(
                      label: 'End Call',
                      icon: Icons.call_end,
                      variant: StyledPillButtonVariant.filled,
                      onPressed: () async {
                        await _service.disconnect();
                        if (mounted) Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.large),
                ],
              ),
            ),
          );
        }
      },
    );
  }
  
  String _getConnectionStateText(lk.ConnectionState state) {
    switch (state) {
      case lk.ConnectionState.connecting:
        return 'Connecting...';
      case lk.ConnectionState.connected:
        return 'Connected';
      case lk.ConnectionState.disconnected:
        return 'Disconnected';
      case lk.ConnectionState.reconnecting:
        return 'Reconnecting...';
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
  
  Color _getStateColor(String state) {
    switch (state.toLowerCase()) {
      case 'listening':
        return AppColors.infoMain;
      case 'thinking':
        return AppColors.warningMain;
      case 'speaking':
        return AppColors.successMain;
      case 'initializing':
        return AppColors.textSecondary;
      default:
        return AppColors.primaryMain;
    }
  }
  
  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

/// Animated Voice Bubble Widget
/// Shows animated sound production activity instead of static bars
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
  late AnimationController _soundWaveController;
  late AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    // Sound wave animation for active states
    _soundWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    
    // Pulse animation for active states
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    
    // Pause animations when not active
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
    
    if (isActive) {
      _soundWaveController.repeat(reverse: true);
      _pulseController.repeat();
    } else {
      _soundWaveController.stop();
      _pulseController.stop();
      _pulseController.reset();
    }
  }
  
  @override
  void dispose() {
    _soundWaveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isActive = widget.agentState == 'speaking' || 
                     widget.agentState == 'listening';
    final stateColor = _getStateColor(widget.agentState);
    
    return AnimatedBuilder(
      animation: Listenable.merge([_soundWaveController, _pulseController]),
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulse ring (only when active)
            if (isActive)
              Container(
                width: widget.size + (_pulseController.value * 40),
                height: widget.size + (_pulseController.value * 40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: stateColor.withValues(alpha: 0.3 * (1 - _pulseController.value)),
                    width: 3,
                  ),
                ),
              ),
            
            // Main bubble
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.warmBrown,
                border: Border.all(
                  color: AppColors.borderPrimary.withValues(alpha: 0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  if (isActive)
                    BoxShadow(
                      color: stateColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                ],
              ),
              child: Center(
                child: _AnimatedSoundBars(
                  controller: _soundWaveController,
                  isActive: isActive,
                  color: stateColor,
                  size: widget.size,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Color _getStateColor(String state) {
    switch (state.toLowerCase()) {
      case 'listening':
        return AppColors.infoMain;
      case 'speaking':
        return AppColors.successMain;
      case 'thinking':
        return AppColors.warningMain;
      default:
        return AppColors.accentLight;
    }
  }
}

/// Animated Sound Bars Widget
/// Shows animated bars that respond to sound production activity
class _AnimatedSoundBars extends StatelessWidget {
  final AnimationController controller;
  final bool isActive;
  final Color color;
  final double size;
  
  const _AnimatedSoundBars({
    required this.controller,
    required this.isActive,
    required this.color,
    required this.size,
  });
  
  @override
  Widget build(BuildContext context) {
    final scale = size / AppSpacing.voiceBubbleSize;
    final barWidth = 4 * scale;
    final barSpacing = 3 * scale;
    final minHeight = 12.0 * scale;
    final maxHeight = 40.0 * scale;
    
    if (!isActive) {
      // Static bars when inactive
      final bars = [12.0 * scale, 18.0 * scale, 24.0 * scale, 18.0 * scale, 12.0 * scale];
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(bars.length, (index) {
          return Container(
            width: barWidth,
            height: bars[index],
            margin: EdgeInsets.only(right: index == bars.length - 1 ? 0 : barSpacing),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(2 * scale),
            ),
          );
        }),
      );
    }
    
    // Animated bars when active (simulating sound production)
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (index) {
        // Create wave-like animation pattern
        final offset = controller.value;
        final phase = (index * 0.15 + offset) % 1.0;
        final heightFactor = (0.5 + 0.5 * (phase < 0.5 ? phase * 2 : 2 - phase * 2));
        final barHeight = minHeight + (maxHeight - minHeight) * heightFactor;
        
        return Container(
          width: barWidth,
          height: barHeight,
          margin: EdgeInsets.only(right: index == 6 ? 0 : barSpacing),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2 * scale),
          ),
        );
      }),
    );
  }
}

