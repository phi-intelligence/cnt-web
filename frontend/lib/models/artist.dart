class Artist {
  final int id;
  final int userId;
  final String? artistName;
  final String? coverImage;
  final String? bio;
  final Map<String, dynamic>? socialLinks;
  final int followersCount;
  final int totalPlays;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool? isFollowing;

  Artist({
    required this.id,
    required this.userId,
    this.artistName,
    this.coverImage,
    this.bio,
    this.socialLinks,
    required this.followersCount,
    required this.totalPlays,
    required this.isVerified,
    required this.createdAt,
    this.updatedAt,
    this.isFollowing,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      artistName: json['artist_name'] as String?,
      coverImage: json['cover_image'] as String?,
      bio: json['bio'] as String?,
      socialLinks: json['social_links'] as Map<String, dynamic>?,
      followersCount: json['followers_count'] as int? ?? 0,
      totalPlays: json['total_plays'] as int? ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      isFollowing: json['is_following'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'artist_name': artistName,
      'cover_image': coverImage,
      'bio': bio,
      'social_links': socialLinks,
      'followers_count': followersCount,
      'total_plays': totalPlays,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_following': isFollowing,
    };
  }

  // Helper getters
  String get displayName => artistName ?? 'Unknown Artist';
  String? get instagram => socialLinks?['instagram'];
  String? get twitter => socialLinks?['twitter'];
  String? get youtube => socialLinks?['youtube'];
  String? get website => socialLinks?['website'];
}

class ArtistSummary {
  final int id;
  final int userId;
  final String? artistName;
  final String? coverImage;
  final int followersCount;

  ArtistSummary({
    required this.id,
    required this.userId,
    this.artistName,
    this.coverImage,
    required this.followersCount,
  });

  factory ArtistSummary.fromJson(Map<String, dynamic> json) {
    return ArtistSummary(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      artistName: json['artist_name'] as String?,
      coverImage: json['cover_image'] as String?,
      followersCount: json['followers_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'artist_name': artistName,
      'cover_image': coverImage,
      'followers_count': followersCount,
    };
  }

  String get displayName => artistName ?? 'Unknown Artist';
}

class ArtistFollower {
  final int id;
  final int userId;
  final String userName;
  final String? userAvatar;
  final DateTime createdAt;

  ArtistFollower({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.createdAt,
  });

  factory ArtistFollower.fromJson(Map<String, dynamic> json) {
    return ArtistFollower(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      userName: json['user_name'] as String,
      userAvatar: json['user_avatar'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

