import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../data/models/schedule_entry.dart';
import '../../widgets/schedule_tile.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _fullDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now().weekday; // 1=Mon ... 7=Sun
    _tabController = TabController(
      length: 7,
      vsync: this,
      initialIndex: today - 1,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar.large(
            title: const Text('Schedule'),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: _days.map((d) => Tab(text: d)).toList(),
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
              ),
              Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: List.generate(7, (dayIndex) {
            final dayClasses = MockData.schedule
                .where((e) => e.dayOfWeek == dayIndex + 1)
                .toList();

            if (dayClasses.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.free_breakfast_outlined,
                        size: 64, color: colorScheme.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text(
                      'No classes on ${_fullDays[dayIndex]}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            return _DaySchedule(
              classes: dayClasses,
              dayIndex: dayIndex,
              theme: theme,
              colorScheme: colorScheme,
            );
          }),
        ),
      ),
    );
  }
}

class _DaySchedule extends StatefulWidget {
  final List<ScheduleEntry> classes;
  final int dayIndex;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _DaySchedule({
    required this.classes,
    required this.dayIndex,
    required this.theme,
    required this.colorScheme,
  });

  @override
  State<_DaySchedule> createState() => _DayScheduleState();
}

class _DayScheduleState extends State<_DaySchedule>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
          milliseconds: 300 + widget.classes.length * 80),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: widget.classes.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${widget.classes.length} class${widget.classes.length > 1 ? 'es' : ''}',
              style: widget.theme.textTheme.bodySmall?.copyWith(
                color: widget.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        final i = index - 1;
        final total = _controller.duration!.inMilliseconds;
        final delay = 80.0 * i;
        final start = (delay / total).clamp(0.0, 1.0);
        final end = ((delay + 300) / total).clamp(0.0, 1.0);

        final animation = CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        );

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Opacity(
              opacity: animation.value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - animation.value)),
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: ScheduleTile(entry: widget.classes[i]),
          ),
        );
      },
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _TabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
