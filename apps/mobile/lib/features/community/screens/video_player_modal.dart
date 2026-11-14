import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/armsphere_image.dart';
import '../../../core/widgets/crystal_toast.dart';

const String _kMobileChromeUserAgent =
    'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';

const Map<String, String> _kEmbedRequestHeaders = {
  'Referer': 'https://armsphere.app',
  'Origin': 'https://armsphere.app',
};

bool _isAllowedEmbedDomain(String url) {
  final lower = url.toLowerCase();
  if (lower.startsWith('about:') || lower.startsWith('data:') || lower.startsWith('blob:')) {
    return true;
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
      lower.contains('tiktok.com') ||
      lower.contains('tiktokcdn.com') ||
      lower.contains('facebook.com') ||
      lower.contains('facebook.net') ||
      lower.contains('fbcdn.net');
}

/// Wraps [rawEmbedUrl] inside a responsive full-bleed HTML5 `<iframe>` document
/// loaded with `baseUrl: 'https://www.youtube.com'` so YouTube, TikTok, and
/// Facebook embeds receive a valid origin and play directly inline inside the
/// feed card without triggering YouTube's raw-WebView error screen.
String _buildResponsiveIframeHtml(String rawEmbedUrl) {
  String normalized = rawEmbedUrl.trim();
  if (normalized.contains('youtube-nocookie.com/embed/')) {
    normalized = normalized.replaceFirst('youtube-nocookie.com/embed/', 'youtube.com/embed/');
  }
  if (normalized.contains('youtube.com/embed/')) {
    final uri = Uri.tryParse(normalized);
    if (uri != null) {
      final qp = Map<String, String>.from(uri.queryParameters);
      qp['autoplay'] = '1';
      qp['playsinline'] = '1';
      qp['rel'] = '0';
      qp['modestbranding'] = '1';
      qp.remove('origin');
      normalized = uri.replace(queryParameters: qp).toString();
    }
  }
  final safeUrl = normalized
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

/// Inline Combat Video Player Card — Plays YouTube, TikTok, and Facebook clips
/// directly inside the Community Feed card (16:9 Stream or 9:16 Vertical Reel)
/// without popping a disruptive modal bottom sheet.
///
/// Enforces single-active-video playback across the feed via [activePostIdNotifier].
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
  });

  @override
  State<InlineCombatVideoPlayer> createState() => _InlineCombatVideoPlayerState();
}

class _InlineCombatVideoPlayerState extends State<InlineCombatVideoPlayer> {
  WebViewController? _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  bool get _isActive =>
      widget.postId.isNotEmpty &&
      widget.activePostIdNotifier.value == widget.postId;

