import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/admin/admin_dashboard_card.dart';
import '../admin/admin_support_page.dart';
import '../admin/admin_documents_page.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../utils/responsive_utils.dart';
import 'admin_commission_settings_page.dart';

/// Dashboard page showing overview statistics and quick actions
class AdminDashboardPage extends StatefulWidget {
  final void Function(int pageIndex, {int tabIndex})? onNavigateToPage;
  
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
            StyledPillButton(
              label: 'Retry',
              icon: Icons.refresh,
              onPressed: _loadStats,
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
    
    // Use ResponsiveUtils to determine layout
    final isMobile = ResponsiveUtils.isMobile(context);

    if (isMobile) {
      return _buildMobileLayout(context, stats);
    } else {
      return _buildDesktopLayout(context, stats);
    }
  }

  Widget _buildMobileLayout(BuildContext context, Map<String, dynamic> stats) {
    final isSmallMobile = ResponsiveUtils.isSmallMobile(context);
    final horizontalPadding = ResponsiveUtils.getPageHorizontalPadding(context);
    final verticalPadding = ResponsiveUtils.getPageVerticalPadding(context);
    
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 0, // Hide default toolbar, we just want the TabBar
          bottom: TabBar(
            indicatorColor: AppColors.warmBrown,
            labelColor: AppColors.warmBrown,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: AppTypography.body.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isSmallMobile ? 12 : 14,
            ),
            unselectedLabelStyle: AppTypography.body.copyWith(
              fontSize: isSmallMobile ? 12 : 14,
            ),
            labelPadding: EdgeInsets.symmetric(
              horizontal: isSmallMobile ? 8 : 12,
            ),
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
              Tab(text: 'Manage'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Pending
            RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: _buildPendingStats(context, stats),
              ),
            ),
            // Tab 2: Approved
            RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: _buildApprovedStats(context, stats),
              ),
            ),
            // Tab 3: Management
            RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Column(
                  children: [
                    _buildSupportStats(context, stats),
                    SizedBox(height: isSmallMobile ? AppSpacing.medium : AppSpacing.large),
                    _buildDocumentStats(context, stats),
                    SizedBox(height: isSmallMobile ? AppSpacing.medium : AppSpacing.large),
                    _buildCommissionSettings(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, Map<String, dynamic> stats) {
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
                _buildPendingStats(context, stats),
                const SizedBox(height: AppSpacing.extraLarge),
                _buildApprovedStats(context, stats),
                const SizedBox(height: AppSpacing.extraLarge),
                _buildSupportStats(context, stats),
                const SizedBox(height: AppSpacing.extraLarge),
                _buildDocumentStats(context, stats),
                const SizedBox(height: AppSpacing.extraLarge),
                _buildCommissionSettings(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingStats(BuildContext context, Map<String, dynamic> stats) {
    final totalPending = (stats['pending_podcasts'] ?? 0) +
        (stats['pending_movies'] ?? 0) +
        (stats['pending_music'] ?? 0) +
        (stats['pending_posts'] ?? 0) +
        (stats['pending_events'] ?? 0);
    
    final isSmallMobile = ResponsiveUtils.isSmallMobile(context);
    final isMobile = ResponsiveUtils.isMobile(context);

    return SectionContainer(
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallMobile ? AppSpacing.tiny : AppSpacing.small),
                decoration: BoxDecoration(
                  color: AppColors.warmBrown.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Icon(
                  Icons.pending_actions,
                  color: AppColors.warmBrown,
                  size: isSmallMobile ? 16 : 20,
                ),
              ),
              SizedBox(width: isSmallMobile ? AppSpacing.tiny : AppSpacing.small),
              Flexible(
                child: Text(
                  'Pending Approvals',
                  style: AppTypography.heading3.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: isSmallMobile ? 16 : (isMobile ? 18 : null),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallMobile ? AppSpacing.medium : AppSpacing.large),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
              context,
              desktop: 4,
              tablet: 2,
              mobile: 2,
              childAspectRatio: isSmallMobile ? 1.4 : 1.2,
              crossAxisSpacing: isSmallMobile ? AppSpacing.small : AppSpacing.medium,
              mainAxisSpacing: isSmallMobile ? AppSpacing.small : AppSpacing.medium,
            ),
            itemCount: 5,
            itemBuilder: (context, index) {
              switch (index) {
                case 0:
                  return AdminDashboardCard(
                    title: 'Total Pending',
                    value: totalPending.toString(),
                    icon: Icons.pending_actions,
                    backgroundColor: AppColors.warmBrown,
                    onTap: () {
                      widget.onNavigateToPage?.call(1, tabIndex: 0); // All tab
                    },
                  );
                case 1:
                  return AdminDashboardCard(
                    title: 'Pending Podcasts',
                    value: (stats['pending_podcasts'] ?? 0).toString(),
                    icon: Icons.podcasts,
                    backgroundColor: AppColors.warmBrown,
                    onTap: () {
                      widget.onNavigateToPage?.call(1, tabIndex: 1); // Podcasts tab
                    },
                  );
                case 2:
                  return AdminDashboardCard(
                    title: 'Pending Movies',
                    value: (stats['pending_movies'] ?? 0).toString(),
                    icon: Icons.movie,
                    backgroundColor: AppColors.warmBrown,
                    onTap: () {
                      widget.onNavigateToPage?.call(1, tabIndex: 2); // Movies tab
                    },
                  );
                case 3:
                  return AdminDashboardCard(
                    title: 'Pending Posts',
                    value: (stats['pending_posts'] ?? 0).toString(),
                    icon: Icons.post_add,
                    backgroundColor: AppColors.warmBrown,
                    onTap: () {
                      widget.onNavigateToPage?.call(1, tabIndex: 3); // Posts tab
                    },
                  );
                case 4:
                  return AdminDashboardCard(
                    title: 'Pending Events',
                    value: (stats['pending_events'] ?? 0).toString(),
                    icon: Icons.event,
                    backgroundColor: AppColors.warmBrown,
                    onTap: () {
                      widget.onNavigateToPage?.call(1, tabIndex: 5); // Events tab
                    },
                  );
                default:
                  return const SizedBox();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildApprovedStats(BuildContext context, Map<String, dynamic> stats) {
    final totalApproved = (stats['total_podcasts'] ?? 0) +
        (stats['total_movies'] ?? 0) +
        (stats['total_posts'] ?? 0);
    
    final isSmallMobile = ResponsiveUtils.isSmallMobile(context);
    final isMobile = ResponsiveUtils.isMobile(context);

    return SectionContainer(
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallMobile ? AppSpacing.tiny : AppSpacing.small),
                decoration: BoxDecoration(
                  color: AppColors.warmBrown.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.warmBrown,
                  size: isSmallMobile ? 16 : 20,
                ),
              ),
              SizedBox(width: isSmallMobile ? AppSpacing.tiny : AppSpacing.small),
              Flexible(
                child: Text(
                  'Approved Content',
                  style: AppTypography.heading3.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: isSmallMobile ? 16 : (isMobile ? 18 : null),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallMobile ? AppSpacing.medium : AppSpacing.large),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
              context,
              desktop: 4,
              tablet: 2,
              mobile: 2,
              childAspectRatio: isSmallMobile ? 1.4 : 1.2,
              crossAxisSpacing: isSmallMobile ? AppSpacing.small : AppSpacing.medium,
              mainAxisSpacing: isSmallMobile ? AppSpacing.small : AppSpacing.medium,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              switch (index) {
                case 0:
                  return AdminDashboardCard(
                    title: 'All Approved',
                    value: totalApproved.toString(),
                    icon: Icons.check_circle,
                    backgroundColor: AppColors.warmBrown,
                    onTap: () {
                      widget.onNavigateToPage?.call(2, tabIndex: 0); // All tab
                    },
                  );
                case 1:
                  return AdminDashboardCard(
                    title: 'Approved Podcasts',
                    value: (stats['total_podcasts'] ?? 0).toString(),
                    icon: Icons.podcasts,
                    backgroundColor: AppColors.warmBrown,
                    onTap: () {
                      widget.onNavigateToPage?.call(2, tabIndex: 1); // Podcasts tab
                    },
                  );
                case 2:
                  return AdminDashboardCard(
                    title: 'Approved Movies',
                    value: (stats['total_movies'] ?? 0).toString(),
                    icon: Icons.movie,
                    backgroundColor: AppColors.warmBrown,
                    onTap: () {
                      widget.onNavigateToPage?.call(2, tabIndex: 2); // Movies tab
                    },
                  );
                case 3:
                  return AdminDashboardCard(
                    title: 'Approved Posts',
                    value: (stats['total_posts'] ?? 0).toString(),
                    icon: Icons.article,
                    backgroundColor: AppColors.warmBrown,
                    onTap: () {
                      widget.onNavigateToPage?.call(2, tabIndex: 3); // Posts tab
                    },
                  );
                default:
                  return const SizedBox();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSupportStats(BuildContext context, Map<String, dynamic> stats) {
    final isSmallMobile = ResponsiveUtils.isSmallMobile(context);
    final isMobile = ResponsiveUtils.isMobile(context);
    
    return SectionContainer(
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support & Inbox',
            style: AppTypography.heading3.copyWith(
              color: AppColors.textPrimary,
              fontSize: isSmallMobile ? 16 : (isMobile ? 18 : null),
            ),
          ),
          SizedBox(height: isSmallMobile ? AppSpacing.medium : AppSpacing.large),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
              context,
              desktop: 2,
              tablet: 2,
              mobile: 1,
              childAspectRatio: isSmallMobile ? 2.5 : 2.2,
              crossAxisSpacing: isSmallMobile ? AppSpacing.medium : AppSpacing.large,
              mainAxisSpacing: isSmallMobile ? AppSpacing.medium : AppSpacing.large,
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
                default:
                  return const SizedBox();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentStats(BuildContext context, Map<String, dynamic> stats) {
    final isSmallMobile = ResponsiveUtils.isSmallMobile(context);
    final isMobile = ResponsiveUtils.isMobile(context);
    
    return SectionContainer(
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Documents',
            style: AppTypography.heading3.copyWith(
              color: AppColors.textPrimary,
              fontSize: isSmallMobile ? 16 : (isMobile ? 18 : null),
            ),
          ),
          SizedBox(height: isSmallMobile ? AppSpacing.medium : AppSpacing.large),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
              context,
              desktop: 2,
              tablet: 2,
              mobile: 1,
              childAspectRatio: isSmallMobile ? 2.0 : 1.8,
              crossAxisSpacing: isSmallMobile ? AppSpacing.medium : AppSpacing.large,
              mainAxisSpacing: isSmallMobile ? AppSpacing.medium : AppSpacing.large,
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
                    backgroundColor: AppColors.primaryMain,
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
    );
  }

  Widget _buildCommissionSettings(BuildContext context) {
    final isSmallMobile = ResponsiveUtils.isSmallMobile(context);
    final isMobile = ResponsiveUtils.isMobile(context);
    
    return SectionContainer(
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallMobile ? AppSpacing.tiny : AppSpacing.small),
                decoration: BoxDecoration(
                  color: AppColors.warmBrown.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.warmBrown,
                  size: isSmallMobile ? 16 : 20,
                ),
              ),
              SizedBox(width: isSmallMobile ? AppSpacing.tiny : AppSpacing.small),
              Flexible(
                child: Text(
                  'Commission Settings',
                  style: AppTypography.heading3.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: isSmallMobile ? 16 : (isMobile ? 18 : null),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallMobile ? AppSpacing.small : AppSpacing.medium),
          Text(
            'Configure platform commission rates for donations',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: isSmallMobile ? 12 : (isMobile ? 13 : null),
            ),
          ),
          SizedBox(height: isSmallMobile ? AppSpacing.medium : AppSpacing.large),
          StyledPillButton(
            label: 'Manage Commission Settings',
            icon: Icons.settings,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminCommissionSettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

}

