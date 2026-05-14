import 'package:flutter/material.dart';

class DoubleBox extends StatelessWidget {
  final List<Widget> children;

  const DoubleBox({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