  @override
  void initState() {
    super.initState();
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
    if (oldWidget.embedUrl != widget.embedUrl && _isActive) {
      _disposeWebView();
      _ensureControllerInitialized();
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
  }

  void _ensureControllerInitialized() {
    if (_webViewController != null) return;
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';

    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF04060B))
        ..setUserAgent(_kMobileChromeUserAgent)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              if (progress > 80 && mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onPageStarted: (String url) {
              if (mounted && url != 'about:blank') {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
              }
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              // Ignore non-main-frame subresource errors (e.g. analytics/tracking pixels)
              if (error.isForMainFrame == false) return;
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                  _errorMessage = error.description;
                });
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              if (_isAllowedEmbedDomain(request.url)) {
                return NavigationDecision.navigate;
              }
              return NavigationDecision.prevent;
            },
          ),
        );

      _configureAndroidGestureFreePlayback(controller);
      controller.loadHtmlString(
        _buildResponsiveIframeHtml(widget.embedUrl),
        baseUrl: 'https://www.youtube.com',
      );
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

  void _retryPlayback() {
    HapticFeedback.lightImpact();
    setState(() {
      _disposeWebView();
      _ensureControllerInitialized();
    });
  }

  void _openExternalFallback(BuildContext context) {
    HapticFeedback.lightImpact();
    final targetLink = widget.rawUrl.isNotEmpty ? widget.rawUrl : widget.embedUrl;
    Clipboard.setData(ClipboardData(text: targetLink));
    ScaffoldMessenger.of(context).showSnackBar(
      CrystalSnackBar(
        content: Text(
          'Direct ${widget.platform} link copied ($targetLink) — ready to open in browser or YouTube app',
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: AppTheme.elevatedSurface,
      ),
    );
  }

  void _openFullScreenModal(BuildContext context) {
    HapticFeedback.lightImpact();
    // Pause inline player before launching fullscreen view so audio does not double-play
    _stopInlinePlayback();
    VideoPlayerModal.show(
      context,
      embedUrl: widget.embedUrl,
      rawUrl: widget.rawUrl,
      platform: widget.platform,
      caption: widget.caption,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isVerticalReel) {
      return _buildVerticalReelContent(context);
    }
    return _buildStreamCardContent(context);
  }

  Widget _buildStreamCardContent(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF04060B),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color: _isActive ? const Color(0x99D4AF37) : const Color(0x38FFFFFF),
            width: _isActive ? 1.2 : 1.0,
          ),
        ),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _isActive
              ? _buildActiveWebViewStack(context)
              : _buildStreamThumbnailPreview(),
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
                color: const Color(0xFF070A11).withValues(alpha: 0.8),
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

  Widget _buildStreamThumbnailPreview() {
    final platform = widget.platform.toUpperCase();
    final platformColor = _platformBadgeColor(platform);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _activateInlinePlayback,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ArmSphereImage(
              imageUrl: widget.thumbnailUrl,
              fallbackAsset: widget.fallbackAsset,
              fit: BoxFit.cover,
              cacheWidth: 720,
              cacheHeight: 405,
              semanticLabel: widget.caption.isNotEmpty
                  ? 'Combat clip: ${widget.caption}'
                  : 'Combat video preview',
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: [0.0, 0.55, 1.0],
                  colors: [
                    Color(0x80000000),
                    Color(0x00000000),
                    Color(0x00000000),
                  ],
                ),
              ),
            ),
          ),
          // Platform Tag in Top-Left
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0x9904060B),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: platformColor.withValues(alpha: 0.7),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _platformBadgeIcon(platform),
                    size: 11,
                    color: platformColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    platform,
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: platformColor,
                      shadows: AppTheme.crystalTextShadows,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Tactical Play Center Medallion
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x8804060B),
              border: Border.all(color: const Color(0xB3D4AF37), width: 1.5),
            ),
            child: const Center(
              child: Icon(
                Icons.play_arrow_rounded,
                size: 34,
                color: AppTheme.goldPrimary,
              ),
            ),
          ),
          // Bottom Video Scrim Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TAP TO PLAY STREAM',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: const Color(0x6638BDF8), width: 1.0),
                    ),
                    child: const Text(
                      '1080P HD',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.info,
                        shadows: AppTheme.crystalTextShadows,
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
                    'INITIALIZING ${widget.platform.toUpperCase()} STREAM...',
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
                      'Stream Unavailable Inline',
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
                          : 'This video may restrict embedded playback.',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _retryPlayback,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary,
                            side: const BorderSide(color: Color(0x4DFFFFFF)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 14),
                          label: const Text(
                            'Retry',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _openExternalFallback(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.goldPrimary,
                            side: const BorderSide(color: Color(0x80D4AF37)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.open_in_new_rounded, size: 14),
                          label: const Text(
                            'Open in Browser / YouTube',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Top-Right Inline Player Controls: Fullscreen & Close/Stop
        Positioned(
          top: widget.isVerticalReel ? 88 : 8,
          right: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Expand to Fullscreen Modal
              Material(
                color: const Color(0xB304060B),
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
              // Stop / Close Inline Player
              Material(
                color: const Color(0xB304060B),
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
        return Icons.play_arrow;
      case 'TIKTOK':
        return Icons.music_note;
      case 'FACEBOOK':
        return Icons.public;
      default:
        return Icons.videocam;
    }
  }
}

class VideoPlayerModal extends StatefulWidget {
  final String embedUrl;
  final String? rawUrl;
  final String platform;
  final String? caption;

  const VideoPlayerModal({
    super.key,
    required this.embedUrl,
    this.rawUrl,
    required this.platform,
    this.caption,
  });

  /// Shows the modal in a clean, dark fullscreen/bottom-sheet overlay when explicitly requested.
  static void show(
    BuildContext context, {
    required String embedUrl,
    String? rawUrl,
    required String platform,
    String? caption,
  }) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VideoPlayerModal(
        embedUrl: embedUrl,
        rawUrl: rawUrl,
        platform: platform,
        caption: caption,
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

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.elevatedSurface)
      ..setUserAgent(_kMobileChromeUserAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress > 85 && mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (error.isForMainFrame == false) return;
            debugPrint('WebView Error: ${error.description}');
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage = error.description;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            if (_isAllowedEmbedDomain(request.url)) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      );

    _configureAndroidGestureFreePlayback(_webViewController);
    _webViewController.loadHtmlString(
      _buildResponsiveIframeHtml(widget.embedUrl),
      baseUrl: 'https://www.youtube.com',
    );
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
    _webViewController.loadHtmlString(
      _buildResponsiveIframeHtml(widget.embedUrl),
      baseUrl: 'https://www.youtube.com',
    );
  }

  void _openExternalFallback(BuildContext context) {
    final targetLink =
        (widget.rawUrl != null && widget.rawUrl!.isNotEmpty) ? widget.rawUrl! : widget.embedUrl;
    Clipboard.setData(ClipboardData(text: targetLink));
    ScaffoldMessenger.of(context).showSnackBar(
      CrystalSnackBar(
        content: Text(
          'Direct ${widget.platform} link copied ($targetLink) — ready to open in browser or YouTube app',
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: AppTheme.elevatedSurface,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.elevatedSurface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 16,
        right: 16,
        bottom: mediaQuery.viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle indicator
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header: Platform title & Close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    widget.platform.toUpperCase() == 'YOUTUBE'
                        ? Icons.play_circle_filled
                        : widget.platform.toUpperCase() == 'TIKTOK'
                            ? Icons.music_note
                            : Icons.facebook,
                    color: widget.platform.toUpperCase() == 'YOUTUBE'
                        ? AppTheme.primaryAccent
                        : widget.platform.toUpperCase() == 'TIKTOK'
                            ? AppTheme.success
                            : AppTheme.info,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.platform.toUpperCase()} VIDEO PLAYER',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close, color: AppTheme.textPrimary.withValues(alpha: 0.7)),
                tooltip: 'Close video',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Player Container
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: AppTheme.background,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    if (!_hasError)
                      WebViewWidget(controller: _webViewController),

                    // Loading State Overlay
                    if (_isLoading)
                      Container(
                        color: AppTheme.elevatedSurface,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(color: AppTheme.primaryAccent),
                              const SizedBox(height: 12),
                              Text(
                                'Loading video player...',
                                style: TextStyle(
                                  color: AppTheme.textPrimary.withValues(alpha: 0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Error State Overlay
                    if (_hasError)
                      Container(
                        color: AppTheme.elevatedSurface,
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 42),
                              const SizedBox(height: 12),
                              const Text(
                                'Failed to Load Video',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _errorMessage.isNotEmpty
                                    ? _errorMessage
                                    : 'The video might have been deleted, made private, or is restricted from embedding.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _retry,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.textSecondary,
                                      foregroundColor: AppTheme.textPrimary,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Retry'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => _openExternalFallback(context),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.goldPrimary,
                                      side: const BorderSide(color: Color(0x80D4AF37)),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    ),
                                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                                    label: const Text('Open in Browser / YouTube'),
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

          // Caption & Info Section
          if (widget.caption != null && widget.caption!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'CAPTION',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.caption!,
              style: TextStyle(
                color: AppTheme.textPrimary.withValues(alpha: 0.7),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Tip: Double-tap or pinch the player within the frame to adjust viewport size if available.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

