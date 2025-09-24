import 'package:get_it/get_it.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dayflow/core/services/notifications/notification_service.dart';
import 'package:dayflow/data/repositories/task_repository.dart';
import 'package:dayflow/data/repositories/habit_repository.dart';
import 'package:dayflow/data/repositories/settings_repository.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Register plugins
  sl.registerLazySingleton<FlutterLocalNotificationsPlugin>(
    () => FlutterLocalNotificationsPlugin(),
  );

  // Register notification service
  sl.registerLazySingleton<NotificationService>(
    () => NotificationService(),
    instanceName: 'NotificationService',
  );

  // Register repositories as singletons
  sl.registerLazySingleton<TaskRepository>(() => TaskRepository());
  sl.registerLazySingleton<HabitRepository>(() => HabitRepository());
  sl.registerLazySingleton<SettingsRepository>(() => SettingsRepository());
}
