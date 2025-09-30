import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/core/constants/statistics_constants.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StatisticsHeatMap extends StatefulWidget {
  final List<Map<String, dynamic>> heatMapData;

  const StatisticsHeatMap({super.key, required this.heatMapData});

  @override
  State<StatisticsHeatMap> createState() => _StatisticsHeatMapState();
}

class _StatisticsHeatMapState extends State<StatisticsHeatMap> {
  Map<String, dynamic>? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildHeatMapGrid(),
          const SizedBox(height: 12),
          _buildLegend(),
          if (_selectedDay != null) ...[
            const SizedBox(height: 12),
            _buildSelectedDayInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final stats = _calculateStats();

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            CupertinoIcons.square_grid_3x2_fill,
            size: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Activity Heat Map',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (stats != null) _buildHeaderStats(stats),
      ],
    );
  }

  Widget _buildHeaderStats(Map<String, int> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${stats['total']}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.accent,
          ),
        ),
        Text(
          'activities • ${stats['active']} active days',
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
        if (stats['perfect']! > 0)
          Text(
            '${stats['perfect']} perfect days',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.warning,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildHeatMapGrid() {
    if (widget.heatMapData.isEmpty) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - 40;
        final weeksToShow = (widget.heatMapData.length / 7).ceil();
        final squareSize = (availableWidth / weeksToShow).clamp(10.0, 16.0);
        final gap = squareSize * 0.2;

        final weeks = _groupIntoWeeks();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthLabels(weeks, squareSize),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWeekdayLabels(squareSize),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          weeks
                              .map(
                                (week) =>
                                    _buildWeekColumn(week, squareSize, gap),
                              )
                              .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMonthLabels(
    List<List<Map<String, dynamic>>> weeks,
    double squareSize,
  ) {
    if (weeks.isEmpty) return const SizedBox.shrink();

    final months = _getMonthLabels();
    if (months.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 32),
      child: SizedBox(
        height: 20,
        child: Row(
          children:
              months
                  .map(
                    (month) => Expanded(
                      child: Text(
                        month,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  Widget _buildWeekdayLabels(double squareSize) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return SizedBox(
      width: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children:
            days
                .map(
                  (day) => Container(
                    height: squareSize,
                    margin: EdgeInsets.only(bottom: squareSize * 0.2),
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildWeekColumn(
    List<Map<String, dynamic>> week,
    double squareSize,
    double gap,
  ) {
    return Padding(
      padding: EdgeInsets.only(right: gap),
      child: Column(
        children:
            week.map((day) => _buildDaySquare(day, squareSize, gap)).toList(),
      ),
    );
  }

  Widget _buildDaySquare(
    Map<String, dynamic> day,
    double squareSize,
    double gap,
  ) {
    final level = day['level'] as int;
    final isPerfect = day['isPerfectDay'] as bool;
    final activities = day['activities'] as int;
    final date = day['date'] as DateTime;
    final isToday = _isToday(date);
    final isSelected = _selectedDay?['date'] == date;

    return GestureDetector(
      onTap: () => _selectDay(day),
      child: Container(
        width: squareSize,
        height: squareSize,
        margin: EdgeInsets.only(bottom: gap),
        decoration: BoxDecoration(
          color: _getLevelColor(level),
          borderRadius: BorderRadius.circular(squareSize * 0.15),
          border: _getBorder(isToday, isPerfect, isSelected),
        ),
        child:
            activities > 0
                ? Center(
                  child: Text(
                    activities > 9 ? '9+' : activities.toString(),
                    style: TextStyle(
                      fontSize: squareSize * 0.35,
                      fontWeight: FontWeight.bold,
                      color: level > 2 ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                )
                : null,
      ),
    );
  }

  Widget _buildSelectedDayInfo() {
    if (_selectedDay == null) return const SizedBox.shrink();

    final date = _selectedDay!['date'] as DateTime;
    final activities = _selectedDay!['activities'] as int;
    final tasks = _selectedDay!['tasks'] as int;
    final habits = _selectedDay!['habits'] as int;
    final isPerfect = _selectedDay!['isPerfectDay'] as bool;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _formatDate(date),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (isPerfect) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Perfect Day',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _selectedDay = null),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    CupertinoIcons.xmark,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatItem('Tasks', tasks, AppColors.success),
              const SizedBox(width: 16),
              _buildStatItem('Habits', habits, AppColors.info),
              const SizedBox(width: 16),
              _buildStatItem('Total', activities, AppColors.accent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Less',
          style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
        ),
        const SizedBox(width: 8),
        ...List.generate(
          5,
          (i) => Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: _getLevelColor(i),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'More',
          style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
        ),
        const Spacer(),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(100),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: AppColors.warning, width: 1),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'Perfect',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.square_grid_3x2,
            size: 32,
            color: AppColors.textTertiary,
          ),
          SizedBox(height: 8),
          Text(
            'No activity data',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Map<String, int>? _calculateStats() {
    if (widget.heatMapData.isEmpty) return null;

    final totalActivities = widget.heatMapData.fold(
      0,
      (sum, day) => sum + (day['activities'] as int),
    );
    final activeDays =
        widget.heatMapData.where((day) => day['activities'] > 0).length;
    final perfectDays =
        widget.heatMapData.where((day) => day['isPerfectDay'] == true).length;

    return {
      'total': totalActivities,
      'active': activeDays,
      'perfect': perfectDays,
    };
  }

  List<List<Map<String, dynamic>>> _groupIntoWeeks() {
    final weeks = <List<Map<String, dynamic>>>[];
    for (int i = 0; i < widget.heatMapData.length; i += 7) {
      final weekEnd =
          (i + 7 < widget.heatMapData.length)
              ? i + 7
              : widget.heatMapData.length;
      weeks.add(widget.heatMapData.sublist(i, weekEnd));
    }
    return weeks;
  }

  List<String> _getMonthLabels() {
    if (widget.heatMapData.isEmpty) return [];

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final firstDate = widget.heatMapData.first['date'] as DateTime;
    final lastDate = widget.heatMapData.last['date'] as DateTime;

    return firstDate.month == lastDate.month
        ? [months[firstDate.month - 1]]
        : [months[firstDate.month - 1], months[lastDate.month - 1]];
  }

  Border? _getBorder(bool isToday, bool isPerfect, bool isSelected) {
    if (isSelected) return Border.all(color: AppColors.accent, width: 2);
    if (isToday) return Border.all(color: AppColors.accent, width: 1);
    if (isPerfect) return Border.all(color: AppColors.warning, width: 1);
    return null;
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 0:
        return AppColors.surfaceLight;
      case 1:
        return AppColors.success.withAlpha(60);
      case 2:
        return AppColors.success.withAlpha(100);
      case 3:
        return AppColors.success.withAlpha(160);
      case 4:
        return AppColors.success;
      default:
        return AppColors.surfaceLight;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void _selectDay(Map<String, dynamic> day) {
    setState(() {
      _selectedDay = _selectedDay?['date'] == day['date'] ? null : day;
    });

    DebugLogger.verbose(
      'Day selected in heat map',
      tag: StatisticsConstants.logTag,
      data: {
        'date': day['date'].toString().split(' ')[0],
        'activities': day['activities'],
      },
    );
  }
}
