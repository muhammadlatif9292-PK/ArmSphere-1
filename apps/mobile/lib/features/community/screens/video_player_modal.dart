import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_theme.dart';

class VideoPlayerModal extends StatefulWidget {
  final String embedUrl;
  final String platform;
  final String? caption;

  const VideoPlayerModal({
    Key? key,
    required this.embedUrl,
    required this.platform,
    this.caption,
  }) : super(key: key);

  /// Shows the modal in a clean, dark bottom-sheet overlay.
  static void show(BuildContext context, {
    required String embedUrl,
    required String platform,
    String? caption,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VideoPlayerModal(
        embedUrl: embedUrl,
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
            debugPrint("WebView Error: ${error.description}");
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage = error.description;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // Only allow loading embed links or corresponding domains inside the player
            final url = request.url;
            if (url.contains('youtube.com') ||
                url.contains('youtu.be') ||
                url.contains('tiktok.com') ||
                url.contains('facebook.com') ||
                url.contains('facebook.net') ||
                url.contains('fbcdn.net')) {
              return NavigationDecision.navigate;
            }
            // Block external redirect clicks to maintain context inside our application
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.embedUrl));
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
    _webViewController.loadRequest(Uri.parse(widget.embedUrl));
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
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close, color: AppTheme.textPrimary.withOpacity(0.7)),
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
                              CircularProgressIndicator(color: AppTheme.primaryAccent),
                              SizedBox(height: 12),
                              Text(
                                'Loading video player...',
                                style: TextStyle(color: AppTheme.textPrimary.withOpacity(0.6), fontSize: 13),
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
                              Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 42),
                              const SizedBox(height: 12),
                              const Text(
                                'Failed to Load Video',
                                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _errorMessage.isNotEmpty
                                    ? _errorMessage
                                    : 'The video might have been deleted, made private, or is restricted from embedding.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _retry,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.textSecondary,
                                  foregroundColor: AppTheme.textPrimary,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                icon: Icon(Icons.refresh, size: 16),
                                label: const Text('Retry'),
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
                color: AppTheme.textPrimary.withOpacity(0.7),
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
