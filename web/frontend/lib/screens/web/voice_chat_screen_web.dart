import 'package:flutter/material.dart';

class VoiceChatScreenWeb extends StatelessWidget {
  const VoiceChatScreenWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Voice Chat'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text('Voice Chat Screen - Coming Soon'),
      ),
    );
  }
}

