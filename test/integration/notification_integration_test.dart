import 'package:dayflow/core/services/notifications/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayflow/core/di/service_locator.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:dayflow/data/models/habit_model.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

void main() {
  setUpAll(() async {
    // Initialize test environment
    TestWidgetsFlutterBinding.ensureInitialized();
    await setupServiceLocator();
  });

  tearDownAll(() {
    GetIt.I.reset();
  });

  group('Notification Integration Tests', () {
    test('Full notification flow for task', () async {
      // Initialize service
      final service = NotificationService();
      final initialized = await service.initialize();

      expect(initialized, isTrue);
      expect(service.isInitialized, isTrue);

      // Create test task
      final task = TaskModel(
        id: 'integration-test-1',
        title: 'Integration Test Task',
        description: 'This is a test task',
        hasNotification: true,
        dueDate: DateTime.now().add(const Duration(seconds: 10)),
        notificationMinutesBefore: 0,
      );

      // Schedule notification
      final scheduled = await service.scheduleTaskNotification(task);
      expect(scheduled, isTrue);

      // Check pending notifications
      final pending = await service.getPendingNotifications();
      expect(pending.isNotEmpty, isTrue);

      // Cancel notification
      await service.cancelTaskNotification(task.id);

      // Verify cancelled
      final afterCancel = await service.getPendingNotifications();
      final found = afterCancel.any(
        (n) => n.payload?.contains(task.id) ?? false,
      );
      expect(found, isFalse);
    });

    test('Full notification flow for habit', () async {
      // Initialize service
      final service = NotificationService();
      await service.initialize();

      // Create test habit
      final habit = HabitModel(
        id: 'integration-test-habit-1',
        title: 'Test Habit',
        frequency: HabitFrequency.daily,
        hasNotification: true,
        preferredTime: const TimeOfDay(hour: 20, minute: 0),
      );

      // Schedule notification
      final scheduled = await service.scheduleHabitNotification(habit);
      expect(scheduled, isTrue);

      // Cancel notification
      await service.cancelHabitNotification(habit.id);
    });
  });
}
