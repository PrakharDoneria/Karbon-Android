import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://agentic-ai-wine.vercel.app';

  static const _countKey = 'api_request_count';
  static const _lastResetKey = 'api_request_last_reset';

  static Future<bool> _canMakeRequest() async {

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastResetMillis = prefs.getInt(_lastResetKey) ?? 0;
    final lastReset = DateTime.fromMillisecondsSinceEpoch(lastResetMillis);
    int count = prefs.getInt(_countKey) ?? 0;

    if (now.difference(lastReset).inMinutes >= 1) {
      // Reset counter
      await prefs.setInt(_lastResetKey, now.millisecondsSinceEpoch);
      await prefs.setInt(_countKey, 1);
      return true;
    }

    if (count < 3) {
      await prefs.setInt(_countKey, count + 1);
      return true;
    }

    return false;
  }

  static Future<String?> generateHtml(String query) async {
    final allowed = await _canMakeRequest();
    if (!allowed) {
      return 'Rate limit reached. Please wait a minute or subscribe for unlimited access.';
    }

    final uri = Uri.parse('$baseUrl/generate?q=${Uri.encodeComponent(query)}');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('code')) {
        return data['code'];
      }
    }

    return null;
  }
}
