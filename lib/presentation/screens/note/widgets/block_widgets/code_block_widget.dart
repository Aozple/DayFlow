import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/data/models/note_block.dart';
import 'base_block_widget.dart';

class CodeBlockWidget extends BaseBlockWidget {
  final CodeBlock block;
  final Function(CodeBlock) onChanged;

  CodeBlockWidget({
    super.key,
    required this.block,
    required super.focusNode,
    required this.onChanged,
    required super.onSelectionChanged,
    required super.onTextChange,
  }) : super(blockId: block.id);

  @override
  Widget buildContent(BuildContext context) {
    return _CodeFieldWidget(
      block: block,
      focusNode: focusNode,
      onChanged: onChanged,
      onSelectionChanged: onSelectionChanged,
      onTextChange: onTextChange,
    );
  }
}

class _CodeFieldWidget extends StatefulWidget {
  final CodeBlock block;
  final FocusNode focusNode;
  final Function(CodeBlock) onChanged;
  final Function(TextSelection) onSelectionChanged;
  final Function(String, String) onTextChange;

  const _CodeFieldWidget({
    required this.block,
    required this.focusNode,
    required this.onChanged,
    required this.onSelectionChanged,
    required this.onTextChange,
  });

  @override
  State<_CodeFieldWidget> createState() => _CodeFieldWidgetState();
}

class _CodeFieldWidgetState extends State<_CodeFieldWidget> {
  late TextEditingController _controller;
  bool _isDisposed = false;
  String _selectedLanguage = 'plain';
  bool _showLineNumbers = true;

  // Popular programming languages
  final List<_LanguageOption> _languages = [
    const _LanguageOption('plain', 'Plain Text', Colors.grey),
    const _LanguageOption('dart', 'Dart', Colors.blue),
    const _LanguageOption('javascript', 'JavaScript', Colors.yellow),
    const _LanguageOption('python', 'Python', Colors.green),
    const _LanguageOption('java', 'Java', Colors.orange),
    const _LanguageOption('swift', 'Swift', Colors.orange),
    const _LanguageOption('kotlin', 'Kotlin', Colors.purple),
    const _LanguageOption('cpp', 'C++', Colors.blue),
    const _LanguageOption('csharp', 'C#', Colors.purple),
    const _LanguageOption('html', 'HTML', Colors.orange),
    const _LanguageOption('css', 'CSS', Colors.blue),
    const _LanguageOption('sql', 'SQL', Colors.cyan),
    const _LanguageOption('json', 'JSON', Colors.green),
    const _LanguageOption('yaml', 'YAML', Colors.red),
    const _LanguageOption('markdown', 'Markdown', Colors.grey),
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.code);
    _controller.addListener(_onTextChanged);
    _controller.addListener(_onSelectionChanged);
    _selectedLanguage = widget.block.language ?? 'plain';
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_CodeFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.code != widget.block.code && !_isDisposed) {
      if (_controller.text != widget.block.code) {
        _controller.text = widget.block.code;
      }
    }
    if (oldWidget.block.language != widget.block.language) {
      _selectedLanguage = widget.block.language ?? 'plain';
    }
  }

  void _onTextChanged() {
    if (_isDisposed) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        widget.onChanged(widget.block.copyWith(code: _controller.text));
        widget.onTextChange(_controller.text, widget.block.id);
      }
    });
  }

  void _onSelectionChanged() {
    if (_isDisposed || !mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        widget.onSelectionChanged(_controller.selection);
      }
    });
  }

  // Get line numbers for the code
  List<int> _getLineNumbers() {
    if (_controller.text.isEmpty) return [1];
    return List.generate(
      _controller.text.split('\n').length,
      (index) => index + 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withAlpha(50), width: 1),
      ),
      child: Column(
        children: [
          // Header with language selector and actions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withAlpha(50),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.divider.withAlpha(50),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Language selector
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background.withAlpha(100),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: PopupMenuButton<String>(
                    initialValue: _selectedLanguage,
                    onSelected: (value) {
                      setState(() {
                        _selectedLanguage = value;
                      });
                      widget.onChanged(widget.block.copyWith(language: value));
                    },
                    itemBuilder:
                        (context) =>
                            _languages.map((lang) {
                              return PopupMenuItem(
                                value: lang.code,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: lang.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Text(lang.name),
                                  ],
                                ),
                              );
                            }).toList(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.code,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _languages
                              .firstWhere((l) => l.code == _selectedLanguage)
                              .name,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Line numbers toggle
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showLineNumbers = !_showLineNumbers;
                    });
                  },
                  icon: Icon(
                    Icons.format_list_numbered,
                    size: 18,
                    color:
                        _showLineNumbers
                            ? AppColors.accent
                            : AppColors.textTertiary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  tooltip: 'Toggle line numbers',
                ),

                // Copy button
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.block.code));
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Code copied to clipboard'),
                        backgroundColor: AppColors.surface,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.content_copy,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  tooltip: 'Copy code',
                ),
              ],
            ),
          ),

          // Code content area
          Container(
            constraints: const BoxConstraints(minHeight: 100),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line numbers
                if (_showLineNumbers)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background.withAlpha(50),
                      border: Border(
                        right: BorderSide(
                          color: AppColors.divider.withAlpha(30),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children:
                          _getLineNumbers().map((lineNumber) {
                            return Container(
                              height: 24,
                              alignment: Alignment.centerRight,
                              child: Text(
                                lineNumber.toString(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textTertiary,
                                  fontFamily: 'monospace',
                                  height: 1.5,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),

                // Code editor
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _controller,
                      focusNode: widget.focusNode,
                      maxLines: null,
                      enableInteractiveSelection: true,
                      selectionControls: _CustomTextSelectionControls(),
                      decoration: const InputDecoration(
                        hintText: 'Paste or type your code here...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        hintStyle: TextStyle(
                          color: Color(0xFF48484A),
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: _getCodeColor(),
                        fontFamily: 'monospace',
                      ),
                      onTap: _onSelectionChanged,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Get code color based on language
  Color _getCodeColor() {
    final lang = _languages.firstWhere((l) => l.code == _selectedLanguage);
    return lang.color.withAlpha(200);
  }
}

// Language option model
class _LanguageOption {
  final String code;
  final String name;
  final Color color;

  const _LanguageOption(this.code, this.name, this.color);
}

// Custom selection controls
class _CustomTextSelectionControls extends MaterialTextSelectionControls {
  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueListenable<ClipboardStatus>? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    return const SizedBox.shrink();
  }
}
