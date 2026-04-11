import 'package:flutter/material.dart';

class StaggeredColumn extends StatefulWidget {
  final List<Widget> children;
  final Duration delay;
  final Duration duration;
  final CrossAxisAlignment crossAxisAlignment;

  const StaggeredColumn({
    super.key,
    required this.children,
    this.delay = const Duration(milliseconds: 60),
    this.duration = const Duration(milliseconds: 400),
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  State<StaggeredColumn> createState() => _StaggeredColumnState();
}

class _StaggeredColumnState extends State<StaggeredColumn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final totalDuration = widget.duration +
        widget.delay * widget.children.length;
    _controller = AnimationController(vsync: this, duration: totalDuration)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _controller.duration!.inMilliseconds;
    return Column(
      crossAxisAlignment: widget.crossAxisAlignment,
      children: List.generate(widget.children.length, (i) {
        final start = (widget.delay.inMilliseconds * i) / total;
        final end = (widget.delay.inMilliseconds * i +
                widget.duration.inMilliseconds) /
            total;
        final animation = CurvedAnimation(
          parent: _controller,
          curve: Interval(start.clamp(0, 1), end.clamp(0, 1),
              curve: Curves.easeOutCubic),
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
          child: widget.children[i],
        );
      }),
    );
  }
}
