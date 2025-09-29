import 'package:dayflow/data/models/habit_model.dart';
import 'package:dayflow/presentation/screens/habit/create_habit_screen.dart';
import 'package:dayflow/presentation/screens/note/create_note_screen.dart';
import 'package:dayflow/presentation/screens/settings/settings_screen.dart';
import 'package:dayflow/presentation/screens/statistics/statistics_screen.dart';
import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/task/create_task_screen.dart';
import '../screens/task/task_details_screen.dart';
import '../../data/models/task_model.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'create-task',
            name: 'createTask',
            builder: (context, state) {
              final hourString = state.uri.queryParameters['hour'];
              final dateString = state.uri.queryParameters['date'];

              final hour = hourString != null ? int.tryParse(hourString) : null;
              final date =
                  dateString != null ? DateTime.tryParse(dateString) : null;

              return CreateTaskScreen(prefilledHour: hour, prefilledDate: date);
            },
          ),

          GoRoute(
            path: 'create-note',
            name: 'createNote',
            builder: (context, state) {
              final hourString = state.uri.queryParameters['hour'];
              final dateString = state.uri.queryParameters['date'];

              final hour = hourString != null ? int.tryParse(hourString) : null;
              final date =
                  dateString != null ? DateTime.tryParse(dateString) : null;

              return CreateNoteScreen(prefilledHour: hour, prefilledDate: date);
            },
          ),

          GoRoute(
            path: 'create-habit',
            name: 'createHabit',
            builder: (context, state) {
              final hourString = state.uri.queryParameters['hour'];
              final hour = hourString != null ? int.tryParse(hourString) : null;

              return CreateHabitScreen(prefilledHour: hour);
            },
          ),

          GoRoute(
            path: 'settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),

          GoRoute(
            path: 'statistics',
            name: 'statistics',
            builder: (context, state) => const StatisticsScreen(),
          ),

          GoRoute(
            path: 'edit-task',
            name: 'editTask',
            builder: (context, state) {
              final task = state.extra as TaskModel;
              return CreateTaskScreen(taskToEdit: task, taskId: task.id);
            },
          ),

          GoRoute(
            path: 'task-details',
            name: 'taskDetails',
            builder: (context, state) {
              final task = state.extra as TaskModel;
              return TaskDetailsScreen(task: task);
            },
          ),

          GoRoute(
            path: 'edit-note',
            name: 'editNote',
            builder: (context, state) {
              final note = state.extra as TaskModel;
              return CreateNoteScreen(noteToEdit: note);
            },
          ),

          GoRoute(
            path: 'edit-habit',
            name: 'editHabit',
            builder: (context, state) {
              final habit = state.extra as HabitModel;
              return CreateHabitScreen(habitToEdit: habit);
            },
          ),

          GoRoute(
            path: 'habit-details',
            name: 'habitDetails',
            builder: (context, state) {
              final habit = state.extra as HabitModel;
              return CreateHabitScreen(habitToEdit: habit);
            },
          ),

          GoRoute(
            path: 'habit-stats',
            name: 'habitStats',
            builder: (context, state) {
              final habit = state.extra as HabitModel;
              return StatisticsScreen(selectedHabit: habit);
            },
          ),
        ],
      ),
    ],
  );
}
