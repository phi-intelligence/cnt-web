import 'dart:async';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import '../../services/livekit_voice_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';

/// Warm cream background from the CNT design system (#F7F5F2).
const Color _kCream = Color(0xFFF7F5F2);

/// Full-screen AI Voice Assistant experience.
///
/// Responsive across desktop, tablet and small mobile screens. Features an
/// animated logo "voice orb" that reacts to the agent state, a live
/// conversation transcript, and call controls.
class AIVoiceAgentScreen extends StatefulWidget {
  final String? roomName;

  const AIVoiceAgentScreen({super.key, this.roomName});

  @override
  State<AIVoiceAgentScreen> createState() => _AIVoiceAgentScreenState();
}

class _AIVoiceAgentScreenState extends State<AIVoiceAgentScreen> {
  final LiveKitVoiceService _service = LiveKitVoiceService();
  final ApiService _apiService = ApiService();

  String _agentState = 'initializing';
  List<TranscriptTurn> _turns = const [];
  bool _isConnecting = true;
  String? _error;
  String _status = 'Connecting…';

  StreamSubscription? _stateSub;
  StreamSubscription? _turnsSub;

  @override
  void initState() {
    super.initState();
    _setupListeners();
    _connectToRoom();
  }

  void _setupListeners() {
    _stateSub = _service.agentState.listen((state) {
      if (mounted) setState(() => _agentState = state);
    });
    _turnsSub = _service.transcriptTurns.listen((turns) {
      if (mounted) setState(() => _turns = turns);
    });
  }

  Future<void> _connectToRoom() async {
    setState(() {
      _isConnecting = true;
      _error = null;
      _status = 'Connecting…';
    });

    try {
      final roomName =
          widget.roomName ?? 'voice-agent-${DateTime.now().millisecondsSinceEpoch}';

      // 1. Create the room so the agent has something to join.
      try {
        await _apiService.createLiveKitRoom(roomName).timeout(
              const Duration(seconds: 10),
              onTimeout: () =>
                  throw TimeoutException('Room creation timed out'),
            );
      } catch (e) {
        final msg = e.toString().toLowerCase();
        if (!msg.contains('already exists') && !msg.contains('duplicate')) {
          rethrow;
        }
      }

      await Future.delayed(const Duration(milliseconds: 400));

      // 2. Connect this client to the room.
      if (mounted) setState(() => _status = 'Joining the conversation…');
      await _service.connectToRoom(roomName: roomName);

      // 3. Wait for the agent participant to arrive.
      if (mounted) setState(() => _status = 'Waking the assistant…');
      final stopwatch = Stopwatch()..start();
      bool agentJoined = false;
      while (!agentJoined && stopwatch.elapsedMilliseconds < 30000) {
        await Future.delayed(const Duration(milliseconds: 400));
        final room = _service.room;
        if (room != null &&
            room.remoteParticipants.values
                .any((p) => p.kind == lk.ParticipantKind.AGENT)) {
          agentJoined = true;
        }
      }
      if (!agentJoined) {
        throw Exception(
            'The assistant did not respond. Please try again in a moment.');
      }

      if (mounted) {
        setState(() {
          _isConnecting = false;
          _status = 'Connected';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _error = _friendlyError(e);
          _status = 'Connection failed';
        });
      }
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('timeout')) {
      return 'Connection timed out. Check your network and try again.';
    }
    if (msg.contains('network') || msg.contains('socket')) {
      return 'Network error. Please check your internet connection.';
    }
    if (msg.contains('assistant') || msg.contains('agent')) {
      return 'The voice assistant is taking longer than usual. Please try again.';
    }
    return 'We couldn\'t connect to the assistant. Please try again.';
  }

