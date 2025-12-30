import 'package:flutter/material.dart';

class NotFoundScreenWeb extends StatelessWidget {
  const NotFoundScreenWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('404 - Not Found'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text('Page Not Found - Coming Soon'),
      ),
    );
  }
}

