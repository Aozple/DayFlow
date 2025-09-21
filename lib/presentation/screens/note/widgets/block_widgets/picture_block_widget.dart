import 'dart:async';
import 'dart:io';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/presentation/widgets/frosted_glass_image_editor.dart';
import 'package:dayflow/presentation/widgets/full_screen_image_viewer.dart';
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

        // Open image editor with Frosted Glass design
        await Navigator.push<Uint8List?>(
          context,
          MaterialPageRoute(
            builder:
                (context) => FrostedGlassImageEditor(
                  imageBytes: imageBytes,
                  onComplete: (bytes) async {
                    DebugLogger.debug(
                      'Image editing completed',
                      tag: 'ImageEditor',
                      data: '${bytes.length} bytes',
                    );
                    // Save the edited image when user confirms
                    await _saveEditedImage(bytes);
                  },
                ),
          ),
        );

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
                borderRadius: BorderRadius.circular(12),
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
            (context) => FullScreenImageViewer(
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
