import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/slate_colors.dart';
import 'models/slate_data.dart';
import 'services/beeper.dart';
import 'services/slate_storage.dart';
import 'widgets/edit_screen.dart';
import 'widgets/slate_screen.dart';

// Mark cadence (per design doc design/sharper-mark.md).
// Audio events at t=0 and t=_markIntervalMs define the editor's sync
// pins; the color flash is a short blip at each. Default 150ms
// (~3.6 frames at 24fps) — visible enough for the human eye, still
// 3× shorter than the original 500ms. The Settings PR makes this
// adjustable, with 50ms as the minimum for users who want a true
// single-frame sync blip.
const _flashDurationMs = 150;
const _markIntervalMs = 1000;
const _markCooldownMs = 50;

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
  String? _editingField;
  final Beeper _beeper = Beeper();

  @override
  void initState() {
    super.initState();
    _beeper.preload();
    loadSlateData().then((loaded) {
      if (!mounted) return;
      setState(() => _data = loaded);
    });
  }

  @override
  void dispose() {
    _beeper.dispose();
    super.dispose();
  }

  void _onEdit(String field) {
    setState(() => _editingField = field);
  }

  void _onEditDone(String value) {
    final field = _editingField;
    if (field == null) return;
    final next = _data.withField(field, value);
    setState(() {
      _data = next;
      _editingField = null;
    });
    saveSlateData(next);
  }

  void _onSwipeUpdate(SlateData next) {
    setState(() => _data = next);
    saveSlateData(next);
  }

  void _onMark() {
    if (_isMarking) return;
    setState(() {
      _isMarking = true;
      _colors = SlateColors.markRed;
    });
    _beeper.beep();

    Future.delayed(const Duration(milliseconds: _flashDurationMs), () {
      if (!mounted) return;
      setState(() => _colors = SlateColors.markWhite);
    });

    Future.delayed(const Duration(milliseconds: _markIntervalMs), () {
      if (!mounted) return;
      setState(() => _colors = SlateColors.markGreen);
      _beeper.beepFinal();
    });

    Future.delayed(
      const Duration(milliseconds: _markIntervalMs + _flashDurationMs),
      () {
        if (!mounted) return;
        setState(() => _colors = SlateColors.markWhite);
      },
    );

    Future.delayed(
      const Duration(
        milliseconds: _markIntervalMs + _flashDurationMs + _markCooldownMs,
      ),
      () {
        if (!mounted) return;
        setState(() => _isMarking = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = _editingField;
    return MaterialApp(
      title: 'Nobu Slate',
      home: Scaffold(
        body: editing != null
            ? EditScreen(
                field: editing,
                initialValue: _data.fieldValue(editing),
                onDone: _onEditDone,
              )
            : SlateScreen(
                data: _data,
                colors: _colors,
                onUpdate: _onSwipeUpdate,
                onEdit: _onEdit,
                onMark: _onMark,
              ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
