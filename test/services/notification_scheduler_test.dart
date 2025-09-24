import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dayflow/core/services/notifications/notification_scheduler.dart';
import 'package:dayflow/data/models/task_model.dart';
import 'package:dayflow/data/models/habit_model.dart';
import 'package:dayflow/core/constants/notification_constants.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Mock classes
class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

void main() {
  late NotificationScheduler scheduler;
  late MockFlutterLocalNotificationsPlugin mockPlugin;

  setUpAll(() async {
    // Initialize timezone for tests
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));

    // Register fallback values for mocktail
    registerFallbackValue(AndroidScheduleMode.exactAllowWhileIdle);
    registerFallbackValue(UILocalNotificationDateInterpretation.absoluteTime);
    registerFallbackValue(
      tz.TZDateTime.now(tz.UTC),
    ); // Use UTC instead of local
    registerFallbackValue(const NotificationDetails());
  });

  setUp(() {
    GetIt.I.reset();

    mockPlugin = MockFlutterLocalNotificationsPlugin();
    GetIt.I.registerSingleton<FlutterLocalNotificationsPlugin>(mockPlugin);

    scheduler = NotificationScheduler(mockPlugin);
  });

  tearDown(() {
    GetIt.I.reset();
  });

  group('NotificationScheduler Tests', () {
    group('Task Notifications', () {
      test('should schedule task notification successfully', () async {
        // Arrange
        final task = TaskModel(
          id: 'test-task-123',
          title: 'Test Task',
          description: 'This is a test task',
          hasNotification: true,
          dueDate: DateTime.now().add(const Duration(hours: 1)),
          notificationMinutesBefore: 15,
          priority: 3,
        );

        when(
          () => mockPlugin.zonedSchedule(
            any(),
            any(),
            any(),
            any(),
            any(),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            uiLocalNotificationDateInterpretation: any(
              named: 'uiLocalNotificationDateInterpretation',
            ),
            payload: any(named: 'payload'),
          ),
        ).thenAnswer((_) async {});

        // Act
        final result = await scheduler.scheduleTaskNotification(task);

        // Assert
        expect(result, isTrue);
        verify(
          () => mockPlugin.zonedSchedule(
            any(),
            any(),
            any(),
            any(),
            any(),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: any(named: 'payload'),
          ),
        ).called(1);
      });

      test('should not schedule notification for past due date', () async {
        // Arrange
        final task = TaskModel(
          id: 'test-task-past',
          title: 'Past Task',
          hasNotification: true,
          dueDate: DateTime.now().subtract(const Duration(hours: 1)),
        );

        // Act
        final result = await scheduler.scheduleTaskNotification(task);

        // Assert
        expect(result, isFalse);
        verifyNever(
          () => mockPlugin.zonedSchedule(
            any(),
            any(),
            any(),
            any(),
            any(),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            uiLocalNotificationDateInterpretation: any(
              named: 'uiLocalNotificationDateInterpretation',
            ),
            payload: any(named: 'payload'),
          ),
        );
      });

      test(
        'should not schedule notification for task without notification enabled',
        () async {
          // Arrange
          final task = TaskModel(
            id: 'test-task-no-notif',
            title: 'No Notification Task',
            hasNotification: false,
            dueDate: DateTime.now().add(const Duration(hours: 1)),
          );

          // Act
          final result = await scheduler.scheduleTaskNotification(task);

          // Assert
          expect(result, isFalse);
          verifyNever(
            () => mockPlugin.zonedSchedule(
              any(),
              any(),
              any(),
              any(),
              any(),
              androidScheduleMode: any(named: 'androidScheduleMode'),
              uiLocalNotificationDateInterpretation: any(
                named: 'uiLocalNotificationDateInterpretation',
              ),
              payload: any(named: 'payload'),
            ),
          );
        },
      );

      test('should cancel task notification', () async {
        // Arrange
        const taskId = 'test-task-cancel';
        when(() => mockPlugin.cancel(any())).thenAnswer((_) async {});

        // Act
        await scheduler.cancelNotification(taskId, NotificationTypes.task);

        // Assert
        verify(() => mockPlugin.cancel(any())).called(1);
      });
    });

    group('Habit Notifications', () {
      test('should schedule habit notification successfully', () async {
        // Arrange
        final habit = HabitModel(
          id: 'test-habit-123',
          title: 'Morning Exercise',
          description: 'Daily workout routine',
          frequency: HabitFrequency.daily,
          hasNotification: true,
          preferredTime: const TimeOfDay(hour: 7, minute: 30),
          currentStreak: 5,
        );

        when(
          () => mockPlugin.zonedSchedule(
            any(),
            any(),
            any(),
            any(),
            any(),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            uiLocalNotificationDateInterpretation: any(
              named: 'uiLocalNotificationDateInterpretation',
            ),
            payload: any(named: 'payload'),
          ),
        ).thenAnswer((_) async {});

        // Act
        final result = await scheduler.scheduleHabitNotification(habit);

        // Assert
        expect(result, isTrue);
        verify(
          () => mockPlugin.zonedSchedule(
            any(),
            any(),
            any(),
            any(),
            any(),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: any(named: 'payload'),
          ),
        ).called(1);
      });

      test(
        'should not schedule habit notification without preferred time',
        () async {
          // Arrange
          final habit = HabitModel(
            id: 'test-habit-no-time',
            title: 'No Time Habit',
            frequency: HabitFrequency.daily,
            hasNotification: true,
            preferredTime: null, // No preferred time
          );

          // Act
          final result = await scheduler.scheduleHabitNotification(habit);

          // Assert
          expect(result, isFalse);
          verifyNever(
            () => mockPlugin.zonedSchedule(
              any(),
              any(),
              any(),
              any(),
              any(),
              androidScheduleMode: any(named: 'androidScheduleMode'),
              uiLocalNotificationDateInterpretation: any(
                named: 'uiLocalNotificationDateInterpretation',
              ),
              payload: any(named: 'payload'),
            ),
          );
        },
      );

      test('should cancel habit notification', () async {
        // Arrange
        const habitId = 'test-habit-cancel';
        when(() => mockPlugin.cancel(any())).thenAnswer((_) async {});

        // Act
        await scheduler.cancelNotification(habitId, NotificationTypes.habit);

        // Assert
        verify(() => mockPlugin.cancel(any())).called(1);
      });
    });
  });
}