  Future<void> _endCall() async {
    await _service.disconnect();
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _toggleMute() async {
    await _service.toggleMute();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _turnsSub?.cancel();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kCream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            return Column(
              children: [
                _Header(onClose: _endCall),
                Expanded(
                  child: _error != null
                      ? _ErrorView(message: _error!, onRetry: _connectToRoom)
                      : _isConnecting
                          ? _ConnectingView(status: _status)
                          : (isWide
                              ? _wideBody(constraints)
                              : _narrowBody(constraints)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---- Connected layouts -----------------------------------------------------

  Widget _wideBody(BoxConstraints c) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: _stage(orbSize: 240),
        ),
        Container(width: 1, color: AppColors.borderPrimary.withOpacity(0.5)),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: _TranscriptPanel(turns: _turns),
          ),
        ),
      ],
    );
  }

  Widget _narrowBody(BoxConstraints c) {
    // Scale the orb to the available space so it never overflows small phones.
    final orb = (c.maxWidth * 0.42).clamp(120.0, 200.0);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: _OrbWithState(
            agentState: _agentState,
            size: orb,
            compact: true,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
            child: _TranscriptPanel(turns: _turns),
          ),
        ),
        _Controls(
          isMuted: _service.isMuted,
          onMute: _toggleMute,
          onEnd: _endCall,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _stage({required double orbSize}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        _OrbWithState(agentState: _agentState, size: orbSize),
        const Spacer(),
        _Controls(
          isMuted: _service.isMuted,
          onMute: _toggleMute,
          onEnd: _endCall,
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

// ============================================================================
// Header
// ============================================================================

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            color: AppColors.textSecondary,
            tooltip: 'Back',
          ),
          const SizedBox(width: 4),
          Image.asset(
            'assets/images/cnt-dove-logo.png',
            height: 26,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 10),
          Text(
            'Voice Assistant',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          const _LiveBadge(),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.successMain.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.successMain,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Connected',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.successMain,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Animated orb (logo + reactive rings)
// ============================================================================

class _OrbWithState extends StatelessWidget {
  final String agentState;
  final double size;
  final bool compact;
  const _OrbWithState({
    required this.agentState,
    required this.size,
    this.compact = false,
  });

  String get _label {
    switch (agentState.toLowerCase()) {
      case 'listening':
        return 'Listening…';
      case 'thinking':
        return 'Thinking…';
      case 'speaking':
        return 'Speaking…';
      case 'initializing':
        return 'Getting ready…';
      default:
        return 'Ready';
    }
  }

  Color get _color {
    switch (agentState.toLowerCase()) {
      case 'thinking':
        return AppColors.warningMain;
      case 'speaking':
        return AppColors.successMain;
      default:
        return AppColors.primaryMain;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        VoiceOrb(agentState: agentState, size: size, accent: _color),
        SizedBox(height: compact ? 12 : 28),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            _label,
            key: ValueKey(_label),
            style: TextStyle(
              fontSize: compact ? 18 : 24,
              fontWeight: FontWeight.w700,
              color: _color,
            ),
          ),
        ),
      ],
    );
  }
}

class VoiceOrb extends StatefulWidget {
  final String agentState;
  final double size;
  final Color accent;
  const VoiceOrb({
    super.key,
    required this.agentState,
    required this.size,
    required this.accent,
  });

  @override
  State<VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<VoiceOrb> with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _ripple;

