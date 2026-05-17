import 'package:flutter/material.dart';
import '../models/slate_colors.dart';
import '../services/swipe_math.dart';
import 'value_box.dart';

// Matches MIN_VERTICAL_SWIPE_LENGTH from the original swipe-functions.js.
const _minVerticalSwipe = 5.0;

class BoxWithSwipe extends StatefulWidget {
  final String label;
  final String value;
  final SlateColors colors;
  final ValueChanged<String> onChange;
  final VoidCallback onTap;

  const BoxWithSwipe({
    super.key,
    required this.label,
    required this.value,
    required this.colors,
    required this.onChange,
    required this.onTap,
  });

  @override
  State<BoxWithSwipe> createState() => _BoxWithSwipeState();
}

class _BoxWithSwipeState extends State<BoxWithSwipe> {
  double _dy = 0;

  void _onStart(DragStartDetails _) => _dy = 0;

  void _onUpdate(DragUpdateDetails d) => _dy += d.delta.dy;

  void _onEnd(DragEndDetails _) {
    if (_dy.abs() < _minVerticalSwipe) return;
    final direction = _dy < 0 ? 1 : -1; // upward drag => increment
    final next = swipeValue(widget.value, direction);
    if (next != widget.value) widget.onChange(next);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onVerticalDragStart: _onStart,
      onVerticalDragUpdate: _onUpdate,
      onVerticalDragEnd: _onEnd,
      behavior: HitTestBehavior.opaque,
      child: ValueBox(
        label: widget.label,
        value: widget.value,
        colors: widget.colors,
      ),
    );
  }
}
