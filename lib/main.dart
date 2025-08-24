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

// This is the main entry point of our app.
// It's an async function because we need to do some setup before running the app.
void main() async {
  // Make sure Flutter's widgets are initialized before anything else.
  WidgetsFlutterBinding.ensureInitialized();

  // Set the style for the system UI (like the status bar and navigation bar).
  // We want them to be transparent and have light icons so they're visible.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Enable edge-to-edge display, so our app content can go behind the system bars.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize notification service

  // Initialize Hive, our local database, for Flutter.
  await Hive.initFlutter();

  // Open the 'tasks' and 'settings' boxes in Hive. Think of these as tables for our data.
  await Hive.openBox('tasks');
  await Hive.openBox('settings');

  // Set up the Settings Repository and initialize it.
  final settingsRepository = SettingsRepository();
  await settingsRepository.init();

  // Lock the app to portrait mode for a consistent mobile experience.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Run the main DayFlow application.
  runApp(DayFlowApp(settingsRepository: settingsRepository));
}

// This is the main widget for our DayFlow application.
// It's a StatelessWidget because its properties don't change after creation.
class DayFlowApp extends StatelessWidget {
  // We're passing in the settings repository to manage app settings.
  final SettingsRepository settingsRepository;
  const DayFlowApp({super.key, required this.settingsRepository});

  @override
  Widget build(BuildContext context) {
    // We're using MultiBlocProvider to provide multiple BLoCs (Business Logic Components)
    // to our widget tree, making them accessible to child widgets.
    return MultiBlocProvider(
      providers: [
        // Provide the TaskBloc, which handles all task-related logic.
        // We also immediately tell it to load tasks when it's created.
        BlocProvider(
          create:
              (context) =>
                  TaskBloc(repository: TaskRepository())
                    ..add(const LoadTasks()),
        ),
        // Provide the SettingsBloc, which manages app settings.
        // It also loads settings right after creation.
        BlocProvider(
          create:
              (context) =>
                  SettingsBloc(repository: settingsRepository)
                    ..add(const LoadSettings()),
        ),
      ],
      // BlocBuilder listens to changes in the SettingsBloc state.
      // This helps us dynamically set the app's theme based on user settings.
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          // MaterialApp.router is used for declarative routing with GoRouter.
          return MaterialApp.router(
            title: 'DayFlow', // The title of our app.
            debugShowCheckedModeBanner: false, // Hide the debug banner.
            theme: AppTheme.lightTheme, // Define our light theme.
            darkTheme: AppTheme.darkTheme, // Define our dark theme.
            themeMode:
                ThemeMode.dark, // For now, we're defaulting to dark mode.
            routerConfig: AppRouter.router, // Our routing configuration.
          );
        },
      ),
    );
  }
}