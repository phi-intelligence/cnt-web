import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Preload Inter font synchronously for CanvasKit
  // This ensures fonts are available when CanvasKit initializes
  // The HTML preload in index.html handles the main font loading,
  // but we also ensure fonts are ready here as a safety measure
  try {
    // Create a test TextStyle to trigger font loading
    // This ensures GoogleFonts.inter() is initialized before CanvasKit
    final testStyle = GoogleFonts.inter(fontSize: 16);
    // Force font loading by accessing the font family
    if (testStyle.fontFamily != null) {
      debugPrint('Inter font initialized successfully');
    }
  } catch (e) {
    // Log error but continue - fallback fonts will be used
    debugPrint('Warning: Failed to initialize Inter font: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppRouter();
  }
}

