import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/shared/loading_shimmer.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/web/content_card_web.dart';
import '../../services/download_service.dart';
import '../../providers/audio_player_provider.dart';
import '../../models/content_item.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../utils/dimension_utils.dart';

/// Web Downloads Screen
class DownloadsScreenWeb extends StatefulWidget {
  const DownloadsScreenWeb({super.key});

  @override
  State<DownloadsScreenWeb> createState() => _DownloadsScreenWebState();
}

class _DownloadsScreenWebState extends State<DownloadsScreenWeb> {
  final DownloadService _downloadService = DownloadService();
  List<Map<String, dynamic>> _downloads = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    setState(() => _isLoading = true);
    try {
      final downloads = await _downloadService.getDownloads();
      setState(() {
        _downloads = downloads;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading downloads: $e');
      setState(() => _isLoading = false);
    }
  }

  void _handlePlay(ContentItem item) {
    context.read<AudioPlayerState>().playContent(item);
  }

  void _handleItemTap(ContentItem item) {
    _handlePlay(item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Container(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Downloads',
                  style: AppTypography.heading1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadDownloads,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.large),
            
            // Downloads Grid
            Expanded(
              child: _isLoading
                  ? GridView.builder(
                      padding: EdgeInsets.zero,
                      gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
                        context,
                        desktop: 5,
                        tablet: 3,
                        mobile: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: AppSpacing.medium,
                        mainAxisSpacing: AppSpacing.medium,
                      ),
                      itemCount: 8,
                      itemBuilder: (context, index) {
                        return const LoadingShimmer(width: double.infinity, height: 250);
                      },
                    )
                  : _downloads.isEmpty
                      ? const EmptyState(
                          icon: Icons.download_outlined,
                          title: 'No Downloads',
                          message: 'Download content to listen offline',
                        )
                      : GridView.builder(
                          padding: EdgeInsets.zero,
                          gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
                            context,
                            desktop: 5,
                            tablet: 3,
                            mobile: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: AppSpacing.medium,
                            mainAxisSpacing: AppSpacing.medium,
                          ),
                          itemCount: _downloads.length,
                          itemBuilder: (context, index) {
                            final download = _downloads[index];
                            final item = ContentItem(
                              id: download['id']?.toString() ?? '',
                              title: download['title'] ?? 'Unknown',
                              creator: download['creator'] ?? 'Unknown',
                              description: download['description'],
                              coverImage: download['cover_image'],
                              audioUrl: download['local_path'],
                              duration: download['duration'] != null
                                  ? Duration(seconds: download['duration'])
                                  : null,
                              category: download['category'] ?? 'Downloaded',
                              createdAt: download['created_at'] != null
                                  ? DateTime.parse(download['created_at'])
                                  : DateTime.now(),
                            );
                            return ContentCardWeb(
                              item: item,
                              onTap: () => _handleItemTap(item),
                              onPlay: () => _handlePlay(item),
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

