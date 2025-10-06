import 'package:dayflow/core/utils/app_date_utils.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:uuid/uuid.dart';

class HabitInstanceModel {
  static const String _tag = 'HabitInstanceModel';

  static final Map<String, HabitInstanceStatus> _statusMap = {
    for (var s in HabitInstanceStatus.values) s.name: s,
  };

  static final Map<String, bool> _validationCache = {};

  final String id;
  final String habitId;
  final DateTime date;
  final HabitInstanceStatus status;
  final DateTime? completedAt;
  final int? value;
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
    final validationKey = '$habitId-${status.name}-${value ?? 0}';

    if (_validationCache.containsKey(validationKey)) {
      if (!_validationCache[validationKey]!) {
        throw ArgumentError('Invalid model data (cached)');
      }
      return;
    }

    try {
      if (habitId.isEmpty) {
        _cacheInvalidResult(validationKey);
        throw ArgumentError('Habit ID cannot be empty');
      }

      if (status == HabitInstanceStatus.completed && completedAt == null) {
        _cacheInvalidResult(validationKey);
        throw ArgumentError(
          'Completed instances must have completedAt timestamp',
        );
      }

      if (value != null && value! < 0) {
        _cacheInvalidResult(validationKey);
        throw ArgumentError('Value cannot be negative');
      }

      _cacheValidResult(validationKey);
    } catch (e) {
      _cacheInvalidResult(validationKey);
      rethrow;
    }
  }

  void _cacheValidResult(String key) {
    if (_validationCache.length < 100) {
      _validationCache[key] = true;
    }
  }

  void _cacheInvalidResult(String key) {
    if (_validationCache.length < 100) {
      _validationCache[key] = false;
    }
  }

  static void clearValidationCache() {
    _validationCache.clear();
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
      int? parseIntSafe(dynamic value, {int? min}) {
        if (value == null) return null;

        int? result;
        if (value is int) {
          result = value;
        } else {
          try {
            result = int.parse(value.toString());
          } catch (_) {
            return null;
          }
        }

        if (min != null && result < min) return null;
        return result;
      }

      String parseStringSafe(dynamic value, String fallback) {
        if (value is String && value.isNotEmpty) {
          return value.trim();
        }
        return fallback;
      }

      final instance = HabitInstanceModel(
        id: parseStringSafe(map['id'], const Uuid().v4()),
        habitId: parseStringSafe(map['habitId'], ''),
        date: AppDateUtils.tryParse(map['date'] as String?) ?? AppDateUtils.now,
        status: _statusMap[map['status']] ?? HabitInstanceStatus.pending,
        completedAt: AppDateUtils.tryParse(map['completedAt'] as String?),
        value: parseIntSafe(map['value'], min: 0),
        note: map['note'] is String ? (map['note'] as String).trim() : null,
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
    if (id == null &&
        habitId == null &&
        date == null &&
        status == null &&
        completedAt == null &&
        value == null &&
        note == null &&
        isDeleted == null) {
      return this;
    }

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

  bool get isCompleted => status == HabitInstanceStatus.completed;
  bool get isPending => status == HabitInstanceStatus.pending;
  bool get isToday => AppDateUtils.isSameDay(date, AppDateUtils.now);
  bool get isPast => date.isBefore(AppDateUtils.now) && !isToday;
  bool get isFuture => date.isAfter(AppDateUtils.now) && !isToday;

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

enum HabitInstanceStatus { pending, completed }
