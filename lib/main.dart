import 'package:dayflow/core/services/notification_service.dart';
import 'package:dayflow/data/repositories/settings_repository.dart';
import 'package:dayflow/data/repositories/task_repository.dart';
import 'package:dayflow/presentation/blocs/settings/settings_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:dayflow/presentation/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/themes/app_theme.dart';

// App entry point with initialization
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set transparent system bars with light icons
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Enable edge-to-edge display
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize local storage
  await Hive.initFlutter();
  await Hive.openBox('tasks');
  await Hive.openBox('settings');

  // Setup notifications
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Initialize settings
  final settingsRepository = SettingsRepository();
  await settingsRepository.init();

  // Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(DayFlowApp(settingsRepository: settingsRepository));
}

// Main app widget
class DayFlowApp extends StatelessWidget {
  final SettingsRepository settingsRepository;
  const DayFlowApp({super.key, required this.settingsRepository});

  @override
  Widget build(BuildContext context) {
    // Setup BLoCs for state management
    return MultiBlocProvider(
      providers: [
        // Task management
        BlocProvider(
          create:
              (context) =>
                  TaskBloc(repository: TaskRepository())
                    ..add(const LoadTasks()),
        ),
        // Settings management
        BlocProvider(
          create:
              (context) =>
                  SettingsBloc(repository: settingsRepository)
                    ..add(const LoadSettings()),
        ),
      ],
      // Update UI based on settings changes
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          // todo: Use settingsState.themeMode instead of hardcoded dark mode
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
