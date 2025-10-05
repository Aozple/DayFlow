import 'package:dayflow/core/utils/color_utils.dart';
import 'package:dayflow/core/utils/date_utils.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:dayflow/core/utils/validation_utils.dart';
import 'package:dayflow/data/models/note_block.dart';
import 'package:uuid/uuid.dart';

class TaskModel {
  static const String _tag = 'TaskModel';

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
  final bool isNote;
  final String? noteContent;
  final int? estimatedMinutes;
  final int? actualMinutes;
  final String? markdownContent;
  final bool hasNotification;
  final int? notificationMinutesBefore;
  final List<NoteBlock>? blocks;

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
       tags = tags ?? [] {
    _validateModel();
  }

  void _validateModel() {
    if (title.isEmpty) {
      throw ArgumentError('Title cannot be empty');
    }
    if (title.length > ValidationUtils.maxTitleLength) {
      throw ArgumentError(
        'Title too long (max ${ValidationUtils.maxTitleLength} characters)',
      );
    }
    if (description != null &&
        description!.length > ValidationUtils.maxDescriptionLength) {
      throw ArgumentError(
        'Description too long (max ${ValidationUtils.maxDescriptionLength} characters)',
      );
    }
    if (priority < ValidationUtils.minPriority ||
        priority > ValidationUtils.maxPriority) {
      throw ArgumentError(
        'Priority must be between ${ValidationUtils.minPriority} and ${ValidationUtils.maxPriority}',
      );
    }
    if (!ColorUtils.isValidHex(color)) {
      throw ArgumentError('Invalid color format');
    }
    if (tags.length > ValidationUtils.maxTags) {
      throw ArgumentError('Too many tags (max ${ValidationUtils.maxTags})');
    }
    for (final tag in tags) {
      if (tag.length > ValidationUtils.maxTagLength) {
        throw ArgumentError(
          'Tag "$tag" too long (max ${ValidationUtils.maxTagLength} characters)',
        );
      }
    }
    if (estimatedMinutes != null &&
        (estimatedMinutes! < ValidationUtils.minEstimatedMinutes ||
            estimatedMinutes! > ValidationUtils.maxEstimatedMinutes)) {
      throw ArgumentError(
        'Estimated minutes must be between ${ValidationUtils.minEstimatedMinutes} and ${ValidationUtils.maxEstimatedMinutes}',
      );
    }
  }

