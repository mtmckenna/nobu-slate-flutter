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

class NobuSlateApp extends StatelessWidget {
  const NobuSlateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Nobu Slate',
      home: Scaffold(
        body: SlateScreen(
          data: SlateData.defaults,
          colors: SlateColors.markWhite,
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
