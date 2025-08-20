import 'package:uuid/uuid.dart';

// This class defines the structure for a single task or note in our app.
// It's like a blueprint for how our task data will look.
class TaskModel {
  // A unique ID for each task, so we can easily identify it.
  final String id;

  // The main title of the task, and an optional longer description.
  final String title;
  final String? description;

  // Timestamps for when the task was created, when it's due, and when it was completed.
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? completedAt;

  // Flags to track the task's current status.
  final bool isCompleted; // Is the task done?
  final bool isDeleted; // Is the task soft-deleted?

  // Extra details about the task.
  final int priority; // How important is this task (e.g., 1-5)?
  final String color; // A hex string for the task's color.
  final List<String> tags; // A list of keywords to categorize the task.

  // Specific fields for when this TaskModel is actually a note.
  final bool isNote; // Is this entry a note instead of a regular task?
  final String? noteContent; // The actual content of the note (deprecated, replaced by markdownContent).

  // Fields for tracking time spent on a task.
  final int? estimatedMinutes; // How long we think the task will take.
  final int? actualMinutes; // How long it actually took.

  // The main content for notes, stored in Markdown format.
  final String? markdownContent;

  // The constructor for creating a TaskModel instance.
  // It sets default values for many fields if they're not provided.
  TaskModel({
    String? id, // Optional ID, a new one will be generated if not provided.
    required this.title, // Title is a must-have.
    this.description,
    DateTime? createdAt, // Optional creation date, defaults to now.
    this.dueDate,
    this.completedAt,
    this.isCompleted = false, // Tasks are not completed by default.
    this.isDeleted = false, // Tasks are not deleted by default.
    this.priority = 1, // Default priority is 1 (lowest).
    this.color = '#6C63FF', // Default color.
    List<String>? tags, // Optional tags, defaults to an empty list.
    this.isNote = false, // Not a note by default.
    this.noteContent, // Old note content field.
    this.estimatedMinutes,
    this.actualMinutes,
    this.markdownContent,
  }) : id = id ?? const Uuid().v4(), // Generate a new UUID if no ID is given.
       createdAt = createdAt ?? DateTime.now(), // Set creation date to now if not provided.
       tags = tags ?? []; // Ensure tags is never null.

  // Converts this TaskModel instance into a Map.
  // This is necessary for storing the data in our Hive database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(), // Convert DateTime to string for storage.
      'dueDate': dueDate?.toIso8601String(), // Convert nullable DateTime to string.
      'completedAt': completedAt?.toIso8601String(), // Convert nullable DateTime to string.
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
    };
  }

  // Creates a TaskModel instance from a Map.
  // This is used when we read data back from the Hive database.
  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String), // Parse string back to DateTime.
      dueDate:
          map['dueDate'] != null
              ? DateTime.parse(map['dueDate'] as String) // Parse nullable string to DateTime.
              : null,
      completedAt:
          map['completedAt'] != null
              ? DateTime.parse(map['completedAt'] as String) // Parse nullable string to DateTime.
              : null,
      isCompleted: map['isCompleted'] as bool? ?? false, // Provide default if null.
      isDeleted: map['isDeleted'] as bool? ?? false, // Provide default if null.
      priority: map['priority'] as int? ?? 1, // Provide default if null.
      color: map['color'] as String? ?? '#6C63FF', // Provide default if null.
      tags: List<String>.from(map['tags'] ?? []), // Ensure tags is a List<String>, default to empty.
      isNote: map['isNote'] as bool? ?? false, // Provide default if null.
      noteContent: map['noteContent'] as String?,
      estimatedMinutes: map['estimatedMinutes'] as int?,
      actualMinutes: map['actualMinutes'] as int?,
      markdownContent: map['markdownContent'] as String?,
    );
  }

  // Creates a new TaskModel instance by copying existing values,
  // but allowing specific fields to be overridden.
  // This is super useful for updating a task without manually recreating it.
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
  }) {
    return TaskModel(
      id: id ?? this.id, // Use new ID if provided, otherwise keep old.
      title: title ?? this.title, // Use new title if provided, otherwise keep old.
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
    );
  }
}