  Map<String, dynamic> toMap() {
    try {
      final map = {
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

      DebugLogger.verbose('Task serialized', tag: _tag, data: 'ID: $id');
      return map;
    } catch (e) {
      DebugLogger.error('Failed to serialize task', tag: _tag, error: e);
      rethrow;
    }
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    try {
      List<NoteBlock>? blocks;
      if (map['blocks'] != null) {
        try {
          blocks =
              (map['blocks'] as List).map((blockJson) {
                if (blockJson is Map<String, dynamic>) {
                  return blockFromJson(blockJson);
                } else {
                  DebugLogger.warning(
                    'Invalid block data',
                    tag: _tag,
                    data: blockJson,
                  );
                  return TextBlock(
                    id: const Uuid().v4(),
                    text: blockJson.toString(),
                  );
                }
              }).toList();
        } catch (e) {
          DebugLogger.error('Error parsing blocks', tag: _tag, error: e);
          blocks = null;
        }
      }

      List<String> tags = [];
      try {
        if (map['tags'] != null) {
          tags = List<String>.from(map['tags']);

          tags =
              tags
                  .where(
                    (tag) =>
                        tag.isNotEmpty &&
                        tag.length <= ValidationUtils.maxTagLength,
                  )
                  .take(ValidationUtils.maxTags)
                  .toList();
        }
      } catch (e) {
        DebugLogger.warning(
          'Error parsing tags',
          tag: _tag,
          data: e.toString(),
        );
      }

      final task = TaskModel(
        id: map['id'] as String? ?? const Uuid().v4(),
        title: ValidationUtils.validateAndTrimTitle(
          map['title'] as String?,
          ValidationUtils.maxTitleLength,
          'Untitled',
        ),
        description: map['description'] as String?,
        createdAt:
            DateUtils.tryParse(map['createdAt'] as String?) ?? DateTime.now(),
        dueDate: DateUtils.tryParse(map['dueDate'] as String?),
        completedAt: DateUtils.tryParse(map['completedAt'] as String?),
        isCompleted: map['isCompleted'] as bool? ?? false,
        isDeleted: map['isDeleted'] as bool? ?? false,
        priority: ValidationUtils.validatePriority(
          map['priority'],
          ValidationUtils.minPriority,
          ValidationUtils.maxPriority,
          1,
        ),
        color: ColorUtils.validateHex(map['color'] as String?) ?? '#6C63FF',
        tags: tags,
        isNote: map['isNote'] as bool? ?? false,
        noteContent: map['noteContent'] as String?,
        estimatedMinutes: ValidationUtils.validateMinutes(
          map['estimatedMinutes'],
          ValidationUtils.minEstimatedMinutes,
          ValidationUtils.maxEstimatedMinutes,
        ),
        actualMinutes: ValidationUtils.validateMinutes(
          map['actualMinutes'],
          ValidationUtils.minEstimatedMinutes,
          ValidationUtils.maxEstimatedMinutes,
        ),
        markdownContent: map['markdownContent'] as String?,
        hasNotification: map['hasNotification'] as bool? ?? false,
        notificationMinutesBefore: ValidationUtils.validateMinutes(
          map['notificationMinutesBefore'],
          0,
          1440,
        ),
        blocks: blocks,
      );

      DebugLogger.verbose(
        'Task deserialized',
        tag: _tag,
        data: 'ID: ${task.id}',
      );
      return task;
    } catch (e) {
      DebugLogger.error('Failed to deserialize task', tag: _tag, error: e);
      rethrow;
    }
  }

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

  List<NoteBlock> getLegacyBlocks() {
    if (markdownContent != null && markdownContent!.isNotEmpty) {
      return [TextBlock(id: const Uuid().v4(), text: markdownContent!)];
    }
    return [];
  }

  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    return DateUtils.isSameDay(dueDate!, DateTime.now());
  }

  bool get isDueTomorrow {
    if (dueDate == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return DateUtils.isSameDay(dueDate!, tomorrow);
  }

  Duration? get timeUntilDue {
    if (dueDate == null) return null;
    return dueDate!.difference(DateTime.now());
  }

  String get priorityLabel {
    switch (priority) {
      case 1:
        return 'Low';
      case 2:
        return 'Normal';
      case 3:
        return 'Medium';
      case 4:
        return 'High';
      case 5:
        return 'Urgent';
      default:
        return 'Unknown';
    }
  }

  bool get isValid {
    try {
      _validateModel();
      return true;
    } catch (_) {
      return false;
    }
  }

  Map<String, String> get validationErrors {
    final errors = <String, String>{};

    if (title.isEmpty) {
      errors['title'] = 'Title cannot be empty';
    } else if (title.length > ValidationUtils.maxTitleLength) {
      errors['title'] = 'Title too long';
    }

    if (description != null &&
        description!.length > ValidationUtils.maxDescriptionLength) {
      errors['description'] = 'Description too long';
    }

    if (priority < ValidationUtils.minPriority ||
        priority > ValidationUtils.maxPriority) {
      errors['priority'] = 'Invalid priority';
    }

    if (!ColorUtils.isValidHex(color)) {
      errors['color'] = 'Invalid color format';
    }

    if (tags.length > ValidationUtils.maxTags) {
      errors['tags'] = 'Too many tags';
    }

    return errors;
  }

  @override
  String toString() {
    return 'TaskModel(id: $id, title: $title, isCompleted: $isCompleted, priority: $priority)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
