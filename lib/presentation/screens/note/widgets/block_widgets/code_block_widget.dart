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
    return _CodeEditorWidget(
      block: block,
      focusNode: focusNode,
      onChanged: onChanged,
      onSelectionChanged: onSelectionChanged,
      onTextChange: onTextChange,
    );
  }
}

class _CodeEditorWidget extends StatefulWidget {
  final CodeBlock block;
  final FocusNode focusNode;
  final Function(CodeBlock) onChanged;
  final Function(TextSelection) onSelectionChanged;
  final Function(String, String) onTextChange;

  const _CodeEditorWidget({
    required this.block,
    required this.focusNode,
    required this.onChanged,
    required this.onSelectionChanged,
    required this.onTextChange,
  });

  @override
  State<_CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends State<_CodeEditorWidget> {
  late TextEditingController _controller;
  late ScrollController _scrollController;
  String _selectedLanguage = 'dart';
  bool _showLineNumbers = true;
  bool _wordWrap = false;

  // Language configurations
  late final Map<String, LanguageConfig> _languages;

  @override
  void initState() {
    super.initState();
    _initializeLanguages();
    _controller = TextEditingController(text: widget.block.code);
    _scrollController = ScrollController();
    _selectedLanguage = widget.block.language ?? 'dart';

    _controller.addListener(() {
      widget.onChanged(widget.block.copyWith(code: _controller.text));
      widget.onTextChange(_controller.text, widget.block.id);
      setState(() {}); // Rebuild for syntax highlighting
    });
  }

  void _initializeLanguages() {
    _languages = {
      'dart': const LanguageConfig(
        name: 'Dart',
        icon: Icons.flutter_dash,
        primaryColor: Color(0xFF40C4FF),
        keywords: {
          'class',
          'void',
          'final',
          'const',
          'var',
          'if',
          'else',
          'return',
          'import',
          'extends',
          'implements',
          'static',
          'async',
          'await',
          'try',
          'catch',
          'throw',
          'new',
          'this',
          'super',
          'null',
          'true',
          'false',
        },
        keywordColor: Color(0xFF569CD6),
        stringColor: Color(0xFFCE9178),
        commentColor: Color(0xFF6A9955),
        numberColor: Color(0xFFB5CEA8),
      ),
      'javascript': const LanguageConfig(
        name: 'JavaScript',
        icon: Icons.javascript,
        primaryColor: Color(0xFFF7DF1E),
        keywords: {
          'function',
          'const',
          'let',
          'var',
          'if',
          'else',
          'return',
          'class',
          'new',
          'async',
          'await',
          'for',
          'while',
          'do',
          'switch',
          'case',
          'break',
          'continue',
          'typeof',
          'instanceof',
          'true',
          'false',
          'null',
          'undefined',
        },
        keywordColor: Color(0xFFC586C0),
        stringColor: Color(0xFFCE9178),
        commentColor: Color(0xFF6A9955),
        numberColor: Color(0xFFB5CEA8),
      ),
      'python': const LanguageConfig(
        name: 'Python',
        icon: Icons.code,
        primaryColor: Color(0xFF3776AB),
        keywords: {
          'def',
          'class',
          'if',
          'else',
          'elif',
          'return',
          'import',
          'from',
          'as',
          'try',
          'except',
          'with',
          'for',
          'while',
          'break',
          'continue',
          'pass',
          'lambda',
          'True',
          'False',
          'None',
          'and',
          'or',
          'not',
          'in',
        },
        keywordColor: Color(0xFF569CD6),
        stringColor: Color(0xFFCE9178),
        commentColor: Color(0xFF6A9955),
        numberColor: Color(0xFFB5CEA8),
      ),
      'html': const LanguageConfig(
        name: 'HTML',
        icon: Icons.html,
        primaryColor: Color(0xFFE34C26),
        keywords: {
          'html',
          'head',
          'body',
          'div',
          'span',
          'p',
          'a',
          'img',
          'ul',
          'li',
          'table',
          'form',
          'input',
          'button',
          'script',
          'style',
          'link',
          'meta',
        },
        keywordColor: Color(0xFF569CD6),
        stringColor: Color(0xFFCE9178),
        commentColor: Color(0xFF6A9955),
        numberColor: Color(0xFFB5CEA8),
      ),
      'css': const LanguageConfig(
        name: 'CSS',
        icon: Icons.css,
        primaryColor: Color(0xFF1572B6),
        keywords: {
          'color',
          'background',
          'border',
          'margin',
          'padding',
          'font',
          'display',
          'position',
          'width',
          'height',
          'top',
          'left',
          'right',
          'bottom',
          'flex',
          'grid',
        },
        keywordColor: Color(0xFF569CD6),
        stringColor: Color(0xFFCE9178),
        commentColor: Color(0xFF6A9955),
        numberColor: Color(0xFFB5CEA8),
      ),
      'sql': const LanguageConfig(
        name: 'SQL',
        icon: Icons.storage,
        primaryColor: Color(0xFF336791),
        keywords: {
          'SELECT',
          'FROM',
          'WHERE',
          'INSERT',
          'UPDATE',
          'DELETE',
          'CREATE',
          'TABLE',
          'JOIN',
          'ON',
          'AS',
          'AND',
          'OR',
          'NOT',
          'NULL',
          'PRIMARY',
          'KEY',
          'FOREIGN',
          'INDEX',
          'INTO',
          'VALUES',
          'SET',
          'ALTER',
          'DROP',
        },
        keywordColor: Color(0xFF569CD6),
        stringColor: Color(0xFFCE9178),
        commentColor: Color(0xFF6A9955),
        numberColor: Color(0xFFB5CEA8),
      ),
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<int> _getLineNumbers() {
    if (_controller.text.isEmpty) return [1];
    return List.generate(_controller.text.split('\n').length, (i) => i + 1);
  }

  @override
  Widget build(BuildContext context) {
    final config = _languages[_selectedLanguage]!;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withAlpha(50), width: 0.5),
      ),
      child: Column(
        children: [
          // Professional header bar
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF2D2D30),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                // Language selector with icon
                InkWell(
                  onTap: () => _showLanguageSelector(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: config.primaryColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: config.primaryColor.withAlpha(40),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(config.icon, size: 14, color: config.primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          config.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: config.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: config.primaryColor.withAlpha(150),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Editor actions
                Row(
                  children: [
                    _buildActionButton(
                      icon: Icons.format_list_numbered_rounded,
                      isActive: _showLineNumbers,
                      onTap:
                          () => setState(
                            () => _showLineNumbers = !_showLineNumbers,
                          ),
                      tooltip: 'Line numbers',
                    ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      icon: Icons.wrap_text_rounded,
                      isActive: _wordWrap,
                      onTap: () => setState(() => _wordWrap = !_wordWrap),
                      tooltip: 'Word wrap',
                    ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      icon: Icons.copy_rounded,
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(text: _controller.text),
                        );
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code copied'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      tooltip: 'Copy',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Code editor area
          Container(
            constraints: const BoxConstraints(minHeight: 150, maxHeight: 400),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line numbers column
                if (_showLineNumbers)
                  Container(
                    width: 50,
                    padding: const EdgeInsets.only(top: 12, right: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF252526),
                      border: Border(
                        right: BorderSide(
                          color: AppColors.divider.withAlpha(30),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children:
                            _getLineNumbers().map((line) {
                              return Container(
                                height: 20,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  line.toString(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                    color: Color(0xFF858585),
                                    height: 1.5,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),

                // Code text field with syntax highlighting
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    child: Stack(
                      children: [
                        // Syntax highlighted text
                        _buildSyntaxHighlightedText(config),

                        // Transparent input field on top
                        TextField(
                          controller: _controller,
                          focusNode: widget.focusNode,
                          maxLines: null,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'monospace',
                            color: Colors.transparent,
                            height: 1.5,
                            letterSpacing: 0,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          cursorColor: AppColors.accent,
                          cursorWidth: 2,
                        ),
                      ],
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

  Widget _buildSyntaxHighlightedText(LanguageConfig config) {
    final text = _controller.text;
    if (text.isEmpty) {
      return Text(
        'Enter your ${config.name} code here...',
        style: const TextStyle(
          fontSize: 14,
          fontFamily: 'monospace',
          color: Color(0xFF6A6A6A),
          height: 1.5,
        ),
      );
    }

    // Process text line by line for proper comment handling
    final lines = text.split('\n');
    final List<TextSpan> allSpans = [];

    for (int i = 0; i < lines.length; i++) {
      if (i > 0) {
        allSpans.add(const TextSpan(text: '\n'));
      }
      allSpans.addAll(_highlightLine(lines[i], config));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14,
          fontFamily: 'monospace',
          color: Color(0xFFD4D4D4),
          height: 1.5,
        ),
        children: allSpans,
      ),
    );
  }

  List<TextSpan> _highlightLine(String line, LanguageConfig config) {
    final spans = <TextSpan>[];

    // Check if line contains comment
    int commentIndex = -1;
    if (_selectedLanguage == 'python') {
      commentIndex = line.indexOf('#');
    } else if (_selectedLanguage == 'dart' ||
        _selectedLanguage == 'javascript' ||
        _selectedLanguage == 'css') {
      commentIndex = line.indexOf('//');
    }

    // If comment found, split line into code and comment parts
    if (commentIndex != -1) {
      final codePart = line.substring(0, commentIndex);
      final commentPart = line.substring(commentIndex);

      // Highlight code part
      spans.addAll(_highlightCode(codePart, config));

      // Add comment part with comment color
      spans.add(
        TextSpan(
          text: commentPart,
          style: TextStyle(
            color: config.commentColor,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    } else {
      // No comment, highlight entire line
      spans.addAll(_highlightCode(line, config));
    }

    return spans;
  }

  List<TextSpan> _highlightCode(String code, LanguageConfig config) {
    final spans = <TextSpan>[];

    // Split by word boundaries but preserve spaces
    final pattern = RegExp(r'(\b\w+\b|\s+|[^\w\s]+)');
    final matches = pattern.allMatches(code);

    for (final match in matches) {
      final token = match.group(0)!;

      if (token.trim().isEmpty) {
        // Preserve spaces
        spans.add(TextSpan(text: token));
      } else if (config.keywords.contains(token)) {
        // Keyword
        spans.add(
          TextSpan(
            text: token,
            style: TextStyle(
              color: config.keywordColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else if (_isString(token)) {
        // String
        spans.add(
          TextSpan(text: token, style: TextStyle(color: config.stringColor)),
        );
      } else if (_isNumber(token)) {
        // Number
        spans.add(
          TextSpan(text: token, style: TextStyle(color: config.numberColor)),
        );
      } else {
        // Default text
        spans.add(TextSpan(text: token));
      }
    }

    return spans;
  }

  bool _isString(String text) {
    return (text.startsWith('"') && text.endsWith('"')) ||
        (text.startsWith("'") && text.endsWith("'")) ||
        (text.startsWith('`') && text.endsWith('`'));
  }

  bool _isNumber(String text) {
    return RegExp(r'^\d+\.?\d*$').hasMatch(text);
  }

  Widget _buildActionButton({
    required IconData icon,
    bool isActive = false,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color:
                isActive ? AppColors.accent.withAlpha(20) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border:
                isActive
                    ? Border.all(
                      color: AppColors.accent.withAlpha(40),
                      width: 0.5,
                    )
                    : null,
          ),
          child: Icon(
            icon,
            size: 16,
            color: isActive ? AppColors.accent : const Color(0xFF858585),
          ),
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Language',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              ..._languages.entries.map((entry) {
                final isSelected = entry.key == _selectedLanguage;
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: entry.value.primaryColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      entry.value.icon,
                      color: entry.value.primaryColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    entry.value.name,
                    style: TextStyle(
                      color:
                          isSelected ? AppColors.accent : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  trailing:
                      isSelected
                          ? Icon(Icons.check_circle, color: AppColors.accent)
                          : null,
                  onTap: () {
                    setState(() => _selectedLanguage = entry.key);
                    widget.onChanged(
                      widget.block.copyWith(language: entry.key),
                    );
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// Language configuration class
class LanguageConfig {
  final String name;
  final IconData icon;
  final Color primaryColor;
  final Set<String> keywords;
  final Color keywordColor;
  final Color stringColor;
  final Color commentColor;
  final Color numberColor;

  const LanguageConfig({
    required this.name,
    required this.icon,
    required this.primaryColor,
    required this.keywords,
    required this.keywordColor,
    required this.stringColor,
    required this.commentColor,
    required this.numberColor,
  });
}
