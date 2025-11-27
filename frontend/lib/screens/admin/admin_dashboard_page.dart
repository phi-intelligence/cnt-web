import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/admin/admin_dashboard_card.dart';
import '../admin/admin_support_page.dart';
import '../admin/admin_documents_page.dart';
import '../../widgets/shared/empty_state.dart';
import '../../utils/platform_helper.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import '../../utils/responsive_grid_delegate.dart';

/// Dashboard page showing overview statistics and quick actions
class AdminDashboardPage extends StatefulWidget {
  final void Function(int pageIndex)? onNavigateToPage;
  
  const AdminDashboardPage({
    super.key,
    this.onNavigateToPage,
  });

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
      child: Container(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveGridDelegate.getMaxContentWidth(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                StyledPageHeader(
                  title: 'Admin Dashboard',
                  size: StyledPageHeaderSize.h2,
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
                SectionContainer(
                  showShadow: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending Approvals',
                        style: AppTypography.heading3.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.large),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
                          context,
                          desktop: 4,
                          tablet: 3,
                          mobile: 2,
                          childAspectRatio: 1.2,
                          crossAxisSpacing: AppSpacing.large,
                          mainAxisSpacing: AppSpacing.large,
                        ),
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          switch (index) {
                            case 0:
                              return AdminDashboardCard(
                                title: 'Total Pending',
                                value: totalPending.toString(),
                                icon: Icons.pending_actions,
                                backgroundColor: AppColors.warningMain,
                                onTap: () {
                                  widget.onNavigateToPage?.call(1);
                                },
                              );
                            case 1:
                              return AdminDashboardCard(
                                title: 'Pending Podcasts',
                                value: (stats['pending_podcasts'] ?? 0).toString(),
                                icon: Icons.podcasts,
                                backgroundColor: AppColors.infoMain,
                                onTap: () {
                                  widget.onNavigateToPage?.call(1);
                                },
                              );
                            case 2:
                              return AdminDashboardCard(
                                title: 'Pending Movies',
                                value: (stats['pending_movies'] ?? 0).toString(),
                                icon: Icons.movie,
                                backgroundColor: AppColors.primaryMain,
                                onTap: () {
                                  widget.onNavigateToPage?.call(2);
                                },
                              );
                            case 3:
                              return AdminDashboardCard(
                                title: 'Pending Posts',
                                value: (stats['pending_posts'] ?? 0).toString(),
                                icon: Icons.post_add,
                                backgroundColor: AppColors.accentMain,
                                onTap: () {
                                  widget.onNavigateToPage?.call(3);
                                },
                              );
                            default:
                              return const SizedBox();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.extraLarge),

                // Total Content Stats
                SectionContainer(
                  showShadow: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Content',
                        style: AppTypography.heading3.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.large),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
                          context,
                          desktop: 4,
                          tablet: 3,
                          mobile: 2,
                          childAspectRatio: 1.2,
                          crossAxisSpacing: AppSpacing.large,
                          mainAxisSpacing: AppSpacing.large,
                        ),
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          switch (index) {
                            case 0:
                              return AdminDashboardCard(
                                title: 'Total Podcasts',
                                value: (stats['total_podcasts'] ?? 0).toString(),
                                icon: Icons.library_books,
                                backgroundColor: AppColors.infoMain,
                                onTap: () {
                                  widget.onNavigateToPage?.call(1);
                                },
                              );
                            case 1:
                              return AdminDashboardCard(
                                title: 'Total Movies',
                                value: (stats['total_movies'] ?? 0).toString(),
                                icon: Icons.video_library,
                                backgroundColor: AppColors.primaryMain,
                                onTap: () {
                                  widget.onNavigateToPage?.call(2);
                                },
                              );
                            case 2:
                              return AdminDashboardCard(
                                title: 'Total Music',
                                value: (stats['total_music'] ?? 0).toString(),
                                icon: Icons.library_music,
                                backgroundColor: AppColors.successMain,
                                onTap: () {
                                  widget.onNavigateToPage?.call(1);
                                },
                              );
                            case 3:
                              return AdminDashboardCard(
                                title: 'Total Posts',
                                value: (stats['total_posts'] ?? 0).toString(),
                                icon: Icons.article,
                                backgroundColor: AppColors.accentMain,
                                onTap: () {
                                  widget.onNavigateToPage?.call(3);
                                },
                              );
                            case 4:
                              return AdminDashboardCard(
                                title: 'Bible Documents',
                                value: (stats['total_documents'] ?? 0).toString(),
                                icon: Icons.menu_book,
                                backgroundColor: AppColors.primaryDark,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AdminDocumentsPage(),
                                    ),
                                  );
                                },
                              );
                            default:
                              return const SizedBox();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.extraLarge),

                // Support & Inbox
                SectionContainer(
                  showShadow: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Support & Inbox',
                        style: AppTypography.heading3.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.large),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
                          context,
                          desktop: 2,
                          tablet: 2,
                          mobile: 1,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: AppSpacing.large,
                          mainAxisSpacing: AppSpacing.large,
                        ),
                        itemCount: 2,
                        itemBuilder: (context, index) {
                          switch (index) {
                            case 0:
                              return AdminDashboardCard(
                                title: 'Open Support Tickets',
                                value: (stats['open_support_tickets'] ?? 0).toString(),
                                icon: Icons.support_agent,
                                backgroundColor: AppColors.primaryMain,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AdminSupportPage(),
                                    ),
                                  );
                                },
                              );
                            case 1:
                              return AdminDashboardCard(
                                title: 'New Messages',
                                value: (stats['unread_support_messages'] ?? 0).toString(),
                                icon: Icons.mark_unread_chat_alt_outlined,
                                backgroundColor: AppColors.errorMain,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AdminSupportPage(),
                                    ),
                                  );
                                },
                              );
                            default:
                              return const SizedBox();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.extraLarge),

                // Documents
                SectionContainer(
                  showShadow: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Documents',
                        style: AppTypography.heading3.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.large),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
                          context,
                          desktop: 2,
                          tablet: 2,
                          mobile: 1,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: AppSpacing.large,
                          mainAxisSpacing: AppSpacing.large,
                        ),
                        itemCount: 2,
                        itemBuilder: (context, index) {
                          switch (index) {
                            case 0:
                              return AdminDashboardCard(
                                title: 'Total Documents',
                                value: (stats['total_documents'] ?? 0).toString(),
                                icon: Icons.menu_book,
                                backgroundColor: AppColors.primaryDark,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AdminDocumentsPage(),
                                    ),
                                  );
                                },
                              );
                            case 1:
                              return AdminDashboardCard(
                                title: 'Manage Documents',
                                value: 'Upload PDF',
                                icon: Icons.add_circle_outline,
                                backgroundColor: AppColors.infoMain,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AdminDocumentsPage(),
                                    ),
                                  );
                                },
                              );
                            default:
                              return const SizedBox();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

