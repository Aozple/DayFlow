import 'package:hive_flutter/hive_flutter.dart';
import 'package:dayflow/core/utils/debug_logger.dart';

class MigrationManager {
  static const String _tag = 'MigrationManager';
  static const String _versionKey = 'db_version';
  static const int currentVersion = 1;

  static Future<void> migrate() async {
    final settingsBox = Hive.box('settings');
    final storedVersion = settingsBox.get(_versionKey, defaultValue: 0);

    DebugLogger.info(
      'Checking migrations',
      tag: _tag,
      data: 'Current: $currentVersion, Stored: $storedVersion',
    );

    if (storedVersion < currentVersion) {
      await _runMigrations(storedVersion, currentVersion);
      await settingsBox.put(_versionKey, currentVersion);
      DebugLogger.success('Migrations completed', tag: _tag);
    }
  }

  static Future<void> _runMigrations(int from, int to) async {
    for (int version = from + 1; version <= to; version++) {
      DebugLogger.info('Running migration v$version', tag: _tag);

      switch (version) {
        case 1:
          await _migrateToV1();
          break;
        // Add future migrations here
      }
    }
  }

  static Future<void> _migrateToV1() async {
    // Example migration
    try {
      final tasksBox = Hive.box('tasks');

      // Add any data transformation needed
      for (final key in tasksBox.keys) {
        final task = tasksBox.get(key);
        if (task is Map && !task.containsKey('version')) {
          task['version'] = 1;
          await tasksBox.put(key, task);
        }
      }

      DebugLogger.success('Migration v1 completed', tag: _tag);
    } catch (e) {
      DebugLogger.error('Migration v1 failed', tag: _tag, error: e);
      throw Exception('Migration failed: $e');
    }
  }
}
