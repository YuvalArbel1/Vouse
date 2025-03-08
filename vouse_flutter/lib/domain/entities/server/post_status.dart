// lib/domain/entities/server/post_status.dart

/// Status of a post on the server.
///
/// Posts go through a lifecycle from draft to published (or failed).
enum PostStatus {
  /// Created locally, not yet sent to server
  draft,

  /// Scheduled for publication at a future time
  scheduled,

  /// Currently being published to Twitter
  publishing,

  /// Successfully published to Twitter
  published,

  /// Failed to publish to Twitter
  failed
}

/// Extension to get a readable display string for each status
extension PostStatusDisplay on PostStatus {
  String get displayName {
    switch (this) {
      case PostStatus.draft:
        return 'Draft';
      case PostStatus.scheduled:
        return 'Scheduled';
      case PostStatus.publishing:
        return 'Publishing';
      case PostStatus.published:
        return 'Published';
      case PostStatus.failed:
        return 'Failed';
    }
  }
}