import 'package:flutter/material.dart';
import '../models/slate_colors.dart';
import 'fitted_value.dart';

class TitleBar extends StatelessWidget {
  final String title;
  final SlateColors colors;

  const TitleBar({super.key, required this.title, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 5, left: 5),
      color: colors.foreground,
      padding: const EdgeInsets.all(5),
      child: FittedValue(
        title,
        color: colors.font,
      ),
    );
  }
}
