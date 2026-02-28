import 'package:dio/dio.dart';
import '../storage/app_prefs.dart';

class ApiClient {
  ApiClient(this._prefs);

  final AppPrefs _prefs;

  static const String defaultBaseUrl = 'http://10.0.2.2:8000';

  Future<Dio> dio() async {
    final baseUrl = (await _prefs.getBaseUrl())?.trim();
    final resolved =
    (baseUrl == null || baseUrl.isEmpty) ? defaultBaseUrl : baseUrl;

    return Dio(BaseOptions(
      baseUrl: resolved,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ));
  }
}
