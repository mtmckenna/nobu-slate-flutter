import 'package:flutter/material.dart';

class FittedValue extends StatelessWidget {
  final String text;
  final Color color;
  final TextAlign align;

  const FittedValue(
    this.text, {
    super.key,
    required this.color,
    this.align = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      alignment: align == TextAlign.left
          ? Alignment.centerLeft
          : Alignment.center,
      child: Text(
        ' $text ',
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
          color: color,
          fontFamily: 'Helvetica Neue',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
