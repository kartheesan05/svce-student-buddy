import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/mock_data.dart';
import '../../data/models/schedule_entry.dart';
import '../../widgets/animated_progress_ring.dart';
import '../../widgets/schedule_tile.dart';
import '../../widgets/staggered_column.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onViewSchedule;
  final VoidCallback onViewCourses;

  const HomeScreen({
    super.key,
    required this.onViewSchedule,
    required this.onViewCourses,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final student = MockData.student;
    final todayClasses = _getTodayClasses();

    final overallAttendance = _calculateOverallAttendance();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Diary'),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
              const SizedBox(width: 4),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                StaggeredColumn(
                  children: [
                    _GreetingCard(
                      name: student.name.split(' ').first,
                      colorScheme: colorScheme,
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _SectionHeader(
                      title: "Today's Classes",
                      actionLabel: 'Full Schedule',
                      onAction: onViewSchedule,
                      theme: theme,
                    ),
                    const SizedBox(height: 8),
                    if (todayClasses.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.celebration_outlined,
                                    size: 40,
                                    color: colorScheme.onSurfaceVariant),
                                const SizedBox(height: 8),
                                Text('No classes today!',
                                    style: theme.textTheme.titleMedium),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ...todayClasses.map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: ScheduleTile(entry: entry),
                          )),
                    const SizedBox(height: 20),
                    _SectionHeader(
                      title: 'Attendance Overview',
                      actionLabel: 'All Courses',
                      onAction: onViewCourses,
                      theme: theme,
                    ),
                    const SizedBox(height: 8),
                    _AttendanceOverviewCard(
                      overallAttendance: overallAttendance,
                      colorScheme: colorScheme,
                      theme: theme,
                    ),
                    const SizedBox(height: 20),
                    _SectionHeader(
                      title: 'Quick Stats',
                      theme: theme,
                    ),
                    const SizedBox(height: 8),
                    _QuickStatsRow(
                      student: student,
                      courseCount: MockData.courses.length,
                      colorScheme: colorScheme,
                      theme: theme,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  List<ScheduleEntry> _getTodayClasses() {
    final weekday = DateTime.now().weekday;
    if (weekday > 5) return [];
    return MockData.schedule.where((e) => e.dayOfWeek == weekday).toList();
  }

  double _calculateOverallAttendance() {
    final courses = MockData.courses;
    if (courses.isEmpty) return 0;
    final totalAttended =
        courses.fold<int>(0, (sum, c) => sum + c.attendedClasses);
    final totalClasses =
        courses.fold<int>(0, (sum, c) => sum + c.totalClasses);
    return totalClasses == 0 ? 0 : totalAttended / totalClasses;
  }
}

class _GreetingCard extends StatelessWidget {
  final String name;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _GreetingCard({
    required this.name,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';
    final today = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting,',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    today,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),
            CircleAvatar(
              radius: 28,
              backgroundColor: colorScheme.primary,
              child: Text(
                name[0],
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final ThemeData theme;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        )),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _AttendanceOverviewCard extends StatelessWidget {
  final double overallAttendance;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _AttendanceOverviewCard({
    required this.overallAttendance,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final lowCourses =
        MockData.courses.where((c) => c.isAttendanceLow).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            AnimatedProgressRing(
              progress: overallAttendance,
              size: 88,
              strokeWidth: 10,
              progressColor: overallAttendance >= 0.75
                  ? Colors.green
                  : colorScheme.error,
              child: Text(
                '${(overallAttendance * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Attendance',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${MockData.courses.length} courses this semester',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (lowCourses.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${lowCourses.length} course${lowCourses.length > 1 ? 's' : ''} below 75%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  final dynamic student;
  final int courseCount;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _QuickStatsRow({
    required this.student,
    required this.courseCount,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(
          icon: Icons.school_outlined,
          label: 'CGPA',
          value: student.cgpa.toStringAsFixed(2),
          colorScheme: colorScheme,
          theme: theme,
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.menu_book_outlined,
          label: 'Courses',
          value: '$courseCount',
          colorScheme: colorScheme,
          theme: theme,
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.timeline_outlined,
          label: 'Semester',
          value: '${student.currentSemester}',
          colorScheme: colorScheme,
          theme: theme,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, color: colorScheme.primary, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
