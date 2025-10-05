import 'package:dayflow/core/di/service_locator.dart';
import 'package:dayflow/core/services/notifications/notification_service.dart';
import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
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

Future<void> _initializeUI() async {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

Future<void> _initializeStorage() async {
  await Hive.initFlutter();

  await Future.wait([
    Hive.openBox(AppConstants.tasksBox),
    Hive.openBox(AppConstants.settingsBox),
    Hive.openBox(AppConstants.habitsBox),
    Hive.openBox(AppConstants.habitInstancesBox),
  ]);

  await MigrationManager.migrate();
}

Future<void> _initializeServices() async {
  await setupServiceLocator();

  final notificationService = GetIt.I<NotificationService>();
  final settingsRepository = GetIt.I<SettingsRepository>();

  await Future.wait([
    notificationService.initialize(),
    settingsRepository.init(),
  ]);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    DebugLogger.info('Starting app initialization', tag: 'AppInit');

    await DebugLogger.timeOperation(
      'App Initialization',
      () => Future.wait([
        _initializeUI(),
        _initializeStorage(),
        _initializeServices(),
      ]),
    );

    DebugLogger.success('App initialized successfully', tag: 'AppInit');
    runApp(const DayFlowApp());
  } catch (error, stackTrace) {
    DebugLogger.error(
      'Failed to initialize app',
      tag: 'AppInit',
      error: error,
      stackTrace: stackTrace,
    );

    runApp(_FallbackApp(error: error.toString()));
  }
}

class DayFlowApp extends StatelessWidget {
  const DayFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => GetIt.I<TaskBloc>()),
        BlocProvider(create: (_) => GetIt.I<HabitBloc>()),
        BlocProvider(create: (_) => GetIt.I<SettingsBloc>()),
      ],
      child: _AppInitializer(
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
      ),
    );
  }
}

class _AppInitializer extends StatefulWidget {
  final Widget child;
  const _AppInitializer({required this.child});

  @override
  State<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<_AppInitializer> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TaskBloc>().add(const LoadTasks());
        context.read<HabitBloc>().add(const LoadHabits());
        context.read<SettingsBloc>().add(const LoadSettings());
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _FallbackApp extends StatelessWidget {
  final String error;
  const _FallbackApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 60),
                const SizedBox(height: 20),
                const Text(
                  'Loading Error',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  'Please restart the app',
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
