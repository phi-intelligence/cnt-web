import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../admin_dashboard.dart';
import '../../providers/auth_provider.dart';
import '../../navigation/app_router.dart';

/// Web Admin Dashboard - Responsive layout optimized for desktop
class AdminDashboardWeb extends StatelessWidget {
  const AdminDashboardWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminDashboardScreen();
  }
}

