import 'package:flutter/material.dart';

void main() {
  runApp(const NobuSlateApp());
}

class NobuSlateApp extends StatelessWidget {
  const NobuSlateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Nobu Slate',
      home: SmokeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SmokeScreen extends StatelessWidget {
  const SmokeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          'Nobu Slate — M1 smoke screen',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
