import 'package:flutter/material.dart';
import '../../data/models/course.dart';
import '../../widgets/animated_progress_ring.dart';

class CourseDetailScreen extends StatelessWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
      appBar: AppBar(
        title: Text(course.code),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AnimatedHeader(course: course, theme: theme, colorScheme: colorScheme),
          const SizedBox(height: 24),
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
          const SizedBox(height: 16),
          _DetailRow(label: 'Course Code', value: course.code, theme: theme),
          _DetailRow(label: 'Instructor', value: course.instructor, theme: theme),
          _DetailRow(label: 'Credits', value: '${course.credits}', theme: theme),
          _DetailRow(label: 'Room', value: course.room, theme: theme),
          _DetailRow(
            label: 'Type',
            value: course.type.name[0].toUpperCase() + course.type.name.substring(1),
            theme: theme,
          ),
        ],
      ),
    );
  }

  int? _classesCanMiss() {
    // How many more classes can be missed while maintaining 75%
    // attended / (total + x) >= 0.75  =>  x <= (attended / 0.75) - total
    final canMiss =
        (course.attendedClasses / 0.75 - course.totalClasses).floor();
    return canMiss;
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
