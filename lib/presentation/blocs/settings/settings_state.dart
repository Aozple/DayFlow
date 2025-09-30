part of 'settings_bloc.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  final String? message;
  final double? progress;

  const SettingsLoading({this.message, this.progress});

  @override
  List<Object?> get props => [message, progress];
}

class SettingsLoaded extends SettingsState {
  final AppSettings settings;
  final SettingsMetadata? metadata;
  final Map<String, dynamic>? stats;

  const SettingsLoaded(this.settings, {this.metadata, this.stats});

  @override
  List<Object?> get props => [settings, metadata, stats];

  String get accentColor => settings.accentColor;
  String get firstDayOfWeek => settings.firstDayOfWeek;
  int get defaultPriority => settings.defaultTaskPriority;
  bool get defaultNotificationEnabled => settings.defaultNotificationEnabled;
  int get defaultNotificationMinutesBefore =>
      settings.defaultNotificationMinutesBefore;
  bool get notificationSound => settings.notificationSound;
  bool get notificationVibration => settings.notificationVibration;

  String get firstDayLabel {
    return settings.firstDayOfWeek == 'saturday' ? 'Saturday' : 'Monday';
  }

  String get priorityLabel {
    switch (settings.defaultTaskPriority) {
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
        return 'Medium';
    }
  }

  String get notificationTimeLabel {
    final minutes = settings.defaultNotificationMinutesBefore;
    if (minutes == 0) return 'At time';
    if (minutes < 60) return '$minutes min before';

    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (mins == 0) {
      return hours == 1 ? '1 hour before' : '$hours hours before';
    }
    return '$hours hr $mins min before';
  }

  bool get isSaturdayFirst => settings.firstDayOfWeek == 'saturday';
  bool get isMondayFirst => settings.firstDayOfWeek == 'monday';

  bool get hasUnsavedChanges {
    return metadata?.hasUnsavedChanges ?? false;
  }

  DateTime? get lastSyncTime {
    return metadata?.lastSyncTime;
  }

  bool get needsSync {
    if (metadata?.lastSyncTime == null) return true;
    final hoursSinceSync =
        DateTime.now().difference(metadata!.lastSyncTime!).inHours;
    return hoursSinceSync > 24;
  }

  Map<String, dynamic> toJson() {
    return {
      'settings': settings.toMap(),
      'metadata': metadata?.toJson(),
      'stats': stats,
    };
  }

  SettingsLoaded copyWith({
    AppSettings? settings,
    SettingsMetadata? metadata,
    Map<String, dynamic>? stats,
  }) {
    return SettingsLoaded(
      settings ?? this.settings,
      metadata: metadata ?? this.metadata,
      stats: stats ?? this.stats,
    );
  }
}

class SettingsError extends SettingsState {
  final String message;
  final SettingsErrorType type;
  final dynamic error;
  final StackTrace? stackTrace;
  final AppSettings? fallbackSettings;

  const SettingsError(
    this.message, {
    this.type = SettingsErrorType.unknown,
    this.error,
    this.stackTrace,
    this.fallbackSettings,
  });

  @override
  List<Object?> get props => [
    message,
    type,
    error,
    stackTrace,
    fallbackSettings,
  ];

  bool get canRecover => fallbackSettings != null;
}

enum SettingsErrorType {
  loadFailed,
  saveFailed,
  validationFailed,
  syncFailed,
  networkError,
  permissionDenied,
  unknown,
}

class SettingsOperationSuccess extends SettingsState {
  final String message;
  final SettingsOperation operation;
  final AppSettings settings;
  final dynamic data;

  const SettingsOperationSuccess({
    required this.message,
    required this.operation,
    required this.settings,
    this.data,
  });

  @override
  List<Object?> get props => [message, operation, settings, data];
}

enum SettingsOperation { save, reset, export, import, sync, clear }

class SettingsAccentColorUpdated extends SettingsState {
  final AppSettings settings;
  final String previousColor;
  final String newColor;

  const SettingsAccentColorUpdated({
    required this.settings,
    required this.previousColor,
    required this.newColor,
  });

  @override
  List<Object?> get props => [settings, previousColor, newColor];
}

class SettingsExportReady extends SettingsState {
  final String exportData;
  final String format;
  final AppSettings settings;
  final int itemCount;
  final int sizeBytes;

  const SettingsExportReady({
    required this.exportData,
    required this.format,
    required this.settings,
    required this.itemCount,
    required this.sizeBytes,
  });

  @override
  List<Object?> get props => [
    exportData,
    format,
    settings,
    itemCount,
    sizeBytes,
  ];

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class SettingsImportSuccess extends SettingsState {
  final AppSettings settings;
  final int itemsImported;
  final List<String> warnings;
  final ImportStats stats;

  const SettingsImportSuccess({
    required this.settings,
    required this.itemsImported,
    this.warnings = const [],
    required this.stats,
  });

  @override
  List<Object?> get props => [settings, itemsImported, warnings, stats];
}

class SettingsSyncProgress extends SettingsState {
  final SyncStatus status;
  final double progress;
  final String? currentItem;
  final int itemsProcessed;
  final int totalItems;

  const SettingsSyncProgress({
    required this.status,
    required this.progress,
    this.currentItem,
    required this.itemsProcessed,
    required this.totalItems,
  });

  @override
  List<Object?> get props => [
    status,
    progress,
    currentItem,
    itemsProcessed,
    totalItems,
  ];

  String get progressText {
    return '$itemsProcessed / $totalItems';
  }

  bool get isComplete => itemsProcessed >= totalItems;
}

enum SyncStatus {
  preparing,
  uploading,
  downloading,
  merging,
  completing,
  done,
  failed,
}

class SettingsMetadata {
  final DateTime lastModified;
  final DateTime? lastSyncTime;
  final String? deviceId;
  final String? userId;
  final int version;
  final bool hasUnsavedChanges;
  final Map<String, DateTime> fieldLastModified;

  const SettingsMetadata({
    required this.lastModified,
    this.lastSyncTime,
    this.deviceId,
    this.userId,
    this.version = 1,
    this.hasUnsavedChanges = false,
    this.fieldLastModified = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'lastModified': lastModified.toIso8601String(),
      'lastSyncTime': lastSyncTime?.toIso8601String(),
      'deviceId': deviceId,
      'userId': userId,
      'version': version,
      'hasUnsavedChanges': hasUnsavedChanges,
      'fieldLastModified': fieldLastModified.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
    };
  }

  factory SettingsMetadata.fromJson(Map<String, dynamic> json) {
    return SettingsMetadata(
      lastModified: DateTime.parse(json['lastModified']),
      lastSyncTime:
          json['lastSyncTime'] != null
              ? DateTime.parse(json['lastSyncTime'])
              : null,
      deviceId: json['deviceId'],
      userId: json['userId'],
      version: json['version'] ?? 1,
      hasUnsavedChanges: json['hasUnsavedChanges'] ?? false,
      fieldLastModified:
          (json['fieldLastModified'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), DateTime.parse(value)),
          ) ??
          {},
    );
  }
}

class ImportStats {
  final int settingsImported;
  final int settingsSkipped;
  final int settingsFailed;
  final Duration importDuration;
  final List<String> errors;

  const ImportStats({
    required this.settingsImported,
    required this.settingsSkipped,
    required this.settingsFailed,
    required this.importDuration,
    this.errors = const [],
  });

  int get totalProcessed => settingsImported + settingsSkipped + settingsFailed;

  double get successRate {
    if (totalProcessed == 0) return 0;
    return settingsImported / totalProcessed;
  }
}
