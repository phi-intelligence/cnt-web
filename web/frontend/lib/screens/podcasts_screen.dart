import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';
import '../models/content_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/shared/image_helper.dart';

class PodcastsScreen extends StatefulWidget {
  const PodcastsScreen({super.key});

  @override
  State<PodcastsScreen> createState() => _PodcastsScreenState();
}

class _PodcastsScreenState extends State<PodcastsScreen> {
  final ApiService _api = ApiService();
  List<ContentItem> _podcasts = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPodcasts();
  }

  Future<void> _fetchPodcasts() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final podcastsData = await _api.getPodcasts();
      
      _podcasts = podcastsData.map((podcast) {
        final audioUrl = podcast.audioUrl != null && podcast.audioUrl!.isNotEmpty
            ? _api.getMediaUrl(podcast.audioUrl!)
            : null;
        
        return ContentItem(
          id: podcast.id.toString(),
          title: podcast.title,
          creator: 'Christ Tabernacle',
          description: podcast.description,
          coverImage: podcast.coverImage != null 
            ? _api.getMediaUrl(podcast.coverImage!) 
            : null,
          audioUrl: audioUrl,
          videoUrl: null,
          duration: podcast.duration != null 
            ? Duration(seconds: podcast.duration!)
            : null,
          category: _getCategoryName(podcast.categoryId),
          plays: podcast.playsCount,
          createdAt: podcast.createdAt,
        );
      }).where((p) => p.audioUrl != null && p.audioUrl!.isNotEmpty).toList();
      
      _error = null;
    } catch (e) {
      _error = 'Failed to load podcasts: $e';
      print('Error fetching podcasts: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getCategoryName(int? categoryId) {
    switch (categoryId) {
      case 1: return 'Sermons';
      case 2: return 'Bible Study';
      case 3: return 'Devotionals';
      case 4: return 'Prayer';
      case 5: return 'Worship';
      case 6: return 'Gospel';
      default: return 'Podcast';
    }
  }

  // Responsive grid configuration
  int _getCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) return 1;  // Mobile
    if (screenWidth < 900) return 2;  // Tablet
    if (screenWidth < 1200) return 3; // Desktop
    return 4; // Large Desktop
  }

  // Responsive aspect ratio
  double _getChildAspectRatio(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) return 0.9;
    return 0.75; 
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'Podcasts',
          style: AppTypography.heading3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search podcasts...',
                hintStyle: AppTypography.body.copyWith(color: AppColors.textPlaceholder),
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.warmBrown),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  borderSide: BorderSide(color: AppColors.borderPrimary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  borderSide: BorderSide(color: AppColors.borderPrimary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  borderSide: BorderSide(color: AppColors.warmBrown, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            
            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(label: 'All', isSelected: true),
                  _FilterChip(label: 'Testimony'),
                  _FilterChip(label: 'Teaching'),
                  _FilterChip(label: 'Prayer'),
                  _FilterChip(label: 'Worship'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            
            // Podcasts Grid
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.warmBrown),
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _error!,
                                style: AppTypography.body.copyWith(color: AppColors.errorMain),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.medium),
                              ElevatedButton(
                                onPressed: _fetchPodcasts,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.warmBrown,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                  ),
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _podcasts.isEmpty
                          ? Center(
                              child: Text(
                                'No podcasts available',
                                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                              ),
                            )
                          : GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: _getCrossAxisCount(context),
                                childAspectRatio: _getChildAspectRatio(context),
                                crossAxisSpacing: AppSpacing.medium,
                                mainAxisSpacing: AppSpacing.medium,
                              ),
                              itemCount: _podcasts.length,
                              itemBuilder: (context, index) {
                                final podcast = _podcasts[index];
                                return _PodcastCard(
                                  title: podcast.title,
                                  creator: podcast.creator ?? 'Unknown',
                                  category: podcast.category ?? 'Podcast',
                                  coverImage: podcast.coverImage,
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _FilterChip({
    required this.label,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.small),
      child: FilterChip(
        label: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        selected: isSelected,
        onSelected: (value) {
          // TODO: Handle filter selection
        },
        backgroundColor: Colors.white,
        selectedColor: AppColors.warmBrown,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          side: BorderSide(
            color: isSelected ? AppColors.warmBrown : AppColors.borderPrimary,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.small, vertical: AppSpacing.tiny),
      ),
    );
  }
}

class _PodcastCard extends StatelessWidget {
  final String title;
  final String creator;
  final String category;
  final String? coverImage;

  const _PodcastCard({
    required this.title,
    required this.creator,
    required this.category,
    this.coverImage,
  });

  @override
  Widget build(BuildContext context) {
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                color: AppColors.backgroundSecondary,
                image: coverImage != null 
                    ? DecorationImage(
                        image: ImageHelper.getImageProvider(coverImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: coverImage == null 
                  ? Icon(Icons.podcasts_rounded, size: 50, color: AppColors.warmBrown.withOpacity(0.5))
                  : null,
            ),
          ),
          
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.tiny),
                  Text(
                    creator,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.small, 
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentMain.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      category,
                      style: AppTypography.label.copyWith(
                        color: AppColors.accentMain,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
