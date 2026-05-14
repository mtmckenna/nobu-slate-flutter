import 'package:flutter/material.dart';
import '../models/slate_colors.dart';
import 'box.dart';
import 'fitted_value.dart';

class AudioChannelsBox extends StatelessWidget {
  final String left;
  final String right;
  final SlateColors colors;

  const AudioChannelsBox({
    super.key,
    required this.left,
    required this.right,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Box(
      label: 'Audio Channels',
      colors: colors,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: FittedValue('L: $left', color: colors.font)),
            Expanded(child: FittedValue('R: $right', color: colors.font)),
          ],
        ),
      ),
    );
  }
}
