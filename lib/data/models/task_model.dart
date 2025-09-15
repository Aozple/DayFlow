import 'package:dayflow/data/models/note_block.dart';
import 'package:uuid/uuid.dart';

class TaskModel {
  final String id;

  final String title;
  final String? description;

  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? completedAt;

  final bool isCompleted;
  final bool isDeleted;

  final int priority;
  final String color;
  final List<String> tags;

  // Flag to distinguish between tasks and notes
  final bool isNote;
  final String? noteContent;

  final int? estimatedMinutes;
  final int? actualMinutes;

  // Legacy field for markdown content
  final String? markdownContent;

  final bool hasNotification;
  final int? notificationMinutesBefore;

  // Structured content for rich text notes
  final List<NoteBlock>? blocks;

  // Constructor with default values and UUID generation
  TaskModel({
    String? id,
    required this.title,
    this.description,
    DateTime? createdAt,
    this.dueDate,
    this.completedAt,
    this.isCompleted = false,
    this.isDeleted = false,
    this.priority = 1,
    this.color = '#6C63FF',
    List<String>? tags,
    this.isNote = false,
    this.noteContent,
    this.estimatedMinutes,
    this.actualMinutes,
    this.markdownContent,
    this.hasNotification = false,
    this.notificationMinutesBefore,
    this.blocks,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       tags = tags ?? [];

  // Convert model to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isCompleted': isCompleted,
      'isDeleted': isDeleted,
      'priority': priority,
      'color': color,
      'tags': tags,
      'isNote': isNote,
      'noteContent': noteContent,
      'estimatedMinutes': estimatedMinutes,
      'actualMinutes': actualMinutes,
      'markdownContent': markdownContent,
      'hasNotification': hasNotification,
      'notificationMinutesBefore': notificationMinutesBefore,
      'blocks': blocks?.map((block) => block.toJson()).toList(),
    };
  }

  // Create model from stored map data
  factory TaskModel.fromMap(Map<String, dynamic> map) {
    // Parse blocks if available
    List<NoteBlock>? blocks;
    if (map['blocks'] != null) {
      blocks =
          (map['blocks'] as List)
              .map((blockJson) => blockFromJson(blockJson))
              .toList();
    }

    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      dueDate:
          map['dueDate'] != null
              ? DateTime.parse(map['dueDate'] as String)
              : null,
      completedAt:
          map['completedAt'] != null
              ? DateTime.parse(map['completedAt'] as String)
              : null,
      isCompleted: map['isCompleted'] as bool? ?? false,
      isDeleted: map['isDeleted'] as bool? ?? false,
      priority: map['priority'] as int? ?? 1,
      color: map['color'] as String? ?? '#6C63FF',
      tags: List<String>.from(map['tags'] ?? []),
      isNote: map['isNote'] as bool? ?? false,
      noteContent: map['noteContent'] as String?,
      estimatedMinutes: map['estimatedMinutes'] as int?,
      actualMinutes: map['actualMinutes'] as int?,
      markdownContent: map['markdownContent'] as String?,
      hasNotification: map['hasNotification'] as bool? ?? false,
      notificationMinutesBefore: map['notificationMinutesBefore'] as int?,
      blocks: blocks,
    );
  }

  // Create a new instance with updated fields
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? dueDate,
    DateTime? completedAt,
    bool? isCompleted,
    bool? isDeleted,
    int? priority,
    String? color,
    List<String>? tags,
    bool? isNote,
    String? noteContent,
    int? estimatedMinutes,
    int? actualMinutes,
    String? markdownContent,
    bool? hasNotification,
    int? notificationMinutesBefore,
    List<NoteBlock>? blocks,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      isDeleted: isDeleted ?? this.isDeleted,
      priority: priority ?? this.priority,
      color: color ?? this.color,
      tags: tags ?? this.tags,
      isNote: isNote ?? this.isNote,
      noteContent: noteContent ?? this.noteContent,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      markdownContent: markdownContent ?? this.markdownContent,
      hasNotification: hasNotification ?? this.hasNotification,
      notificationMinutesBefore:
          notificationMinutesBefore ?? this.notificationMinutesBefore,
      blocks: blocks ?? this.blocks,
    );
  }

  // Convert legacy markdown to block format
  List<NoteBlock> getLegacyBlocks() {
    if (markdownContent != null && markdownContent!.isNotEmpty) {
      return [TextBlock(id: const Uuid().v4(), text: markdownContent!)];
    }
    return [];
  }
}
