import 'package:equatable/equatable.dart';

/// Enum representing all possible block types
enum BlockType {
  text,
  heading,
  bulletList,
  numberedList,
  todoList,
  quote,
  code,
  toggle,
  callout,
}

/// Base class for all note blocks
abstract class NoteBlock extends Equatable {
  final String id;
  final BlockType type;

  const NoteBlock({required this.id, required this.type});

  @override
  List<Object> get props => [id, type];

  /// Convert block to JSON for storage
  Map<String, dynamic> toJson();

  /// Create a copy of the block with optional new values
  NoteBlock copyWith({String? id});
}

/// Text block - a simple paragraph
class TextBlock extends NoteBlock {
  final String text;

  const TextBlock({required super.id, required this.text})
    : super(type: BlockType.text);

  @override
  List<Object> get props => [...super.props, text];

  @override
  Map<String, dynamic> toJson() {
    return {'id': id, 'type': type.name, 'text': text};
  }

  factory TextBlock.fromJson(Map<String, dynamic> json) {
    return TextBlock(id: json['id'], text: json['text'] ?? '');
  }

  @override
  TextBlock copyWith({String? id, String? text}) {
    return TextBlock(id: id ?? this.id, text: text ?? this.text);
  }
}

/// Heading block - with levels 1-6
class HeadingBlock extends NoteBlock {
  final String text;
  final int level; // 1-6

  const HeadingBlock({
    required super.id,
    required this.text,
    required this.level,
  }) : super(type: BlockType.heading);

  @override
  List<Object> get props => [...super.props, text, level];

  @override
  Map<String, dynamic> toJson() {
    return {'id': id, 'type': type.name, 'text': text, 'level': level};
  }

  factory HeadingBlock.fromJson(Map<String, dynamic> json) {
    return HeadingBlock(
      id: json['id'],
      text: json['text'] ?? '',
      level: json['level'] ?? 1,
    );
  }

  @override
  HeadingBlock copyWith({String? id, String? text, int? level}) {
    return HeadingBlock(
      id: id ?? this.id,
      text: text ?? this.text,
      level: level ?? this.level,
    );
  }
}

/// Base class for list blocks
abstract class ListBlock extends NoteBlock {
  final List<String> items;

  const ListBlock({
    required super.id,
    required super.type,
    required this.items,
  });

  @override
  List<Object> get props => [...super.props, items];

  @override
  Map<String, dynamic> toJson() {
    return {'id': id, 'type': type.name, 'items': items};
  }
}

/// Bullet list block
class BulletListBlock extends ListBlock {
  const BulletListBlock({required super.id, required super.items})
    : super(type: BlockType.bulletList);

  factory BulletListBlock.fromJson(Map<String, dynamic> json) {
    return BulletListBlock(
      id: json['id'],
      items: List<String>.from(json['items'] ?? []),
    );
  }

  @override
  BulletListBlock copyWith({String? id, List<String>? items}) {
    return BulletListBlock(id: id ?? this.id, items: items ?? this.items);
  }
}

/// Numbered list block
class NumberedListBlock extends ListBlock {
  const NumberedListBlock({required super.id, required super.items})
    : super(type: BlockType.numberedList);

  factory NumberedListBlock.fromJson(Map<String, dynamic> json) {
    return NumberedListBlock(
      id: json['id'],
      items: List<String>.from(json['items'] ?? []),
    );
  }

  @override
  NumberedListBlock copyWith({String? id, List<String>? items}) {
    return NumberedListBlock(id: id ?? this.id, items: items ?? this.items);
  }
}

/// Todo list block with checked/unchecked items
class TodoListBlock extends ListBlock {
  final List<bool> checked;

  const TodoListBlock({
    required super.id,
    required super.items,
    required this.checked,
  }) : super(type: BlockType.todoList);

  @override
  List<Object> get props => [...super.props, checked];

  @override
  Map<String, dynamic> toJson() {
    return {'id': id, 'type': type.name, 'items': items, 'checked': checked};
  }

  factory TodoListBlock.fromJson(Map<String, dynamic> json) {
    return TodoListBlock(
      id: json['id'],
      items: List<String>.from(json['items'] ?? []),
      checked: List<bool>.from(json['checked'] ?? []),
    );
  }

  @override
  TodoListBlock copyWith({
    String? id,
    List<String>? items,
    List<bool>? checked,
  }) {
    return TodoListBlock(
      id: id ?? this.id,
      items: items ?? this.items,
      checked: checked ?? this.checked,
    );
  }
}

