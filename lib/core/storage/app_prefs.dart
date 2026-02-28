import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  static const _kBaseUrl = 'base_url';

  Future<String?> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kBaseUrl);
  }

  Future<void> setBaseUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBaseUrl, value);
  }
}
