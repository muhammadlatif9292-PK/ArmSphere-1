import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/embed_url_builder.dart';
import '../../../core/widgets/armsphere_image.dart';
import '../../../core/widgets/crystal_toast.dart';

const String _kMobileChromeUserAgent =
    'Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36';

bool _isAllowedEmbedDomain(String url) {
  final lower = url.toLowerCase();
  if (lower.startsWith('about:') ||
      lower.startsWith('data:') ||
      lower.startsWith('blob:')) {
    return true;
  }
  if (lower.startsWith('intent://') ||
      lower.startsWith('vnd.youtube:') ||
      lower.startsWith('market://')) {
    return false;
  }
  return lower.contains('youtube-nocookie.com') ||
      lower.contains('youtube.com') ||
      lower.contains('youtu.be') ||
      lower.contains('googlevideo.com') ||
      lower.contains('googleapis.com') ||
      lower.contains('google.com') ||
      lower.contains('gstatic.com') ||
      lower.contains('doubleclick.net') ||
      lower.contains('ytimg.com') ||
      lower.contains('ggpht.com') ||
      lower.contains('armsphere.app') ||
      lower.contains('tiktok.com') ||
      lower.contains('tiktokcdn.com') ||
      lower.contains('tiktokv.com') ||
      lower.contains('byteoversea.com') ||
      lower.contains('ibytedtos.com') ||
      lower.contains('musical.ly') ||
      lower.contains('ttwstatic.com') ||
      lower.contains('facebook.com') ||
      lower.contains('facebook.net') ||
      lower.contains('fbcdn.net');
}

/// JavaScript & CSS injected whenever a YouTube mobile page (`m.youtube.com/watch`
/// or `m.youtube.com/shorts`) is loaded inside the WebView (either via automatic
/// fallback when a video restricts third-party embeds [Error 150/152-4] or when
/// the user clicks "Watch on YouTube").
///
/// It strips all mobile YouTube topbars, "Open App" prompts, related feeds, and
/// "TAP TO UNMUTE" stickers, locking the `<video>` element to 100% full-bleed
/// inside the ArmSphere player frame.
const String _kYouTubeCleanTheaterScript = r'''
(function() {
  try {
    var styleId = 'armsphere-clean-theater-style';
    if (!document.getElementById(styleId)) {
      var style = document.createElement('style');
      style.id = styleId;
      style.innerHTML = `
        html, body {
          margin: 0 !important;
          padding: 0 !important;
          width: 100vw !important;
          height: 100vh !important;
          overflow: hidden !important;
          background: #000000 !important;
        }
        header,
        ytm-mobile-topbar-renderer,
        .mobile-topbar-header,
        ytm-pivot-bar-renderer,
        ytm-single-column-watch-next-results-renderer,
        ytm-item-section-renderer,
        ytm-watch-metadata,
        ytm-slim-video-metadata-section-renderer,
        ytm-comment-section-renderer,
        ytm-EngagementPanelSectionListRenderer,
        ytm-companion-ad-renderer,
        ytm-promoted-sparkles-web-renderer,
        .watch-below-the-player,
        #below,
        #masthead-container,
        #related,
        #comments,
        .ytp-unmute,
        .ytp-unmute-inner,
        .ytp-UnmuteOverlay,
        .ytm-autonav-bar,
        .ytp-watermark,
        .ytp-chrome-top,
        .ytp-show-cards-title,
        .reel-player-header-renderer,
        .reel-player-overlay-actions,
        ytm-reel-player-overlay-renderer,
        [aria-label*="Open App"],
        [aria-label*="Open app"],
        a[href*="intent://"] {
          display: none !important;
          visibility: hidden !important;
          opacity: 0 !important;
          height: 0 !important;
          width: 0 !important;
          pointer-events: none !important;
        }
        #player-container-id,
        #player,
        #movie_player,
        .html5-video-player,
        .html5-video-container,
        ytm-reel-video-renderer,
        #shorts-player {
          position: fixed !important;
          top: 0 !important;
          left: 0 !important;
          right: 0 !important;
          bottom: 0 !important;
          width: 100vw !important;
          height: 100vh !important;
          max-width: 100vw !important;
          max-height: 100vh !important;
          margin: 0 !important;
          padding: 0 !important;
          z-index: 2147483646 !important;
          background: #000000 !important;
        }
        video,
        video.html5-main-video {
          position: fixed !important;
          top: 0 !important;
          left: 0 !important;
          width: 100vw !important;
          height: 100vh !important;
          object-fit: contain !important;
          background: #000000 !important;
        }
      `;
      (document.head || document.documentElement).appendChild(style);
    }

    function enforceVideoTheater() {
      var unmuteBtns = document.querySelectorAll('.ytp-unmute, button[aria-label*="Unmute"], button[aria-label*="unmute"]');
      for (var i = 0; i < unmuteBtns.length; i++) {
        try { unmuteBtns[i].style.display = 'none'; } catch (_) {}
      }
      var videos = document.getElementsByTagName('video');
      for (var j = 0; j < videos.length; j++) {
        var v = videos[j];
        try {
          if (v.muted) {
            v.muted = false;
            v.volume = 1.0;
          }
          if (v.paused && v.readyState >= 2) {
            v.play().catch(function(){});
          }
          if (v.videoWidth > 0 && v.videoHeight > 0 && window.ArmSphereVideoBridge) {
            var mode = v.videoHeight > v.videoWidth ? 'ORIENTATION:PORTRAIT' : 'ORIENTATION:LANDSCAPE';
            window.ArmSphereVideoBridge.postMessage(mode);
          }
        } catch (_) {}
      }
    }

    enforceVideoTheater();
    if (!window.__armSphereTheaterInterval) {
      window.__armSphereTheaterInterval = setInterval(enforceVideoTheater, 350);
    }
  } catch (_) {}
})();
''';

