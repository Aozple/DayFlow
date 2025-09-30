import 'package:dayflow/core/services/export_import/importers/base_importer.dart';
import 'package:dayflow/core/services/export_import/models/export_import_models.dart';
import 'package:dayflow/data/models/habit_model.dart';
import 'package:dayflow/data/models/habit_instance_model.dart';
import 'package:dayflow/data/repositories/habit_repository.dart';
import 'package:flutter/material.dart';

class HabitImporter extends BaseImporter {
  final HabitRepository repository;

  HabitImporter({required this.repository}) : super(tag: 'HabitImporter');

  Future<ImportResult> importFromJson(
    List<dynamic> habitsData, {
    List<dynamic>? instancesData,
    bool merge = true,
  }) async {
    try {
      logInfo('Starting habits import', data: '${habitsData.length} habits');

      if (!merge) {
        await repository.clearAllHabits();
        logInfo('Cleared existing habits');
      }

      int imported = 0;
      int failed = 0;
      final errors = <String>[];

      for (final habitData in habitsData) {
        try {
          final habit = HabitModel.fromMap(habitData);
          await repository.addHabit(habit);
          imported++;
        } catch (e) {
          failed++;
          errors.add('Habit import failed: ${e.toString()}');
          logWarning('Failed to import habit', data: e.toString());
        }
      }

      if (instancesData != null) {
        int instancesImported = 0;
        for (final instanceData in instancesData) {
          try {
            final instance = HabitInstanceModel.fromMap(instanceData);
            await repository.addInstance(instance);
            instancesImported++;
          } catch (e) {
            logWarning('Failed to import instance', data: e.toString());
          }
        }
        logInfo('Imported $instancesImported instances');
      }

      logSuccess(
        'Habits import completed',
        data: 'Imported: $imported, Failed: $failed',
      );

      return ImportResult(
        success: imported > 0,
        importedCount: imported,
        failedCount: failed,
        errors: errors,
        type: ImportType.habits,
      );
    } catch (e) {
      logError('Import from JSON failed', error: e);
      return ImportResult(
        success: false,
        error: e.toString(),
        type: ImportType.habits,
      );
    }
  }

  Future<ImportResult> importFromCsv(String csvString) async {
    try {
      logInfo('Starting CSV import');

      if (csvString.startsWith('\uFEFF')) {
        csvString = csvString.substring(1);
      }

      final lines = csvString.split('\n');
      if (lines.isEmpty) {
        throw Exception('Empty CSV file');
      }

      final dataLines =
          lines.skip(1).where((line) => line.trim().isNotEmpty).toList();

      int imported = 0;
      int failed = 0;
      final errors = <String>[];

      for (final line in dataLines) {
        try {
          final fields = parseCsvLine(line);
          if (fields.length < 8) continue;

          TimeOfDay? preferredTime;
          if (fields[3].isNotEmpty) {
            final timeParts = fields[3].split(':');
            if (timeParts.length == 2) {
              preferredTime = TimeOfDay(
                hour: parseInt(timeParts[0]) ?? 0,
                minute: parseInt(timeParts[1]) ?? 0,
              );
            }
          }

          HabitFrequency frequency = HabitFrequency.daily;
          final freqStr = fields[2].toLowerCase();
          if (freqStr.contains('weekly')) {
            frequency = HabitFrequency.weekly;
          } else if (freqStr.contains('monthly')) {
            frequency = HabitFrequency.monthly;
          } else if (freqStr.contains('custom')) {
            frequency = HabitFrequency.custom;
          }

          final habit = HabitModel(
            title: fields[0],
            description: fields[1].isNotEmpty ? fields[1] : null,
            frequency: frequency,
            preferredTime: preferredTime,
            currentStreak: parseInt(fields[4]) ?? 0,
            totalCompletions: parseInt(fields[5]) ?? 0,
            tags:
                fields[6].isNotEmpty
                    ? fields[6]
                        .split(';')
                        .map((t) => t.trim())
                        .where((t) => t.isNotEmpty)
                        .toList()
                    : [],
            hasNotification: fields[7].toLowerCase() == 'yes',
          );

          await repository.addHabit(habit);
          imported++;
        } catch (e) {
          failed++;
          logWarning('Failed to parse CSV line', data: e.toString());
        }
      }

      logSuccess(
        'CSV import completed',
        data: 'Imported: $imported, Failed: $failed',
      );

      return ImportResult(
        success: imported > 0,
        importedCount: imported,
        failedCount: failed,
        errors: errors,
        type: ImportType.habits,
      );
    } catch (e) {
      logError('Import from CSV failed', error: e);
      return ImportResult(
        success: false,
        error: e.toString(),
        type: ImportType.habits,
      );
    }
  }
}
