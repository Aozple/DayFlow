import 'package:dayflow/presentation/screens/note/create_note_screen.dart';
import 'package:dayflow/presentation/screens/settings/settings_screen.dart';
import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/task/create_task_screen.dart';
import '../screens/task/task_details_screen.dart';
import '../../data/models/task_model.dart';

class AppRouter {
  // Main router configuration
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
        routes: [
          // Create task screen with optional prefilled data
          GoRoute(
            path: 'create-task',
            name: 'createTask',
            builder: (context, state) {
              // Extract hour and date from query parameters
              final hourString = state.uri.queryParameters['hour'];
              final dateString = state.uri.queryParameters['date'];

              final hour = hourString != null ? int.tryParse(hourString) : null;
              final date =
                  dateString != null ? DateTime.tryParse(dateString) : null;

              return CreateTaskScreen(prefilledHour: hour, prefilledDate: date);
            },
          ),

          // Create note screen with optional prefilled data
          GoRoute(
            path: 'create-note',
            name: 'createNote',
            builder: (context, state) {
              // Extract hour and date from query parameters
              final hourString = state.uri.queryParameters['hour'];
              final dateString = state.uri.queryParameters['date'];

              final hour = hourString != null ? int.tryParse(hourString) : null;
              final date =
                  dateString != null ? DateTime.tryParse(dateString) : null;

              return CreateNoteScreen(prefilledHour: hour, prefilledDate: date);
            },
          ),

          // Settings screen
          GoRoute(
            path: 'settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),

          // Edit existing task
          GoRoute(
            path: 'edit-task',
            name: 'editTask',
            builder: (context, state) {
              final task = state.extra as TaskModel;
              return CreateTaskScreen(taskToEdit: task, taskId: task.id);
            },
          ),

          // Task details view
          GoRoute(
            path: 'task-details',
            name: 'taskDetails',
            builder: (context, state) {
              final task = state.extra as TaskModel;
              return TaskDetailsScreen(task: task);
            },
          ),

          // Edit existing note
          GoRoute(
            path: 'edit-note',
            name: 'editNote',
            builder: (context, state) {
              final note = state.extra as TaskModel;
              return CreateNoteScreen(noteToEdit: note);
            },
          ),
        ],
      ),
    ],
  );
}
