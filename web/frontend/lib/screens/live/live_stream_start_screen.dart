import 'package:flutter/material.dart';
import 'live_stream_setup_screen.dart';

/// Live Stream Start Screen
/// Redirects to the setup screen for stream configuration
class LiveStreamStartScreen extends StatelessWidget {
  const LiveStreamStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Immediately navigate to setup screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LiveStreamSetupScreen(),
        ),
      );
    });

    return const Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
