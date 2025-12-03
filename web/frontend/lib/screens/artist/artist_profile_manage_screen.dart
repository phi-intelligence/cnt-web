import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../models/artist.dart';
import '../../providers/artist_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../services/api_service.dart';
import '../../models/content_item.dart';
import '../../utils/media_utils.dart';

class ArtistProfileManageScreen extends StatefulWidget {
  const ArtistProfileManageScreen({super.key});

  @override
  State<ArtistProfileManageScreen> createState() => _ArtistProfileManageScreenState();
}

class _ArtistProfileManageScreenState extends State<ArtistProfileManageScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _artistNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _instagramController = TextEditingController();
  final _twitterController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _websiteController = TextEditingController();
  final ApiService _api = ApiService();
  
  bool _isLoading = false;
  bool _isSaving = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  List<ContentItem> _myPodcasts = [];
  bool _loadingPodcasts = false;

  bool _isEditing = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Defer loading to after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadArtistData();
      }
    });
  }

  Future<void> _loadArtistData() async {
    setState(() {
      _isLoading = true;
      _loadingPodcasts = true;
    });

    final provider = context.read<ArtistProvider>();
    await provider.fetchMyArtist();
    
    final artist = provider.myArtist;
    if (artist != null) {
      _artistNameController.text = artist.artistName ?? '';
      _bioController.text = artist.bio ?? '';
      _instagramController.text = artist.instagram ?? '';
      _twitterController.text = artist.twitter ?? '';
      _youtubeController.text = artist.youtube ?? '';
      _websiteController.text = artist.website ?? '';
      
      // Fetch artist's podcasts
      try {
        await provider.fetchArtistPodcasts(artist.id);
        final podcasts = provider.getArtistPodcasts(artist.id) ?? [];
        setState(() {
          _myPodcasts = podcasts;
        });
      } catch (e) {
        print('Error loading podcasts: $e');
      }
    }

    setState(() {
      _isLoading = false;
      _loadingPodcasts = false;
    });
  }

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = pickedFile.name;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final provider = context.read<ArtistProvider>();

    try {
      // Upload cover image if selected
      if (_selectedImageBytes != null && _selectedImageName != null) {
        await provider.uploadCoverImage(_selectedImageBytes!, _selectedImageName!);
      }

      // Update profile
      final success = await provider.updateArtist(
        artistName: _artistNameController.text.trim(),
        bio: _bioController.text.trim(),
        socialLinks: {
          'instagram': _instagramController.text.trim(),
          'twitter': _twitterController.text.trim(),
          'youtube': _youtubeController.text.trim(),
          'website': _websiteController.text.trim(),
        }..removeWhere((key, value) => value.isEmpty),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        _toggleEditMode(); // Exit edit mode on success
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _artistNameController.dispose();
    _bioController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    _youtubeController.dispose();
    _websiteController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset fields if cancelling edit
        _loadArtistData();
        _selectedImageBytes = null;
        _selectedImageName = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<ArtistProvider>(
              builder: (context, provider, _) {
                final artist = provider.myArtist;
                if (artist == null) {
                  return const Center(child: Text('Artist profile not found'));
                }

                final videoPodcasts = _myPodcasts.where((p) => p.videoUrl != null).toList();
                final audioPodcasts = _myPodcasts.where((p) => p.videoUrl == null && p.audioUrl != null).toList();

                return CustomScrollView(
                  slivers: [
                    // Header with cover image - white/brown theme
                    SliverAppBar(
                      expandedHeight: 300,
                      pinned: true,
                      backgroundColor: AppColors.warmBrown,
                      foregroundColor: Colors.white,
                      actions: [
                        if (_isEditing)
                          IconButton(
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check),
                            onPressed: _isSaving ? null : _saveProfile,
                            tooltip: 'Save Changes',
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: _toggleEditMode,
                            tooltip: 'Edit Profile',
                          ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Cover Image
                            if (_selectedImageBytes != null)
                              Image.memory(
                                _selectedImageBytes!,
                                fit: BoxFit.cover,
                              )
                            else if (artist.coverImage != null)
                              Image.network(
                                artist.coverImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.warmBrown.withOpacity(0.3),
                                  child: Icon(Icons.person, size: 100, color: AppColors.warmBrown),
                                ),
                              )
                            else
                              Container(
                                color: AppColors.warmBrown.withOpacity(0.3),
                                child: Icon(Icons.person, size: 100, color: AppColors.warmBrown),
                              ),
                            
                            // Edit Overlay
                            if (_isEditing)
                              Container(
                                color: Colors.black54,
                                child: Center(
                                  child: ElevatedButton.icon(
                                    onPressed: _pickCoverImage,
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('Change Cover'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white.withOpacity(0.2),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                            // Gradient Overlay (View Mode)
                            if (!_isEditing)
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.8),
                                    ],
                                  ),
                                ),
                              ),

                            // Artist Info (View Mode)
                            if (!_isEditing)
                              Positioned(
                                bottom: 16,
                                left: 16,
                                right: 16,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      artist.displayName,
                                      style: AppTypography.heading1.copyWith(color: Colors.white),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          '${artist.followersCount} followers',
                                          style: AppTypography.body.copyWith(color: Colors.white70),
                                        ),
                                        const SizedBox(width: 16),
                                        if (artist.isVerified)
                                          Icon(Icons.verified, color: AppColors.accentMain, size: 20),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Profile Details Form/View
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.large),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_isEditing) ...[
                                Text('Artist Name', style: AppTypography.label),
                                const SizedBox(height: AppSpacing.small),
                                TextFormField(
                                  controller: _artistNameController,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter your artist name',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) =>
                                      value?.trim().isEmpty == true ? 'Required' : null,
                                ),
                                const SizedBox(height: AppSpacing.large),
                              ],

                              Text('About', style: AppTypography.heading2),
                              const SizedBox(height: AppSpacing.small),
                              if (_isEditing)
                                TextFormField(
                                  controller: _bioController,
                                  decoration: const InputDecoration(
                                    hintText: 'Tell your fans about yourself...',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 5,
                                )
                              else
                                Text(
                                  artist.bio ?? 'No bio yet.',
                                  style: AppTypography.body,
                                ),
                              
                              const SizedBox(height: AppSpacing.large),
                              Text('Connect', style: AppTypography.heading2),
                              const SizedBox(height: AppSpacing.small),
                              
                              if (_isEditing) ...[
                                _buildSocialInput(_instagramController, 'Instagram', Icons.photo_camera),
                                const SizedBox(height: AppSpacing.small),
                                _buildSocialInput(_twitterController, 'Twitter/X', Icons.chat),
                                const SizedBox(height: AppSpacing.small),
                                _buildSocialInput(_youtubeController, 'YouTube', Icons.play_circle_outline),
                                const SizedBox(height: AppSpacing.small),
                                _buildSocialInput(_websiteController, 'Website', Icons.language),
                                const SizedBox(height: AppSpacing.large),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _toggleEditMode,
                                        child: const Text('Cancel'),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.medium),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _isSaving ? null : _saveProfile,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryMain,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: _isSaving
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Text('Save Changes'),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else if (artist.socialLinks != null && artist.socialLinks!.isNotEmpty)
                                Wrap(
                                  spacing: 12,
                                  children: [
                                    if (artist.instagram != null)
                                      _buildSocialIcon(Icons.photo_camera, artist.instagram!),
                                    if (artist.twitter != null)
                                      _buildSocialIcon(Icons.chat, artist.twitter!),
                                    if (artist.youtube != null)
                                      _buildSocialIcon(Icons.play_circle_outline, artist.youtube!),
                                    if (artist.website != null)
                                      _buildSocialIcon(Icons.language, artist.website!),
                                  ],
                                )
                              else
                                Text(
                                  'No social links added.',
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Stats Section - white/brown theme
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
                        padding: const EdgeInsets.all(AppSpacing.large),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                          border: Border.all(color: AppColors.borderPrimary),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.warmBrown.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('Followers', '${artist.followersCount}'),
                            _buildStatItem('Podcasts', '${_myPodcasts.length}'),
                            _buildStatItem('Total Plays', '${_myPodcasts.fold<int>(0, (sum, p) => sum + (p.plays ?? 0))}'),
                          ],
                        ),
                      ),
                    ),
                    
                    const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.large)),

                    // Content Tabs
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _TabBarDelegate(
                        TabBar(
                          controller: _tabController,
                          labelColor: AppColors.primaryMain,
                          unselectedLabelColor: AppColors.textSecondary,
                          indicatorColor: AppColors.primaryMain,
                          tabs: const [
                            Tab(text: 'Video Podcasts'),
                            Tab(text: 'Audio Podcasts'),
                          ],
                        ),
                      ),
                    ),

                    // Content Grid
                    SliverFillRemaining(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildContentGrid(videoPodcasts, isVideo: true),
                          _buildContentGrid(audioPodcasts, isVideo: false),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.heading2.copyWith(
            color: AppColors.warmBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialInput(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.warmBrown),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          borderSide: BorderSide(color: AppColors.borderPrimary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          borderSide: BorderSide(color: AppColors.borderPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          borderSide: BorderSide(color: AppColors.warmBrown, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, String url) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        color: AppColors.warmBrown.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: IconButton(
        icon: Icon(icon),
        color: AppColors.warmBrown,
        onPressed: () {}, // In manage mode, maybe just show tooltip or nothing
        tooltip: url,
      ),
    );
  }

  Widget _buildContentGrid(List<ContentItem> items, {required bool isVideo}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isVideo ? Icons.videocam_off : Icons.music_off,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${isVideo ? 'video' : 'audio'} podcasts yet',
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.medium),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        childAspectRatio: 0.8,
        crossAxisSpacing: AppSpacing.medium,
        mainAxisSpacing: AppSpacing.medium,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: item.coverImage != null && resolveMediaUrl(item.coverImage) != null
                    ? Image.network(
                        resolveMediaUrl(item.coverImage!)!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.primaryMain.withOpacity(0.1),
                          child: Icon(Icons.broken_image, color: AppColors.textSecondary),
                        ),
                      )
                    : Container(
                        color: AppColors.primaryMain.withOpacity(0.1),
                        child: Center(
                          child: Icon(
                            isVideo ? Icons.movie : Icons.mic,
                            size: 48,
                            color: AppColors.primaryMain,
                          ),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.small),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item.createdAt.toString().split(' ')[0],
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.borderPrimary),
        ),
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return false;
  }
}

