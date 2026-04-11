import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/app_state.dart';
import '../../data/models/course.dart';
import '../../data/models/schedule_entry.dart';
import '../../widgets/animated_progress_ring.dart';
import '../../widgets/schedule_tile.dart';
import '../../widgets/staggered_column.dart';
import '../courses/course_detail_screen.dart';
import '../results/results_screen.dart';
import '../schedule/schedule_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onViewCourses;
  final VoidCallback onViewInternalMarks;
  final VoidCallback onViewProfile;

  const HomeScreen({
    super.key,
    required this.onViewCourses,
    required this.onViewInternalMarks,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appState = AppStateScope.of(context);
    final student = appState.student;
    final courses = appState.courses;
    final todayClasses = _getTodayClasses(appState);

    final overallAttendance = _calculateOverallAttendance(courses);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Diary'),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                StaggeredColumn(
                  children: [
                    _GreetingCard(
                      name: student?.name.split(' ').first ?? '',
                      photoBytes: student?.photoBytes,
                      colorScheme: colorScheme,
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _SectionHeader(
                      title: "Today's Classes",
                      actionLabel: 'Full Schedule',
                      onAction: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ScheduleScreen()),
                      ),
                      theme: theme,
                    ),
                    const SizedBox(height: 8),
                    if (todayClasses.isEmpty)
                      Card.filled(
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
                      ...todayClasses.take(3).map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: ScheduleTile(
                              entry: entry,
                              onTap: () {
                                final course = courses.where(
                                  (c) => c.code == entry.courseCode,
                                ).firstOrNull;
                                if (course != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CourseDetailScreen(course: course),
                                    ),
                                  );
                                }
                              },
                            ),
                          )),
                    if (todayClasses.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Center(
                          child: TextButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ScheduleScreen()),
                            ),
                            icon: const Icon(Icons.expand_more, size: 18),
                            label: Text('+${todayClasses.length - 3} more classes'),
                          ),
                        ),
                      ),
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
                      courses: courses,
                      colorScheme: colorScheme,
                      theme: theme,
                      onTap: onViewCourses,
                    ),
                    const SizedBox(height: 20),
                    _SectionHeader(
                      title: 'Quick Stats',
                      theme: theme,
                    ),
                    const SizedBox(height: 8),
                    _QuickStatsRow(
                      student: student,
                      courseCount: courses.length,
                      colorScheme: colorScheme,
                      theme: theme,
                      onCgpaTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ResultsScreen(),
                        ),
                      ),
                      onCoursesTap: onViewCourses,
                      onSemesterTap: onViewProfile,
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

  List<ScheduleEntry> _getTodayClasses(AppState appState) {
    final weekday = DateTime.now().weekday;
    return appState.schedule.where((e) => e.dayOfWeek == weekday).toList();
  }

  double _calculateOverallAttendance(List<Course> courses) {
    final withClasses = courses.where((c) => c.totalClasses > 0).toList();
    if (withClasses.isEmpty) return 0;
    final totalAttended =
        withClasses.fold<int>(0, (sum, c) => sum + c.attendedClasses);
    final totalClasses =
        withClasses.fold<int>(0, (sum, c) => sum + c.totalClasses);
    return totalClasses == 0 ? 0 : totalAttended / totalClasses;
  }
}

class _GreetingCard extends StatelessWidget {
  final String name;
  final Uint8List? photoBytes;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _GreetingCard({
    required this.name,
    this.photoBytes,
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

    return Card.filled(
      color: colorScheme.surfaceContainerHigh,
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
              backgroundImage: photoBytes != null
                  ? MemoryImage(photoBytes!)
                  : null,
              child: photoBytes == null
                  ? Text(
                      name.isNotEmpty ? name[0] : '?',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
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
  final List<Course> courses;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback? onTap;

  const _AttendanceOverviewCard({
    required this.overallAttendance,
    required this.courses,
    required this.colorScheme,
    required this.theme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lowCourses = courses.where((c) => c.totalClasses > 0 && c.isAttendanceLow).toList();
    return Card.filled(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                    '${courses.length} courses this semester',
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
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  final dynamic student;
  final int courseCount;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback? onCgpaTap;
  final VoidCallback? onCoursesTap;
  final VoidCallback? onSemesterTap;

  const _QuickStatsRow({
    required this.student,
    required this.courseCount,
    required this.colorScheme,
    required this.theme,
    this.onCgpaTap,
    this.onCoursesTap,
    this.onSemesterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(
          icon: Icons.school_outlined,
          label: 'CGPA',
          value: student?.cgpa?.toStringAsFixed(2) ?? '–',
          colorScheme: colorScheme,
          theme: theme,
          onTap: onCgpaTap,
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.menu_book_outlined,
          label: 'Courses',
          value: '$courseCount',
          colorScheme: colorScheme,
          theme: theme,
          onTap: onCoursesTap,
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.timeline_outlined,
          label: 'Semester',
          value: '${student?.currentSemester ?? '–'}',
          colorScheme: colorScheme,
          theme: theme,
          onTap: onSemesterTap,
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
  final VoidCallback? onTap;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    required this.theme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card.filled(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
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
      ),
    );
  }
}
