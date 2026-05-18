import 'package:flutter/material.dart';
import '../models/slate_colors.dart';
import 'box.dart';
import 'fitted_value.dart';

class ValueBox extends StatelessWidget {
  final String label;
  final String value;
  final SlateColors colors;

  const ValueBox({
    super.key,
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Box(
      label: label,
      colors: colors,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: FittedValue(
          value,
          color: colors.font,
          align: TextAlign.center,
        ),
      ),
    );
  }
}
