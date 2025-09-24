import 'package:dayflow/core/di/service_locator.dart';
import 'package:dayflow/core/services/notifications/notification_service.dart';
import 'package:dayflow/core/constants/app_constants.dart';
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

  // System UI setup
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.tasksBox);
  await Hive.openBox(AppConstants.settingsBox);
  await Hive.openBox(AppConstants.habitsBox);
  await Hive.openBox(AppConstants.habitInstancesBox);

  // Setup DI
  await setupServiceLocator();

  // Initialize services
  final notificationService = NotificationService();
  await notificationService.initialize();

  final settingsRepository = GetIt.I<SettingsRepository>();
  await settingsRepository.init();

  // Lock orientation
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
          return MaterialApp.router(
            title: 'DayFlow',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
