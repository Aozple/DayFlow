import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dayflow/core/constants/app_colors.dart';

class FormattingToolbar extends StatefulWidget {
  final Function(String) onFormat;
  final VoidCallback onHide;
  final String? selectedText;

  const FormattingToolbar({
    super.key,
    required this.onFormat,
    required this.onHide,
    this.selectedText,
  });

  @override
  State<FormattingToolbar> createState() => _FormattingToolbarState();
}

class _FormattingToolbarState extends State<FormattingToolbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _hasClipboardContent = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
    _checkClipboard();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Check if clipboard has content for paste functionality
  void _checkClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (mounted) {
        setState(() {
          _hasClipboardContent = data?.text?.isNotEmpty == true;
        });
      }
    } catch (e) {
      // Clipboard access might fail, that's okay
    }
  }

  // Check if selected text is a URL
  bool _isURL(String text) {
    return text.startsWith('http://') ||
        text.startsWith('https://') ||
        text.startsWith('www.');
  }

  // Check if selected text is all caps
  bool _isAllCaps(String text) {
    return text == text.toUpperCase() && text != text.toLowerCase();
  }

  // Check if selected text has formatting markers
  bool _hasFormatting(String text) {
    return text.contains('**') ||
        text.contains('*') ||
        text.contains('`') ||
        text.contains('~~') ||
        text.contains('<u>');
  }

  @override
  Widget build(BuildContext context) {
    final selectedText = widget.selectedText ?? '';
    final isURL = _isURL(selectedText);
    final isAllCaps = _isAllCaps(selectedText);
    final hasFormatting = _hasFormatting(selectedText);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        elevation: 16,
        borderRadius: BorderRadius.circular(16),
        color: AppColors.surface,
        shadowColor: AppColors.accent.withAlpha(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accent.withAlpha(30), width: 1),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.surface, AppColors.surface.withAlpha(240)],
            ),
          ),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main actions row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Clipboard actions section
                    _buildActionGroup([
                      _buildActionButton(
                        Icons.content_copy_rounded,
                        'Copy',
                        () => _handleCopy(),
                        color: Colors.blue,
                      ),
                      _buildActionButton(
                        Icons.content_cut_rounded,
                        'Cut',
                        () => _handleCut(),
                        color: Colors.orange,
                      ),
                      if (_hasClipboardContent)
                        _buildActionButton(
                          Icons.content_paste_rounded,
                          'Paste',
                          () => _handlePaste(),
                          color: Colors.green,
                        ),
                    ]),

                    _buildDivider(),

                    // Formatting actions section
                    _buildActionGroup([
                      _buildActionButton(
                        Icons.format_bold_rounded,
                        'Bold',
                        () => _handleFormat('bold'),
                        isToggleable: true,
                      ),
                      _buildActionButton(
                        Icons.format_italic_rounded,
                        'Italic',
                        () => _handleFormat('italic'),
                        isToggleable: true,
                      ),
                      _buildActionButton(
                        Icons.format_underlined_rounded,
                        'Underline',
                        () => _handleFormat('underline'),
                        isToggleable: true,
                      ),
                      _buildActionButton(
                        Icons.strikethrough_s_rounded,
                        'Strikethrough',
                        () => _handleFormat('strikethrough'),
                        isToggleable: true,
                      ),
                      _buildActionButton(
                        Icons.code_rounded,
                        'Code',
                        () => _handleFormat('code'),
                        isToggleable: true,
                      ),
                    ]),
                  ],
                ),

                // Smart contextual actions (second row if needed)
                if (isURL ||
                    isAllCaps ||
                    hasFormatting ||
                    selectedText.length > 10)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // URL specific actions
                        if (isURL) ...[
                          _buildSmartAction(
                            Icons.link_rounded,
                            'Link',
                            () => _handleFormat('link'),
                            color: Colors.purple,
                          ),
                        ],

                        // Text case actions
                        if (selectedText.length > 1 && !isURL) ...[
                          if (isAllCaps)
                            _buildSmartAction(
                              Icons.text_fields_rounded,
                              'Lowercase',
                              () => _handleFormat('lowercase'),
                              color: Colors.indigo,
                            )
                          else
                            _buildSmartAction(
                              Icons.format_size_rounded,
                              'Uppercase',
                              () => _handleFormat('uppercase'),
                              color: Colors.indigo,
                            ),

                          _buildSmartAction(
                            Icons.title_rounded,
                            'Title Case',
                            () => _handleFormat('titlecase'),
                            color: Colors.teal,
                          ),
                        ],

                        // Clear formatting if has formatting
                        if (hasFormatting) ...[
                          _buildSmartAction(
                            Icons.format_clear_rounded,
                            'Clear Format',
                            () => _handleFormat('clear'),
                            color: Colors.red,
                          ),
                        ],

                        // Select all for long text
                        if (selectedText.length > 10) ...[
                          _buildSmartAction(
                            Icons.select_all_rounded,
                            'Select All',
                            () => _handleFormat('selectall'),
                            color: Colors.grey,
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build action group with spacing
  Widget _buildActionGroup(List<Widget> actions) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children:
          actions
              .map(
                (action) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: action,
                ),
              )
              .toList(),
    );
  }

  // Build main action button
  Widget _buildActionButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed, {
    Color? color,
    bool isToggleable = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: color?.withAlpha(15) ?? Colors.transparent,
              border:
                  color != null
                      ? Border.all(color: color.withAlpha(30), width: 0.5)
                      : null,
            ),
            child: Icon(icon, size: 18, color: color ?? AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  // Build smart contextual action (smaller)
  Widget _buildSmartAction(
    IconData icon,
    String tooltip,
    VoidCallback onPressed, {
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: color?.withAlpha(10) ?? Colors.transparent,
            ),
            child: Icon(
              icon,
              size: 14,
              color: color ?? AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // Build divider
  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.divider.withAlpha(0),
            AppColors.divider.withAlpha(100),
            AppColors.divider.withAlpha(0),
          ],
        ),
      ),
    );
  }

  // Enhanced action handlers
  void _handleCopy() {
    if (widget.selectedText != null && widget.selectedText!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: widget.selectedText!));
      HapticFeedback.lightImpact();
      _showFeedback('Copied');
    }
    widget.onHide();
  }

  void _handleCut() {
    if (widget.selectedText != null && widget.selectedText!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: widget.selectedText!));
      widget.onFormat('delete');
      HapticFeedback.lightImpact();
      _showFeedback('Cut');
    }
    widget.onHide();
  }

  void _handlePaste() {
    widget.onFormat('paste');
    HapticFeedback.lightImpact();
    _showFeedback('Pasted');
    widget.onHide();
  }

  void _handleFormat(String format) {
    widget.onFormat(format);
    HapticFeedback.lightImpact();

    // Don't hide immediately for some actions
    if (['uppercase', 'lowercase', 'titlecase', 'clear'].contains(format)) {
      _showFeedback('Applied');
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onHide();
      });
    } else {
      widget.onHide();
    }
  }

  // Show brief feedback
  void _showFeedback(String message) {
    // You can implement a brief toast or snackbar here if needed
    // For now, just haptic feedback
    HapticFeedback.lightImpact();
  }
}
