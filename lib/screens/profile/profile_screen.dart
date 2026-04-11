import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../widgets/animated_progress_ring.dart';
import '../../widgets/staggered_column.dart';
import '../results/results_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final student = MockData.student;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Profile'),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                StaggeredColumn(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8, width: double.infinity),
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        student.name.split(' ').map((w) => w[0]).take(2).join(),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      student.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      student.id,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${student.programme}  •  Semester ${student.currentSemester}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedProgressRing(
                          progress: student.cgpa / 10,
                          size: 100,
                          strokeWidth: 10,
                          progressColor: colorScheme.primary,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                student.cgpa.toStringAsFixed(2),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('CGPA',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _MiniStat(
                              label: 'Credits Earned',
                              value: '${student.totalCreditsEarned}',
                              theme: theme,
                            ),
                            const SizedBox(height: 8),
                            _MiniStat(
                              label: 'Enrolled Since',
                              value: student.enrollmentYear,
                              theme: theme,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: _SectionTitle(title: 'Academic', theme: theme),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: Card.filled(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            _ProfileTile(
                              icon: Icons.assessment_outlined,
                              title: 'Semester Results',
                              subtitle: 'View all semester grades & SGPA',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ResultsScreen(),
                                ),
                              ),
                            ),
                            const Divider(height: 1, indent: 56),
                            _ProfileTile(
                              icon: Icons.emoji_events_outlined,
                              title: 'Achievements',
                              subtitle: "Dean's List — Semester 5",
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: _SectionTitle(title: 'Personal Info', theme: theme),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: Card.filled(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            _ProfileTile(
                              icon: Icons.email_outlined,
                              title: 'Email',
                              subtitle: student.email,
                            ),
                            const Divider(height: 1, indent: 56),
                            _ProfileTile(
                              icon: Icons.phone_outlined,
                              title: 'Phone',
                              subtitle: student.phone,
                            ),
                            const Divider(height: 1, indent: 56),
                            _ProfileTile(
                              icon: Icons.business_outlined,
                              title: 'Department',
                              subtitle: student.department,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: _SectionTitle(title: 'Preferences', theme: theme),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: Card.filled(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            _ProfileTile(
                              icon: Icons.dark_mode_outlined,
                              title: 'Dark Mode',
                              subtitle: 'System default',
                              onTap: () {},
                            ),
                            const Divider(height: 1, indent: 56),
                            _ProfileTile(
                              icon: Icons.notifications_outlined,
                              title: 'Notifications',
                              subtitle: 'Enabled',
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
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
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final ThemeData theme;

  const _SectionTitle({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
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
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ListTile(
      leading: Icon(icon, color: colorScheme.onSurfaceVariant),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: onTap != null
          ? Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant)
          : null,
      onTap: onTap,
    );
  }
}