  bool get _active =>
      widget.agentState == 'listening' ||
      widget.agentState == 'speaking' ||
      widget.agentState == 'thinking';

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _ripple = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _ripple.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s * 1.9,
      height: s * 1.9,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Expanding ripple rings when the agent is active.
          if (_active)
            AnimatedBuilder(
              animation: _ripple,
              builder: (context, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: List.generate(3, (i) {
                    final t = (_ripple.value + i / 3) % 1.0;
                    return Container(
                      width: s * (1.0 + t * 0.85),
                      height: s * (1.0 + t * 0.85),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.accent.withOpacity((1 - t) * 0.45),
                          width: 2,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          // Soft glowing halo with gentle breathing.
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final scale = _active ? 1.0 + _pulse.value * 0.06 : 1.0;
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              width: s,
              height: s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryLight,
                    AppColors.primaryMain,
                    AppColors.primaryDark,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.accent.withOpacity(0.35),
                    blurRadius: 40,
                    spreadRadius: _active ? 6 : 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(s * 0.22),
                child: Image.asset(
                  'assets/images/cnt-dove-logo.png',
                  fit: BoxFit.contain,
                  color: Colors.white,
                  colorBlendMode: BlendMode.srcIn,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.mic_rounded,
                    color: Colors.white,
                    size: s * 0.4,
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

// ============================================================================
// Transcript
// ============================================================================

class _TranscriptPanel extends StatefulWidget {
  final List<TranscriptTurn> turns;
  const _TranscriptPanel({required this.turns});

  @override
  State<_TranscriptPanel> createState() => _TranscriptPanelState();
}

class _TranscriptPanelState extends State<_TranscriptPanel> {
  final ScrollController _scroll = ScrollController();

  @override
  void didUpdateWidget(covariant _TranscriptPanel old) {
    super.didUpdateWidget(old);
    if (widget.turns.length != old.turns.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderPrimary.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(Icons.forum_outlined,
                    size: 18, color: AppColors.primaryMain),
                const SizedBox(width: 8),
                Text(
                  'Transcript',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderPrimary.withOpacity(0.5)),
          Expanded(
            child: widget.turns.isEmpty
                ? _empty()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(14),
                    itemCount: widget.turns.length,
                    itemBuilder: (context, i) =>
                        _Bubble(turn: widget.turns[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.graphic_eq_rounded,
                size: 36, color: AppColors.textPlaceholder),
            const SizedBox(height: 12),
            Text(
              'Say hello to start the conversation.\nYour words will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textPlaceholder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final TranscriptTurn turn;
  const _Bubble({required this.turn});

  @override
  Widget build(BuildContext context) {
    final isAgent = turn.isAgent;
    final align = isAgent ? Alignment.centerLeft : Alignment.centerRight;
    final bg = isAgent ? _kCream : AppColors.primaryMain;
    final fg = isAgent ? AppColors.textPrimary : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Align(
        alignment: align,
        child: Column(
          crossAxisAlignment:
              isAgent ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 4, bottom: 3),
              child: Text(
                isAgent ? 'Assistant' : 'You',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isAgent ? 4 : 16),
                  bottomRight: Radius.circular(isAgent ? 16 : 4),
                ),
                border: isAgent
                    ? Border.all(
                        color: AppColors.borderPrimary.withOpacity(0.6))
                    : null,
              ),
              child: Text(
                turn.text,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.4,
                  color: fg,
                  fontStyle:
                      turn.isFinal ? FontStyle.normal : FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Controls
// ============================================================================

class _Controls extends StatelessWidget {
  final bool isMuted;
  final VoidCallback onMute;
  final VoidCallback onEnd;
  const _Controls({
    required this.isMuted,
    required this.onMute,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _RoundButton(
          icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
          label: isMuted ? 'Unmute' : 'Mute',
          background:
              isMuted ? AppColors.errorMain : Colors.white,
          foreground: isMuted ? Colors.white : AppColors.primaryMain,
          bordered: !isMuted,
          onTap: onMute,
        ),
        const SizedBox(width: 32),
        _RoundButton(
          icon: Icons.call_end_rounded,
          label: 'End',
          background: AppColors.errorMain,
          foreground: Colors.white,
          onTap: onEnd,
          large: true,
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final bool bordered;
  final bool large;
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.bordered = false,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = large ? 66.0 : 58.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: background,
          shape: CircleBorder(
            side: bordered
                ? BorderSide(color: AppColors.borderPrimary, width: 1.5)
                : BorderSide.none,
          ),
          elevation: 3,
          shadowColor: Colors.black.withOpacity(0.2),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, color: foreground, size: large ? 30 : 26),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Connecting / Error states
// ============================================================================

class _ConnectingView extends StatelessWidget {
  final String status;
  const _ConnectingView({required this.status});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VoiceOrb(
            agentState: 'thinking',
            size: 150,
            accent: AppColors.primaryMain,
          ),
          const SizedBox(height: 32),
          Text(
            status,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 56, color: AppColors.errorMain),
            const SizedBox(height: 20),
            Text(
              'Connection problem',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMain,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
