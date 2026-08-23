/**
 * Extracts the 11-character video ID from various YouTube URL formats.
 */
export function extractYouTubeId(url: string): string | null {
  const regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=|shorts\/)([^#\&\?]*).*/i;
  const match = url.match(regExp);
  if (match && match[2] && match[2].length === 11) {
    return match[2];
  }
  return null;
}

/**
 * Extracts the numeric video ID from TikTok URL formats.
 */
export function extractTikTokVideoId(url: string): string | null {
  const regExp = /\/video\/(\d+)/i;
  const match = url.match(regExp);
  if (match && match[1]) {
    return match[1];
  }
  const regExpV = /\/v\/(\d+)/i;
  const matchV = url.match(regExpV);
  if (matchV && matchV[1]) {
    return matchV[1];
  }
  return null;
}

/**
 * Converts a stored externalUrl + platform into a proper embeddable URL.
 */
export function getEmbedUrl(externalUrl: string, platform: string): string | null {
  const cleanUrl = externalUrl.trim();
  const upperPlatform = platform.toUpperCase();

  if (upperPlatform === 'YOUTUBE') {
    const videoId = extractYouTubeId(cleanUrl);
    if (videoId) {
      return `https://www.youtube.com/embed/${videoId}?autoplay=0`;
    }
  } else if (upperPlatform === 'TIKTOK') {
    const videoId = extractTikTokVideoId(cleanUrl);
    if (videoId) {
      return `https://www.tiktok.com/embed/v2/${videoId}`;
    }
  } else if (upperPlatform === 'FACEBOOK') {
    return `https://www.facebook.com/plugins/video.php?href=${encodeURIComponent(cleanUrl)}&show_text=0&autoplay=false`;
  }

  return null;
}
