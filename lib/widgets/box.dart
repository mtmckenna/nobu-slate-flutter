import 'package:flutter/material.dart';
import '../models/slate_colors.dart';
import 'fitted_value.dart';

class Box extends StatelessWidget {
  final String label;
  final Widget child;
  final SlateColors colors;

  const Box({
    super.key,
    required this.label,
    required this.child,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(top: 5, left: 5),
        color: colors.foreground,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 15,
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: FittedValue(label, color: colors.font),
              ),
            ),
            Expanded(flex: 85, child: child),
          ],
        ),
      ),
    );
  }
}
