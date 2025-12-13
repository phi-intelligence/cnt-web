/// Content Draft model for the CNT Media Platform
/// Supports video_podcast, audio_podcast, community_post, quote_post drafts

enum DraftType {
  videoPodcast,
  audioPodcast,
  communityPost,
  quotePost,
}

extension DraftTypeExtension on DraftType {
  String get value {
    switch (this) {
      case DraftType.videoPodcast:
        return 'video_podcast';
      case DraftType.audioPodcast:
        return 'audio_podcast';
      case DraftType.communityPost:
        return 'community_post';
      case DraftType.quotePost:
        return 'quote_post';
    }
  }

  static DraftType fromString(String value) {
    switch (value) {
      case 'video_podcast':
        return DraftType.videoPodcast;
      case 'audio_podcast':
        return DraftType.audioPodcast;
      case 'community_post':
        return DraftType.communityPost;
      case 'quote_post':
        return DraftType.quotePost;
      default:
        return DraftType.videoPodcast;
    }
  }

  String get displayName {
    switch (this) {
      case DraftType.videoPodcast:
        return 'Video Podcast';
      case DraftType.audioPodcast:
        return 'Audio Podcast';
      case DraftType.communityPost:
        return 'Community Post';
      case DraftType.quotePost:
        return 'Quote';
    }
  }

  String get icon {
    switch (this) {
      case DraftType.videoPodcast:
        return 'videocam';
      case DraftType.audioPodcast:
        return 'mic';
      case DraftType.communityPost:
        return 'article';
      case DraftType.quotePost:
        return 'format_quote';
    }
  }
}

enum DraftStatus {
  editing,
  ready,
}

extension DraftStatusExtension on DraftStatus {
  String get value {
    switch (this) {
      case DraftStatus.editing:
        return 'editing';
      case DraftStatus.ready:
        return 'ready';
    }
  }

  static DraftStatus fromString(String value) {
    switch (value) {
      case 'editing':
        return DraftStatus.editing;
      case 'ready':
        return DraftStatus.ready;
      default:
        return DraftStatus.editing;
    }
  }
}

class ContentDraft {
  final int id;
  final int userId;
  final DraftType draftType;
  final String? title;
  final String? description;
  
  // Media URLs
  final String? originalMediaUrl;
  final String? editedMediaUrl;
  final String? thumbnailUrl;
  
  // Content fields (for posts/quotes)
  final String? content;
  final String? category;
  
  // Editing state (for video/audio editors)
  final Map<String, dynamic>? editingState;
  final int? duration;
  
  // Status
  final DraftStatus status;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime? updatedAt;

  ContentDraft({
    required this.id,
    required this.userId,
    required this.draftType,
    this.title,
    this.description,
    this.originalMediaUrl,
    this.editedMediaUrl,
    this.thumbnailUrl,
    this.content,
    this.category,
    this.editingState,
    this.duration,
    this.status = DraftStatus.editing,
    required this.createdAt,
    this.updatedAt,
  });

  factory ContentDraft.fromJson(Map<String, dynamic> json) {
    return ContentDraft(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      draftType: DraftTypeExtension.fromString(json['draft_type'] as String),
      title: json['title'] as String?,
      description: json['description'] as String?,
      originalMediaUrl: json['original_media_url'] as String?,
      editedMediaUrl: json['edited_media_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      content: json['content'] as String?,
      category: json['category'] as String?,
      editingState: json['editing_state'] as Map<String, dynamic>?,
      duration: json['duration'] as int?,
      status: DraftStatusExtension.fromString(json['status'] as String? ?? 'editing'),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'draft_type': draftType.value,
      'title': title,
      'description': description,
      'original_media_url': originalMediaUrl,
      'edited_media_url': editedMediaUrl,
      'thumbnail_url': thumbnailUrl,
      'content': content,
      'category': category,
      'editing_state': editingState,
      'duration': duration,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ContentDraft copyWith({
    int? id,
    int? userId,
    DraftType? draftType,
    String? title,
    String? description,
    String? originalMediaUrl,
    String? editedMediaUrl,
    String? thumbnailUrl,
    String? content,
    String? category,
    Map<String, dynamic>? editingState,
    int? duration,
    DraftStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContentDraft(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      draftType: draftType ?? this.draftType,
      title: title ?? this.title,
      description: description ?? this.description,
      originalMediaUrl: originalMediaUrl ?? this.originalMediaUrl,
      editedMediaUrl: editedMediaUrl ?? this.editedMediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      content: content ?? this.content,
      category: category ?? this.category,
      editingState: editingState ?? this.editingState,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get relative time string (e.g., "2 hours ago")
  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(updatedAt ?? createdAt);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${(diff.inDays / 30).floor()} months ago';
  }

  /// Get preview text for display
  String get previewText {
    if (title != null && title!.isNotEmpty) return title!;
    if (content != null && content!.isNotEmpty) {
      return content!.length > 50 ? '${content!.substring(0, 50)}...' : content!;
    }
    return 'Untitled ${draftType.displayName}';
  }
}

/// Create draft request model
class ContentDraftCreate {
  final DraftType draftType;
  final String? title;
  final String? description;
  final String? originalMediaUrl;
  final String? editedMediaUrl;
  final String? thumbnailUrl;
  final String? content;
  final String? category;
  final Map<String, dynamic>? editingState;
  final int? duration;
  final DraftStatus status;

  ContentDraftCreate({
    required this.draftType,
    this.title,
    this.description,
    this.originalMediaUrl,
    this.editedMediaUrl,
    this.thumbnailUrl,
    this.content,
    this.category,
    this.editingState,
    this.duration,
    this.status = DraftStatus.editing,
  });

  Map<String, dynamic> toJson() {
    return {
      'draft_type': draftType.value,
      'title': title,
      'description': description,
      'original_media_url': originalMediaUrl,
      'edited_media_url': editedMediaUrl,
      'thumbnail_url': thumbnailUrl,
      'content': content,
      'category': category,
      'editing_state': editingState,
      'duration': duration,
      'status': status.value,
    }..removeWhere((k, v) => v == null);
  }
}

/// Update draft request model
class ContentDraftUpdate {
  final String? title;
  final String? description;
  final String? originalMediaUrl;
  final String? editedMediaUrl;
  final String? thumbnailUrl;
  final String? content;
  final String? category;
  final Map<String, dynamic>? editingState;
  final int? duration;
  final DraftStatus? status;

  ContentDraftUpdate({
    this.title,
    this.description,
    this.originalMediaUrl,
    this.editedMediaUrl,
    this.thumbnailUrl,
    this.content,
    this.category,
    this.editingState,
    this.duration,
    this.status,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (originalMediaUrl != null) data['original_media_url'] = originalMediaUrl;
    if (editedMediaUrl != null) data['edited_media_url'] = editedMediaUrl;
    if (thumbnailUrl != null) data['thumbnail_url'] = thumbnailUrl;
    if (content != null) data['content'] = content;
    if (category != null) data['category'] = category;
    if (editingState != null) data['editing_state'] = editingState;
    if (duration != null) data['duration'] = duration;
    if (status != null) data['status'] = status!.value;
    return data;
  }
}

