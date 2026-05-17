import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/slate_colors.dart';
import 'models/slate_data.dart';
import 'services/beeper.dart';
import 'widgets/slate_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const NobuSlateApp());
}

class NobuSlateApp extends StatefulWidget {
  const NobuSlateApp({super.key});

  @override
  State<NobuSlateApp> createState() => _NobuSlateAppState();
}

class _NobuSlateAppState extends State<NobuSlateApp> {
  SlateData _data = SlateData.defaults;
  SlateColors _colors = SlateColors.markWhite;
  bool _isMarking = false;
  final Beeper _beeper = Beeper();

  @override
  void initState() {
    super.initState();
    _beeper.preload();
  }

  @override
  void dispose() {
    _beeper.dispose();
    super.dispose();
  }

  void _onUpdate(SlateData next) {
    setState(() => _data = next);
  }

  void _onEdit(String field) {
    developer.log('edit: $field', name: 'slate');
  }

  void _onMark() {
    if (_isMarking) return;
    setState(() {
      _isMarking = true;
      _colors = SlateColors.markRed;
    });
    _beeper.beep();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _colors = SlateColors.markWhite);
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() => _colors = SlateColors.markGreen);
      _beeper.beepFinal();
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _colors = SlateColors.markWhite;
        _isMarking = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nobu Slate',
      home: Scaffold(
        body: SlateScreen(
          data: _data,
          colors: _colors,
          onUpdate: _onUpdate,
          onEdit: _onEdit,
          onMark: _onMark,
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
