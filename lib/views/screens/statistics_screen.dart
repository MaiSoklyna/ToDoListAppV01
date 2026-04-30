import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/app_localizations.dart';
import '../../viewmodels/task_viewmodel.dart';
import '../../services/streak_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StreakService _streakService = StreakService();
  int _currentStreak = 0;
  int _bestStreak = 0;
  int _productivityScore = 0;
  int _totalCompletions = 0;

  @override
  void initState() {
    super.initState();
    _loadStreakData();
  }

  Future<void> _loadStreakData() async {
    final taskVM = context.read<TaskViewModel>();
    final results = await Future.wait([
      _streakService.getCurrentStreak(),
      _streakService.getBestStreak(),
      _streakService.getProductivityScore(taskVM.tasks),
      _streakService.getTotalCompletions(),
    ]);
    if (mounted) {
      setState(() {
        _currentStreak = results[0];
        _bestStreak = results[1];
        _productivityScore = results[2];
        _totalCompletions = results[3];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskVM = context.watch<TaskViewModel>();
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final total = taskVM.tasks.length;
    final completed = taskVM.completedTasks.length;
    final active = taskVM.activeTasks.length;

    // Category breakdown
    final categoryMap = <String, int>{};
    for (final task in taskVM.tasks) {
      categoryMap[task.category] = (categoryMap[task.category] ?? 0) + 1;
    }

    // Priority breakdown
    final priorityMap = {1: 0, 2: 0, 3: 0};
    for (final task in taskVM.tasks) {
      priorityMap[task.priority] = (priorityMap[task.priority] ?? 0) + 1;
    }

    // Weekly completion data (last 7 days) - uses completedAt for accuracy
    final now = DateTime.now();
    final weeklyData = <int>[];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final count = taskVM.getCompletedOnDate(day).length;
      weeklyData.add(count);
    }

    if (total == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart,
                size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              l.get('noTasksStats'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Productivity Score
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.speed, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(l.get('productivityScore'),
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('$_productivityScore/100',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _productivityScore >= 70
                                ? Colors.green
                                : _productivityScore >= 40
                                    ? Colors.orange
                                    : Colors.red,
                          )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _productivityScore / 100,
                      minHeight: 10,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      color: _productivityScore >= 70
                          ? Colors.green
                          : _productivityScore >= 40
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Streak cards
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.local_fire_department,
                            color: Colors.deepOrange, size: 32),
                        const SizedBox(height: 8),
                        Text('$_currentStreak',
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text(l.get('currentStreak'),
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.emoji_events,
                            color: Colors.amber, size: 32),
                        const SizedBox(height: 8),
                        Text('$_bestStreak',
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text(l.get('bestStreak'),
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.done_all,
                            color: theme.colorScheme.primary, size: 32),
                        const SizedBox(height: 8),
                        Text('$_totalCompletions',
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text(l.get('totalDone'),
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Summary cards
          Row(
            children: [
              _StatCard(
                label: l.get('total'),
                value: '$total',
                icon: Icons.list_alt,
                color: theme.colorScheme.primary,
                theme: theme,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: l.get('done'),
                value: '$completed',
                icon: Icons.check_circle,
                color: Colors.green,
                theme: theme,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: l.get('active'),
                value: '$active',
                icon: Icons.pending,
                color: Colors.orange,
                theme: theme,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Completion pie chart
          Text(l.get('completionRate'),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: completed.toDouble(),
                          title: '${(completed / total * 100).round()}%',
                          color: Colors.green,
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: active.toDouble(),
                          title: '${(active / total * 100).round()}%',
                          color: theme.colorScheme.surfaceContainerHighest,
                          radius: 55,
                          titleStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                      centerSpaceRadius: 30,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendItem(
                        color: Colors.green, label: l.get('completed')),
                    const SizedBox(height: 8),
                    _LegendItem(
                        color: theme.colorScheme.surfaceContainerHighest,
                        label: l.get('active')),
                  ],
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 30-day completion trend line chart
          Text('Last 30 days',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: _build30DayTrend(context, theme, taskVM, now),
          ),
          const SizedBox(height: 24),

          // Day-of-week productivity bar chart
          Text('By day of week',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: _buildDayOfWeek(context, theme, taskVM),
          ),
          const SizedBox(height: 24),

          // Weekly bar chart
          Text(l.get('thisWeek'),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (weeklyData.reduce((a, b) => a > b ? a : b) + 2)
                    .toDouble(),
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final dayIndex =
                            (now.subtract(Duration(days: 6 - value.toInt())))
                                .weekday;
                        return Text(days[(dayIndex - 1) % 7],
                            style: theme.textTheme.labelSmall);
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: weeklyData.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.toDouble(),
                        color: theme.colorScheme.primary,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Category breakdown
          if (categoryMap.isNotEmpty) ...[
            Text(l.get('byCategory'),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...categoryMap.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(e.key)),
                      Expanded(
                        flex: 5,
                        child: LinearProgressIndicator(
                          value: e.value / total,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${e.value}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 24),

          // Priority breakdown
          Text(l.get('byPriority'),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              _PriorityCard(
                  label: l.get('high'),
                  count: priorityMap[3]!,
                  color: Colors.red,
                  theme: theme),
              const SizedBox(width: 12),
              _PriorityCard(
                  label: l.get('medium'),
                  count: priorityMap[2]!,
                  color: Colors.orange,
                  theme: theme),
              const SizedBox(width: 12),
              _PriorityCard(
                  label: l.get('low'),
                  count: priorityMap[1]!,
                  color: Colors.green,
                  theme: theme),
            ],
          ),
        ],
      ),
    );
  }

  /// Line chart of daily completion counts for the last 30 days. Uses
  /// completedAt for accuracy (so back-dated completions show on the right
  /// day, not the day they were entered).
  Widget _build30DayTrend(
    BuildContext context,
    ThemeData theme,
    TaskViewModel taskVM,
    DateTime now,
  ) {
    final spots = <FlSpot>[];
    int maxY = 0;
    for (int i = 29; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final count = taskVM.getCompletedOnDate(day).length;
      spots.add(FlSpot((29 - i).toDouble(), count.toDouble()));
      if (count > maxY) maxY = count;
    }
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: (maxY + 1).toDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY == 0 ? 1 : (maxY / 4).ceilToDouble(),
          getDrawingHorizontalLine: (_) => FlLine(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          // Show "30d ago" / "today" only — keeps the axis clean.
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 29,
              getTitlesWidget: (value, _) {
                final label = value == 0 ? '30d ago' : 'today';
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(label, style: theme.textTheme.labelSmall),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: maxY == 0 ? 1 : (maxY / 2).ceilToDouble(),
              getTitlesWidget: (value, _) => Text(
                value.toInt().toString(),
                style: theme.textTheme.labelSmall,
              ),
            ),
          ),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: theme.colorScheme.primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  /// Bar chart of total completions bucketed by weekday over the user's
  /// entire history. Surfaces patterns like "I close out tasks on Sundays."
  Widget _buildDayOfWeek(
    BuildContext context,
    ThemeData theme,
    TaskViewModel taskVM,
  ) {
    // 1=Mon..7=Sun. Initialise all keys so empty days still render a 0 bar.
    final byWeekday = <int, int>{for (int i = 1; i <= 7; i++) i: 0};
    for (final task in taskVM.completedTasks) {
      final at = task.completedAt;
      if (at == null) continue;
      byWeekday[at.weekday] = (byWeekday[at.weekday] ?? 0) + 1;
    }
    final maxY = byWeekday.values.fold<int>(0, (m, v) => v > m ? v : m);
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxY + 1).toDouble(),
        barTouchData: BarTouchData(enabled: true),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) => Text(
                labels[value.toInt() - 1],
                style: theme.textTheme.labelSmall,
              ),
            ),
          ),
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: [
          for (int day = 1; day <= 7; day++)
            BarChartGroupData(
              x: day,
              barRods: [
                BarChartRodData(
                  toY: (byWeekday[day] ?? 0).toDouble(),
                  color: theme.colorScheme.tertiary,
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final ThemeData theme;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(value,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _PriorityCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final ThemeData theme;

  const _PriorityCard({
    required this.label,
    required this.count,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(height: 6),
              Text('$count',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(label, style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}
