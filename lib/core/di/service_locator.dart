import 'package:get_it/get_it.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dayflow/core/services/notifications/notification_service.dart';
import 'package:dayflow/data/repositories/task_repository.dart';
import 'package:dayflow/data/repositories/habit_repository.dart';
import 'package:dayflow/data/repositories/settings_repository.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  sl.registerLazySingleton<FlutterLocalNotificationsPlugin>(
    () => FlutterLocalNotificationsPlugin(),
  );

  sl.registerLazySingleton<NotificationService>(() => NotificationService());

  sl.registerLazySingleton<TaskRepository>(() => TaskRepository());
  sl.registerLazySingleton<HabitRepository>(() => HabitRepository());
  sl.registerLazySingleton<SettingsRepository>(() => SettingsRepository());
  sl.registerLazySingleton<HabitInstanceRepository>(
    () => HabitInstanceRepository(),
  );
}
