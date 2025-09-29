import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:flutter/cupertino.dart';

class TasksBreakdown extends StatelessWidget {
  final TaskLoaded taskState;
  final (DateTime, DateTime) dateRange;

  const TasksBreakdown({
    super.key,
    required this.taskState,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context) {
    final breakdown = _calculateBreakdown();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withAlpha(30), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildStatusDistribution(breakdown.statusData),
          const SizedBox(height: 16),
          _buildPriorityAnalysis(breakdown.priorityData),
          const SizedBox(height: 16),
          _buildTimeEstimates(breakdown.timeData),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(
              CupertinoIcons.doc_text_fill,
              size: 18,
              color: AppColors.success,
            ),
            SizedBox(width: 8),
            Text(
              'Tasks Analysis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.success.withAlpha(20),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${taskState.activeTasks.length} active',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDistribution(StatusData data) {
    final total = data.completed + data.pending + data.overdue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status Overview',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                'Completed',
                data.completed,
                AppColors.success,
                CupertinoIcons.checkmark_circle_fill,
                total,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatusCard(
                'Pending',
                data.pending,
                AppColors.info,
                CupertinoIcons.clock_fill,
                total,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatusCard(
                'Overdue',
                data.overdue,
                AppColors.error,
                CupertinoIcons.exclamationmark_circle_fill,
                total,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusCard(
    String label,
    int count,
    Color color,
    IconData icon,
    int total,
  ) {
    final percentage = total > 0 ? ((count / total) * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider.withAlpha(20), width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 4),
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.divider.withAlpha(30),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityAnalysis(Map<int, int> priorityData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority Distribution',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ...priorityData.entries.map((entry) {
          return _buildPriorityItem(entry.key, entry.value);
        }),
      ],
    );
  }

  Widget _buildPriorityItem(int priority, int count) {
    final color = AppColors.getPriorityColor(priority);
    final label = _getPriorityLabel(priority);
    final total = taskState.activeTasks.length;
    final percentage = total > 0 ? (count / total) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage,
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withAlpha(150),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeEstimates(TimeData timeData) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withAlpha(20),
            AppColors.accent.withAlpha(10),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withAlpha(30), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTimeMetric(
            'Estimated',
            '${timeData.estimatedHours}h',
            CupertinoIcons.timer,
          ),
          Container(
            width: 1,
            height: 30,
            color: AppColors.divider.withAlpha(30),
          ),
          _buildTimeMetric(
            'Actual',
            '${timeData.actualHours}h',
            CupertinoIcons.stopwatch,
          ),
          Container(
            width: 1,
            height: 30,
            color: AppColors.divider.withAlpha(30),
          ),
          _buildTimeMetric(
            'Accuracy',
            '${timeData.accuracy}%',
            CupertinoIcons.scope,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppColors.accent),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
        ),
      ],
    );
  }

  String _getPriorityLabel(int priority) {
    switch (priority) {
      case 1:
        return 'Low';
      case 2:
        return 'Normal';
      case 3:
        return 'Medium';
      case 4:
        return 'High';
      case 5:
        return 'Urgent';
      default:
        return 'Unknown';
    }
  }

  ({StatusData statusData, Map<int, int> priorityData, TimeData timeData})
  _calculateBreakdown() {
    final rangeTasks =
        taskState.tasks.where((task) {
          if (task.dueDate == null) return false;
          return task.dueDate!.isAfter(
                dateRange.$1.subtract(const Duration(days: 1)),
              ) &&
              task.dueDate!.isBefore(dateRange.$2.add(const Duration(days: 1)));
        }).toList();

    final completed = rangeTasks.where((t) => t.isCompleted).length;
    final overdue =
        rangeTasks.where((t) => t.isOverdue && !t.isCompleted).length;
    final pending = rangeTasks.length - completed - overdue;

    final priorityData = <int, int>{};
    for (final task in taskState.activeTasks) {
      priorityData[task.priority] = (priorityData[task.priority] ?? 0) + 1;
    }

    final estimatedMinutes = taskState.activeTasks.fold(
      0,
      (sum, task) => sum + (task.estimatedMinutes ?? 0),
    );

    final actualMinutes = taskState.completedTasks.fold(
      0,
      (sum, task) => sum + (task.actualMinutes ?? 0),
    );

    final accuracy =
        estimatedMinutes > 0 && actualMinutes > 0
            ? ((1 -
                        (estimatedMinutes - actualMinutes).abs() /
                            estimatedMinutes) *
                    100)
                .round()
                .clamp(0, 100)
            : 0;

    return (
      statusData: StatusData(
        completed: completed,
        pending: pending,
        overdue: overdue,
      ),
      priorityData: priorityData,
      timeData: TimeData(
        estimatedHours: estimatedMinutes ~/ 60,
        actualHours: actualMinutes ~/ 60,
        accuracy: accuracy,
      ),
    );
  }
}

class StatusData {
  final int completed;
  final int pending;
  final int overdue;

  StatusData({
    required this.completed,
    required this.pending,
    required this.overdue,
  });
}

class TimeData {
  final int estimatedHours;
  final int actualHours;
  final int accuracy;

  TimeData({
    required this.estimatedHours,
    required this.actualHours,
    required this.accuracy,
  });
}
