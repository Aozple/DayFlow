import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/core/utils/debug_logger.dart';

/// Professional image editor with real crop, draw, and text features
class ImageEditor extends StatefulWidget {
  final Uint8List imageBytes;
  final Function(Uint8List) onSave;
  final VoidCallback? onCancel;

  const ImageEditor({
    super.key,
    required this.imageBytes,
    required this.onSave,
    this.onCancel,
  });

  @override
  State<ImageEditor> createState() => _ImageEditorState();
}

class _ImageEditorState extends State<ImageEditor>
    with TickerProviderStateMixin {
  // Controllers
  late AnimationController _toolbarAnimationController;
  late Animation<double> _toolbarAnimation;
  final GlobalKey _repaintKey = GlobalKey();
  final TransformationController _transformController =
      TransformationController();

  // Image data
  ui.Image? _originalImage;
  ui.Image? _currentImage;
  bool _isLoading = true;
  Size _imageSize = Size.zero;

  // Editing mode
  EditMode _currentMode = EditMode.none;

  // Crop data
  Rect? _cropRect;
  bool _isCropping = false;
  CropHandle _activeCropHandle = CropHandle.none;
  Offset? _dragStartPos;
  Rect? _dragStartRect;

  // Drawing data
  List<DrawingPoint> _drawingPoints = [];
  Color _drawColor = Colors.white;
  double _strokeWidth = 3.0;

  // Text overlays
  List<TextOverlay> _textOverlays = [];
  TextOverlay? _draggingText;
  final TextEditingController _textController = TextEditingController();
  TextOverlay? _selectedText;
  double _textFontSize = 32.0;
  Color _textColor = Colors.white;
  DateTime? _lastTapTime;
  Offset? _dragOffset;

  // Undo/Redo stacks
  final List<EditAction> _undoStack = [];
  final List<EditAction> _redoStack = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadImage();
  }

  void _initializeAnimations() {
    _toolbarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _toolbarAnimation = CurvedAnimation(
      parent: _toolbarAnimationController,
      curve: Curves.easeOutCubic,
    );
    _toolbarAnimationController.forward();
  }

  @override
  void dispose() {
    _toolbarAnimationController.dispose();
    _transformController.dispose();
    _textController.dispose();

    try {
      if (_currentImage != null && _currentImage != _originalImage) {
        _currentImage!.dispose();
      }
    } catch (e) {
      DebugLogger.debug('Image already disposed', tag: 'ImageEditor');
    }

    super.dispose();
  }

  Future<void> _loadImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.imageBytes);
      final frame = await codec.getNextFrame();

      setState(() {
        _originalImage = frame.image;
        _currentImage = frame.image;
        _imageSize = Size(
          frame.image.width.toDouble(),
          frame.image.height.toDouble(),
        );
        _isLoading = false;
      });

      DebugLogger.success(
        'Image loaded',
        tag: 'ImageEditor',
        data: '${frame.image.width}x${frame.image.height}',
      );
    } catch (e) {
      DebugLogger.error('Failed to load image', tag: 'ImageEditor', error: e);
      setState(() => _isLoading = false);
    }
  }

  void _switchMode(EditMode mode) {
    setState(() {
      // Save current crop if switching from crop mode
      if (_currentMode == EditMode.crop &&
          _cropRect != null &&
          mode != EditMode.crop) {
        _applyCrop();
      }

      _currentMode = _currentMode == mode ? EditMode.none : mode;

      if (_currentMode == EditMode.text) {
        _showAddTextDialog();
      }
    });

    HapticFeedback.lightImpact();
  }

  // CROP FUNCTIONALITY
  void _startCrop() {
    setState(() {
      _isCropping = true;
      // Start with full image
      _cropRect = Rect.fromLTWH(0, 0, _imageSize.width, _imageSize.height);
    });
  }

  CropHandle _getCropHandle(Offset localPosition, double scale) {
    if (_cropRect == null) return CropHandle.none;

    const handleRadius = 30.0; // Touch sensitive area
    final rect = _cropRect!;

    // Convert position to image coordinates
    final imagePos = localPosition / scale;

    // Check corners
    if ((imagePos - rect.topLeft).distance < handleRadius) {
      return CropHandle.topLeft;
    }
    if ((imagePos - rect.topRight).distance < handleRadius) {
      return CropHandle.topRight;
    }
    if ((imagePos - rect.bottomLeft).distance < handleRadius) {
      return CropHandle.bottomLeft;
    }
    if ((imagePos - rect.bottomRight).distance < handleRadius) {
      return CropHandle.bottomRight;
    }

    // Check mid-points
    final centerTop = Offset(rect.center.dx, rect.top);
    final centerBottom = Offset(rect.center.dx, rect.bottom);
    final centerLeft = Offset(rect.left, rect.center.dy);
    final centerRight = Offset(rect.right, rect.center.dy);

    if ((imagePos - centerTop).distance < handleRadius) return CropHandle.top;
    if ((imagePos - centerBottom).distance < handleRadius) {
      return CropHandle.bottom;
    }
    if ((imagePos - centerLeft).distance < handleRadius) return CropHandle.left;
    if ((imagePos - centerRight).distance < handleRadius) {
      return CropHandle.right;
    }

    // Check inside rectangle for move
    if (rect.contains(imagePos)) return CropHandle.move;

    return CropHandle.none;
  }

  void _applyCrop() async {
    if (_cropRect == null || _currentImage == null) return;

    setState(() => _isLoading = true);

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw only the cropped portion
      canvas.drawImageRect(
        _currentImage!,
        _cropRect!,
        Rect.fromLTWH(0, 0, _cropRect!.width, _cropRect!.height),
        Paint(),
      );

      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(
        _cropRect!.width.toInt(),
        _cropRect!.height.toInt(),
      );

      // Update current image and size
      setState(() {
        _currentImage?.dispose();
        _currentImage = croppedImage;
        _imageSize = Size(_cropRect!.width, _cropRect!.height);
        _cropRect = null;
        _isCropping = false;
        _isLoading = false;
      });

      // Add to undo stack
      _addToUndoStack(EditAction(type: ActionType.crop, image: croppedImage));

      DebugLogger.success('Crop applied', tag: 'ImageEditor');
    } catch (e) {
      DebugLogger.error('Failed to apply crop', tag: 'ImageEditor', error: e);
      setState(() => _isLoading = false);
    }
  }

  void _cancelCrop() {
    setState(() {
      _cropRect = null;
      _isCropping = false;
    });
  }

  // TEXT FUNCTIONALITY
  void _showAddTextDialog({TextOverlay? existingText}) {
    if (existingText != null) {
      _textController.text = existingText.text;
      _textFontSize = existingText.fontSize;
      _textColor = existingText.color;
    } else {
      _textController.clear();
      _textFontSize = 32.0;
      _textColor = Colors.white;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (BuildContext bottomSheetContext) => StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(color: Colors.black.withAlpha(150)),
                  child: Center(
                    child: Container(
                      margin: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                        left: 20,
                        right: 20,
                      ),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withAlpha(30),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            existingText != null ? 'Edit Text' : 'Add Text',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Text input
                          TextField(
                            controller: _textController,
                            autofocus: true,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter text...',
                              hintStyle: TextStyle(
                                color: Colors.white.withAlpha(100),
                              ),
                              filled: true,
                              fillColor: Colors.white.withAlpha(10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withAlpha(30),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.accent,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Font size with visual feedback
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.textformat_size,
                                color: Colors.white.withAlpha(200),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Size',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(200),
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              // Size preview
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(10),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withAlpha(20),
                                  ),
                                ),
                                child: Text(
                                  'Aa',
                                  style: TextStyle(
                                    fontSize: _textFontSize / 2,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Improved slider with snap points
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: AppColors.accent,
                              inactiveTrackColor: Colors.white.withAlpha(30),
                              thumbColor: AppColors.accent,
                              overlayColor: AppColors.accent.withAlpha(50),
                              valueIndicatorColor: AppColors.accent,
                              valueIndicatorTextStyle: const TextStyle(
                                color: Colors.white,
                              ),
                              showValueIndicator: ShowValueIndicator.onDrag,
                            ),
                            child: Slider(
                              value: _textFontSize,
                              min: 16,
                              max: 64,
                              divisions: 12, // Creates snap points
                              label: _textFontSize.round().toString(),
                              onChanged: (value) {
                                setModalState(() {
                                  _textFontSize = value;
                                });
                                setState(() {
                                  _textFontSize = value;
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Color selector with labels
                          Text(
                            'Color',
                            style: TextStyle(
                              color: Colors.white.withAlpha(200),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children:
                                  [
                                    Colors.white,
                                    Colors.black,
                                    Colors.red,
                                    Colors.blue,
                                    Colors.yellow,
                                    Colors.green,
                                    Colors.purple,
                                    Colors.orange,
                                    Colors.pink,
                                    Colors.cyan,
                                  ].map((color) {
                                    return GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          _textColor = color;
                                        });
                                        setState(() {
                                          _textColor = color;
                                        });
                                      },
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color:
                                                _textColor == color
                                                    ? AppColors.accent
                                                    : Colors.white.withAlpha(
                                                      50,
                                                    ),
                                            width: 3,
                                          ),
                                          boxShadow:
                                              _textColor == color
                                                  ? [
                                                    BoxShadow(
                                                      color: color.withAlpha(
                                                        100,
                                                      ),
                                                      blurRadius: 8,
                                                      spreadRadius: 1,
                                                    ),
                                                  ]
                                                  : null,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Action buttons
                          Row(
                            children: [
                              if (existingText != null)
                                Expanded(
                                  child: CupertinoButton(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    color: AppColors.error.withAlpha(30),
                                    borderRadius: BorderRadius.circular(12),
                                    onPressed: () {
                                      setState(() {
                                        _textOverlays.remove(existingText);
                                        _selectedText = null;
                                      });
                                      Navigator.pop(context);
                                    },
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: AppColors.error),
                                    ),
                                  ),
                                ),
                              if (existingText != null)
                                const SizedBox(width: 12),
                              Expanded(
                                child: CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(12),
                                  onPressed: () {
                                    if (_textController.text.isNotEmpty) {
                                      setState(() {
                                        if (existingText != null) {
                                          // Update existing text
                                          final index = _textOverlays.indexOf(
                                            existingText,
                                          );
                                          _textOverlays[index] = TextOverlay(
                                            text: _textController.text,
                                            position: existingText.position,
                                            color: _textColor,
                                            fontSize: _textFontSize,
                                          );
                                        } else {
                                          // Add new text
                                          _textOverlays.add(
                                            TextOverlay(
                                              text: _textController.text,
                                              position: Offset(
                                                _imageSize.width / 2,
                                                _imageSize.height / 2,
                                              ),
                                              color: _textColor,
                                              fontSize: _textFontSize,
                                            ),
                                          );
                                        }
                                        _currentMode = EditMode.none;
                                        _selectedText = null;
                                      });
                                      Navigator.pop(context);

                                      _addToUndoStack(
                                        EditAction(
                                          type: ActionType.text,
                                          textOverlays: List.from(
                                            _textOverlays,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Text(
                                    existingText != null
                                        ? 'Update'
                                        : 'Add Text',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }

  // DRAWING FUNCTIONALITY
  void _startDrawing(Offset position) {
    setState(() {
      _drawingPoints.add(
        DrawingPoint(
          points: [position],
          color: _drawColor,
          strokeWidth: _strokeWidth,
        ),
      );
    });
  }

  void _updateDrawing(Offset position) {
    setState(() {
      if (_drawingPoints.isNotEmpty) {
        _drawingPoints.last.points.add(position);
      }
    });
  }

  void _endDrawing() {
    if (_drawingPoints.isNotEmpty) {
      _addToUndoStack(
        EditAction(
          type: ActionType.draw,
          drawingPoints: List.from(_drawingPoints),
        ),
      );
    }
  }

  // UNDO/REDO FUNCTIONALITY
  void _addToUndoStack(EditAction action) {
    setState(() {
      _undoStack.add(action);
      _redoStack.clear();
    });
  }

  void _undo() {
    if (_undoStack.isNotEmpty) {
      final action = _undoStack.removeLast();
      _redoStack.add(action);
      _revertAction(action);
      HapticFeedback.lightImpact();
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      final action = _redoStack.removeLast();
      _undoStack.add(action);
      _applyAction(action);
      HapticFeedback.lightImpact();
    }
  }

  void _revertAction(EditAction action) {
    setState(() {
      switch (action.type) {
        case ActionType.draw:
          if (_drawingPoints.isNotEmpty) {
            _drawingPoints.removeLast();
          }
          break;
        case ActionType.text:
          if (_textOverlays.isNotEmpty) {
            _textOverlays.removeLast();
          }
          break;
        case ActionType.crop:
          // Revert to previous image if available
          break;
      }
    });
  }

  void _applyAction(EditAction action) {
    setState(() {
      switch (action.type) {
        case ActionType.draw:
          _drawingPoints = List.from(action.drawingPoints ?? []);
          break;
        case ActionType.text:
          _textOverlays = List.from(action.textOverlays ?? []);
          break;
        case ActionType.crop:
          // Apply cropped image
          break;
      }
    });
  }

  // SAVE FUNCTIONALITY
  Future<void> _saveImage() async {
    setState(() => _isLoading = true);

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      if (_currentImage != null) {
        // Draw the current image
        canvas.drawImage(_currentImage!, Offset.zero, Paint());

        // Draw all drawing strokes
        for (final drawing in _drawingPoints) {
          final paint =
              Paint()
                ..color = drawing.color
                ..strokeWidth = drawing.strokeWidth
                ..strokeCap = StrokeCap.round
                ..style = PaintingStyle.stroke;

          if (drawing.points.length > 1) {
            final path = Path();
            path.moveTo(drawing.points.first.dx, drawing.points.first.dy);

            for (int i = 1; i < drawing.points.length; i++) {
              path.lineTo(drawing.points[i].dx, drawing.points[i].dy);
            }

            canvas.drawPath(path, paint);
          }
        }

        // Draw all text overlays
        for (final overlay in _textOverlays) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: overlay.text,
              style: TextStyle(
                color: overlay.color,
                fontSize: overlay.fontSize,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withAlpha(150),
                    blurRadius: 3,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, overlay.position);
        }

        // Convert to image
        final picture = recorder.endRecording();
        final finalImage = await picture.toImage(
          _imageSize.width.toInt(),
          _imageSize.height.toInt(),
        );

        // Convert to bytes
        final byteData = await finalImage.toByteData(
          format: ui.ImageByteFormat.png,
        );

        if (byteData != null) {
          widget.onSave(byteData.buffer.asUint8List());
          DebugLogger.success('Image saved', tag: 'ImageEditor');
        }

        finalImage.dispose();
        picture.dispose();
      }
    } catch (e) {
      DebugLogger.error('Failed to save image', tag: 'ImageEditor', error: e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body:
          _isLoading
              ? const Center(
                child: CupertinoActivityIndicator(color: Colors.white),
              )
              : Stack(
                fit: StackFit.expand,
                children: [
                  // Main canvas
                  _buildCanvas(),

                  // Top controls
                  _buildTopControls(),

                  // Bottom toolbar
                  _buildBottomToolbar(),

                  // Mode-specific overlays
                  if (_currentMode == EditMode.draw) _buildDrawControls(),

                  if (_isCropping) _buildCropControls(),
                ],
              ),
    );
  }

  Widget _buildCanvas() {
    return Center(
      child: RepaintBoundary(
        key: _repaintKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = math.min(
              constraints.maxWidth / _imageSize.width,
              constraints.maxHeight / _imageSize.height,
            );

            final scaledWidth = _imageSize.width * scale;
            final scaledHeight = _imageSize.height * scale;
            final imageOffset = Offset(
              (constraints.maxWidth - scaledWidth) / 2,
              (constraints.maxHeight - scaledHeight) / 2,
            );

            // Helper function to convert screen to image coordinates
            Offset screenToImage(Offset screenPos) {
              return (screenPos - imageOffset) / scale;
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                if (_currentMode != EditMode.none &&
                    _currentMode != EditMode.text) {
                  return;
                }

                final imagePos = screenToImage(details.localPosition);
                TextOverlay? tappedText;
                for (final text in _textOverlays) {
                  final textPainter = TextPainter(
                    text: TextSpan(
                      text: text.text,
                      style: TextStyle(fontSize: text.fontSize),
                    ),
                    textDirection: TextDirection.ltr,
                  );
                  textPainter.layout();

                  final hitBox = Rect.fromCenter(
                    center: text.position,
                    width: textPainter.width + 40,
                    height: textPainter.height + 40,
                  );

                  if (hitBox.contains(imagePos)) {
                    tappedText = text;
                    break;
                  }
                }

                if (tappedText != null) {
                  final now = DateTime.now();
                  if (_lastTapTime != null &&
                      now.difference(_lastTapTime!).inMilliseconds < 300 &&
                      _selectedText == tappedText) {
                    // Double tap
                    _showAddTextDialog(existingText: tappedText);
                  } else {
                    // Single tap
                    setState(() {
                      _selectedText = tappedText;
                    });
                  }
                  _lastTapTime = now;
                } else {
                  setState(() {
                    _selectedText = null;
                  });
                }
              },
              onPanStart: (details) {
                final imagePos = screenToImage(details.localPosition);

                if (_currentMode == EditMode.draw) {
                  _startDrawing(imagePos);
                  return;
                }

                if (_currentMode == EditMode.crop && _cropRect != null) {
                  _activeCropHandle = _getCropHandle(
                    details.localPosition - imageOffset,
                    scale,
                  );
                  _dragStartPos = imagePos;
                  _dragStartRect = _cropRect;
                  return;
                }

                // Text dragging - prioritize selected text
                if (_selectedText != null) {
                  final textPainter = TextPainter(
                    text: TextSpan(
                      text: _selectedText!.text,
                      style: TextStyle(fontSize: _selectedText!.fontSize),
                    ),
                    textDirection: TextDirection.ltr,
                  );
                  textPainter.layout();

                  final hitBox = Rect.fromCenter(
                    center: _selectedText!.position,
                    width: textPainter.width + 40,
                    height: textPainter.height + 40,
                  );

                  if (hitBox.contains(imagePos)) {
                    _draggingText = _selectedText;
                    _dragStartPos = _selectedText!.position;
                    _dragOffset = imagePos - _selectedText!.position;
                    return;
                  }
                }

                // If no selected text, check all texts
                for (final text in _textOverlays) {
                  final textPainter = TextPainter(
                    text: TextSpan(
                      text: text.text,
                      style: TextStyle(fontSize: text.fontSize),
                    ),
                    textDirection: TextDirection.ltr,
                  );
                  textPainter.layout();

                  final hitBox = Rect.fromCenter(
                    center: text.position,
                    width: textPainter.width + 40,
                    height: textPainter.height + 40,
                  );

                  if (hitBox.contains(imagePos)) {
                    setState(() {
                      _selectedText = text;
                    });
                    _draggingText = text;
                    _dragStartPos = text.position;
                    _dragOffset = imagePos - text.position; // مهم!
                    break;
                  }
                }
              },
              onPanUpdate: (details) {
                final imagePos = screenToImage(details.localPosition);

                if (_currentMode == EditMode.draw) {
                  _updateDrawing(imagePos);
                  return;
                }

                if (_currentMode == EditMode.crop &&
                    _cropRect != null &&
                    _dragStartRect != null &&
                    _dragStartPos != null) {
                  // Handle crop resize
                  setState(() {
                    final delta = imagePos - _dragStartPos!;

                    switch (_activeCropHandle) {
                      case CropHandle.move:
                        double newLeft = (_dragStartRect!.left + delta.dx)
                            .clamp(0, _imageSize.width - _dragStartRect!.width);
                        double newTop = (_dragStartRect!.top + delta.dy).clamp(
                          0,
                          _imageSize.height - _dragStartRect!.height,
                        );
                        _cropRect = Rect.fromLTWH(
                          newLeft,
                          newTop,
                          _dragStartRect!.width,
                          _dragStartRect!.height,
                        );
                        break;
                      case CropHandle.topLeft:
                        _cropRect = Rect.fromLTRB(
                          (_dragStartRect!.left + delta.dx).clamp(
                            0,
                            _dragStartRect!.right - 50,
                          ),
                          (_dragStartRect!.top + delta.dy).clamp(
                            0,
                            _dragStartRect!.bottom - 50,
                          ),
                          _dragStartRect!.right,
                          _dragStartRect!.bottom,
                        );
                        break;
                      case CropHandle.topRight:
                        _cropRect = Rect.fromLTRB(
                          _dragStartRect!.left,
                          (_dragStartRect!.top + delta.dy).clamp(
                            0,
                            _dragStartRect!.bottom - 50,
                          ),
                          (_dragStartRect!.right + delta.dx).clamp(
                            _dragStartRect!.left + 50,
                            _imageSize.width,
                          ),
                          _dragStartRect!.bottom,
                        );
                        break;
                      case CropHandle.bottomLeft:
                        _cropRect = Rect.fromLTRB(
                          (_dragStartRect!.left + delta.dx).clamp(
                            0,
                            _dragStartRect!.right - 50,
                          ),
                          _dragStartRect!.top,
                          _dragStartRect!.right,
                          (_dragStartRect!.bottom + delta.dy).clamp(
                            _dragStartRect!.top + 50,
                            _imageSize.height,
                          ),
                        );
                        break;
                      case CropHandle.bottomRight:
                        _cropRect = Rect.fromLTRB(
                          _dragStartRect!.left,
                          _dragStartRect!.top,
                          (_dragStartRect!.right + delta.dx).clamp(
                            _dragStartRect!.left + 50,
                            _imageSize.width,
                          ),
                          (_dragStartRect!.bottom + delta.dy).clamp(
                            _dragStartRect!.top + 50,
                            _imageSize.height,
                          ),
                        );
                        break;
                      case CropHandle.top:
                        _cropRect = Rect.fromLTRB(
                          _dragStartRect!.left,
                          (_dragStartRect!.top + delta.dy).clamp(
                            0,
                            _dragStartRect!.bottom - 50,
                          ),
                          _dragStartRect!.right,
                          _dragStartRect!.bottom,
                        );
                        break;
                      case CropHandle.bottom:
                        _cropRect = Rect.fromLTRB(
                          _dragStartRect!.left,
                          _dragStartRect!.top,
                          _dragStartRect!.right,
                          (_dragStartRect!.bottom + delta.dy).clamp(
                            _dragStartRect!.top + 50,
                            _imageSize.height,
                          ),
                        );
                        break;
                      case CropHandle.left:
                        _cropRect = Rect.fromLTRB(
                          (_dragStartRect!.left + delta.dx).clamp(
                            0,
                            _dragStartRect!.right - 50,
                          ),
                          _dragStartRect!.top,
                          _dragStartRect!.right,
                          _dragStartRect!.bottom,
                        );
                        break;
                      case CropHandle.right:
                        _cropRect = Rect.fromLTRB(
                          _dragStartRect!.left,
                          _dragStartRect!.top,
                          (_dragStartRect!.right + delta.dx).clamp(
                            _dragStartRect!.left + 50,
                            _imageSize.width,
                          ),
                          _dragStartRect!.bottom,
                        );
                        break;
                      default:
                        break;
                    }
                  });
                  return;
                }

                // Text dragging
                if (_draggingText != null && _dragOffset != null) {
                  setState(() {
                    final index = _textOverlays.indexOf(_draggingText!);
                    if (index != -1) {
                      final newPosition = imagePos - _dragOffset!;

                      final textPainter = TextPainter(
                        text: TextSpan(
                          text: _draggingText!.text,
                          style: TextStyle(fontSize: _draggingText!.fontSize),
                        ),
                        textDirection: TextDirection.ltr,
                      );
                      textPainter.layout();

                      final halfWidth = textPainter.width / 2;
                      final halfHeight = textPainter.height / 2;

                      final clampedPosition = Offset(
                        newPosition.dx.clamp(
                          halfWidth,
                          _imageSize.width - halfWidth,
                        ),
                        newPosition.dy.clamp(
                          halfHeight,
                          _imageSize.height - halfHeight,
                        ),
                      );

                      _textOverlays[index] = TextOverlay(
                        text: _draggingText!.text,
                        position: clampedPosition,
                        color: _draggingText!.color,
                        fontSize: _draggingText!.fontSize,
                      );

                      if (_selectedText == _draggingText) {
                        _selectedText = _textOverlays[index];
                        _draggingText = _textOverlays[index];
                      }
                    }
                  });
                }
              },
              onPanEnd: (details) {
                if (_currentMode == EditMode.draw) {
                  _endDrawing();
                } else if (_currentMode == EditMode.crop) {
                  _activeCropHandle = CropHandle.none;
                  _dragStartPos = null;
                  _dragStartRect = null;
                } else if (_draggingText != null) {
                  _addToUndoStack(
                    EditAction(
                      type: ActionType.text,
                      textOverlays: List.from(_textOverlays),
                    ),
                  );
                  _draggingText = null;
                  _dragStartPos = null;
                  _dragOffset = null;
                }
              },
              onPanCancel: () {
                // Restore original position if drag cancelled
                if (_draggingText != null && _dragStartPos != null) {
                  setState(() {
                    final index = _textOverlays.indexOf(_draggingText!);
                    if (index != -1) {
                      _textOverlays[index] = TextOverlay(
                        text: _draggingText!.text,
                        position: _dragStartPos!,
                        color: _draggingText!.color,
                        fontSize: _draggingText!.fontSize,
                      );

                      if (_selectedText == _draggingText) {
                        _selectedText = _textOverlays[index];
                      }
                    }
                  });
                }

                _draggingText = null;
                _dragStartPos = null;
                _dragOffset = null;
                _activeCropHandle = CropHandle.none;
                _dragStartRect = null;
              },
              child: CustomPaint(
                painter: ImageEditorPainter(
                  image: _currentImage,
                  cropRect: _isCropping ? _cropRect : null,
                  drawingPoints: _drawingPoints,
                  textOverlays: _textOverlays,
                  imageSize: _imageSize,
                  selectedText: _selectedText,
                ),
                size: Size.infinite,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withAlpha(200), Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Cancel button
            _buildIconButton(
              icon: CupertinoIcons.xmark,
              onPressed: widget.onCancel,
            ),

            // Undo/Redo
            Row(
              children: [
                _buildIconButton(
                  icon: CupertinoIcons.arrow_uturn_left,
                  onPressed: _undoStack.isNotEmpty ? _undo : null,
                ),
                const SizedBox(width: 8),
                _buildIconButton(
                  icon: CupertinoIcons.arrow_uturn_right,
                  onPressed: _redoStack.isNotEmpty ? _redo : null,
                ),
              ],
            ),

            // Save button
            _buildIconButton(
              icon: CupertinoIcons.checkmark,
              onPressed: _saveImage,
              isPrimary: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomToolbar() {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _toolbarAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 100 * (1 - _toolbarAnimation.value)),
            child: Opacity(
              opacity: _toolbarAnimation.value,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withAlpha(20),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildToolButton(
                          icon: CupertinoIcons.crop,
                          label: 'Crop',
                          isActive: _currentMode == EditMode.crop,
                          onPressed: () {
                            if (_currentMode != EditMode.crop) {
                              _startCrop();
                            }
                            _switchMode(EditMode.crop);
                          },
                        ),
                        _buildToolButton(
                          icon: CupertinoIcons.pencil,
                          label: 'Draw',
                          isActive: _currentMode == EditMode.draw,
                          onPressed: () => _switchMode(EditMode.draw),
                        ),
                        _buildToolButton(
                          icon: CupertinoIcons.textformat,
                          label: 'Text',
                          isActive: _currentMode == EditMode.text,
                          onPressed: () => _switchMode(EditMode.text),
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
    );
  }

  Widget _buildDrawControls() {
    return Positioned(
      bottom: 130,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(20), width: 1),
            ),
            child: Column(
              children: [
                // Color selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      [
                        Colors.white,
                        Colors.red,
                        Colors.blue,
                        Colors.yellow,
                        Colors.green,
                      ].map((color) {
                        return GestureDetector(
                          onTap: () {
                            setState(() => _drawColor = color);
                            HapticFeedback.lightImpact();
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    _drawColor == color
                                        ? AppColors.accent
                                        : Colors.white.withAlpha(50),
                                width: 3,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),

                const SizedBox(height: 12),

                // Stroke width slider
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.pencil,
                      color: Colors.white.withAlpha(200),
                      size: 16,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CupertinoSlider(
                        value: _strokeWidth,
                        min: 1,
                        max: 20,
                        activeColor: AppColors.accent,
                        onChanged: (value) {
                          setState(() => _strokeWidth = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: _strokeWidth * 2,
                      height: _strokeWidth * 2,
                      decoration: BoxDecoration(
                        color: _drawColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCropControls() {
    return Positioned(
      bottom: 130,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(20), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  onPressed: _cancelCrop,
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: _applyCrop,
                  child: const Text(
                    'Apply Crop',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool isPrimary = false,
  }) {
    final isEnabled = onPressed != null;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color:
              isPrimary
                  ? (isEnabled
                      ? AppColors.accent
                      : AppColors.accent.withAlpha(100))
                  : (isEnabled
                      ? Colors.white.withAlpha(20)
                      : Colors.white.withAlpha(10)),
          shape: BoxShape.circle,
          border: Border.all(
            color:
                isEnabled
                    ? Colors.white.withAlpha(30)
                    : Colors.white.withAlpha(10),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: isEnabled ? Colors.white : Colors.white.withAlpha(100),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.accent : Colors.white,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color:
                    isActive ? AppColors.accent : Colors.white.withAlpha(200),
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for rendering
class ImageEditorPainter extends CustomPainter {
  final ui.Image? image;
  final Rect? cropRect;
  final List<DrawingPoint> drawingPoints;
  final List<TextOverlay> textOverlays;
  final Size imageSize;
  final TextOverlay? selectedText;

  ImageEditorPainter({
    this.image,
    this.cropRect,
    required this.drawingPoints,
    required this.textOverlays,
    required this.imageSize,
    this.selectedText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (image == null) return;

    // Calculate scale to fit image in canvas
    final scale = math.min(
      size.width / imageSize.width,
      size.height / imageSize.height,
    );

    final scaledWidth = imageSize.width * scale;
    final scaledHeight = imageSize.height * scale;
    final offset = Offset(
      (size.width - scaledWidth) / 2,
      (size.height - scaledHeight) / 2,
    );

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    // Draw the image
    canvas.drawImage(image!, Offset.zero, Paint());

    // Draw crop overlay if in crop mode
    if (cropRect != null) {
      // Darken everything outside crop rect
      final paint = Paint()..color = Colors.black.withAlpha(128);

      // Top
      canvas.drawRect(
        Rect.fromLTWH(0, 0, imageSize.width, cropRect!.top),
        paint,
      );

      // Bottom
      canvas.drawRect(
        Rect.fromLTWH(
          0,
          cropRect!.bottom,
          imageSize.width,
          imageSize.height - cropRect!.bottom,
        ),
        paint,
      );

      // Left
      canvas.drawRect(
        Rect.fromLTWH(0, cropRect!.top, cropRect!.left, cropRect!.height),
        paint,
      );

      // Right
      canvas.drawRect(
        Rect.fromLTWH(
          cropRect!.right,
          cropRect!.top,
          imageSize.width - cropRect!.right,
          cropRect!.height,
        ),
        paint,
      );

      // Draw crop border
      canvas.drawRect(
        cropRect!,
        Paint()
          ..color = AppColors.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Draw resize handles
      final handlePaint =
          Paint()
            ..color = AppColors.accent
            ..style = PaintingStyle.fill;

      const handleSize = 12.0;

      // Helper function to draw handle
      void drawHandle(Offset position) {
        canvas.drawCircle(position, handleSize / 2, handlePaint);
        canvas.drawCircle(
          position,
          handleSize / 2,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }

      // Corner handles
      drawHandle(cropRect!.topLeft);
      drawHandle(cropRect!.topRight);
      drawHandle(cropRect!.bottomLeft);
      drawHandle(cropRect!.bottomRight);

      // Mid-point handles
      drawHandle(Offset(cropRect!.center.dx, cropRect!.top));
      drawHandle(Offset(cropRect!.center.dx, cropRect!.bottom));
      drawHandle(Offset(cropRect!.left, cropRect!.center.dy));
      drawHandle(Offset(cropRect!.right, cropRect!.center.dy));

      // Draw grid lines
      final gridPaint =
          Paint()
            ..color = Colors.white.withAlpha(50)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5;

      // Vertical lines
      final thirdWidth = cropRect!.width / 3;
      canvas.drawLine(
        Offset(cropRect!.left + thirdWidth, cropRect!.top),
        Offset(cropRect!.left + thirdWidth, cropRect!.bottom),
        gridPaint,
      );
      canvas.drawLine(
        Offset(cropRect!.left + thirdWidth * 2, cropRect!.top),
        Offset(cropRect!.left + thirdWidth * 2, cropRect!.bottom),
        gridPaint,
      );

      // Horizontal lines
      final thirdHeight = cropRect!.height / 3;
      canvas.drawLine(
        Offset(cropRect!.left, cropRect!.top + thirdHeight),
        Offset(cropRect!.right, cropRect!.top + thirdHeight),
        gridPaint,
      );
      canvas.drawLine(
        Offset(cropRect!.left, cropRect!.top + thirdHeight * 2),
        Offset(cropRect!.right, cropRect!.top + thirdHeight * 2),
        gridPaint,
      );
    }

    // Draw drawing strokes
    for (final drawing in drawingPoints) {
      if (drawing.points.length > 1) {
        final paint =
            Paint()
              ..color = drawing.color
              ..strokeWidth = drawing.strokeWidth
              ..strokeCap = StrokeCap.round
              ..style = PaintingStyle.stroke;

        final path = Path();
        path.moveTo(drawing.points.first.dx, drawing.points.first.dy);

        for (int i = 1; i < drawing.points.length; i++) {
          path.lineTo(drawing.points[i].dx, drawing.points[i].dy);
        }

        canvas.drawPath(path, paint);
      }
    }

    // Draw text overlays
    for (final overlay in textOverlays) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: overlay.text,
          style: TextStyle(
            color: overlay.color,
            fontSize: overlay.fontSize,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withAlpha(150),
                blurRadius: 3,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Draw text centered at position
      textPainter.paint(
        canvas,
        overlay.position -
            Offset(textPainter.width / 2, textPainter.height / 2),
      );

      // Draw selection border if selected
      if (selectedText == overlay) {
        final rect = Rect.fromCenter(
          center: overlay.position,
          width: textPainter.width + 16,
          height: textPainter.height + 16,
        );

        canvas.drawRect(
          rect,
          Paint()
            ..color = AppColors.accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Models
enum EditMode { none, crop, draw, text }

enum ActionType { crop, draw, text }

enum CropHandle {
  none,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  top,
  bottom,
  left,
  right,
  move,
}

class EditAction {
  final ActionType type;
  final ui.Image? image;
  final List<DrawingPoint>? drawingPoints;
  final List<TextOverlay>? textOverlays;

  EditAction({
    required this.type,
    this.image,
    this.drawingPoints,
    this.textOverlays,
  });
}

class DrawingPoint {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  DrawingPoint({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
}

class TextOverlay {
  final String text;
  final Offset position;
  final Color color;
  final double fontSize;

  TextOverlay({
    required this.text,
    required this.position,
    required this.color,
    required this.fontSize,
  });
}
