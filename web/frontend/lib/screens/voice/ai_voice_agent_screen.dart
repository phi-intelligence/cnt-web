import 'dart:async';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import '../../services/livekit_voice_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/voice/responsive_voice_bubble.dart';
import '../../widgets/voice/voice_responsive_layout.dart';

/// Screen for interacting with AI Voice Agent via LiveKit - Responsive Design
class AIVoiceAgentScreen extends StatefulWidget {
  final String? roomName;
  
  const AIVoiceAgentScreen({
    super.key,
    this.roomName,
  });
  
  @override
  State<AIVoiceAgentScreen> createState() => _AIVoiceAgentScreenState();
}

class _AIVoiceAgentScreenState extends State<AIVoiceAgentScreen> {
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
    _connectToRoom();
    _setupListeners();
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
          // Provide more detailed error message
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
    return Scaffold(
      resizeToAvoidBottomInset: false, AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        title: Text(
          'AI Voice Assistant',
          style: AppTypography.heading2,
        ),
        actions: [
          if (!_isConnecting && _service.isConnected)
            IconButton(
              icon: Icon(
                _service.isMuted ? Icons.mic_off : Icons.mic,
                color: _service.isMuted ? Colors.red : AppColors.textPrimary,
              ),
              onPressed: () async {
                await _service.toggleMute();
                if (mounted) setState(() {});
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Connection Error',
                style: AppTypography.heading2,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: AppTypography.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _connectToRoom,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    return StreamBuilder<lk.ConnectionState>(
      stream: _service.connectionState,
      builder: (context, snapshot) {
        final connectionState = snapshot.data ?? lk.ConnectionState.disconnected;
        
        if (_isConnecting || connectionState != lk.ConnectionState.connected) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  _isConnecting 
                      ? _connectionStatus 
                      : _getConnectionStateText(connectionState),
                  style: AppTypography.body,
                  textAlign: TextAlign.center,
                ),
                if (_connectionStatus.contains('Waiting for agent'))
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'This may take up to 30 seconds...',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          );
        }
        
        // Connected State - Use Responsive Layout
        return VoiceResponsiveLayout(
          agentState: _agentState,
          isLoading: _isConnecting,
          voiceBubble: ResponsiveVoiceBubble(
            isActive: _agentState == 'speaking' || _agentState == 'listening',
            enableAnimations: true,
            label: _agentState == 'speaking'
                ? 'Speaking'
                : _agentState == 'listening'
                    ? 'Listening'
                    : 'Voice Assistant',
          ),
          transcriptSection: ResponsiveTranscript(
            transcript: _transcript,
            isLoading: false,
          ),
          controlsSection: ResponsiveControls(
            onEndCall: () async {
              await _service.disconnect();
              if (mounted) Navigator.pop(context);
            },
            onMuteToggle: () async {
              await _service.toggleMute();
              if (mounted) setState(() {});
            },
            isMuted: _service.isMuted,
            isLoading: false,
          ),
        );
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
  
  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
