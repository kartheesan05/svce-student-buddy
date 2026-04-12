import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../data/models/course.dart';
import '../../widgets/course_card.dart';
import 'course_detail_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  String _searchQuery = '';
  CourseType? _filterType;

  List<Course> _filteredCourses(List<Course> allCourses) {
    return allCourses.where((course) {
      final matchesSearch = _searchQuery.isEmpty ||
          course.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          course.code.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _filterType == null || course.type == _filterType;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appState = AppStateScope.of(context);
    final filtered = _filteredCourses(appState.courses);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => appState.refreshAllData(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              title: const Text('Courses'),
            ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: const InputDecoration(
                    hintText: 'Search courses...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _filterType == null,
                        onSelected: () =>
                            setState(() => _filterType = null),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Theory',
                        selected: _filterType == CourseType.theory,
                        onSelected: () =>
                            setState(() => _filterType = CourseType.theory),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Lab',
                        selected: _filterType == CourseType.lab,
                        onSelected: () =>
                            setState(() => _filterType = CourseType.lab),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Elective',
                        selected: _filterType == CourseType.elective,
                        onSelected: () =>
                            setState(() => _filterType = CourseType.elective),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${filtered.length} courses  •  ${_totalCredits(filtered)} credits',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final course = filtered[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: CourseCard(
                      course: course,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CourseDetailScreen(course: course),
                        ),
                      ),
                    ),
                  );
                },
                childCount: filtered.length,
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
        ),
      ),
    );
  }

  String _totalCredits(List<Course> courses) {
    final known = courses.where((c) => c.credits != null).toList();
    if (known.isEmpty) return '–';
    final total = known.fold<int>(0, (sum, c) => sum + c.credits!);
    final suffix = known.length < courses.length ? '+' : '';
    return '$total$suffix';
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
    );
  }
}
