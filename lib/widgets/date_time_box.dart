import 'dart:async';
import 'package:flutter/material.dart';
import '../models/slate_colors.dart';
import 'box.dart';
import 'fitted_value.dart';

class DateTimeBox extends StatefulWidget {
  final SlateColors colors;

  const DateTimeBox({super.key, required this.colors});

  @override
  State<DateTimeBox> createState() => _DateTimeBoxState();
}

class _DateTimeBoxState extends State<DateTimeBox> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String get _date =>
      '${_now.year}-${_two(_now.month)}-${_two(_now.day)}';

  String get _time =>
      '${_two(_now.hour)}:${_two(_now.minute)}:${_two(_now.second)}';

  @override
  Widget build(BuildContext context) {
    return Box(
      label: 'Date/Time',
      colors: widget.colors,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: FittedValue(_date, color: widget.colors.font)),
            Expanded(child: FittedValue(_time, color: widget.colors.font)),
          ],
        ),
      ),
    );
  }
}
