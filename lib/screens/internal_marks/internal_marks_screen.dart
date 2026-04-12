import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../data/models/internal_mark.dart';

class InternalMarksScreen extends StatelessWidget {
  const InternalMarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appState = AppStateScope.of(context);
    final marks = appState.internalMarks;
    final isLoading = appState.isInternalMarksLoading;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => appState.refreshAllData(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(title: const Text('Internal Marks')),
          if (isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (marks.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.assignment_outlined,
                        size: 64, color: colorScheme.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text(
                      'No internal marks available',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Marks will appear once published',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount: marks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final mark = marks[index];
                  return mark.isLab
                      ? _LabMarkCard(mark: mark, theme: theme, colorScheme: colorScheme)
                      : _TheoryMarkCard(mark: mark, theme: theme, colorScheme: colorScheme);
                },
              ),
            ),
        ],
        ),
      ),
    );
  }
}

class _TheoryMarkCard extends StatelessWidget {
  final InternalMark mark;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _TheoryMarkCard({
    required this.mark,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mark.courseName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              mark.courseCode,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MarkSection(
                    title: 'CAT',
                    entries: [
                      _MarkEntry('1', mark.cat1),
                      _MarkEntry('2', mark.cat2),
                      _MarkEntry('3', mark.cat3),
                    ],
                    accentColor: colorScheme.primary,
                    theme: theme,
                    colorScheme: colorScheme,
                  ),
                ),
                Container(
                  width: 1,
                  height: 56,
                  color: colorScheme.outlineVariant,
                ),
                Expanded(
                  child: _MarkSection(
                    title: 'Assignment',
                    entries: [
                      _MarkEntry('1', mark.asign1),
                      _MarkEntry('2', mark.asign2),
                      _MarkEntry('3', mark.asign3),
                    ],
                    accentColor: colorScheme.tertiary,
                    theme: theme,
                    colorScheme: colorScheme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LabMarkCard extends StatelessWidget {
  final InternalMark mark;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _LabMarkCard({
    required this.mark,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mark.courseName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mark.courseCode,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Lab',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MarkSection(
                    title: 'CAT',
                    entries: [
                      _MarkEntry('1', mark.cat1),
                      _MarkEntry('2', mark.cat2),
                      _MarkEntry('3', mark.cat3),
                    ],
                    accentColor: colorScheme.primary,
                    theme: theme,
                    colorScheme: colorScheme,
                  ),
                ),
                Container(
                  width: 1,
                  height: 56,
                  color: colorScheme.outlineVariant,
                ),
                Expanded(
                  child: _MarkSection(
                    title: 'Assignment',
                    entries: [
                      _MarkEntry('1', mark.asign1),
                      _MarkEntry('2', mark.asign2),
                      _MarkEntry('3', mark.asign3),
                    ],
                    accentColor: colorScheme.tertiary,
                    theme: theme,
                    colorScheme: colorScheme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.science_outlined,
                    size: 18, color: colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'Model Exam',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                _MarkChip(
                  value: mark.modelExam,
                  color: colorScheme.secondary,
                  theme: theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkSection extends StatelessWidget {
  final String title;
  final List<_MarkEntry> entries;
  final Color accentColor;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _MarkSection({
    required this.title,
    required this.entries,
    required this.accentColor,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: entries
                .map((e) => _MarkChipLabeled(
                      label: e.label,
                      value: e.value,
                      color: accentColor,
                      theme: theme,
                      colorScheme: colorScheme,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _MarkChipLabeled extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _MarkChipLabeled({
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MarkChip(value: value, color: color, theme: theme),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MarkChip extends StatelessWidget {
  final String value;
  final Color color;
  final ThemeData theme;

  const _MarkChip({
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != '-';
    return Container(
      constraints: const BoxConstraints(minWidth: 40),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: hasValue ? color.withAlpha(25) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: hasValue ? null : Border.all(color: color.withAlpha(50)),
      ),
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
          color: hasValue ? color : color.withAlpha(100),
        ),
      ),
    );
  }
}

class _MarkEntry {
  final String label;
  final String value;
  const _MarkEntry(this.label, this.value);
}
