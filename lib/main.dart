import 'package:dayflow/core/di/service_locator.dart';
import 'package:dayflow/core/services/notifications/notification_service.dart';
import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/data/migrations/migration_manager.dart';
import 'package:dayflow/data/repositories/settings_repository.dart';
import 'package:dayflow/presentation/blocs/habits/habit_bloc.dart';
import 'package:dayflow/presentation/blocs/settings/settings_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:dayflow/presentation/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get_it/get_it.dart';
import 'core/themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await Hive.initFlutter();
  await Hive.openBox(AppConstants.tasksBox);
  await Hive.openBox(AppConstants.settingsBox);
  await Hive.openBox(AppConstants.habitsBox);
  await Hive.openBox(AppConstants.habitInstancesBox);

  await MigrationManager.migrate();

  await setupServiceLocator();

  final notificationService = GetIt.I<NotificationService>();
  await notificationService.initialize();

  final settingsRepository = GetIt.I<SettingsRepository>();
  await settingsRepository.init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const DayFlowApp());
}

class DayFlowApp extends StatelessWidget {
  const DayFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => TaskBloc()..add(const LoadTasks())),
        BlocProvider(create: (_) => HabitBloc()..add(const LoadHabits())),
        BlocProvider(create: (_) => SettingsBloc()..add(const LoadSettings())),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          String accentColor = '#4A90E2';

          if (settingsState is SettingsLoaded) {
            accentColor = settingsState.accentColor;
          }

          return MaterialApp.router(
            title: 'DayFlow',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getDarkTheme(accentColor),
            darkTheme: AppTheme.getDarkTheme(accentColor),
            themeMode: ThemeMode.dark,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
