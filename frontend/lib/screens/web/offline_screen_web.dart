import 'package:flutter/material.dart';

class OfflineScreenWeb extends StatelessWidget {
  const OfflineScreenWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text('Offline Screen - Coming Soon'),
      ),
    );
  }
}

