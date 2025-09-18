import 'package:dayflow/data/models/note_block.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class EditorUtils {
  // Create different types of blocks
  static NoteBlock createBlockOfType(BlockType type) {
    final id = const Uuid().v4();

    switch (type) {
      case BlockType.text:
        return TextBlock(id: id, text: '');
      case BlockType.heading:
        return HeadingBlock(id: id, text: '', level: 1);
      case BlockType.bulletList:
        return BulletListBlock(id: id, items: const ['']);
      case BlockType.numberedList:
        return NumberedListBlock(id: id, items: const ['']);
      case BlockType.todoList:
        return TodoListBlock(id: id, items: const [''], checked: const [false]);
      case BlockType.quote:
        return QuoteBlock(id: id, text: '');
      case BlockType.code:
        return CodeBlock(id: id, code: '');
      case BlockType.toggle:
        return ToggleBlock(
          id: id,
          title: 'Toggle',
          children: [TextBlock(id: const Uuid().v4(), text: '')],
        );
      case BlockType.callout:
        return CalloutBlock(id: id, text: '', calloutType: 'info');
      case BlockType.picture:
        return PictureBlock(id: id);
    }
  }

  // Duplicate a block
  static NoteBlock duplicateBlock(NoteBlock block) {
    final newId = const Uuid().v4();

    if (block is TextBlock) {
      return TextBlock(id: newId, text: block.text);
    } else if (block is HeadingBlock) {
      return HeadingBlock(id: newId, text: block.text, level: block.level);
    } else if (block is BulletListBlock) {
      return BulletListBlock(id: newId, items: List.from(block.items));
    } else if (block is NumberedListBlock) {
      return NumberedListBlock(id: newId, items: List.from(block.items));
    } else if (block is TodoListBlock) {
      return TodoListBlock(
        id: newId,
        items: List.from(block.items),
        checked: List.from(block.checked),
      );
    } else if (block is QuoteBlock) {
      return QuoteBlock(id: newId, text: block.text);
    } else if (block is CodeBlock) {
      return CodeBlock(id: newId, code: block.code, language: block.language);
    } else if (block is PictureBlock) {
      return PictureBlock(
        id: newId,
        imagePath: block.imagePath,
        imageUrl: block.imageUrl,
        caption: block.caption,
        width: block.width,
        height: block.height,
        alignment: block.alignment,
      );
    } else {
      return TextBlock(id: newId, text: '');
    }
  }

  // Apply text formatting
  static String applyTextFormatting(
    String text,
    TextSelection selection,
    String format,
  ) {
    if (selection.isCollapsed) return text;

    final selectedText = text.substring(selection.start, selection.end);
    String formattedText = '';

    switch (format) {
      case 'bold':
        formattedText = '**$selectedText**';
        break;
      case 'italic':
        formattedText = '*$selectedText*';
        break;
      case 'underline':
        formattedText = '<u>$selectedText</u>';
        break;
      case 'strikethrough':
        formattedText = '~~$selectedText~~';
        break;
      case 'code':
        formattedText = '`$selectedText`';
        break;
      default:
        return text;
    }

    return text.replaceRange(selection.start, selection.end, formattedText);
  }
}
