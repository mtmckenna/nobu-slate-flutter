import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/slate_data.dart';

const _key = 'SLATE_PROPS';

Future<SlateData> loadSlateData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return SlateData.defaults;
    return SlateData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return SlateData.defaults;
  }
}

Future<void> saveSlateData(SlateData data) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data.toJson()));
  } catch (_) {
    // Match original: swallow storage errors, keep running.
  }
}