/// Builds a clean HTML5 player document.
/// For YouTube videos, uses the official YouTube IFrame Player API with
/// `baseUrl: 'https://armsphere.app'` (avoiding the spoofed `youtube.com`
/// origin that triggers `Error code: 152 - 4`) and automatically notifies
/// `ArmSphereVideoBridge.postMessage('FALLBACK_WATCH')` if the uploader
/// restricted third-party iframe embedding (`onError` codes 100/101/150/152).
String _buildResponsivePlayerHtml({
  required String rawEmbedUrl,
  required String rawUrl,
  required String platform,
}) {
  final ytId = EmbedUrlBuilder.extractYouTubeId(
    rawUrl.isNotEmpty ? rawUrl : rawEmbedUrl,
  );

  if (ytId != null && (platform.toUpperCase() == 'YOUTUBE' || rawEmbedUrl.contains('youtube'))) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <meta name="referrer" content="origin">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; background-color: #000000; }
    html, body { width: 100%; height: 100%; overflow: hidden; background-color: #000000; }
    #player-wrap { position: fixed; inset: 0; width: 100vw; height: 100vh; background-color: #000000; }
    iframe, #yt-player { width: 100% !important; height: 100% !important; border: 0; display: block; background-color: #000000; }
  </style>
</head>
<body>
  <div id="player-wrap">
    <div id="yt-player"></div>
  </div>
  <script>
    var tag = document.createElement('script');
    tag.src = "https://www.youtube.com/iframe_api";
    var firstScriptTag = document.getElementsByTagName('script')[0];
    firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

    var player;
    var fallbackTriggered = false;
    function triggerWatchFallback() {
      if (fallbackTriggered) return;
      fallbackTriggered = true;
      if (window.ArmSphereVideoBridge) {
        window.ArmSphereVideoBridge.postMessage('FALLBACK_WATCH');
      } else {
        window.location.replace('https://m.youtube.com/watch?v=$ytId&playsinline=1&autoplay=1');
      }
    }

    function onYouTubeIframeAPIReady() {
      try {
        player = new YT.Player('yt-player', {
          width: '100%',
          height: '100%',
          videoId: '$ytId',
          playerVars: {
            'autoplay': 1,
            'playsinline': 1,
            'rel': 0,
            'modestbranding': 1,
            'controls': 1,
            'fs': 1,
            'origin': 'https://armsphere.app',
            'widget_referrer': 'https://armsphere.app'
          },
          events: {
            'onReady': function(event) {
              try {
                event.target.unMute();
                event.target.setVolume(100);
                event.target.playVideo();
                if (window.ArmSphereVideoBridge) {
                  window.ArmSphereVideoBridge.postMessage('PLAYER_READY');
                }
              } catch (_) {}
            },
            'onError': function(event) {
              triggerWatchFallback();
            }
          }
        });
      } catch (e) {
        triggerWatchFallback();
      }
    }

    // Safety fallback if iframe_api script fails to initialize within 4.5s
    setTimeout(function() {
      if (!player && !fallbackTriggered) {
        triggerWatchFallback();
      }
    }, 4500);
  </script>
</body>
</html>
''';
  }

  final isTikTok = platform.toUpperCase() == 'TIKTOK' ||
      rawEmbedUrl.toLowerCase().contains('tiktok.com') ||
      rawUrl.toLowerCase().contains('tiktok.com');
  final tikTokId = EmbedUrlBuilder.extractTikTokVideoId(
    rawUrl.isNotEmpty ? rawUrl : rawEmbedUrl,
  );

  if (isTikTok) {
    final targetVideoUrl = rawUrl.isNotEmpty ? rawUrl : rawEmbedUrl;
    final safeTarget = targetVideoUrl
        .replaceAll('&', '&amp;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
    final dataAttr = tikTokId != null ? 'data-video-id="$tikTokId"' : '';
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <meta name="referrer" content="origin">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; background-color: #000000; }
    html, body { width: 100%; height: 100%; overflow: hidden; background-color: #000000; display: flex; align-items: center; justify-content: center; }
    .player-wrap { width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; background-color: #000000; }
    blockquote.tiktok-embed { max-width: 100% !important; min-width: 100% !important; margin: 0 auto !important; }
  </style>
</head>
<body>
  <div class="player-wrap">
    <blockquote class="tiktok-embed" cite="$safeTarget" $dataAttr>
      <section></section>
    </blockquote>
    <script async src="https://www.tiktok.com/embed.js"></script>
  </div>
</body>
</html>
''';
  }

  final safeUrl = rawEmbedUrl
      .trim()
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <meta name="referrer" content="strict-origin-when-cross-origin">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; background-color: #000000; }
    html, body { width: 100%; height: 100%; overflow: hidden; background-color: #000000; }
    .player-wrap { position: fixed; inset: 0; width: 100%; height: 100%; background-color: #000000; }
    iframe { width: 100%; height: 100%; border: 0; display: block; background-color: #000000; }
  </style>
</head>
<body>
  <div class="player-wrap">
    <iframe
      src="$safeUrl"
      frameborder="0"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
      allowfullscreen
      playsinline
      webkit-playsinline>
    </iframe>
  </div>
</body>
</html>
''';
}

void _configureAndroidGestureFreePlayback(WebViewController controller) {
  try {
    final dynamic platformController = controller.platform;
    platformController.setMediaPlaybackRequiresUserGesture(false);
  } catch (_) {
    // Gracefully ignore on non-Android platforms or mock test environments.
  }
}

/// Inline Combat Video Player Card — Plays YouTube (Streams & Shorts), TikTok,
/// and Facebook clips directly inside the Community Feed card with distinct,
/// dedicated layouts for **Shorts / Portrait (`9:16`)** vs **Widescreen (`16:9`)**.
class InlineCombatVideoPlayer extends StatefulWidget {
  final String postId;
  final String embedUrl;
  final String rawUrl;
  final String platform;
  final String caption;
  final String? thumbnailUrl;
  final String fallbackAsset;
  final ValueNotifier<String?> activePostIdNotifier;
  final bool isVerticalReel;
  final bool? isPortraitOverride;

  const InlineCombatVideoPlayer({
    super.key,
    required this.postId,
    required this.embedUrl,
    required this.rawUrl,
    required this.platform,
    required this.caption,
    required this.thumbnailUrl,
    required this.fallbackAsset,
    required this.activePostIdNotifier,
    this.isVerticalReel = false,
    this.isPortraitOverride,
  });

  @override
  State<InlineCombatVideoPlayer> createState() => _InlineCombatVideoPlayerState();
}

class _InlineCombatVideoPlayerState extends State<InlineCombatVideoPlayer> {
  WebViewController? _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _usingCleanTheaterWatchFallback = false;
  late bool _isPortrait;

  bool get _isActive =>
      widget.postId.isNotEmpty &&
      widget.activePostIdNotifier.value == widget.postId;

  @override
  void initState() {
    super.initState();
    _isPortrait = widget.isPortraitOverride ??
        EmbedUrlBuilder.isPortraitVideo(
          widget.rawUrl.isNotEmpty ? widget.rawUrl : widget.embedUrl,
          widget.platform,
          caption: widget.caption,
        );
    widget.activePostIdNotifier.addListener(_handleActivePostChanged);
    if (_isActive) {
      _ensureControllerInitialized();
    }
  }

  @override
  void didUpdateWidget(covariant InlineCombatVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activePostIdNotifier != widget.activePostIdNotifier) {
      oldWidget.activePostIdNotifier.removeListener(_handleActivePostChanged);
      widget.activePostIdNotifier.addListener(_handleActivePostChanged);
    }
    if (oldWidget.rawUrl != widget.rawUrl ||
        oldWidget.embedUrl != widget.embedUrl ||
        oldWidget.isPortraitOverride != widget.isPortraitOverride) {
      _isPortrait = widget.isPortraitOverride ??
          EmbedUrlBuilder.isPortraitVideo(
            widget.rawUrl.isNotEmpty ? widget.rawUrl : widget.embedUrl,
            widget.platform,
            caption: widget.caption,
          );
      if (_isActive) {
        _disposeWebView();
        _ensureControllerInitialized();
      }
    }
  }

  @override
  void dispose() {
    widget.activePostIdNotifier.removeListener(_handleActivePostChanged);
    _disposeWebView();
    super.dispose();
  }

  void _handleActivePostChanged() {
    if (!mounted) return;
    if (_isActive) {
      _ensureControllerInitialized();
      setState(() {});
    } else {
      if (_webViewController != null) {
        _disposeWebView();
        setState(() {});
      }
    }
  }

  void _disposeWebView() {
    try {
      _webViewController?.loadRequest(Uri.parse('about:blank'));
    } catch (_) {}
    _webViewController = null;
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    _usingCleanTheaterWatchFallback = false;
  }

  void _switchToCleanYouTubeTheaterWatch() {
    if (_usingCleanTheaterWatchFallback || _webViewController == null) return;
    final watchUrl = EmbedUrlBuilder.getYouTubeMobileWatchUrl(
      widget.rawUrl.isNotEmpty ? widget.rawUrl : widget.embedUrl,
    );
    if (watchUrl == null) return;
    _usingCleanTheaterWatchFallback = true;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    _webViewController!.loadRequest(Uri.parse(watchUrl));
  }

  void _handleBridgeMessage(JavaScriptMessage message) {
    final msg = message.message.trim();
    if (msg == 'FALLBACK_WATCH') {
      _switchToCleanYouTubeTheaterWatch();
    } else if (msg == 'PLAYER_READY') {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
      }
    } else if (msg == 'ORIENTATION:PORTRAIT') {
      if (mounted && !_isPortrait && widget.isPortraitOverride == null) {
        setState(() {
          _isPortrait = true;
        });
      }
    } else if (msg == 'ORIENTATION:LANDSCAPE') {
      if (mounted && _isPortrait && widget.isPortraitOverride == null) {
        // Keep explicit /shorts/ or TikTok URLs in portrait, otherwise adapt
        final explicitlyPortraitUrl = EmbedUrlBuilder.isPortraitVideo(
          widget.rawUrl,
          widget.platform,
          caption: widget.caption,
        );
        if (!explicitlyPortraitUrl) {
          setState(() {
            _isPortrait = false;
          });
        }
      }
    }
  }

  bool _isDirectYouTubeWatchOrShortsUrl(String url) {
    final lower = url.toLowerCase();
    return (lower.contains('youtube.com/watch') ||
            lower.contains('youtube.com/shorts') ||
            lower.contains('m.youtube.com')) &&
        !lower.contains('/embed/');
  }

  void _ensureControllerInitialized() {
    if (_webViewController != null) return;
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    _usingCleanTheaterWatchFallback = false;

    try {
      late final WebViewController controller;
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF04060B))
        ..setUserAgent(_kMobileChromeUserAgent)
        ..addJavaScriptChannel(
          'ArmSphereVideoBridge',
          onMessageReceived: _handleBridgeMessage,
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              if (_usingCleanTheaterWatchFallback) {
                controller.runJavaScript(_kYouTubeCleanTheaterScript).catchError((_) {});
              }
              if (progress > 80 && mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onPageStarted: (String url) {
              if (_isDirectYouTubeWatchOrShortsUrl(url)) {
                _usingCleanTheaterWatchFallback = true;
                controller.runJavaScript(_kYouTubeCleanTheaterScript).catchError((_) {});
              }
              if (mounted && url != 'about:blank') {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
              }
            },
            onPageFinished: (String url) {
              if (_usingCleanTheaterWatchFallback || _isDirectYouTubeWatchOrShortsUrl(url)) {
                controller.runJavaScript(_kYouTubeCleanTheaterScript).catchError((_) {});
              }
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              if (error.isForMainFrame == false) return;
              if (!_usingCleanTheaterWatchFallback &&
                  (widget.platform.toUpperCase() == 'YOUTUBE' ||
                      widget.embedUrl.contains('youtube'))) {
                _switchToCleanYouTubeTheaterWatch();
                return;
              }
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                  _errorMessage = error.description;
                });
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              final reqUrl = request.url;
              if (_isDirectYouTubeWatchOrShortsUrl(reqUrl)) {
                // User tapped "Watch on YouTube" or embed redirected — activate Clean Theater Mode!
                _usingCleanTheaterWatchFallback = true;
                Future.delayed(const Duration(milliseconds: 250), () {
                  controller.runJavaScript(_kYouTubeCleanTheaterScript).catchError((_) {});
                });
                return NavigationDecision.navigate;
              }
              if (_isAllowedEmbedDomain(reqUrl)) {
                return NavigationDecision.navigate;
              }
              return NavigationDecision.prevent;
            },
          ),
        );

      _configureAndroidGestureFreePlayback(controller);
      final isTikTok = widget.platform.toUpperCase() == 'TIKTOK' ||
          widget.embedUrl.toLowerCase().contains('tiktok.com') ||
          widget.rawUrl.toLowerCase().contains('tiktok.com');
      final tikTokTarget = EmbedUrlBuilder.getTikTokEmbedOrWatchUrl(
        widget.rawUrl,
        embedUrl: widget.embedUrl,
      );
      if (isTikTok && tikTokTarget != null) {
        controller.loadRequest(Uri.parse(tikTokTarget));
      } else {
        controller.loadHtmlString(
          _buildResponsivePlayerHtml(
            rawEmbedUrl: widget.embedUrl,
            rawUrl: widget.rawUrl,
            platform: widget.platform,
          ),
          baseUrl: 'https://armsphere.app',
        );
      }
      _webViewController = controller;
    } catch (e) {
      _hasError = true;
      _isLoading = false;
      _errorMessage = e.toString();
    }
  }

  void _activateInlinePlayback() {
    HapticFeedback.lightImpact();
    widget.activePostIdNotifier.value = widget.postId;
  }

  void _stopInlinePlayback() {
    HapticFeedback.selectionClick();
    if (widget.activePostIdNotifier.value == widget.postId) {
      widget.activePostIdNotifier.value = null;
    }
  }

  void _toggleOrientationMode() {
    HapticFeedback.selectionClick();
    setState(() {
      _isPortrait = !_isPortrait;
    });
  }

  void _retryPlayback() {
    HapticFeedback.lightImpact();
    setState(() {
      _disposeWebView();
      _ensureControllerInitialized();
    });
  }

  void _openFullScreenModal(BuildContext context) {
    HapticFeedback.lightImpact();
    _stopInlinePlayback();
    VideoPlayerModal.show(
      context,
      embedUrl: widget.embedUrl,
      rawUrl: widget.rawUrl,
      platform: widget.platform,
      caption: widget.caption,
      isPortrait: _isPortrait,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isVerticalReel) {
      return _buildVerticalReelContent(context);
    }
    return _buildFeedStageCardContent(context);
  }

  /// Renders either a **Portrait / Shorts Stage (`9:14` vertical showcase)**
  /// or a **Widescreen Broadcast Stage (`16:9` horizontal cinema)** so both
  /// vertical Shorts and landscape streams are 100% visible and tailored.
  Widget _buildFeedStageCardContent(BuildContext context) {
    final double stageAspectRatio = _isPortrait ? (9 / 13.5) : (16 / 9);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF04060B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isActive
                ? AppTheme.goldPrimary.withValues(alpha: 0.72)
                : (_isPortrait
                    ? const Color(0x59E23B3B)
                    : const Color(0x38FFFFFF)),
            width: _isActive ? 1.4 : 1.0,
          ),
        ),
        child: AspectRatio(
          aspectRatio: stageAspectRatio,
          child: _isActive
              ? _buildActiveWebViewStack(context)
              : _buildThumbnailPreviewStage(context),
        ),
      ),
    );
  }

  Widget _buildVerticalReelContent(BuildContext context) {
    if (_isActive) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF04060B),
        child: _buildActiveWebViewStack(context),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _activateInlinePlayback,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF060910),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: ArmSphereImage(
                imageUrl: widget.thumbnailUrl,
                fallbackAsset: widget.fallbackAsset,
                fit: BoxFit.cover,
                semanticLabel: widget.caption.isNotEmpty
                    ? 'Combat clip: ${widget.caption}'
                    : 'Combat video background',
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF070A11).withValues(alpha: 0.85),
                border: Border.all(color: AppTheme.goldPrimary, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.goldPrimary.withValues(alpha: 0.4),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: 44,
                  color: AppTheme.goldPrimary,
                ),
              ),
            ),
            const Positioned(
              bottom: 120,
              child: Text(
                'TAP TO PLAY INLINE COMBAT CLIP',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailPreviewStage(BuildContext context) {
    final platform = widget.platform.toUpperCase();
    final platformColor = _platformBadgeColor(platform);
    final formatBadgeText = _isPortrait ? '$platform SHORT • 9:16' : '$platform • 16:9 HD';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _activateInlinePlayback,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Layer: For Portrait Shorts, ambient blurred fill + sharp centered frame
          Positioned.fill(
            child: ArmSphereImage(
              imageUrl: widget.thumbnailUrl,
              fallbackAsset: widget.fallbackAsset,
              fit: BoxFit.cover,
              cacheWidth: 720,
              cacheHeight: _isPortrait ? 960 : 405,
              semanticLabel: widget.caption.isNotEmpty
                  ? 'Combat clip: ${widget.caption}'
                  : 'Combat video preview',
            ),
          ),
          if (_isPortrait)
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          if (_isPortrait)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ArmSphereImage(
                    imageUrl: widget.thumbnailUrl,
                    fallbackAsset: widget.fallbackAsset,
                    fit: BoxFit.cover,
                    cacheWidth: 720,
                    cacheHeight: 960,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
            ),

          // Subtle Top & Bottom Cinema Vignette
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.28, 0.72, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.62),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.82),
                  ],
                ),
              ),
            ),
          ),

          // Top-Left Platform + Orientation Badge
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
              decoration: BoxDecoration(
                color: const Color(0xCC04060B),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: platformColor.withValues(alpha: 0.75),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isPortrait
                        ? Icons.stay_current_portrait_rounded
                        : _platformBadgeIcon(platform),
                    size: 12,
                    color: platformColor,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    formatBadgeText,
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: platformColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top-Right Format Toggle (9:16 <-> 16:9) & Fullscreen Theater Button
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _toggleOrientationMode,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: const Color(0xCC04060B),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0x4DFFFFFF)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isPortrait ? Icons.crop_portrait : Icons.crop_16_9,
                          size: 12,
                          color: AppTheme.goldPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isPortrait ? '9:16' : '16:9',
                          style: const TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _openFullScreenModal(context),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xCC04060B),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0x4DFFFFFF)),
                    ),
                    child: const Icon(
                      Icons.fullscreen_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tactical Center Play Medallion
          Container(
            width: _isPortrait ? 62 : 56,
            height: _isPortrait ? 62 : 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xB304060B),
              border: Border.all(color: AppTheme.goldPrimary, width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldPrimary.withValues(alpha: 0.32),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.play_arrow_rounded,
                size: _isPortrait ? 38 : 34,
                color: AppTheme.goldPrimary,
              ),
            ),
          ),

          // Bottom Video Telemetry Scrim Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_circle_outline_rounded,
                        size: 13,
                        color: AppTheme.goldPrimary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isPortrait
                            ? 'TAP TO PLAY PORTRAIT SHORT'
                            : 'TAP TO PLAY WIDESCREEN STREAM',
                        style: const TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0x9904060B),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _isPortrait
                            ? const Color(0x80D4AF37)
                            : const Color(0x6638BDF8),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      _isPortrait ? 'VERTICAL 9:16' : '1080P HD',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: _isPortrait ? AppTheme.goldPrimary : AppTheme.info,
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

  Widget _buildActiveWebViewStack(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (!_hasError && _webViewController != null)
          WebViewWidget(controller: _webViewController!),

        if (_isLoading && !_hasError)
          Container(
            color: const Color(0xE604060B),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.goldPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'LOADING ${widget.platform.toUpperCase()} ${_isPortrait ? "SHORT" : "STREAM"}...',
                    style: const TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (_hasError)
          Container(
            color: const Color(0xF204060B),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppTheme.error,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Video Stream Interrupted',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _errorMessage.isNotEmpty
                          ? _errorMessage
                          : 'Check your connection or retry playback.',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _retryPlayback,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.goldPrimary,
                        side: const BorderSide(color: Color(0x80D4AF37)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 14),
                      label: const Text(
                        'Retry Playback',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Top-Right Inline Player Controls: Orientation Toggle, Fullscreen & Close/Stop
        Positioned(
          top: widget.isVerticalReel ? 88 : 8,
          right: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.isVerticalReel) ...[
                Material(
                  color: const Color(0xCC04060B),
                  borderRadius: BorderRadius.circular(6),
                  child: InkWell(
                    onTap: _toggleOrientationMode,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0x4DFFFFFF)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isPortrait ? Icons.crop_portrait : Icons.crop_16_9,
                            size: 13,
                            color: AppTheme.goldPrimary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _isPortrait ? '9:16' : '16:9',
                            style: const TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Material(
                color: const Color(0xCC04060B),
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  onTap: () => _openFullScreenModal(context),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0x4DFFFFFF)),
                    ),
                    child: const Icon(
                      Icons.fullscreen_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Material(
                color: const Color(0xCC04060B),
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  onTap: _stopInlinePlayback,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0x66D4AF37)),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppTheme.goldPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _platformBadgeColor(String platform) {
    switch (platform) {
      case 'YOUTUBE':
        return const Color(0xFFEF4444);
      case 'TIKTOK':
        return const Color(0xFF38BDF8);
      case 'FACEBOOK':
        return const Color(0xFF3B82F6);
      default:
        return AppTheme.goldPrimary;
    }
  }

  IconData _platformBadgeIcon(String platform) {
    switch (platform) {
      case 'YOUTUBE':
        return Icons.play_arrow_rounded;
      case 'TIKTOK':
        return Icons.music_note_rounded;
      case 'FACEBOOK':
        return Icons.public_rounded;
      default:
        return Icons.videocam_rounded;
    }
  }
}

class VideoPlayerModal extends StatefulWidget {
  final String embedUrl;
  final String? rawUrl;
  final String platform;
  final String? caption;
  final bool? isPortrait;

  const VideoPlayerModal({
    super.key,
    required this.embedUrl,
    this.rawUrl,
    required this.platform,
    this.caption,
    this.isPortrait,
  });

  /// Shows the modal in a clean, dark fullscreen/bottom-sheet overlay.
  /// Supports both `(embedUrl, rawUrl, platform, caption)` and convenience
  /// `(videoUrl, title)` parameters.
  static void show(
    BuildContext context, {
    String? embedUrl,
    String? rawUrl,
    String? videoUrl,
    String platform = 'YOUTUBE',
    String? caption,
    String? title,
    bool? isPortrait,
  }) {
    final effectiveRawUrl = rawUrl ?? videoUrl ?? embedUrl ?? '';
    final effectivePlatform = platform.isNotEmpty
        ? platform
        : (effectiveRawUrl.toLowerCase().contains('tiktok')
            ? 'TIKTOK'
            : (effectiveRawUrl.toLowerCase().contains('facebook') ||
                    effectiveRawUrl.toLowerCase().contains('fb.watch')
                ? 'FACEBOOK'
                : 'YOUTUBE'));
    final resolvedEmbedUrl = embedUrl ??
        EmbedUrlBuilder.getEmbedUrl(effectiveRawUrl, effectivePlatform) ??
        effectiveRawUrl;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VideoPlayerModal(
        embedUrl: resolvedEmbedUrl,
        rawUrl: effectiveRawUrl,
        platform: effectivePlatform,
        caption: caption ?? title,
        isPortrait: isPortrait,
      ),
    );
  }

  @override
  State<VideoPlayerModal> createState() => _VideoPlayerModalState();
}

class _VideoPlayerModalState extends State<VideoPlayerModal> {
  late final WebViewController _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _usingCleanTheaterWatchFallback = false;
  late bool _isPortrait;

  @override
  void initState() {
    super.initState();
    _isPortrait = widget.isPortrait ??
        EmbedUrlBuilder.isPortraitVideo(
          (widget.rawUrl != null && widget.rawUrl!.isNotEmpty)
              ? widget.rawUrl!
              : widget.embedUrl,
          widget.platform,
          caption: widget.caption,
        );
    _initController();
  }

  bool _isDirectYouTubeWatchOrShortsUrl(String url) {
    final lower = url.toLowerCase();
    return (lower.contains('youtube.com/watch') ||
            lower.contains('youtube.com/shorts') ||
            lower.contains('m.youtube.com')) &&
        !lower.contains('/embed/');
  }

  void _switchToCleanYouTubeTheaterWatch() {
    if (_usingCleanTheaterWatchFallback) return;
    final watchUrl = EmbedUrlBuilder.getYouTubeMobileWatchUrl(
      (widget.rawUrl != null && widget.rawUrl!.isNotEmpty)
          ? widget.rawUrl!
          : widget.embedUrl,
    );
    if (watchUrl == null) return;
    _usingCleanTheaterWatchFallback = true;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    _webViewController.loadRequest(Uri.parse(watchUrl));
  }

  void _handleBridgeMessage(JavaScriptMessage message) {
    final msg = message.message.trim();
    if (msg == 'FALLBACK_WATCH') {
      _switchToCleanYouTubeTheaterWatch();
    } else if (msg == 'PLAYER_READY') {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
      }
    } else if (msg == 'ORIENTATION:PORTRAIT') {
      if (mounted && !_isPortrait && widget.isPortrait == null) {
        setState(() => _isPortrait = true);
      }
    }
  }

  void _initController() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF04060B))
      ..setUserAgent(_kMobileChromeUserAgent)
      ..addJavaScriptChannel(
        'ArmSphereVideoBridge',
        onMessageReceived: _handleBridgeMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (_usingCleanTheaterWatchFallback) {
              _webViewController
                  .runJavaScript(_kYouTubeCleanTheaterScript)
                  .catchError((_) {});
            }
            if (progress > 85 && mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onPageStarted: (String url) {
            if (_isDirectYouTubeWatchOrShortsUrl(url)) {
              _usingCleanTheaterWatchFallback = true;
              _webViewController
                  .runJavaScript(_kYouTubeCleanTheaterScript)
                  .catchError((_) {});
            }
            if (mounted && url != 'about:blank') {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (String url) {
            if (_usingCleanTheaterWatchFallback || _isDirectYouTubeWatchOrShortsUrl(url)) {
              _webViewController
                  .runJavaScript(_kYouTubeCleanTheaterScript)
                  .catchError((_) {});
            }
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (error.isForMainFrame == false) return;
            if (!_usingCleanTheaterWatchFallback &&
                (widget.platform.toUpperCase() == 'YOUTUBE' ||
                    widget.embedUrl.contains('youtube'))) {
              _switchToCleanYouTubeTheaterWatch();
              return;
            }
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage = error.description;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final reqUrl = request.url;
            if (_isDirectYouTubeWatchOrShortsUrl(reqUrl)) {
              _usingCleanTheaterWatchFallback = true;
              Future.delayed(const Duration(milliseconds: 250), () {
                _webViewController
                    .runJavaScript(_kYouTubeCleanTheaterScript)
                    .catchError((_) {});
              });
              return NavigationDecision.navigate;
            }
            if (_isAllowedEmbedDomain(reqUrl)) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      );

    _configureAndroidGestureFreePlayback(_webViewController);
    final isTikTok = widget.platform.toUpperCase() == 'TIKTOK' ||
        widget.embedUrl.toLowerCase().contains('tiktok.com') ||
        (widget.rawUrl ?? '').toLowerCase().contains('tiktok.com');
    final tikTokTarget = EmbedUrlBuilder.getTikTokEmbedOrWatchUrl(
      widget.rawUrl,
      embedUrl: widget.embedUrl,
    );
    if (isTikTok && tikTokTarget != null) {
      _webViewController.loadRequest(Uri.parse(tikTokTarget));
    } else {
      _webViewController.loadHtmlString(
        _buildResponsivePlayerHtml(
          rawEmbedUrl: widget.embedUrl,
          rawUrl: widget.rawUrl ?? '',
          platform: widget.platform,
        ),
        baseUrl: 'https://armsphere.app',
      );
    }
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
      _usingCleanTheaterWatchFallback = false;
    });
    final isTikTok = widget.platform.toUpperCase() == 'TIKTOK' ||
        widget.embedUrl.toLowerCase().contains('tiktok.com') ||
        (widget.rawUrl ?? '').toLowerCase().contains('tiktok.com');
    final tikTokTarget = EmbedUrlBuilder.getTikTokEmbedOrWatchUrl(
      widget.rawUrl,
      embedUrl: widget.embedUrl,
    );
    if (isTikTok && tikTokTarget != null) {
      _webViewController.loadRequest(Uri.parse(tikTokTarget));
    } else {
      _webViewController.loadHtmlString(
        _buildResponsivePlayerHtml(
          rawEmbedUrl: widget.embedUrl,
          rawUrl: widget.rawUrl ?? '',
          platform: widget.platform,
        ),
        baseUrl: 'https://armsphere.app',
      );
    }
  }

  void _copyShareLink(BuildContext context) {
    final targetLink =
        (widget.rawUrl != null && widget.rawUrl!.isNotEmpty) ? widget.rawUrl! : widget.embedUrl;
    Clipboard.setData(ClipboardData(text: targetLink));
    ScaffoldMessenger.of(context).showSnackBar(
      CrystalSnackBar(
        content: const Text('Direct video link copied to clipboard'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.elevatedSurface,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxModalHeight = mediaQuery.size.height * 0.88;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxModalHeight),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0B0F18),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
          ),
          border: Border.all(
            color: AppTheme.goldPrimary.withValues(alpha: 0.35),
          ),
        ),
        padding: EdgeInsets.only(
          top: 12,
          left: 16,
          right: 16,
          bottom: mediaQuery.viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Header: Platform title, Orientation Switch & Close button
              Row(
                children: [
                  Icon(
                    _isPortrait
                        ? Icons.stay_current_portrait_rounded
                        : Icons.play_circle_filled_rounded,
                    color: AppTheme.goldPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isPortrait
                          ? '${widget.platform.toUpperCase()} SHORT • 9:16 THEATER'
                          : '${widget.platform.toUpperCase()} STREAM • 16:9 THEATER',
                      style: const TextStyle(
                        fontFamily: 'Space Grotesk',
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _isPortrait = !_isPortrait),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x4DFFFFFF)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isPortrait ? Icons.crop_portrait : Icons.crop_16_9,
                            size: 13,
                            color: AppTheme.goldPrimary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isPortrait ? '9:16' : '16:9',
                            style: const TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: AppTheme.goldPrimary, size: 19),
                    tooltip: 'Share video link',
                    onPressed: () => _copyShareLink(context),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppTheme.textPrimary.withValues(alpha: 0.8)),
                    tooltip: 'Close video',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Adaptive Player Container (Portrait 9:14 vs Landscape 16:9)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  color: Colors.black,
                  constraints: BoxConstraints(
                    maxHeight: _isPortrait ? mediaQuery.size.height * 0.64 : mediaQuery.size.height * 0.42,
                  ),
                  child: AspectRatio(
                    aspectRatio: _isPortrait ? (9 / 14) : (16 / 9),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (!_hasError)
                          WebViewWidget(controller: _webViewController),

                        if (_isLoading)
                          Container(
                            color: const Color(0xE604060B),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(color: AppTheme.goldPrimary),
                                  const SizedBox(height: 12),
                                  Text(
                                    'INITIALIZING ${_isPortrait ? "PORTRAIT SHORT" : "HD STREAM"}...',
                                    style: const TextStyle(
                                      fontFamily: 'Space Grotesk',
                                      color: AppTheme.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        if (_hasError)
                          Container(
                            color: const Color(0xF204060B),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    widget.platform.toUpperCase() == 'TIKTOK'
                                        ? Icons.movie_outlined
                                        : Icons.error_outline_rounded,
                                    color: AppTheme.goldPrimary,
                                    size: 42,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    widget.platform.toUpperCase() == 'TIKTOK'
                                        ? 'TikTok Stream Protected'
                                        : 'Stream Temporarily Unavailable',
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _errorMessage.isNotEmpty
                                        ? _errorMessage
                                        : 'Video is protected or connection interrupted. Use the direct link to view.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontBody,
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: _retry,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.goldPrimary,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        icon: const Icon(Icons.refresh_rounded, size: 16),
                                        label: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700)),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () => _copyShareLink(context),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.goldLight,
                                          side: const BorderSide(color: Color(0x73D4AF37)),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        icon: const Icon(Icons.copy_rounded, size: 16),
                                        label: const Text('Copy Link', style: TextStyle(fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              if (widget.caption != null && widget.caption!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  widget.caption!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.textPrimary.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
