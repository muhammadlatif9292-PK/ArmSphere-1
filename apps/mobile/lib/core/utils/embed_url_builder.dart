class EmbedUrlBuilder {
  /// Converts a standard video URL and its platform into an embeddable URL.
  static String? getEmbedUrl(String externalUrl, String platform) {
    final cleanUrl = externalUrl.trim();
    final upperPlatform = platform.toUpperCase();

    if (upperPlatform == 'YOUTUBE') {
      final videoId = extractYouTubeId(cleanUrl);
      if (videoId != null) {
        return 'https://www.youtube.com/embed/$videoId?autoplay=1';
      }
    } else if (upperPlatform == 'TIKTOK') {
      final videoId = extractTikTokVideoId(cleanUrl);
      if (videoId != null) {
        return 'https://www.tiktok.com/embed/v2/$videoId';
      }
      return cleanUrl;
    } else if (upperPlatform == 'FACEBOOK') {
      // Facebook's Embedded Video Player Plugin URL is robust and handles redirects/watches.
      return 'https://www.facebook.com/plugins/video.php?href=${Uri.encodeComponent(cleanUrl)}&show_text=0&autoplay=true';
    }

    return cleanUrl;
  }

  /// Extracts the 11-character video ID from various YouTube URL formats.
  static String? extractYouTubeId(String url) {
    final regExp = RegExp(
      r'^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=|shorts\/)([^#\&\?]*).*',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    if (match != null && match.groupCount >= 2) {
      final id = match.group(2);
      if (id != null && id.length == 11) {
        return id;
      }
    }
    return null;
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