/// Quote block
class QuoteBlock extends NoteBlock {
  final String text;

  const QuoteBlock({required super.id, required this.text})
    : super(type: BlockType.quote);

  @override
  List<Object> get props => [...super.props, text];

  @override
  Map<String, dynamic> toJson() {
    return {'id': id, 'type': type.name, 'text': text};
  }

  factory QuoteBlock.fromJson(Map<String, dynamic> json) {
    return QuoteBlock(id: json['id'], text: json['text'] ?? '');
  }

  @override
  QuoteBlock copyWith({String? id, String? text}) {
    return QuoteBlock(id: id ?? this.id, text: text ?? this.text);
  }
}

/// Code block
class CodeBlock extends NoteBlock {
  final String code;
  final String? language;

  const CodeBlock({required super.id, required this.code, this.language})
    : super(type: BlockType.code);

  @override
  List<Object> get props => [...super.props, code, language ?? ''];

  @override
  Map<String, dynamic> toJson() {
    return {'id': id, 'type': type.name, 'code': code, 'language': language};
  }

  factory CodeBlock.fromJson(Map<String, dynamic> json) {
    return CodeBlock(
      id: json['id'],
      code: json['code'] ?? '',
      language: json['language'],
    );
  }

  @override
  CodeBlock copyWith({String? id, String? code, String? language}) {
    return CodeBlock(
      id: id ?? this.id,
      code: code ?? this.code,
      language: language ?? this.language,
    );
  }
}

/// Toggle block (collapsible section)
class ToggleBlock extends NoteBlock {
  final String title;
  final List<NoteBlock> children;
  final bool isExpanded;

  const ToggleBlock({
    required super.id,
    required this.title,
    required this.children,
    this.isExpanded = false,
  }) : super(type: BlockType.toggle);

  @override
  List<Object> get props => [...super.props, title, children, isExpanded];

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'children': children.map((child) => child.toJson()).toList(),
      'isExpanded': isExpanded,
    };
  }

  factory ToggleBlock.fromJson(Map<String, dynamic> json) {
    return ToggleBlock(
      id: json['id'],
      title: json['title'] ?? '',
      children:
          (json['children'] as List)
              .map((childJson) => blockFromJson(childJson))
              .toList(),
      isExpanded: json['isExpanded'] ?? false,
    );
  }

  @override
  ToggleBlock copyWith({
    String? id,
    String? title,
    List<NoteBlock>? children,
    bool? isExpanded,
  }) {
    return ToggleBlock(
      id: id ?? this.id,
      title: title ?? this.title,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}

/// Callout block (highlighted information box)
class CalloutBlock extends NoteBlock {
  final String text;
  final String calloutType; // 'info', 'warning', 'error', 'success'

  const CalloutBlock({
    required super.id,
    required this.text,
    required this.calloutType,
  }) : super(type: BlockType.callout);

  @override
  List<Object> get props => [...super.props, text, calloutType];

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'text': text,
      'calloutType': calloutType,
    };
  }

  factory CalloutBlock.fromJson(Map<String, dynamic> json) {
    return CalloutBlock(
      id: json['id'],
      text: json['text'] ?? '',
      calloutType: json['calloutType'] ?? 'info',
    );
  }

  @override
  CalloutBlock copyWith({String? id, String? text, String? calloutType}) {
    return CalloutBlock(
      id: id ?? this.id,
      text: text ?? this.text,
      calloutType: calloutType ?? this.calloutType,
    );
  }
}

/// Factory to create blocks from JSON
NoteBlock blockFromJson(Map<String, dynamic> json) {
  final type = BlockType.values.byName(json['type']);

  switch (type) {
    case BlockType.text:
      return TextBlock.fromJson(json);
    case BlockType.heading:
      return HeadingBlock.fromJson(json);
    case BlockType.bulletList:
      return BulletListBlock.fromJson(json);
    case BlockType.numberedList:
      return NumberedListBlock.fromJson(json);
    case BlockType.todoList:
      return TodoListBlock.fromJson(json);
    case BlockType.quote:
      return QuoteBlock.fromJson(json);
    case BlockType.code:
      return CodeBlock.fromJson(json);
    case BlockType.toggle:
      return ToggleBlock.fromJson(json);
    case BlockType.callout:
      return CalloutBlock.fromJson(json);
  }
}
