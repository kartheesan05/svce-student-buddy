import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme_provider.dart';
import '../../data/app_state.dart';
import '../../widgets/animated_progress_ring.dart';
import '../../widgets/staggered_column.dart';
import '../results/results_screen.dart';

Future<void> _openDeveloperSite() async {
  final uri = Uri.parse('https://kartheesan.dev');
  // Do not gate on canLaunchUrl: on Android 11+ it often returns false unless
  // AndroidManifest.xml declares VIEW + https queries; launchUrl still works.
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appState = AppStateScope.of(context);
    final student = appState.student;

    if (student == null) {
      return Scaffold(
        body: RefreshIndicator(
          onRefresh: () => appState.refreshAllData(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar.large(title: const Text('Profile')),
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ),
      );
    }

    final initials = student.name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => appState.refreshAllData(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                      backgroundImage: student.photoBytes != null
                          ? MemoryImage(student.photoBytes!)
                          : null,
                      child: student.photoBytes == null
                          ? Text(
                              initials,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
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
                        if (student.cgpa != null)
                          AnimatedProgressRing(
                            backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                            progress: student.cgpa! / 10,
                            size: 100,
                            strokeWidth: 10,
                            progressColor: colorScheme.primary,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  student.cgpa!.toStringAsFixed(2),
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
                        if (student.cgpa != null) const SizedBox(width: 32),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (student.totalCreditsEarned != null)
                                _MiniStat(
                                  label: 'Credits Earned',
                                  value: '${student.totalCreditsEarned}',
                                  theme: theme,
                                ),
                              if (student.totalCreditsEarned != null)
                                const SizedBox(height: 8),
                              _MiniStat(
                                label: 'Department',
                                value: student.department,
                                theme: theme,
                              ),
                            ],
                          ),
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
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_hasPersonalInfo(student)) ...[
                      SizedBox(
                        width: double.infinity,
                        child:
                            _SectionTitle(title: 'Personal Info', theme: theme),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: Card.filled(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: _buildPersonalInfoTiles(student),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (student.email != null || student.phone != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child:
                            _SectionTitle(title: 'Contact Info', theme: theme),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: Card.filled(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              if (student.email != null)
                                _ProfileTile(
                                  icon: Icons.email_outlined,
                                  title: 'Email',
                                  subtitle: student.email!,
                                ),
                              if (student.email != null &&
                                  student.phone != null)
                                const Divider(height: 1, indent: 56),
                              if (student.phone != null)
                                _ProfileTile(
                                  icon: Icons.phone_outlined,
                                  title: 'Phone',
                                  subtitle: student.phone!,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_hasAddressInfo(student)) ...[
                      SizedBox(
                        width: double.infinity,
                        child: _SectionTitle(title: 'Address', theme: theme),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: Card.filled(
                          clipBehavior: Clip.antiAlias,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.location_on_outlined,
                                    color: colorScheme.onSurfaceVariant),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    _buildAddressString(student),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (student.transportRoute != null ||
                        student.boardingPoint != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: _SectionTitle(title: 'Transport', theme: theme),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: Card.filled(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              if (student.transportRoute != null)
                                _ProfileTile(
                                  icon: Icons.directions_bus_outlined,
                                  title: 'Route',
                                  subtitle: student.transportRoute!,
                                ),
                              if (student.transportRoute != null &&
                                  student.boardingPoint != null)
                                const Divider(height: 1, indent: 56),
                              if (student.boardingPoint != null)
                                _ProfileTile(
                                  icon: Icons.place_outlined,
                                  title: 'Boarding Point',
                                  subtitle: student.boardingPoint!,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child:
                          _SectionTitle(title: 'Preferences', theme: theme),
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(
                      width: double.infinity,
                      child: _PreferencesCard(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async => appState.logout(),
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign Out'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        onPressed: () => _openDeveloperSite(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Developer',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'kartheesan.dev',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.open_in_new,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                              ],
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
      ),
    );
  }

  static bool _hasPersonalInfo(dynamic student) {
    return student.enrollmentNo != null ||
        student.degree != null ||
        student.fatherName != null ||
        student.motherName != null ||
        student.gender != null ||
        student.dob != null ||
        student.bloodGroup != null;
  }

  static List<Widget> _buildPersonalInfoTiles(dynamic student) {
    final tiles = <({IconData icon, String title, String subtitle})>[];

    if (student.enrollmentNo != null) {
      tiles.add((
        icon: Icons.badge_outlined,
        title: 'Enrollment No',
        subtitle: student.enrollmentNo!,
      ));
    }
    if (student.degree != null) {
      tiles.add((
        icon: Icons.school_outlined,
        title: 'Degree',
        subtitle: student.degree!,
      ));
    }
    if (student.fatherName != null && student.fatherName!.isNotEmpty) {
      tiles.add((
        icon: Icons.person_outlined,
        title: "Father's Name",
        subtitle: student.fatherName!,
      ));
    }
    if (student.motherName != null && student.motherName!.isNotEmpty) {
      tiles.add((
        icon: Icons.person_outlined,
        title: "Mother's Name",
        subtitle: student.motherName!,
      ));
    }
    if (student.gender != null) {
      tiles.add((
        icon: Icons.wc_outlined,
        title: 'Gender',
        subtitle: student.gender!,
      ));
    }
    if (student.dob != null) {
      tiles.add((
        icon: Icons.cake_outlined,
        title: 'Date of Birth',
        subtitle: student.dob!,
      ));
    }
    if (student.bloodGroup != null) {
      tiles.add((
        icon: Icons.water_drop_outlined,
        title: 'Blood Group',
        subtitle: student.bloodGroup!,
      ));
    }

    final widgets = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      if (i > 0) widgets.add(const Divider(height: 1, indent: 56));
      widgets.add(_ProfileTile(
        icon: tiles[i].icon,
        title: tiles[i].title,
        subtitle: tiles[i].subtitle,
      ));
    }
    return widgets;
  }

  static bool _hasAddressInfo(dynamic student) {
    return student.address != null ||
        student.city != null ||
        student.state != null ||
        student.postalCode != null;
  }

  static String _buildAddressString(dynamic student) {
    final parts = <String>[];
    if (student.address != null) parts.add(student.address!);
    if (student.city != null) parts.add(student.city!);
    if (student.state != null && student.postalCode != null) {
      parts.add('${student.state!} - ${student.postalCode!}');
    } else {
      if (student.state != null) parts.add(student.state!);
      if (student.postalCode != null) parts.add(student.postalCode!);
    }
    return parts.join('\n');
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
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = ThemeProvider.of(context);

    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final themeMode = provider.themeMode;
        final themeSource = provider.themeSource;

        String themeModeLabel;
        switch (themeMode) {
          case ThemeMode.system:
            themeModeLabel = 'System';
          case ThemeMode.light:
            themeModeLabel = 'Light';
          case ThemeMode.dark:
            themeModeLabel = 'Dark';
        }

        return Card.filled(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.brightness_6_outlined,
                    color: colorScheme.onSurfaceVariant),
                title: const Text('Appearance'),
                subtitle: Text(
                  themeModeLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode, size: 18),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.auto_mode, size: 18),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode, size: 18),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (v) => provider.setThemeMode(v.first),
                ),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: Icon(Icons.palette_outlined,
                    color: colorScheme.onSurfaceVariant),
                title: const Text('Color Theme'),
                subtitle: Text(
                  themeSource == ThemeSource.dynamic
                      ? 'System wallpaper'
                      : 'Default blue',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: SegmentedButton<ThemeSource>(
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: ThemeSource.dynamic,
                      label: Text('Dynamic'),
                    ),
                    ButtonSegment(
                      value: ThemeSource.defaultSeed,
                      label: Text('Default'),
                    ),
                  ],
                  selected: {themeSource},
                  onSelectionChanged: (v) => provider.setThemeSource(v.first),
                ),
              ),
            ],
          ),
        );
      },
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
