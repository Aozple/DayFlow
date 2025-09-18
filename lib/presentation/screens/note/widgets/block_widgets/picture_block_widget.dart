import 'dart:async';
import 'dart:io';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/presentation/widgets/image_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/note_block.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'base_block_widget.dart';

class PictureBlockWidget extends BaseBlockWidget {
  final PictureBlock block;
  final Function(PictureBlock) onChanged;

  PictureBlockWidget({
    super.key,
    required this.block,
    required super.focusNode,
    required this.onChanged,
    required super.onSelectionChanged,
    required super.onTextChange,
  }) : super(blockId: block.id);

  @override
  Widget buildContent(BuildContext context) {
    DebugLogger.debug(
      'Building picture block content',
      tag: 'PictureBlock',
      data: 'Block ID: ${block.id}',
    );
    return _PictureBlockContent(
      block: block,
      focusNode: focusNode,
      onChanged: onChanged,
    );
  }
}

class _PictureBlockContent extends StatefulWidget {
  final PictureBlock block;
  final FocusNode focusNode;
  final Function(PictureBlock) onChanged;

  const _PictureBlockContent({
    required this.block,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  State<_PictureBlockContent> createState() => _PictureBlockContentState();
}

class _PictureBlockContentState extends State<_PictureBlockContent>
    with SingleTickerProviderStateMixin {
  // Image picker and controllers
  final ImagePicker _picker = ImagePicker();
  late TextEditingController _captionController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // State management
  bool _isLoading = false;
  bool _isEditingCaption = false;
  bool _isEditingImage = false; // New flag to prevent multiple editor opens
  TextDirection _captionDirection = TextDirection.ltr;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    DebugLogger.debug(
      'Initializing picture block widget',
      tag: 'PictureBlock',
      data: 'Block ID: ${widget.block.id}',
    );
    _initializeControllers();
    _loadImage();
  }

  @override
  void dispose() {
    DebugLogger.debug('Disposing picture block widget', tag: 'PictureBlock');
    _captionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Initialize all controllers and animations
  void _initializeControllers() {
    DebugLogger.debug('Initializing controllers', tag: 'PictureBlock');

    _captionController = TextEditingController(
      text: widget.block.caption ?? '',
    );
    _captionController.addListener(_updateCaptionDirection);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
  }

  // Load existing image from storage
  void _loadImage() {
    if (widget.block.imagePath != null && widget.block.imagePath!.isNotEmpty) {
      final imageFile = File(widget.block.imagePath!);
      if (imageFile.existsSync()) {
        DebugLogger.success(
          'Image loaded successfully',
          tag: 'PictureBlock',
          data: widget.block.imagePath,
        );
        setState(() {
          _imageFile = imageFile;
        });
      } else {
        DebugLogger.warning(
          'Image file not found',
          tag: 'PictureBlock',
          data: widget.block.imagePath,
        );
      }
    }
  }

  // Detect text direction for RTL languages
  void _updateCaptionDirection() {
    final text = _captionController.text;
    if (text.isEmpty) return;

    final firstChar = text.trim().runes.first;
    final isRTL = _isRTLCharacter(firstChar);
    final newDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    if (_captionDirection != newDirection) {
      DebugLogger.debug(
        'Caption direction changed',
        tag: 'PictureBlock',
        data: 'RTL: $isRTL',
      );
      setState(() => _captionDirection = newDirection);
    }
  }

  // Check if character is RTL (Arabic, Hebrew, etc.)
  bool _isRTLCharacter(int char) {
    return (char >= 0x0600 && char <= 0x06FF) || // Arabic
        (char >= 0x0750 && char <= 0x077F) || // Arabic Supplement
        (char >= 0xFB50 && char <= 0xFDFF) || // Arabic Presentation Forms
        (char >= 0xFE70 && char <= 0xFEFF) || // Arabic Presentation Forms-B
        (char >= 0x0590 && char <= 0x05FF); // Hebrew
  }

  // Pick image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    if (_isLoading || _isEditingImage) {
      DebugLogger.warning(
        'Image picker already in progress',
        tag: 'ImagePicker',
      );
      return;
    }

    DebugLogger.info(
      'Starting image picker',
      tag: 'ImagePicker',
      data: 'Source: ${source.name}',
    );

    setState(() => _isLoading = true);

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        DebugLogger.success(
          'Image picked successfully',
          tag: 'ImagePicker',
          data: pickedFile.path,
        );

        if (mounted) {
          await _openImageEditor(pickedFile.path);
        }
      } else {
        DebugLogger.info('User canceled image picker', tag: 'ImagePicker');
      }
    } catch (e) {
      DebugLogger.error('Failed to pick image', error: e, tag: 'ImagePicker');
      if (mounted) _showError('Failed to pick image');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Open ProImageEditor with proper error handling
  Future<void> _openImageEditor(String imagePath) async {
    if (_isEditingImage) {
      DebugLogger.warning('Image editor already open', tag: 'ImageEditor');
      return;
    }

    await DebugLogger.timeOperation('OpenImageEditor', () async {
      try {
        setState(() => _isEditingImage = true);

        final imageFile = File(imagePath);
        if (!await imageFile.exists()) {
          DebugLogger.warning(
            'Image file not found',
            tag: 'ImageEditor',
            data: imagePath,
          );
          if (mounted) _showError('Image not found');
          return;
        }

        final imageBytes = await imageFile.readAsBytes();

        DebugLogger.debug(
          'Image loaded for editing',
          tag: 'ImageEditor',
          data: '${imageBytes.length} bytes',
        );

        if (!mounted) {
          DebugLogger.debug('Widget not mounted, aborting', tag: 'ImageEditor');
          return;
        }

        // Open simple image editor
        final result = await Navigator.push<Uint8List?>(
          context,
          MaterialPageRoute(
            builder:
                (context) => ImageEditor(
                  imageBytes: imageBytes,
                  onSave: (editedBytes) {
                    Navigator.of(context).pop(editedBytes);
                  },
                  onCancel: () {
                    Navigator.of(context).pop();
                  },
                ),
          ),
        );

        if (result != null && mounted) {
          await _saveEditedImage(result);
        }

        DebugLogger.success(
          'Image editor completed successfully',
          tag: 'ImageEditor',
        );
      } catch (e, st) {
        DebugLogger.error(
          'Failed to edit image',
          tag: 'ImageEditor',
          error: e,
          stackTrace: st,
        );
        if (mounted) _showError('Failed to edit image');
      } finally {
        if (mounted) {
          setState(() => _isEditingImage = false);
        }
      }
    });
  }

  // Save edited image to app directory
  Future<void> _saveEditedImage(Uint8List imageBytes) async {
    DebugLogger.debug(
      'Starting to save edited image',
      tag: 'ImageSaver',
      data: '${imageBytes.length} bytes',
    );

    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imagePath = path.join(directory.path, 'images', fileName);

      final imageFile = File(imagePath);
      await imageFile.parent.create(recursive: true);
      await imageFile.writeAsBytes(imageBytes);

      DebugLogger.success(
        'Image saved successfully',
        tag: 'ImageSaver',
        data: imagePath,
      );

      if (mounted) {
        setState(() => _imageFile = imageFile);
        widget.onChanged(widget.block.copyWith(imagePath: imagePath));
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      DebugLogger.error('Failed to save image', error: e, tag: 'ImageSaver');
      if (mounted) _showError('Failed to save image');
    }
  }

  // Edit existing image
  Future<void> _editExistingImage() async {
    if (_imageFile != null && _imageFile!.existsSync() && !_isEditingImage) {
      DebugLogger.info(
        'Starting to edit existing image',
        tag: 'ImageEditor',
        data: _imageFile!.path,
      );
      await _openImageEditor(_imageFile!.path);
    } else {
      DebugLogger.warning(
        'Cannot edit image',
        tag: 'ImageEditor',
        data:
            'File exists: ${_imageFile?.existsSync()}, Is editing: $_isEditingImage',
      );
    }
  }

  // Show image source selection dialog
  void _showImageSourceDialog() {
    if (_isLoading || _isEditingImage) {
      DebugLogger.warning(
        'Cannot show image source dialog - operation in progress',
        tag: 'ImagePicker',
      );
      return;
    }

    DebugLogger.debug('Showing image source dialog', tag: 'ImagePicker');
    HapticFeedback.lightImpact();

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: const Text('Add Image'),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.camera_fill, color: AppColors.accent),
                    const SizedBox(width: 8),
                    const Text('Take Photo'),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.photo_fill, color: AppColors.accent),
                    const SizedBox(width: 8),
                    const Text('Choose from Gallery'),
                  ],
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () {
                DebugLogger.debug(
                  'Image source dialog canceled',
                  tag: 'ImagePicker',
                );
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ),
    );
  }

  // Remove image with confirmation
  void _removeImage() {
    if (_isLoading || _isEditingImage) {
      DebugLogger.warning(
        'Cannot remove image - operation in progress',
        tag: 'PictureBlock',
      );
      return;
    }

    DebugLogger.debug('Showing remove image dialog', tag: 'PictureBlock');
    HapticFeedback.lightImpact();

    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Remove Image?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () {
                  DebugLogger.debug(
                    'Remove image canceled',
                    tag: 'PictureBlock',
                  );
                  Navigator.pop(context);
                },
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  DebugLogger.info('Removing image', tag: 'PictureBlock');
                  setState(() => _imageFile = null);
                  widget.onChanged(
                    widget.block.copyWith(imagePath: '', imageUrl: ''),
                  );
                  DebugLogger.success(
                    'Image removed successfully',
                    tag: 'PictureBlock',
                  );
                },
                child: const Text('Remove'),
              ),
            ],
          ),
    );
  }

  // Update caption and exit edit mode
  void _updateCaption() {
    DebugLogger.debug(
      'Updating caption',
      tag: 'PictureBlock',
      data: _captionController.text,
    );

    widget.onChanged(widget.block.copyWith(caption: _captionController.text));
    setState(() => _isEditingCaption = false);
    HapticFeedback.lightImpact();

    DebugLogger.success('Caption updated successfully', tag: 'PictureBlock');
  }

  // Show error message to user
  void _showError(String message) {
    if (!mounted) return;

    DebugLogger.error(
      'Showing error to user',
      tag: 'PictureBlock',
      error: message,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  // Build main image content area
  Widget _buildImageContent() {
    if (_imageFile == null || !_imageFile!.existsSync()) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        // Main image with hero animation
        Hero(
          tag: 'image_${widget.block.id}',
          child: GestureDetector(
            onTap: () => _showFullScreenImage(),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 400),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _imageFile!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    DebugLogger.error(
                      'Failed to load image for display',
                      error: error,
                      tag: 'PictureBlock',
                    );
                    return _buildErrorWidget();
                  },
                ),
              ),
            ),
          ),
        ),

        // Action buttons overlay
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withAlpha(200),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _buildActionButton(
                  icon: CupertinoIcons.trash,
                  tooltip: 'Remove',
                  onPressed:
                      (_isLoading || _isEditingImage) ? null : _removeImage,
                  isDestructive: true,
                ),
                const SizedBox(width: 4),
                _buildActionButton(
                  icon: CupertinoIcons.arrow_2_circlepath,
                  tooltip: 'Replace',
                  onPressed:
                      (_isLoading || _isEditingImage)
                          ? null
                          : _showImageSourceDialog,
                ),
                const SizedBox(width: 4),
                _buildActionButton(
                  icon: CupertinoIcons.pencil,
                  tooltip: 'Edit',
                  onPressed: _isEditingImage ? null : _editExistingImage,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Build empty state when no image is selected
  Widget _buildEmptyState() {
    return GestureDetector(
      onTap: (_isLoading || _isEditingImage) ? null : _showImageSourceDialog,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.surface.withAlpha(20),
              AppColors.surface.withAlpha(10),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.divider.withAlpha(30),
            width: 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.photo_on_rectangle,
              size: 48,
              color: AppColors.textSecondary.withAlpha(100),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap to add image',
              style: TextStyle(
                color: AppColors.textSecondary.withAlpha(150),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Camera • Gallery',
              style: TextStyle(
                color: AppColors.textTertiary.withAlpha(100),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build error widget when image fails to load
  Widget _buildErrorWidget() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withAlpha(30), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 12),
          const Text(
            'Failed to load image',
            style: TextStyle(
              color: AppColors.error,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onPressed:
                (_isLoading || _isEditingImage) ? null : _showImageSourceDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Try again',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build caption input field
  Widget _buildCaptionField() {
    if (!widget.block.hasImage && !_isEditingCaption) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              _isEditingCaption
                  ? AppColors.accent.withAlpha(50)
                  : AppColors.divider.withAlpha(20),
          width: 1,
        ),
      ),
      child:
          _isEditingCaption
              ? Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _captionController,
                      focusNode: widget.focusNode,
                      textDirection: _captionDirection,
                      textAlign:
                          _captionDirection == TextDirection.rtl
                              ? TextAlign.right
                              : TextAlign.left,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            _captionDirection == TextDirection.rtl
                                ? 'توضیحات تصویر...'
                                : 'Add caption...',
                        hintStyle: TextStyle(
                          color: AppColors.textTertiary.withAlpha(100),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      onSubmitted: (_) => _updateCaption(),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(28, 28),
                    onPressed: _updateCaption,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        CupertinoIcons.check_mark,
                        size: 16,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              )
              : GestureDetector(
                onTap: () {
                  DebugLogger.debug(
                    'Starting caption editing',
                    tag: 'PictureBlock',
                  );
                  setState(() => _isEditingCaption = true);
                  HapticFeedback.lightImpact();
                },
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.text_cursor,
                      size: 14,
                      color: AppColors.textTertiary.withAlpha(100),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.block.caption?.isNotEmpty == true
                            ? widget.block.caption!
                            : _captionDirection == TextDirection.rtl
                            ? 'اضافه کردن توضیحات...'
                            : 'Add caption...',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              widget.block.caption?.isNotEmpty == true
                                  ? AppColors.textSecondary
                                  : AppColors.textTertiary.withAlpha(100),
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign:
                            _captionDirection == TextDirection.rtl
                                ? TextAlign.right
                                : TextAlign.left,
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  // Build action button with proper state handling
  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    bool isDestructive = false,
  }) {
    final isDisabled = onPressed == null;

    return Tooltip(
      message: tooltip,
      child: CupertinoButton(
        padding: const EdgeInsets.all(2),
        minimumSize: const Size(24, 24),
        onPressed: onPressed,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color:
                isDestructive
                    ? AppColors.error.withAlpha(isDisabled ? 5 : 15)
                    : AppColors.surface.withAlpha(isDisabled ? 20 : 50),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color:
                  isDestructive
                      ? AppColors.error.withAlpha(isDisabled ? 10 : 30)
                      : AppColors.divider.withAlpha(isDisabled ? 10 : 30),
              width: 0.5,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color:
                isDestructive
                    ? (isDisabled
                        ? AppColors.error.withAlpha(50)
                        : AppColors.error)
                    : (isDisabled
                        ? AppColors.textSecondary.withAlpha(50)
                        : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  // Show full screen image viewer
  void _showFullScreenImage() {
    if (_imageFile == null || !_imageFile!.existsSync()) return;

    DebugLogger.debug(
      'Opening full screen image viewer',
      tag: 'PictureBlock',
      data: _imageFile!.path,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => _FullScreenImage(
              imageFile: _imageFile!,
              heroTag: 'image_${widget.block.id}',
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Loading indicator or image content
            if (_isLoading)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.surface.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CupertinoActivityIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        'Processing image...',
                        style: TextStyle(
                          color: AppColors.textSecondary.withAlpha(150),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildImageContent(),

            // Caption input field
            _buildCaptionField(),
          ],
        ),
      ),
    );
  }
}

// Professional full screen image viewer widget
class _FullScreenImage extends StatefulWidget {
  final File imageFile;
  final String heroTag;

  const _FullScreenImage({required this.imageFile, required this.heroTag});

  @override
  State<_FullScreenImage> createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<_FullScreenImage>
    with TickerProviderStateMixin {
  // Controllers
  late TransformationController _transformationController;
  late AnimationController _overlayAnimationController;
  late AnimationController _transformAnimationController;
  late Animation<double> _overlayAnimation;
  late Animation<Matrix4> _transformAnimation;

  // State
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

  // Initialize all controllers and animations
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

  // Load image information
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

  // Format file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  // Toggle overlay visibility
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

  // Auto-hide overlay after delay
  void _startOverlayTimer() {
    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showOverlay) {
        setState(() => _showOverlay = false);
        _overlayAnimationController.reverse();
      }
    });
  }

  // Handle double tap to zoom at specific location
  // Handle double tap to zoom at specific location
  void _handleDoubleTap() {
    final isZoomedIn = _currentScale > 1.5;

    if (isZoomedIn) {
      // Reset zoom
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

      // Zoom in at tap location
      final tapPosition = _doubleTapDetails!.localPosition;
      const targetScale = 2.5;

      // Get current matrix values
      final currentMatrix = _transformationController.value;
      final currentScale = currentMatrix.getMaxScaleOnAxis();
      final currentTranslation = currentMatrix.getTranslation();

      // Calculate the position of the tap in the scaled coordinate system
      final scaledTapX = (tapPosition.dx - currentTranslation.x) / currentScale;
      final scaledTapY = (tapPosition.dy - currentTranslation.y) / currentScale;

      // Calculate new translation to center the tap point
      final newTranslationX = tapPosition.dx - (scaledTapX * targetScale);
      final newTranslationY = tapPosition.dy - (scaledTapY * targetScale);

      // Create target matrix
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

  // Reset zoom to fit screen
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

  // Share image functionality
  Future<void> _shareImage() async {
    try {
      // This would require the share_plus package
      // await Share.shareXFiles([XFile(widget.imageFile.path)]);

      // For now, just show a placeholder
      _showSnackBar('Share functionality would be implemented here');

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

  // Show image details bottom sheet
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
                // Handle bar
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

                // Title
                const Text(
                  'Image Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Details
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

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        color: AppColors.accent.withAlpha(50),
                        borderRadius: BorderRadius.circular(12),
                        onPressed: () {
                          Navigator.pop(context);
                          _shareImage();
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.share, color: AppColors.accent),
                            const SizedBox(width: 8),
                            Text(
                              'Share',
                              style: TextStyle(color: AppColors.accent),
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

  // Build detail row widget
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

  // Show snackbar message
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

  // Build action button
  Widget _buildActionButton({
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
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(150),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(30), width: 1),
          ),
          child: Icon(icon, color: iconColor ?? Colors.white, size: 22),
        ),
      ),
    );
  }

  // Build zoom indicator
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
          children: [
            // Main image with zoom capabilities
            Center(
              child: Hero(
                tag: widget.heroTag,
                child: GestureDetector(
                  onDoubleTap: _handleDoubleTap,
                  onDoubleTapDown: (details) {
                    // Capture position exactly when double tap starts
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
                          // Reset overlay timer on interaction
                          if (_showOverlay) _startOverlayTimer();
                        },
                        child: Image.file(
                          widget.imageFile,
                          fit: BoxFit.contain,
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
            ),

            // Loading indicator
            if (_isLoading)
              const Center(
                child: CupertinoActivityIndicator(
                  color: Colors.white,
                  radius: 16,
                ),
              ),

            // Top overlay with controls
            AnimatedBuilder(
              animation: _overlayAnimation,
              builder: (context, child) {
                return Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Transform.translate(
                    offset: Offset(0, -100 * (1 - _overlayAnimation.value)),
                    child: Opacity(
                      opacity: _overlayAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withAlpha(200),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Close button
                                _buildActionButton(
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

                                const Spacer(),

                                // Reset zoom button (only show when zoomed)
                                if (_currentScale > 1.1)
                                  _buildActionButton(
                                    icon: CupertinoIcons.zoom_out,
                                    tooltip: 'Reset Zoom',
                                    onPressed: _resetZoom,
                                    iconColor: AppColors.accent,
                                  ),

                                if (_currentScale > 1.1)
                                  const SizedBox(width: 12),

                                // Share button
                                _buildActionButton(
                                  icon: CupertinoIcons.share,
                                  tooltip: 'Share',
                                  onPressed: _shareImage,
                                ),

                                const SizedBox(width: 12),

                                // Info button
                                _buildActionButton(
                                  icon: CupertinoIcons.info,
                                  tooltip: 'Details',
                                  onPressed: _showImageDetails,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Bottom overlay with image info
            AnimatedBuilder(
              animation: _overlayAnimation,
              builder: (context, child) {
                return Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Transform.translate(
                    offset: Offset(0, 100 * (1 - _overlayAnimation.value)),
                    child: Opacity(
                      opacity: _overlayAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withAlpha(200),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Image info
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

                                // Instructions
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
                  ),
                );
              },
            ),

            // Zoom indicator (top right)
            Positioned(
              top: 100,
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
