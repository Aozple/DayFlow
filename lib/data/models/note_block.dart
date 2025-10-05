import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:dayflow/core/utils/validation_utils.dart';

typedef BlockFactory = NoteBlock Function(Map<String, dynamic> json);

final Map<String, BlockFactory> _blockFactories = {
  'text': TextBlock.fromJson,
  'heading': HeadingBlock.fromJson,
  'bulletList': BulletListBlock.fromJson,
  'numberedList': NumberedListBlock.fromJson,
  'todoList': TodoListBlock.fromJson,
  'quote': QuoteBlock.fromJson,
  'code': CodeBlock.fromJson,
  'toggle': ToggleBlock.fromJson,
  'callout': CalloutBlock.fromJson,
  'picture': PictureBlock.fromJson,
};

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
  picture,
}

abstract class NoteBlock extends Equatable {
  final String id;
  final BlockType type;

  const NoteBlock({required this.id, required this.type});

  @override
  List<Object> get props => [id, type];

  Map<String, dynamic> toJson();

  NoteBlock copyWith({String? id});
}

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

class HeadingBlock extends NoteBlock {
  final String text;
  final int level;

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
    final level = ValidationUtils.validateHeadingLevel(json['level']);
    return HeadingBlock(id: json['id'], text: json['text'] ?? '', level: level);
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

  static List<String> _parseStringList(dynamic data) {
    if (data is! List) return [];

    final result = <String>[];
    result.length = data.length;

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      result[i] = item?.toString() ?? '';
    }

    return result;
  }
}

class BulletListBlock extends ListBlock {
  const BulletListBlock({required super.id, required super.items})
    : super(type: BlockType.bulletList);

  factory BulletListBlock.fromJson(Map<String, dynamic> json) {
    return BulletListBlock(
      id: json['id'],
      items: ListBlock._parseStringList(json['items']),
    );
  }

  @override
  BulletListBlock copyWith({String? id, List<String>? items}) {
    return BulletListBlock(id: id ?? this.id, items: items ?? this.items);
  }
}

class NumberedListBlock extends ListBlock {
  const NumberedListBlock({required super.id, required super.items})
    : super(type: BlockType.numberedList);

  factory NumberedListBlock.fromJson(Map<String, dynamic> json) {
    return NumberedListBlock(
      id: json['id'],
      items: ListBlock._parseStringList(json['items']),
    );
  }

  @override
  NumberedListBlock copyWith({String? id, List<String>? items}) {
    return NumberedListBlock(id: id ?? this.id, items: items ?? this.items);
  }
}

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
    final items = ListBlock._parseStringList(json['items']);
    final checkedData = json['checked'];

    final checked = <bool>[];

    if (checkedData is List) {
      final targetLength = items.length;
      checked.length = targetLength;

      for (int i = 0; i < targetLength; i++) {
        checked[i] = i < checkedData.length ? checkedData[i] == true : false;
      }
    } else {
      checked.addAll(List.filled(items.length, false));
    }

    return TodoListBlock(id: json['id'], items: items, checked: checked);
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
    List<NoteBlock> children = [];
    try {
      if (json['children'] is List) {
        children =
            (json['children'] as List)
                .map((childJson) => blockFromJson(childJson))
                .toList();
      }
    } catch (_) {}

    return ToggleBlock(
      id: json['id'],
      title: json['title'] ?? '',
      children: children,
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

class CalloutBlock extends NoteBlock {
  final String text;
  final String calloutType;

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

class PictureBlock extends NoteBlock {
  final String? imagePath;
  final String? imageUrl;
  final String? caption;
  final double? width;
  final double? height;
  final String? alignment;

  const PictureBlock({
    required super.id,
    this.imagePath,
    this.imageUrl,
    this.caption,
    this.width,
    this.height,
    this.alignment = 'center',
  }) : super(type: BlockType.picture);

  @override
  List<Object> get props => [
    ...super.props,
    imagePath ?? '',
    imageUrl ?? '',
    caption ?? '',
    width ?? 0,
    height ?? 0,
    alignment ?? 'center',
  ];

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
      'caption': caption,
      'width': width,
      'height': height,
      'alignment': alignment,
    };
  }

  factory PictureBlock.fromJson(Map<String, dynamic> json) {
    return PictureBlock(
      id: json['id'],
      imagePath: json['imagePath'],
      imageUrl: json['imageUrl'],
      caption: json['caption'],
      width: json['width']?.toDouble(),
      height: json['height']?.toDouble(),
      alignment: json['alignment'] ?? 'center',
    );
  }

  @override
  PictureBlock copyWith({
    String? id,
    String? imagePath,
    String? imageUrl,
    String? caption,
    double? width,
    double? height,
    String? alignment,
  }) {
    return PictureBlock(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      width: width ?? this.width,
      height: height ?? this.height,
      alignment: alignment ?? this.alignment,
    );
  }

  bool get hasImage => imagePath != null || imageUrl != null;
}

NoteBlock blockFromJson(Map<String, dynamic> json) {
  try {
    final typeString = json['type'] as String?;
    if (typeString == null) {
      return TextBlock(
        id: json['id'] ?? const Uuid().v4(),
        text: 'Invalid block',
      );
    }

    final factory = _blockFactories[typeString];
    if (factory != null) {
      return factory(json);
    }

    return TextBlock(
      id: json['id'] ?? const Uuid().v4(),
      text: 'Unknown block type: $typeString',
    );
  } catch (e) {
    return TextBlock(
      id: json['id'] ?? const Uuid().v4(),
      text: 'Error loading block: ${e.toString()}',
    );
  }
}
