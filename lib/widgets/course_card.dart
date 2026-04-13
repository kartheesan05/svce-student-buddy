import 'package:flutter/material.dart';
import '../data/models/course.dart';
import 'animated_progress_ring.dart';

int _stableLabelIndex(String label) {
  var h = 0;
  for (var i = 0; i < label.length; i++) {
    h = (31 * h + label.codeUnitAt(i)) & 0x7FFFFFFF;
  }
  return h;
}

/// Distinct chip colors for course code prefixes (CS, OE, …); stable per label.
Color _labelChipBackground(String label) {
  const palette = <Color>[
    Color(0xFF1E4A7A), // blue
    Color(0xFF5C2D6B), // purple
    Color(0xFF0F6B5C), // teal
    Color(0xFF8B4513), // rust
    Color(0xFF2D5A3D), // green
    Color(0xFF7A2844), // wine
    Color(0xFF3D4F8C), // indigo
    Color(0xFF6B5B00), // olive
    Color(0xFF006B7A), // cyan
    Color(0xFF5A4A2A), // brown
  ];
  if (label.isEmpty) return palette[0];
  return palette[_stableLabelIndex(label) % palette.length];
}

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback? onTap;

  const CourseCard({super.key, required this.course, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final attendance = course.attendancePercent;
    final label =
        course.code.replaceAll(RegExp(r'[^A-Z]'), '');
    final chipBg = _labelChipBackground(label);

    final Color indicatorColor;
    if (attendance >= 85) {
      indicatorColor = Colors.green;
    } else if (attendance >= 75) {
      indicatorColor = Colors.orange;
    } else {
      indicatorColor = colorScheme.error;
    }

    return Card.filled(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${course.code}  •  ${course.instructor}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedProgressRing(
                backgroundColor: indicatorColor.withValues(alpha: 0.2),
                progress: attendance / 100,
                size: 44,
                strokeWidth: 4,
                progressColor: indicatorColor,
                child: Text(
                  '${attendance.toStringAsFixed(0)}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: indicatorColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
