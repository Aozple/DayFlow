import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:uuid/uuid.dart';

class HabitInstanceModel {
  static const String _tag = 'HabitInstanceModel';

  final String id;
  final String habitId; // Reference to parent HabitModel
  final DateTime date;
  final HabitInstanceStatus status;
  final DateTime? completedAt;
  final int? value; // For quantifiable habits
  final String? note;
  final bool isDeleted;

  HabitInstanceModel({
    String? id,
    required this.habitId,
    required this.date,
    this.status = HabitInstanceStatus.pending,
    this.completedAt,
    this.value,
    this.note,
    this.isDeleted = false,
  }) : id = id ?? const Uuid().v4() {
    _validateModel();
  }

  void _validateModel() {
    if (habitId.isEmpty) {
      throw ArgumentError('Habit ID cannot be empty');
    }
    if (status == HabitInstanceStatus.completed && completedAt == null) {
      throw ArgumentError(
        'Completed instances must have completedAt timestamp',
      );
    }
    if (value != null && value! < 0) {
      throw ArgumentError('Value cannot be negative');
    }
  }

  Map<String, dynamic> toMap() {
    try {
      final map = {
        'id': id,
        'habitId': habitId,
        'date': date.toIso8601String(),
        'status': status.name,
        'completedAt': completedAt?.toIso8601String(),
        'value': value,
        'note': note,
        'isDeleted': isDeleted,
      };

      DebugLogger.verbose(
        'HabitInstance serialized',
        tag: _tag,
        data: 'ID: $id',
      );
      return map;
    } catch (e) {
      DebugLogger.error(
        'Failed to serialize habit instance',
        tag: _tag,
        error: e,
      );
      rethrow;
    }
  }

  factory HabitInstanceModel.fromMap(Map<String, dynamic> map) {
    try {
      DateTime? parseDate(String? dateStr) {
        if (dateStr == null || dateStr.isEmpty) return null;
        try {
          return DateTime.parse(dateStr);
        } catch (e) {
          DebugLogger.warning('Invalid date format', tag: _tag, data: dateStr);
          return null;
        }
      }

      final instance = HabitInstanceModel(
        id: map['id'] as String? ?? const Uuid().v4(),
        habitId: map['habitId'] as String,
        date: parseDate(map['date'] as String?) ?? DateTime.now(),
        status: HabitInstanceStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => HabitInstanceStatus.pending,
        ),
        completedAt: parseDate(map['completedAt'] as String?),
        value: map['value'] as int?,
        note: map['note'] as String?,
        isDeleted: map['isDeleted'] as bool? ?? false,
      );

      DebugLogger.verbose(
        'HabitInstance deserialized',
        tag: _tag,
        data: 'ID: ${instance.id}',
      );
      return instance;
    } catch (e) {
      DebugLogger.error(
        'Failed to deserialize habit instance',
        tag: _tag,
        error: e,
      );
      rethrow;
    }
  }

  HabitInstanceModel copyWith({
    String? id,
    String? habitId,
    DateTime? date,
    HabitInstanceStatus? status,
    DateTime? completedAt,
    int? value,
    String? note,
    bool? isDeleted,
  }) {
    return HabitInstanceModel(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      value: value ?? this.value,
      note: note ?? this.note,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  // Computed properties
  bool get isCompleted => status == HabitInstanceStatus.completed;
  bool get isSkipped => status == HabitInstanceStatus.skipped;
  bool get isPending => status == HabitInstanceStatus.pending;
  bool get isToday => _isSameDay(date, DateTime.now());
  bool get isPast => date.isBefore(DateTime.now()) && !isToday;
  bool get isFuture => date.isAfter(DateTime.now()) && !isToday;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  String toString() {
    return 'HabitInstanceModel(id: $id, habitId: $habitId, date: $date, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HabitInstanceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum HabitInstanceStatus { pending, completed, skipped }
