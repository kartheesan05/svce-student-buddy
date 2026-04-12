import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/app_state.dart';
import '../../data/models/attendance_entry.dart';
import '../../data/models/course.dart';
import '../../widgets/animated_progress_ring.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late Course _course;
  List<AttendanceEntry>? _entries;
  bool _loading = true;
  bool _fetched = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_fetched) {
      _fetched = true;
      _fetchAttendance();
    }
  }

  Future<void> _onRefresh() async {
    final appState = AppStateScope.of(context);
    await appState.refreshAllData();
    if (!mounted) return;
    final no = _course.courseNo;
    if (no != null && no.isNotEmpty) {
      for (final c in appState.courses) {
        if (c.courseNo == no) {
          setState(() => _course = c);
          break;
        }
      }
    }
    await _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    final courseNo = _course.courseNo;
    if (courseNo == null || courseNo.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No course number available';
      });
      return;
    }

    try {
      final api = AppStateScope.of(context).api;
      final data = await api.getAttendanceBySubject(courseNo);
      final list = data['AttendanceBySubject'] as List<dynamic>? ?? [];
      final entries = list
          .map((e) => AttendanceEntry.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final course = _course;
    final attendance = course.attendancePercent;

    final Color attendanceColor;
    if (attendance >= 85) {
      attendanceColor = Colors.green;
    } else if (attendance >= 75) {
      attendanceColor = Colors.orange;
    } else {
      attendanceColor = colorScheme.error;
    }

    final classesCanMiss = _classesCanMiss();

    return Scaffold(
      appBar: AppBar(title: Text(course.code)),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
          _AnimatedHeader(course: course, theme: theme, colorScheme: colorScheme),
          const SizedBox(height: 24),
          if (course.totalClasses > 0) ...[
            Center(
              child: AnimatedProgressRing(
                progress: attendance / 100,
                size: 160,
                strokeWidth: 14,
                progressColor: attendanceColor,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${attendance.toStringAsFixed(1)}%',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: attendanceColor,
                      ),
                    ),
                    Text(
                      'Attendance',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _StatCard(
                  label: 'Attended',
                  value: '${course.attendedClasses}',
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  theme: theme,
                ),
                const SizedBox(width: 8),
                _StatCard(
                  label: 'Missed',
                  value: '${course.totalClasses - course.attendedClasses}',
                  icon: Icons.cancel_outlined,
                  color: colorScheme.error,
                  theme: theme,
                ),
                const SizedBox(width: 8),
                _StatCard(
                  label: 'Total',
                  value: '${course.totalClasses}',
                  icon: Icons.calendar_today_outlined,
                  color: colorScheme.primary,
                  theme: theme,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (classesCanMiss != null)
              Card.filled(
                color: classesCanMiss > 0
                    ? colorScheme.tertiaryContainer
                    : colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        classesCanMiss > 0
                            ? Icons.info_outline
                            : Icons.warning_amber_rounded,
                        color: classesCanMiss > 0
                            ? colorScheme.onTertiaryContainer
                            : colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          classesCanMiss > 0
                              ? 'You can miss up to $classesCanMiss more class${classesCanMiss > 1 ? 'es' : ''} and stay above 75%'
                              : 'You need to attend the next ${-classesCanMiss} class${classesCanMiss < -1 ? 'es' : ''} to reach 75%',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: classesCanMiss > 0
                                ? colorScheme.onTertiaryContainer
                                : colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ] else
            Card.filled(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No attendance data yet',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          _DetailRow(label: 'Course Code', value: course.code, theme: theme),
          _DetailRow(label: 'Instructor', value: course.instructor, theme: theme),
          if (course.credits != null)
            _DetailRow(label: 'Credits', value: '${course.credits}', theme: theme),
          if (course.room != null && course.room!.isNotEmpty)
            _DetailRow(label: 'Room', value: course.room!, theme: theme),
          _DetailRow(
            label: 'Type',
            value: course.type.name[0].toUpperCase() + course.type.name.substring(1),
            theme: theme,
          ),
          const SizedBox(height: 24),
          Text(
            'Attendance Log',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _AttendanceLog(
            entries: _entries,
            loading: _loading,
            error: _error,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 24),
        ],
        ),
      ),
    );
  }

  int? _classesCanMiss() {
    if (_course.totalClasses == 0) return null;
    return (_course.attendedClasses / 0.75 - _course.totalClasses).floor();
  }
}

class _AttendanceLog extends StatelessWidget {
  final List<AttendanceEntry>? entries;
  final bool loading;
  final String? error;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _AttendanceLog({
    required this.entries,
    required this.loading,
    this.error,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Card.filled(
        color: colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            error!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onErrorContainer,
            ),
          ),
        ),
      );
    }

    final list = entries ?? [];
    if (list.isEmpty) {
      return Card.filled(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No attendance records found',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    final dateFormat = DateFormat('d MMM, EEE');

    return Card.filled(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: List.generate(list.length, (i) {
          final entry = list[i];
          final isLast = i == list.length - 1;

          final Color statusColor;
          final IconData statusIcon;
          final String statusLabel;
          switch (entry.status) {
            case AttendanceStatus.present:
              statusColor = Colors.green;
              statusIcon = Icons.check_circle;
              statusLabel = 'Present';
            case AttendanceStatus.absent:
              statusColor = colorScheme.error;
              statusIcon = Icons.cancel;
              statusLabel = 'Absent';
            case AttendanceStatus.onDuty:
              statusColor = Colors.blue;
              statusIcon = Icons.work_outline;
              statusLabel = 'On Duty';
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateFormat.format(entry.date),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Period ${entry.period}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) Divider(height: 1, indent: 48, color: colorScheme.outlineVariant),
            ],
          );
        }),
      ),
    );
  }
}

class _AnimatedHeader extends StatefulWidget {
  final Course course;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _AnimatedHeader({
    required this.course,
    required this.theme,
    required this.colorScheme,
  });

  @override
  State<_AnimatedHeader> createState() => _AnimatedHeaderState();
}

class _AnimatedHeaderState extends State<_AnimatedHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideIn,
      child: FadeTransition(
        opacity: _fadeIn,
        child: Column(
          children: [
            Text(
              widget.course.name,
              style: widget.theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              widget.course.instructor,
              style: widget.theme.textTheme.bodyLarge?.copyWith(
                color: widget.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
      child: Card.filled(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
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
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
