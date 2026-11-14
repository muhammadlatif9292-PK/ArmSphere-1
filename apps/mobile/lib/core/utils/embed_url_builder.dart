class EmbedUrlBuilder {
  /// Converts a standard video URL and its platform into an embeddable URL.
  static String? getEmbedUrl(String externalUrl, String platform) {
    final cleanUrl = externalUrl.trim();
    if (cleanUrl.isEmpty) return null;
    final upperPlatform = platform.toUpperCase();

    if (upperPlatform == 'YOUTUBE' ||
        cleanUrl.toLowerCase().contains('youtube.com') ||
        cleanUrl.toLowerCase().contains('youtu.be')) {
      final videoId = extractYouTubeId(cleanUrl);
      if (videoId != null) {
        return 'https://www.youtube.com/embed/$videoId?autoplay=1&playsinline=1&enablejsapi=1&rel=0&modestbranding=1';
      }
    } else if (upperPlatform == 'TIKTOK' || cleanUrl.toLowerCase().contains('tiktok.com')) {
      final videoId = extractTikTokVideoId(cleanUrl);
      if (videoId != null) {
        return 'https://www.tiktok.com/embed/v2/$videoId';
      }
      return cleanUrl;
    } else if (upperPlatform == 'FACEBOOK' ||
        cleanUrl.toLowerCase().contains('facebook.com') ||
        cleanUrl.toLowerCase().contains('fb.watch')) {
      return 'https://www.facebook.com/plugins/video.php?href=${Uri.encodeComponent(cleanUrl)}&show_text=0&autoplay=true';
    }

    return cleanUrl;
  }

  /// Detects whether a video URL/post is a vertical Short / Portrait clip (9:16)
  /// vs a standard widescreen landscape video (16:9).
  static bool isPortraitVideo(
    String externalUrl,
    String platform, {
    String? caption,
  }) {
    final lowerUrl = externalUrl.trim().toLowerCase();
    final upperPlatform = platform.trim().toUpperCase();
    final lowerCaption = (caption ?? '').toLowerCase();

    if (upperPlatform == 'TIKTOK') return true;
    if (lowerUrl.contains('/shorts/') ||
        lowerUrl.contains('youtube.com/shorts') ||
        lowerUrl.contains('youtu.be/shorts') ||
        lowerUrl.contains('tiktok.com') ||
        lowerUrl.contains('/reel/') ||
        lowerUrl.contains('/reels/') ||
        lowerUrl.contains('format=portrait') ||
        lowerUrl.contains('orientation=portrait')) {
      return true;
    }
    if (lowerCaption.contains('#shorts') ||
        lowerCaption.contains('#short') ||
        lowerCaption.contains('#reels') ||
        lowerCaption.contains('#tiktok')) {
      return true;
    }
    return false;
  }

  /// Extracts the 11-character video ID from various YouTube URL formats
  /// (including watch?v=, youtu.be/, shorts/, live/, and embed/).
  static String? extractYouTubeId(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;

    final regExp = RegExp(
      r'^.*(youtu\.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=|shorts\/|live\/)([^#\&\?\/]*).*',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(trimmed);
    if (match != null && match.groupCount >= 2) {
      final id = match.group(2);
      if (id != null && id.length == 11) {
        return id;
      }
    }
    return null;
  }

  /// Builds a clean mobile watch URL for YouTube fallback theater mode.
  static String? getYouTubeMobileWatchUrl(String urlOrEmbed) {
    final videoId = extractYouTubeId(urlOrEmbed);
    if (videoId == null) return null;
    return 'https://m.youtube.com/watch?v=$videoId&playsinline=1&autoplay=1';
  }

  /// Extracts the numeric video ID from TikTok URL formats.
  static String? extractTikTokVideoId(String url) {
    final regExp = RegExp(r'\/video\/(\d+)', caseSensitive: false);
    final match = regExp.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    final regExpV = RegExp(r'\/v\/(\d+)', caseSensitive: false);
    final matchV = regExpV.firstMatch(url);
    if (matchV != null && matchV.groupCount >= 1) {
      return matchV.group(1);
    }
    return null;
  }
}
