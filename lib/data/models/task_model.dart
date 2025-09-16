import 'package:dayflow/core/utils/debug_logger.dart';
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

  // Validation constants
  static const int minPriority = 1;
  static const int maxPriority = 5;
  static const int minEstimatedMinutes = 1;
  static const int maxEstimatedMinutes = 1440; // 24 hours
  static const int maxTitleLength = 200;
  static const int maxDescriptionLength = 1000;
  static const int maxTags = 10;
  static const int maxTagLength = 30;

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
    // Validate on creation
    _validateModel();
  }

  void _validateModel() {
    if (title.isEmpty) {
      throw ArgumentError('Title cannot be empty');
    }
    if (title.length > maxTitleLength) {
      throw ArgumentError('Title too long (max $maxTitleLength characters)');
    }
    if (description != null && description!.length > maxDescriptionLength) {
      throw ArgumentError(
        'Description too long (max $maxDescriptionLength characters)',
      );
    }
    if (priority < minPriority || priority > maxPriority) {
      throw ArgumentError(
        'Priority must be between $minPriority and $maxPriority',
      );
    }
    if (!_isValidHexColor(color)) {
      throw ArgumentError('Invalid color format');
    }
    if (tags.length > maxTags) {
      throw ArgumentError('Too many tags (max $maxTags)');
    }
    for (final tag in tags) {
      if (tag.length > maxTagLength) {
        throw ArgumentError(
          'Tag "$tag" too long (max $maxTagLength characters)',
        );
      }
    }
    if (estimatedMinutes != null &&
        (estimatedMinutes! < minEstimatedMinutes ||
            estimatedMinutes! > maxEstimatedMinutes)) {
      throw ArgumentError(
        'Estimated minutes must be between $minEstimatedMinutes and $maxEstimatedMinutes',
      );
    }
  }

  static bool _isValidHexColor(String color) {
    final regex = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');
    return regex.hasMatch(color);
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
      // Safe parsing with defaults
      List<NoteBlock>? blocks;
      if (map['blocks'] != null) {
        try {
          blocks =
              (map['blocks'] as List).map((blockJson) {
                if (blockJson is Map<String, dynamic>) {
                  return blockFromJson(blockJson);
                } else {
                  // Handle legacy or corrupted data
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

      // Safe tag parsing
      List<String> tags = [];
      try {
        if (map['tags'] != null) {
          tags = List<String>.from(map['tags']);
          // Validate and clean tags
          tags =
              tags
                  .where((tag) => tag.isNotEmpty && tag.length <= maxTagLength)
                  .take(maxTags)
                  .toList();
        }
      } catch (e) {
        DebugLogger.warning(
          'Error parsing tags',
          tag: _tag,
          data: e.toString(),
        );
      }

      // Safe date parsing
      DateTime? parseDate(String? dateStr) {
        if (dateStr == null || dateStr.isEmpty) return null;
        try {
          return DateTime.parse(dateStr);
        } catch (e) {
          DebugLogger.warning('Invalid date format', tag: _tag, data: dateStr);
          return null;
        }
      }

      final task = TaskModel(
        id: map['id'] as String? ?? const Uuid().v4(),
        title: (map['title'] as String? ?? 'Untitled').substring(
          0,
          (map['title'] as String? ?? 'Untitled').length.clamp(
            0,
            maxTitleLength,
          ),
        ),
        description: map['description'] as String?,
        createdAt: parseDate(map['createdAt'] as String?) ?? DateTime.now(),
        dueDate: parseDate(map['dueDate'] as String?),
        completedAt: parseDate(map['completedAt'] as String?),
        isCompleted: map['isCompleted'] as bool? ?? false,
        isDeleted: map['isDeleted'] as bool? ?? false,
        priority: _validatePriority(map['priority']),
        color: _validateColor(map['color'] as String?),
        tags: tags,
        isNote: map['isNote'] as bool? ?? false,
        noteContent: map['noteContent'] as String?,
        estimatedMinutes: _validateMinutes(map['estimatedMinutes']),
        actualMinutes: _validateMinutes(map['actualMinutes']),
        markdownContent: map['markdownContent'] as String?,
        hasNotification: map['hasNotification'] as bool? ?? false,
        notificationMinutesBefore: _validateMinutes(
          map['notificationMinutesBefore'],
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
      // Return a minimal valid task instead of crashing
      return TaskModel(
        id: map['id'] as String? ?? const Uuid().v4(),
        title: 'Error loading task',
        isDeleted: true, // Mark as deleted to prevent display issues
      );
    }
  }

  static int _validatePriority(dynamic value) {
    if (value == null) return 1;
    if (value is int) {
      return value.clamp(minPriority, maxPriority);
    }
    try {
      final parsed = int.parse(value.toString());
      return parsed.clamp(minPriority, maxPriority);
    } catch (_) {
      return 1;
    }
  }

  static String _validateColor(String? color) {
    if (color == null || !_isValidHexColor(color)) {
      return '#6C63FF';
    }
    return color;
  }

  static int? _validateMinutes(dynamic value) {
    if (value == null) return null;
    if (value is int) {
      return value.clamp(minEstimatedMinutes, maxEstimatedMinutes);
    }
    try {
      final parsed = int.parse(value.toString());
      return parsed.clamp(minEstimatedMinutes, maxEstimatedMinutes);
    } catch (_) {
      return null;
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

  // Legacy support
  List<NoteBlock> getLegacyBlocks() {
    if (markdownContent != null && markdownContent!.isNotEmpty) {
      return [TextBlock(id: const Uuid().v4(), text: markdownContent!)];
    }
    return [];
  }

  // Computed properties
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  bool get isDueTomorrow {
    if (dueDate == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dueDate!.year == tomorrow.year &&
        dueDate!.month == tomorrow.month &&
        dueDate!.day == tomorrow.day;
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

  // Validation methods
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
    } else if (title.length > maxTitleLength) {
      errors['title'] = 'Title too long';
    }

    if (description != null && description!.length > maxDescriptionLength) {
      errors['description'] = 'Description too long';
    }

    if (priority < minPriority || priority > maxPriority) {
      errors['priority'] = 'Invalid priority';
    }

    if (!_isValidHexColor(color)) {
      errors['color'] = 'Invalid color format';
    }

    if (tags.length > maxTags) {
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
