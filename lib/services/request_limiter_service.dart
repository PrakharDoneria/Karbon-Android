import 'package:shared_preferences/shared_preferences.dart';

class RequestLimiterService {
  static const String _countKey = 'request_count';
  static const String _timestampKey = 'request_timestamp';
  static const int freeLimitPerMinute = 3;

  static final RequestLimiterService instance = RequestLimiterService._internal();
  RequestLimiterService._internal();

  Future<bool> canMakeRequest({required bool isProUser}) async {
    if (isProUser) return true;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastTimestamp = prefs.getInt(_timestampKey) ?? 0;
    final lastTime = DateTime.fromMillisecondsSinceEpoch(lastTimestamp);
    final count = prefs.getInt(_countKey) ?? 0;

    if (now.difference(lastTime).inMinutes >= 1) {
      await prefs.setInt(_timestampKey, now.millisecondsSinceEpoch);
      await prefs.setInt(_countKey, 1);
      return true;
    }

    if (count < freeLimitPerMinute) {
      await prefs.setInt(_countKey, count + 1);
      return true;
    }

    return false;
  }
}
