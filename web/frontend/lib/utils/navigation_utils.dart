import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Helper function to handle back navigation consistently using GoRouter
/// Returns true if navigation was handled, false otherwise
bool handleBackNavigation(BuildContext context) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
    return true;
  }
  // If can't pop in GoRouter, navigate to home as fallback
  router.go('/home');
  return true;
}


