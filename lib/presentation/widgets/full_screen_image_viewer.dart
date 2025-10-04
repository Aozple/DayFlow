import 'dart:ui' as ui;
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:dayflow/core/utils/debug_logger.dart';

class FullScreenImageViewer extends StatefulWidget {
  final File imageFile;
  final String heroTag;

  const FullScreenImageViewer({
    super.key,
    required this.imageFile,
    required this.heroTag,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer>
    with TickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _overlayAnimationController;
  late AnimationController _transformAnimationController;
  late Animation<double> _overlayAnimation;
  late Animation<Matrix4> _transformAnimation;

  bool _showOverlay = true;
  bool _isLoading = true;
  double _currentScale = 1.0;
  String? _imageSizeText;
  Timer? _overlayTimer;
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadImageInfo();
    _startOverlayTimer();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _overlayAnimationController.dispose();
    _transformAnimationController.dispose();
    _overlayTimer?.cancel();
    super.dispose();
  }

  void _initializeControllers() {
    _transformationController = TransformationController();

    _overlayAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _transformAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _overlayAnimation = CurvedAnimation(
      parent: _overlayAnimationController,
      curve: Curves.easeInOut,
    );

    _overlayAnimationController.forward();
  }

  Future<void> _loadImageInfo() async {
    try {
      final imageBytes = await widget.imageFile.readAsBytes();
      final image = await decodeImageFromList(imageBytes);
      final fileStat = await widget.imageFile.stat();

      if (mounted) {
        setState(() {
          _imageSizeText =
              '${image.width} × ${image.height} • ${_formatFileSize(fileStat.size)}';
          _isLoading = false;
        });
      }

      DebugLogger.success(
        'Image info loaded',
        tag: 'FullScreenViewer',
        data: _imageSizeText,
      );
    } catch (e) {
      DebugLogger.error(
        'Failed to load image info',
        tag: 'FullScreenViewer',
        error: e,
      );
      if (mounted) {
        setState(() {
          _imageSizeText = 'Unable to load image info';
          _isLoading = false;
        });
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  void _toggleOverlay() {
    setState(() => _showOverlay = !_showOverlay);

    if (_showOverlay) {
      _overlayAnimationController.forward();
      _startOverlayTimer();
    } else {
      _overlayAnimationController.reverse();
      _overlayTimer?.cancel();
    }

    DebugLogger.debug(
      'Overlay toggled',
      tag: 'FullScreenViewer',
      data: 'Visible: $_showOverlay',
    );
  }

  void _startOverlayTimer() {
    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showOverlay) {
        setState(() => _showOverlay = false);
        _overlayAnimationController.reverse();
      }
    });
  }

  void _handleDoubleTap() {
    final isZoomedIn = _currentScale > 1.5;

    if (isZoomedIn) {
      _transformAnimationController.reset();
      _transformAnimation = Matrix4Tween(
        begin: _transformationController.value,
        end: Matrix4.identity(),
      ).animate(
        CurvedAnimation(
          parent: _transformAnimationController,
          curve: Curves.easeInOut,
        ),
      );

      _transformAnimationController.forward().then((_) {
        setState(() => _currentScale = 1.0);
      });
    } else {
      if (_doubleTapDetails == null) {
        const targetScale = 2.5;
        final targetMatrix =
            Matrix4.identity()
              ..scaleByDouble(targetScale, targetScale, 1.0, 1.0);

        _transformAnimationController.reset();
        _transformAnimation = Matrix4Tween(
          begin: _transformationController.value,
          end: targetMatrix,
        ).animate(
          CurvedAnimation(
            parent: _transformAnimationController,
            curve: Curves.easeInOut,
          ),
        );

        _transformAnimationController.forward().then((_) {
          setState(() => _currentScale = targetScale);
        });
        return;
      }

      final tapPosition = _doubleTapDetails!.localPosition;
      const targetScale = 2.5;

      final currentMatrix = _transformationController.value;
      final currentScale = currentMatrix.getMaxScaleOnAxis();
      final currentTranslation = currentMatrix.getTranslation();

      final scaledTapX = (tapPosition.dx - currentTranslation.x) / currentScale;
      final scaledTapY = (tapPosition.dy - currentTranslation.y) / currentScale;

      final newTranslationX = tapPosition.dx - (scaledTapX * targetScale);
      final newTranslationY = tapPosition.dy - (scaledTapY * targetScale);

      final targetMatrix =
          Matrix4.identity()
            ..translateByDouble(newTranslationX, newTranslationY, 0.0, 0.0)
            ..scaleByDouble(targetScale, targetScale, 1.0, 1.0);

      _transformAnimationController.reset();
      _transformAnimation = Matrix4Tween(
        begin: currentMatrix,
        end: targetMatrix,
      ).animate(
        CurvedAnimation(
          parent: _transformAnimationController,
          curve: Curves.easeInOut,
        ),
      );

      _transformAnimationController.forward().then((_) {
        setState(() => _currentScale = targetScale);
      });
    }

    HapticFeedback.lightImpact();
    DebugLogger.debug(
      'Double tap zoom',
      tag: 'FullScreenViewer',
      data:
          'Zoomed ${isZoomedIn ? 'out' : 'in'}, Position: ${_doubleTapDetails?.localPosition}',
    );
  }

  void _resetZoom() {
    final targetMatrix = Matrix4.identity();

    _transformAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(
      CurvedAnimation(
        parent: _transformAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _transformAnimationController.reset();
    _transformAnimationController.forward().then((_) {
      setState(() => _currentScale = 1.0);
    });

    HapticFeedback.lightImpact();
    DebugLogger.debug('Zoom reset', tag: 'FullScreenViewer');
  }

  Future<void> _shareImage() async {
    try {
      _showSnackBar('Share functionality coming soon');
      DebugLogger.info('Image share requested', tag: 'FullScreenViewer');
    } catch (e) {
      DebugLogger.error(
        'Failed to share image',
        tag: 'FullScreenViewer',
        error: e,
      );
      _showSnackBar('Failed to share image');
    }
  }

  void _showImageDetails() {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(100),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Image Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (_imageSizeText != null)
                  _buildDetailRow('Dimensions & Size', _imageSizeText!),
                _buildDetailRow(
                  'File Name',
                  widget.imageFile.path.split('/').last,
                ),
                _buildDetailRow('Format', 'JPEG'),
                _buildDetailRow(
                  'Current Zoom',
                  '${(_currentScale * 100).toInt()}%',
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        color: Theme.of(context).colorScheme.primary.withAlpha(50),
                        borderRadius: BorderRadius.circular(12),
                        onPressed: () {
                          Navigator.pop(context);
                          _shareImage();
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.share, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Share',
                              style: TextStyle(color: Theme.of(context).colorScheme.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        color: Colors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Close',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );

    DebugLogger.debug('Image details shown', tag: 'FullScreenViewer');
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withAlpha(150),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    Color? iconColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(100),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withAlpha(30), width: 1),
              ),
              child: Icon(icon, color: iconColor ?? Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomIndicator() {
    if (_currentScale <= 1.1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(150),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(30), width: 1),
      ),
      child: Text(
        '${(_currentScale * 100).toInt()}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DebugLogger.debug(
      'Building full screen image viewer',
      tag: 'FullScreenViewer',
      data: widget.imageFile.path,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: _toggleOverlay,
        onTapDown: (details) => _doubleTapDetails = details,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: widget.heroTag,
              child: GestureDetector(
                onDoubleTap: _handleDoubleTap,
                onDoubleTapDown: (details) {
                  _doubleTapDetails = details;
                  DebugLogger.debug(
                    'Double tap captured',
                    tag: 'FullScreenViewer',
                    data: 'Position: ${details.localPosition}',
                  );
                },
                child: AnimatedBuilder(
                  animation: _transformAnimationController,
                  builder: (context, child) {
                    if (_transformAnimationController.isAnimating) {
                      _transformationController.value =
                          _transformAnimation.value;
                    }

                    return InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 0.1,
                      maxScale: 5.0,
                      onInteractionUpdate: (details) {
                        final matrix = _transformationController.value;
                        final newScale = matrix.getMaxScaleOnAxis();
                        if ((newScale - _currentScale).abs() > 0.01) {
                          setState(() => _currentScale = newScale);
                        }
                        if (_showOverlay) _startOverlayTimer();
                      },
                      child: Image.file(
                        widget.imageFile,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          DebugLogger.error(
                            'Failed to load image in viewer',
                            error: error,
                            tag: 'FullScreenViewer',
                          );
                          return Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(50),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.exclamationmark_triangle,
                                  color: Colors.white70,
                                  size: 48,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

            if (_isLoading)
              const Center(
                child: CupertinoActivityIndicator(
                  color: Colors.white,
                  radius: 16,
                ),
              ),

            AnimatedBuilder(
              animation: _overlayAnimation,
              builder: (context, child) {
                return IgnorePointer(
                  ignoring: !_showOverlay,
                  child: AnimatedOpacity(
                    opacity: _overlayAnimation.value,
                    duration: const Duration(milliseconds: 300),
                    child: SafeArea(
                      child: Stack(
                        children: [
                          Positioned(
                            top: 16,
                            left: 16,
                            child: _buildGlassButton(
                              icon: CupertinoIcons.xmark,
                              tooltip: 'Close',
                              onPressed: () {
                                DebugLogger.debug(
                                  'Closing full screen image viewer',
                                  tag: 'FullScreenViewer',
                                );
                                Navigator.pop(context);
                              },
                            ),
                          ),

                          Positioned(
                            top: 16,
                            right: 16,
                            child: Row(
                              children: [
                                if (_currentScale > 1.1) ...[
                                  _buildGlassButton(
                                    icon: CupertinoIcons.zoom_out,
                                    tooltip: 'Reset Zoom',
                                    onPressed: _resetZoom,
                                    iconColor: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                _buildGlassButton(
                                  icon: CupertinoIcons.share,
                                  tooltip: 'Share',
                                  onPressed: _shareImage,
                                ),
                                const SizedBox(width: 8),
                                _buildGlassButton(
                                  icon: CupertinoIcons.info,
                                  tooltip: 'Details',
                                  onPressed: _showImageDetails,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            AnimatedBuilder(
              animation: _overlayAnimation,
              builder: (context, child) {
                return Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: !_showOverlay,
                    child: AnimatedOpacity(
                      opacity: _overlayAnimation.value,
                      duration: const Duration(milliseconds: 300),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_imageSizeText != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(150),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withAlpha(30),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    _imageSizeText!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to toggle • Double tap to zoom • Pinch to scale',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(150),
                                  fontSize: 11,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            Positioned(
              top: 125,
              right: 16,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildZoomIndicator(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
