import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/shared/loading_shimmer.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/web/content_card_web.dart';
import '../../widgets/web/styled_search_field.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/styled_filter_chip.dart';
import '../../widgets/web/section_container.dart';
import '../../providers/music_provider.dart';
import '../../providers/audio_player_provider.dart';
import '../../models/content_item.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../utils/dimension_utils.dart';

/// Web Music Screen - Full implementation
class MusicScreenWeb extends StatefulWidget {
  const MusicScreenWeb({super.key});

  @override
  State<MusicScreenWeb> createState() => _MusicScreenWebState();
}

class _MusicScreenWebState extends State<MusicScreenWeb> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedGenre = 'All';
  String _selectedSort = 'Latest';
  final List<String> _genres = ['All', 'Worship', 'Gospel', 'Contemporary', 'Hymns', 'Choir', 'Instrumental'];
  final List<String> _sortOptions = ['Latest', 'Popular', 'A-Z'];
  List<ContentItem> _filteredTracks = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterTracks);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MusicProvider>().fetchTracks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterTracks() {
    final provider = context.read<MusicProvider>();
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredTracks = provider.tracks.where((track) {
        final matchesSearch = query.isEmpty ||
            track.title.toLowerCase().contains(query) ||
            track.creator.toLowerCase().contains(query);
        
        final matchesGenre = _selectedGenre == 'All' ||
            (track.category?.toLowerCase() == _selectedGenre.toLowerCase());
        
        return matchesSearch && matchesGenre;
      }).toList();
      
      // Apply sorting
      switch (_selectedSort) {
        case 'Popular':
          _filteredTracks.sort((a, b) => b.plays.compareTo(a.plays));
          break;
        case 'A-Z':
          _filteredTracks.sort((a, b) => a.title.compareTo(b.title));
          break;
        case 'Latest':
        default:
          _filteredTracks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
      }
    });
  }

  void _handlePlay(ContentItem item) {
    if (item.audioUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No audio available for ${item.title}')),
      );
      return;
    }

    context.read<AudioPlayerState>().playContent(item);
  }

  void _handleItemTap(ContentItem item) {
    _handlePlay(item);
  }

  // Responsive aspect ratio for music cards
  double _getChildAspectRatio(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 480) {
      return 0.8; // Mobile: More compact cards
    } else if (screenWidth < 768) {
      return 0.75; // Tablet: Slightly less compact
    } else if (screenWidth < 1024) {
      return 0.7; // Desktop: Balanced
    }
    return 0.65; // Large desktop: More spacious
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
            // Header with Sort
            StyledPageHeader(
              title: 'Music',
              size: StyledPageHeaderSize.h1,
              action: PopupMenuButton<String>(
                icon: Icon(
                  Icons.sort,
                  color: AppColors.textPrimary,
                ),
                        onSelected: (value) {
                          setState(() {
                            _selectedSort = value;
                          });
                          _filterTracks();
                        },
                        itemBuilder: (context) {
                          return _sortOptions.map((option) {
                            return PopupMenuItem(
                              value: option,
                              child: Row(
                                children: [
                                  if (_selectedSort == option)
                                    const Icon(Icons.check, color: AppColors.primaryMain, size: 20)
                                  else
                                    const SizedBox(width: 20),
                                  Text(option),
                                ],
                              ),
                            );
                          }).toList();
                        },
                      ),
                  ),
            const SizedBox(height: AppSpacing.extraLarge),
                  
            // Search and Filter Section
            SectionContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  StyledSearchField(
                    controller: _searchController,
                      hintText: 'Search music...',
                    onChanged: (_) => _filterTracks(),
                  ),
                  
                  const SizedBox(height: AppSpacing.medium),
                  
                  // Genre Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _genres.map((genre) {
                        final isSelected = genre == _selectedGenre;
                        return Padding(
                          padding: EdgeInsets.only(right: AppSpacing.small),
                          child: StyledFilterChip(
                            label: genre,
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedGenre = genre;
                              });
                              _filterTracks();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                    ),
                  ),
                  
            const SizedBox(height: AppSpacing.extraLarge),
                  
                  // Music Grid
                  Expanded(
                    child: Consumer<MusicProvider>(
                      builder: (context, provider, child) {
                        if (provider.isLoading) {
                          return GridView.builder(
                            padding: EdgeInsets.zero,
                            gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
                              context,
                              desktop: 5,
                              tablet: 3,
                              mobile: 2,
                              childAspectRatio: _getChildAspectRatio(context),
                              crossAxisSpacing: AppSpacing.medium,
                              mainAxisSpacing: AppSpacing.medium,
                            ),
                            itemCount: 10,
                            itemBuilder: (context, index) {
                              return const LoadingShimmer(width: double.infinity, height: 250);
                            },
                          );
                        }

                        // Initialize filtered tracks on first load
                        if (_filteredTracks.isEmpty && provider.tracks.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _filterTracks();
                          });
                        }

                        final tracksToShow = _filteredTracks.isEmpty ? provider.tracks : _filteredTracks;

                        if (tracksToShow.isEmpty) {
                          return const EmptyState(
                            icon: Icons.music_note,
                            title: 'No Music Found',
                            message: 'Try adjusting your search or filters',
                          );
                        }

                        return GridView.builder(
                          padding: EdgeInsets.zero,
                          gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
                            context,
                            desktop: 5,
                            tablet: 3,
                            mobile: 2,
                            childAspectRatio: _getChildAspectRatio(context),
                            crossAxisSpacing: AppSpacing.medium,
                            mainAxisSpacing: AppSpacing.medium,
                          ),
                          itemCount: tracksToShow.length,
                          itemBuilder: (context, index) {
                            final track = tracksToShow[index];
                            return ContentCardWeb(
                              item: track,
                              onTap: () => _handleItemTap(track),
                              onPlay: () => _handlePlay(track),
                            );
                          },
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

