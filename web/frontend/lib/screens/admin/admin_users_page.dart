import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/web/styled_filter_chip.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/responsive_grid_delegate.dart';

/// Redesigned Users management page with cream/brown theme
class AdminUsersPage extends StatefulWidget {
  final VoidCallback? onNavigateBack;

  const AdminUsersPage({
    super.key,
    this.onNavigateBack,
  });

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Admins', 'Artists', 'Regular'];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await _api.getUsers();
      if (mounted) {
        setState(() {
          _users = users;
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

  List<dynamic> _getFilteredUsers() {
    var filtered = _users;

    // Apply role filter
    if (_selectedFilter != 'All') {
      filtered = filtered.where((user) {
        final isAdmin = user['is_admin'] == true;
        final isArtist = user['has_artist_profile'] == true;
        
        switch (_selectedFilter) {
          case 'Admins':
            return isAdmin;
          case 'Artists':
            return isArtist;
          case 'Regular':
            return !isAdmin && !isArtist;
          default:
            return true;
        }
      }).toList();
    }

    // Apply search filter
    final query = _searchController.text.toLowerCase().trim();
    if (query.isNotEmpty) {
      filtered = filtered.where((user) {
        final name = user['name']?.toString().toLowerCase() ?? '';
        final email = user['email']?.toString().toLowerCase() ?? '';
        final username = user['username']?.toString().toLowerCase() ?? '';
        return name.contains(query) || email.contains(query) || username.contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 900;
    
    return Container(
      color: const Color(0xFFF5F0E8),
      child: RefreshIndicator(
        onRefresh: _fetchUsers,
        color: AppColors.warmBrown,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),
            SliverToBoxAdapter(
              child: _buildFilters(),
            ),
            _buildUsersListSliver(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isSmallMobile = ResponsiveUtils.isSmallMobile(context);
    final horizontalPadding = ResponsiveUtils.getPageHorizontalPadding(context);
    final verticalPadding = ResponsiveUtils.getPageVerticalPadding(context);
    
    return Container(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        verticalPadding,
        horizontalPadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stack vertically on mobile, horizontal on desktop
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Management',
                          style: AppTypography.heading3.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: isSmallMobile ? 18 : 20,
                          ),
                        ),
                        SizedBox(height: isSmallMobile ? 2 : 4),
                        Text(
                          '${_users.length} total users',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: isSmallMobile ? 11 : null,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallMobile ? AppSpacing.small : AppSpacing.medium),
                    // Stats Cards - wrap on mobile
                    Wrap(
                      spacing: isSmallMobile ? 8 : 12,
                      runSpacing: isSmallMobile ? 8 : 12,
                      children: [
                        _buildStatBadge(
                          '${_users.where((u) => u['is_admin'] == true).length} Admins',
                          Icons.admin_panel_settings,
                          AppColors.warmBrown,
                        ),
                        _buildStatBadge(
                          '${_users.where((u) => u['has_artist_profile'] == true).length} Artists',
                          Icons.music_note,
                          const Color(0xFF8B5CF6),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Management',
                          style: AppTypography.heading3.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_users.length} total users',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    // Stats Cards
                    Row(
                      children: [
                        _buildStatBadge(
                          '${_users.where((u) => u['is_admin'] == true).length} Admins',
                          Icons.admin_panel_settings,
                          AppColors.warmBrown,
                        ),
                        const SizedBox(width: 12),
                        _buildStatBadge(
                          '${_users.where((u) => u['has_artist_profile'] == true).length} Artists',
                          Icons.music_note,
                          const Color(0xFF8B5CF6),
                        ),
                      ],
                    ),
                  ],
                ),
          SizedBox(height: isSmallMobile ? AppSpacing.small : AppSpacing.medium),
          // Search Field - Pill-shaped white search bar matching approved page
          Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 500,
            ),
            child: TextField(
              controller: _searchController,
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary,
                fontSize: isSmallMobile ? 13 : null,
              ),
              decoration: InputDecoration(
                hintText: 'Search by name, email, or username...',
                hintStyle: AppTypography.body.copyWith(
                  color: AppColors.textSecondary.withOpacity(0.6),
                  fontSize: isSmallMobile ? 13 : null,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.warmBrown,
                  size: isSmallMobile ? 20 : 24,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: AppColors.textSecondary,
                          size: isSmallMobile ? 20 : 24,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide(color: AppColors.borderPrimary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide(color: AppColors.borderPrimary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide(color: AppColors.warmBrown, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isSmallMobile ? AppSpacing.medium : AppSpacing.large,
                  vertical: isSmallMobile ? 12 : 14,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, IconData icon, Color color) {
    final isSmallMobile = ResponsiveUtils.isSmallMobile(context);
    final isMobile = ResponsiveUtils.isMobile(context);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallMobile ? 10 : 12,
        vertical: isSmallMobile ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isSmallMobile ? 14 : 16,
            color: color,
          ),
          SizedBox(width: isSmallMobile ? 4 : 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: isSmallMobile ? 10 : (isMobile ? 11 : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final horizontalPadding = ResponsiveUtils.getPageHorizontalPadding(context);
    
    return Container(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AppSpacing.medium,
        horizontalPadding,
        AppSpacing.small,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: EdgeInsets.only(
                right: filter != _filters.last ? AppSpacing.small : 0,
              ),
              child: StyledFilterChip(
                label: filter,
                selected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.warmBrown),
            const SizedBox(height: 16),
            Text(
              'Loading users...',
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.errorMain),
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warmBrown,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final filteredUsers = _getFilteredUsers();

    if (filteredUsers.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline,
        title: 'No users found',
        message: 'Try adjusting your filters or search',
      );
    }

    // Use responsive grid layout
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    
    // For mobile, use list layout
    if (isMobile) {
      return ListView.builder(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
        itemCount: filteredUsers.length,
        itemBuilder: (context, index) {
          return _buildUserCard(filteredUsers[index]);
        },
      );
    }
    
    // For tablet and desktop, use grid layout
    return GridView.builder(
      padding: ResponsiveGridDelegate.getResponsivePadding(context),
      gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
        context,
        mobile: 1,
        tablet: 2,
        desktop: 3,
        childAspectRatio: ResponsiveUtils.getResponsiveValue(
          context: context,
          mobile: 2.5,
          tablet: 2.5,
          desktop: 2.5,
        ),
        crossAxisSpacing: ResponsiveUtils.getResponsivePadding(context, 16),
        mainAxisSpacing: ResponsiveUtils.getResponsivePadding(context, 16),
      ),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        return _buildUserCard(filteredUsers[index]);
      },
    );
  }

  Widget _buildUsersListSliver() {
    if (_isLoading) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.warmBrown),
              const SizedBox(height: 16),
              Text(
                'Loading users...',
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.errorMain),
              const SizedBox(height: 16),
              Text(
                'Error: $_error',
                style: AppTypography.body.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warmBrown,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filteredUsers = _getFilteredUsers();

    if (filteredUsers.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: const EmptyState(
          icon: Icons.people_outline,
          title: 'No users found',
          message: 'Try adjusting your filters or search',
        ),
      );
    }

    // Use responsive grid layout
    final isMobile = ResponsiveUtils.isMobile(context);
    
    // For mobile, use list layout
    if (isMobile) {
      return SliverPadding(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildUserCard(filteredUsers[index]),
            childCount: filteredUsers.length,
          ),
        ),
      );
    }
    
    // For tablet and desktop, use grid layout
    return SliverPadding(
      padding: ResponsiveGridDelegate.getResponsivePadding(context),
      sliver: SliverGrid(
        gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
          context,
          mobile: 1,
          tablet: 2,
          desktop: 3,
          childAspectRatio: ResponsiveUtils.getResponsiveValue(
            context: context,
            mobile: 2.5,
            tablet: 2.5,
            desktop: 2.5,
          ),
          crossAxisSpacing: ResponsiveUtils.getResponsivePadding(context, 16),
          mainAxisSpacing: ResponsiveUtils.getResponsivePadding(context, 16),
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return _buildUserCard(filteredUsers[index]);
          },
          childCount: filteredUsers.length,
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final name = user['name'] ?? 'Unknown User';
    final email = user['email'] ?? '';
    final username = user['username'] ?? '';
    final isAdmin = user['is_admin'] == true;
    final isArtist = user['has_artist_profile'] == true;
    final avatar = user['avatar'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.warmBrown.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: avatar != null && avatar.toString().isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        _api.getMediaUrl(avatar),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(name),
                      ),
                    )
                  : _buildAvatarPlaceholder(name),
            ),
            const SizedBox(width: 16),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isAdmin)
                        _buildRoleBadge('Admin', AppColors.warmBrown),
                      if (isArtist)
                        _buildRoleBadge('Artist', const Color(0xFF8B5CF6)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (username.isNotEmpty)
                    Text(
                      '@$username',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.warmBrown,
                      ),
                    ),
                  Text(
                    email,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Actions Menu
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 20, color: AppColors.textPrimary),
                      const SizedBox(width: 12),
                      Text(
                        'View Profile',
                        style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_admin',
                  child: Row(
                    children: [
                      Icon(
                        isAdmin ? Icons.remove_moderator : Icons.admin_panel_settings,
                        size: 20,
                        color: isAdmin ? AppColors.errorMain : AppColors.successMain,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isAdmin ? 'Remove Admin' : 'Make Admin',
                        style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 12),
                      Text('Delete User', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) => _handleUserAction(value, user),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initial,
        style: AppTypography.heading3.copyWith(
          color: AppColors.warmBrown,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Future<void> _handleUserAction(String action, Map<String, dynamic> user) async {
    switch (action) {
      case 'view':
        _showUserProfile(user);
        break;
      case 'toggle_admin':
        await _toggleAdminStatus(user);
        break;
      case 'delete':
        await _deleteUser(user);
        break;
    }
  }

  void _showUserProfile(Map<String, dynamic> user) {
    final name = user['name'] ?? 'Unknown User';
    final email = user['email'] ?? '';
    final username = user['username'] ?? '';
    final phone = user['phone'] ?? '';
    final isAdmin = user['is_admin'] == true;
    final isArtist = user['has_artist_profile'] == true || user['is_artist'] == true;
    final avatar = user['avatar'];
    final createdAt = user['created_at'];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F0E8),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'User Profile',
                      style: AppTypography.heading3.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.warmBrown.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: AppColors.warmBrown.withOpacity(0.2),
                            width: 3,
                          ),
                        ),
                        child: avatar != null && avatar.toString().isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Image.network(
                                  _api.getMediaUrl(avatar),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: AppTypography.heading1.copyWith(
                                        color: AppColors.warmBrown,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: AppTypography.heading1.copyWith(
                                    color: AppColors.warmBrown,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      // Name
                      Text(
                        name,
                        style: AppTypography.heading2.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Badges
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isAdmin)
                            _buildProfileBadge('Admin', AppColors.warmBrown),
                          if (isArtist)
                            _buildProfileBadge('Artist', const Color(0xFF8B5CF6)),
                          if (!isAdmin && !isArtist)
                            _buildProfileBadge('User', AppColors.textSecondary),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Details
                      _buildDetailItem('Email', email, Icons.email_outlined),
                      if (username.isNotEmpty)
                        _buildDetailItem('Username', '@$username', Icons.alternate_email),
                      if (phone.isNotEmpty)
                        _buildDetailItem('Phone', phone, Icons.phone_outlined),
                      if (createdAt != null)
                        _buildDetailItem('Joined', _formatDate(createdAt), Icons.calendar_today_outlined),
                      const SizedBox(height: 24),
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _handleUserAction('toggle_admin', user);
                              },
                              icon: Icon(
                                isAdmin ? Icons.remove_moderator : Icons.admin_panel_settings,
                                color: isAdmin ? AppColors.errorMain : AppColors.successMain,
                              ),
                              label: Text(
                                isAdmin ? 'Remove Admin' : 'Make Admin',
                                style: TextStyle(
                                  color: isAdmin ? AppColors.errorMain : AppColors.successMain,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isAdmin ? AppColors.errorMain : AppColors.successMain,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _handleUserAction('delete', user);
                          },
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          label: const Text('Delete User', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warmBrown.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.warmBrown.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.warmBrown, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _toggleAdminStatus(Map<String, dynamic> user) async {
    final isAdmin = user['is_admin'] == true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isAdmin ? 'Remove Admin Access' : 'Grant Admin Access',
          style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          isAdmin
              ? 'Are you sure you want to remove admin access from ${user['name']}?'
              : 'Are you sure you want to grant admin access to ${user['name']}?',
          style: AppTypography.body.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          if (ResponsiveUtils.isMobile(context))
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StyledPillButton(
                  label: 'Cancel',
                  icon: Icons.close,
                  onPressed: () => Navigator.pop(context, false),
                  variant: StyledPillButtonVariant.outlined,
                  width: double.infinity,
                ),
                SizedBox(height: ResponsiveUtils.getResponsivePadding(context, AppSpacing.small)),
                StyledPillButton(
                  label: isAdmin ? 'Remove' : 'Grant',
                  icon: isAdmin ? Icons.remove_circle_outline : Icons.add_circle_outline,
                  onPressed: () => Navigator.pop(context, true),
                  variant: StyledPillButtonVariant.filled,
                  width: double.infinity,
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                StyledPillButton(
                  label: 'Cancel',
                  icon: Icons.close,
                  onPressed: () => Navigator.pop(context, false),
                  variant: StyledPillButtonVariant.outlined,
                  width: ResponsiveUtils.getResponsiveValue(
                    context: context,
                    mobile: 100.0,
                    tablet: 120.0,
                    desktop: 100.0,
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getResponsivePadding(context, AppSpacing.small)),
                StyledPillButton(
                  label: isAdmin ? 'Remove' : 'Grant',
                  icon: isAdmin ? Icons.remove_circle_outline : Icons.add_circle_outline,
                  onPressed: () => Navigator.pop(context, true),
                  variant: StyledPillButtonVariant.filled,
                  width: ResponsiveUtils.getResponsiveValue(
                    context: context,
                    mobile: 100.0,
                    tablet: 120.0,
                    desktop: 100.0,
                  ),
                ),
              ],
            ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _api.updateUserAdmin(user['id'], !isAdmin);
        _showSnackBar(
          isAdmin ? 'Admin access removed' : 'Admin access granted',
          isSuccess: true,
        );
        _fetchUsers();
      } catch (e) {
        _showSnackBar('Failed to update user: $e');
      }
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isSmallMobile = ResponsiveUtils.isSmallMobile(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.getPageHorizontalPadding(context),
          vertical: ResponsiveUtils.getPageVerticalPadding(context),
        ),
        contentPadding: EdgeInsets.all(
          ResponsiveUtils.getResponsivePadding(context, AppSpacing.large),
        ),
        titlePadding: EdgeInsets.fromLTRB(
          ResponsiveUtils.getResponsivePadding(context, AppSpacing.large),
          ResponsiveUtils.getResponsivePadding(context, AppSpacing.large),
          ResponsiveUtils.getResponsivePadding(context, AppSpacing.large),
          ResponsiveUtils.getResponsivePadding(context, AppSpacing.small),
        ),
        actionsPadding: EdgeInsets.all(
          ResponsiveUtils.getResponsivePadding(context, AppSpacing.large),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        title: Text(
          'Delete User',
          style: AppTypography.heading3.copyWith(
            color: AppColors.textPrimary,
            fontSize: isSmallMobile ? 18 : null,
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${user['name']}? This action cannot be undone.',
          style: AppTypography.body.copyWith(
            color: AppColors.textPrimary,
            fontSize: isSmallMobile ? 13 : null,
          ),
        ),
        actions: [
          if (isMobile)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StyledPillButton(
                  label: 'Cancel',
                  icon: Icons.close,
                  onPressed: () => Navigator.pop(context, false),
                  variant: StyledPillButtonVariant.outlined,
                  width: double.infinity,
                ),
                SizedBox(height: ResponsiveUtils.getResponsivePadding(context, AppSpacing.medium)),
                StyledPillButton(
                  label: 'Delete',
                  icon: Icons.delete_outline,
                  onPressed: () => Navigator.pop(context, true),
                  variant: StyledPillButtonVariant.filled,
                  width: double.infinity,
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                StyledPillButton(
                  label: 'Cancel',
                  icon: Icons.close,
                  onPressed: () => Navigator.pop(context, false),
                  variant: StyledPillButtonVariant.outlined,
                  width: ResponsiveUtils.getResponsiveValue(
                    context: context,
                    mobile: 120.0,
                    tablet: 120.0,
                    desktop: 120.0,
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getResponsivePadding(context, AppSpacing.medium)),
                StyledPillButton(
                  label: 'Delete',
                  icon: Icons.delete_outline,
                  onPressed: () => Navigator.pop(context, true),
                  variant: StyledPillButtonVariant.filled,
                  width: ResponsiveUtils.getResponsiveValue(
                    context: context,
                    mobile: 120.0,
                    tablet: 120.0,
                    desktop: 120.0,
                  ),
                ),
              ],
            ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _api.deleteUser(user['id']);
        _showSnackBar('User deleted', isSuccess: true);
        _fetchUsers();
      } catch (e) {
        _showSnackBar('Failed to delete user: $e');
      }
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppColors.successMain : AppColors.errorMain,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
