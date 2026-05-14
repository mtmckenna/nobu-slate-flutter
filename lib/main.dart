import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/slate_colors.dart';
import 'models/slate_data.dart';
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

  void _onUpdate(SlateData next) {
    setState(() => _data = next);
  }

  void _onEdit(String field) {
    developer.log('edit: $field', name: 'slate');
  }

  void _onMark() {
    developer.log('mark!', name: 'slate');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nobu Slate',
      home: Scaffold(
        body: SlateScreen(
          data: _data,
          colors: SlateColors.markWhite,
          onUpdate: _onUpdate,
          onEdit: _onEdit,
          onMark: _onMark,
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
