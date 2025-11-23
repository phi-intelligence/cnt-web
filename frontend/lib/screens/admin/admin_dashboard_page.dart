import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/admin/admin_stat_card.dart';
import '../admin/admin_support_page.dart';
import '../admin/admin_documents_page.dart';
import '../../widgets/shared/empty_state.dart';
import '../../utils/platform_helper.dart';

/// Dashboard page showing overview statistics and quick actions
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await _api.getAdminDashboard();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryMain,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.errorMain,
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              'Error loading dashboard',
              style: AppTypography.heading3,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              _error!,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.large),
            ElevatedButton(
              onPressed: _loadStats,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMain,
                foregroundColor: AppColors.textInverse,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_stats == null) {
      return const EmptyState(
        icon: Icons.dashboard_outlined,
        title: 'No data available',
        message: 'Unable to load dashboard statistics',
      );
    }

    final stats = _stats!;
    final totalPending = (stats['pending_podcasts'] ?? 0) +
        (stats['pending_movies'] ?? 0) +
        (stats['pending_music'] ?? 0) +
        (stats['pending_posts'] ?? 0);

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: AppColors.primaryMain,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Text(
              'Admin Dashboard',
              style: AppTypography.heading1.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              'Manage content and users',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.extraLarge),

            // Pending Content Stats
            Text(
              'Pending Approvals',
              style: AppTypography.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            GridView.count(
              crossAxisCount: PlatformHelper.isWebPlatform() ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.medium,
              mainAxisSpacing: AppSpacing.medium,
              childAspectRatio: PlatformHelper.isWebPlatform() ? 1.2 : 1.1,
              children: [
                AdminStatCard(
                  icon: Icons.pending_actions,
                  label: 'Total Pending',
                  value: totalPending.toString(),
                  color: AppColors.warningMain,
                  onTap: () {
                    // Navigate to pending tab
                    DefaultTabController.of(context).animateTo(1);
                  },
                ),
                AdminStatCard(
                  icon: Icons.podcasts,
                  label: 'Pending Podcasts',
                  value: (stats['pending_podcasts'] ?? 0).toString(),
                  color: AppColors.infoMain,
                  onTap: () {
                    // Navigate to audio page
                    DefaultTabController.of(context).animateTo(1);
                  },
                ),
                AdminStatCard(
                  icon: Icons.movie,
                  label: 'Pending Movies',
                  value: (stats['pending_movies'] ?? 0).toString(),
                  color: AppColors.primaryMain,
                  onTap: () {
                    // Navigate to video page
                    DefaultTabController.of(context).animateTo(2);
                  },
                ),
                AdminStatCard(
                  icon: Icons.post_add,
                  label: 'Pending Posts',
                  value: (stats['pending_posts'] ?? 0).toString(),
                  color: AppColors.accentMain,
                  onTap: () {
                    // Navigate to posts page
                    DefaultTabController.of(context).animateTo(3);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.extraLarge),

            // Total Content Stats
            Text(
              'Total Content',
              style: AppTypography.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            GridView.count(
              crossAxisCount: PlatformHelper.isWebPlatform() ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.medium,
              mainAxisSpacing: AppSpacing.medium,
              childAspectRatio: PlatformHelper.isWebPlatform() ? 1.2 : 1.1,
              children: [
                AdminStatCard(
                  icon: Icons.library_books,
                  label: 'Total Podcasts',
                  value: (stats['total_podcasts'] ?? 0).toString(),
                  color: AppColors.infoMain,
                ),
                AdminStatCard(
                  icon: Icons.video_library,
                  label: 'Total Movies',
                  value: (stats['total_movies'] ?? 0).toString(),
                  color: AppColors.primaryMain,
                ),
                AdminStatCard(
                  icon: Icons.library_music,
                  label: 'Total Music',
                  value: (stats['total_music'] ?? 0).toString(),
                  color: AppColors.successMain,
                ),
                AdminStatCard(
                  icon: Icons.article,
                  label: 'Total Posts',
                  value: (stats['total_posts'] ?? 0).toString(),
                  color: AppColors.accentMain,
                ),
                AdminStatCard(
                  icon: Icons.menu_book,
                  label: 'Bible Documents',
                  value: (stats['total_documents'] ?? 0).toString(),
                  color: AppColors.primaryDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminDocumentsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.extraLarge),

            Text(
              'Support & Inbox',
              style: AppTypography.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            GridView.count(
              crossAxisCount: PlatformHelper.isWebPlatform() ? 2 : 1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.medium,
              mainAxisSpacing: AppSpacing.medium,
              childAspectRatio: PlatformHelper.isWebPlatform() ? 2.2 : 2.8,
              children: [
                AdminStatCard(
                  icon: Icons.support_agent,
                  label: 'Open Support Tickets',
                  value: (stats['open_support_tickets'] ?? 0).toString(),
                  color: AppColors.primaryMain,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminSupportPage(),
                      ),
                    );
                  },
                ),
                AdminStatCard(
                  icon: Icons.mark_unread_chat_alt_outlined,
                  label: 'New Messages',
                  value: (stats['unread_support_messages'] ?? 0).toString(),
                  color: AppColors.errorMain,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminSupportPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.extraLarge),

            Text(
              'Documents',
              style: AppTypography.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            GridView.count(
              crossAxisCount: PlatformHelper.isWebPlatform() ? 2 : 1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.medium,
              mainAxisSpacing: AppSpacing.medium,
              childAspectRatio: PlatformHelper.isWebPlatform() ? 2.2 : 2.8,
              children: [
                AdminStatCard(
                  icon: Icons.menu_book,
                  label: 'Total Documents',
                  value: (stats['total_documents'] ?? 0).toString(),
                  color: AppColors.primaryDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminDocumentsPage(),
                      ),
                    );
                  },
                ),
                AdminStatCard(
                  icon: Icons.add_circle_outline,
                  label: 'Manage Documents',
                  value: 'Upload PDF',
                  color: AppColors.infoMain,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminDocumentsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

