import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../data/models/semester_result.dart';
import '../../widgets/animated_progress_ring.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  int _selectedSemester = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appState = AppStateScope.of(context);
    final results = appState.semesterResults;

    if (results.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Results')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assignment_outlined,
                  size: 64, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                'No results available',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Results will appear once published',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedSemester < 0 || _selectedSemester >= results.length) {
      _selectedSemester = results.length - 1;
    }
    final selected = results[_selectedSemester];

    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SgpaTrendChart(
            results: results,
            selectedIndex: _selectedSemester,
            colorScheme: colorScheme,
            theme: theme,
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(results.length, (i) {
                final isSelected = i == _selectedSemester;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('Sem ${results[i].semester}'),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedSemester = i),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          _SemesterSummary(result: selected, theme: theme, colorScheme: colorScheme),
          const SizedBox(height: 16),
          Text(
            'Course Grades',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...selected.grades.map((grade) => _GradeCard(
                grade: grade,
                theme: theme,
                colorScheme: colorScheme,
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SgpaTrendChart extends StatefulWidget {
  final List<SemesterResult> results;
  final int selectedIndex;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _SgpaTrendChart({
    required this.results,
    required this.selectedIndex,
    required this.colorScheme,
    required this.theme,
  });

  @override
  State<_SgpaTrendChart> createState() => _SgpaTrendChartState();
}

class _SgpaTrendChartState extends State<_SgpaTrendChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SGPA Trend',
                style: widget.theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    size: const Size(double.infinity, 120),
                    painter: _ChartPainter(
                      results: widget.results,
                      selectedIndex: widget.selectedIndex,
                      progress: CurvedAnimation(
                        parent: _controller,
                        curve: Curves.easeOutCubic,
                      ).value,
                      primaryColor: widget.colorScheme.primary,
                      surfaceColor: widget.colorScheme.surfaceContainerHighest,
                      labelColor: widget.colorScheme.onSurfaceVariant,
                      selectedColor: widget.colorScheme.tertiary,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<SemesterResult> results;
  final int selectedIndex;
  final double progress;
  final Color primaryColor;
  final Color surfaceColor;
  final Color labelColor;
  final Color selectedColor;

  _ChartPainter({
    required this.results,
    required this.selectedIndex,
    required this.progress,
    required this.primaryColor,
    required this.surfaceColor,
    required this.labelColor,
    required this.selectedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (results.isEmpty) return;

    const bottomPadding = 20.0;
    final chartHeight = size.height - bottomPadding;
    final barWidth = (size.width / results.length) * 0.5;
    final spacing = size.width / results.length;

    for (int i = 0; i < results.length; i++) {
      final x = spacing * i + spacing / 2;
      final normalizedHeight = ((results[i].sgpa - 6) / 4).clamp(0.0, 1.0);
      final barHeight = chartHeight * normalizedHeight * progress;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x - barWidth / 2,
          chartHeight - barHeight,
          barWidth,
          barHeight,
        ),
        const Radius.circular(6),
      );

      final paint = Paint()
        ..color = i == selectedIndex ? selectedColor : primaryColor.withAlpha(160);
      canvas.drawRRect(rect, paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: results[i].sgpa.toStringAsFixed(1),
          style: TextStyle(
            color: i == selectedIndex ? selectedColor : labelColor,
            fontSize: 10,
            fontWeight: i == selectedIndex ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, chartHeight - barHeight - 16),
      );

      final labelPainter = TextPainter(
        text: TextSpan(
          text: 'S${results[i].semester}',
          style: TextStyle(color: labelColor, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(x - labelPainter.width / 2, chartHeight + 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.progress != progress || old.selectedIndex != selectedIndex;
}

class _SemesterSummary extends StatelessWidget {
  final SemesterResult result;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _SemesterSummary({
    required this.result,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Card.filled(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  AnimatedProgressRing(
                    key: ValueKey('sgpa-${result.semester}'),
                    progress: result.sgpa / 10,
                    size: 72,
                    strokeWidth: 8,
                    progressColor: colorScheme.primary,
                    child: Text(
                      result.sgpa.toStringAsFixed(1),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'SGPA',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Card.filled(
            color: colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  AnimatedProgressRing(
                    key: ValueKey('cgpa-${result.semester}'),
                    progress: result.cgpa / 10,
                    size: 72,
                    strokeWidth: 8,
                    progressColor: colorScheme.tertiary,
                    child: Text(
                      result.cgpa.toStringAsFixed(2),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'CGPA',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onTertiaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Card.filled(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.surfaceContainerHighest,
                    ),
                    child: Center(
                      child: Text(
                        result.creditsEarned.toStringAsFixed(
                            result.creditsEarned == result.creditsEarned.roundToDouble()
                                ? 0
                                : 1),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Credits', style: theme.textTheme.labelLarge),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GradeCard extends StatelessWidget {
  final CourseGrade grade;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _GradeCard({
    required this.grade,
    required this.theme,
    required this.colorScheme,
  });

  Color _gradeColor() {
    switch (grade.grade) {
      case 'O':
        return Colors.green.shade700;
      case 'A+':
      case 'A':
        return Colors.green;
      case 'A-':
        return Colors.green.shade300;
      case 'B+':
      case 'B':
        return Colors.orange;
      case 'P':
        return Colors.blue;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _gradeColor().withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  grade.grade,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _gradeColor(),
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
                    grade.courseName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${grade.courseCode}  •  ${grade.credits.toStringAsFixed(grade.credits == grade.credits.roundToDouble() ? 0 : 1)} credits',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (grade.gradePoint > 0)
              Text(
                '${grade.gradePoint}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
