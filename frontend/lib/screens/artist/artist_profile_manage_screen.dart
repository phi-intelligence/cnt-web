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

class ArtistProfileManageScreen extends StatefulWidget {
  const ArtistProfileManageScreen({super.key});

  @override
  State<ArtistProfileManageScreen> createState() => _ArtistProfileManageScreenState();
}

class _ArtistProfileManageScreenState extends State<ArtistProfileManageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _artistNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _instagramController = TextEditingController();
  final _twitterController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _websiteController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSaving = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  @override
  void initState() {
    super.initState();
    _loadArtistData();
  }

  Future<void> _loadArtistData() async {
    setState(() {
      _isLoading = true;
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
    }

    setState(() {
      _isLoading = false;
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
        context.pop();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Artist Profile'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: CircularProgressIndicator(),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: Text('Save', style: TextStyle(color: AppColors.accentMain)),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.large),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cover image section
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.medium),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cover Image', style: AppTypography.heading2),
                            SizedBox(height: AppSpacing.small),
                            if (_selectedImageBytes != null)
                              Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                                    child: Image.memory(
                                      _selectedImageBytes!,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white),
                                    onPressed: () {
                                      setState(() {
                                        _selectedImageBytes = null;
                                        _selectedImageName = null;
                                      });
                                    },
                                  ),
                                ],
                              )
                            else
                              Consumer<ArtistProvider>(
                                builder: (context, provider, _) {
                                  final artist = provider.myArtist;
                                  if (artist?.coverImage != null) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                                      child: Image.network(
                                        artist!.coverImage!,
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          height: 200,
                                          color: AppColors.warmBrown.withOpacity(0.3),
                                          child: const Center(child: Icon(Icons.image, size: 64)),
                                        ),
                                      ),
                                    );
                                  }
                                  return Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: AppColors.warmBrown.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                                    ),
                                    child: Center(child: Icon(Icons.image, size: 64)),
                                  );
                                },
                              ),
                            SizedBox(height: AppSpacing.small),
                            ElevatedButton.icon(
                              onPressed: _pickCoverImage,
                              icon: const Icon(Icons.upload),
                              label: const Text('Upload Cover Image'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.large),

                    // Artist name
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.medium),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Artist Name', style: AppTypography.heading2),
                            SizedBox(height: AppSpacing.small),
                            TextFormField(
                              controller: _artistNameController,
                              decoration: const InputDecoration(
                                hintText: 'Enter your artist name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Artist name is required';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.large),

                    // Bio
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.medium),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bio', style: AppTypography.heading2),
                            SizedBox(height: AppSpacing.small),
                            TextFormField(
                              controller: _bioController,
                              decoration: const InputDecoration(
                                hintText: 'Tell your fans about yourself...',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.large),

                    // Social links
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.medium),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Social Links', style: AppTypography.heading2),
                            SizedBox(height: AppSpacing.small),
                            TextFormField(
                              controller: _instagramController,
                              decoration: const InputDecoration(
                                labelText: 'Instagram',
                                hintText: 'https://instagram.com/username',
                                prefixIcon: Icon(Icons.photo_camera),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: AppSpacing.small),
                            TextFormField(
                              controller: _twitterController,
                              decoration: InputDecoration(
                                labelText: 'Twitter/X',
                                hintText: 'https://twitter.com/username',
                                prefixIcon: Icon(Icons.chat),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: AppSpacing.small),
                            TextFormField(
                              controller: _youtubeController,
                              decoration: InputDecoration(
                                labelText: 'YouTube',
                                hintText: 'https://youtube.com/@username',
                                prefixIcon: Icon(Icons.play_circle_outline),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: AppSpacing.small),
                            TextFormField(
                              controller: _websiteController,
                              decoration: const InputDecoration(
                                labelText: 'Website',
                                hintText: 'https://yourwebsite.com',
                                prefixIcon: Icon(Icons.language),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.large),

                    // Save button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentMain,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Save Profile', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

