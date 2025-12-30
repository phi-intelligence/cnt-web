import 'package:flutter/material.dart';

class SupportScreenWeb extends StatelessWidget {
  const SupportScreenWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Support Ministry'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text('Support Ministry Screen - Coming Soon'),
      ),
    );
  }
}

