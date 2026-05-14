import 'package:flutter/material.dart';
import '../models/slate_colors.dart';
import '../services/swipe_math.dart';
import 'value_box.dart';

class BoxWithSwipe extends StatelessWidget {
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

  void _handleVerticalDrag(DragEndDetails details) {
    final v = details.primaryVelocity ?? 0;
    if (v == 0) return;
    final direction = v < 0 ? 1 : -1;
    final newValue = swipeValue(value, direction);
    if (newValue != value) onChange(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onVerticalDragEnd: _handleVerticalDrag,
      behavior: HitTestBehavior.opaque,
      child: ValueBox(label: label, value: value, colors: colors),
    );
  }
}
