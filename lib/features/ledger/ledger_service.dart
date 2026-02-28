import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import 'colleague_ledger_model.dart';

class LedgerService {
  LedgerService(this._apiClient);
  final ApiClient _apiClient;

  Future<ColleagueLedgerResponse> getColleagueLedger(int colleagueId) async {
    final dio = await _apiClient.dio();
    final res = await dio.get(Endpoints.colleagueLedger(colleagueId));
    return ColleagueLedgerResponse.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<void> manualCredit({
    required int colleagueId,
    required double amount,
    String? note,
  }) async {
    final dio = await _apiClient.dio();
    await dio.post(Endpoints.ledgerManualCredit, data: {
      'colleague_id': colleagueId,
      'amount': amount,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
  }

  // lib/features/ledger/ledger_service.dart

  Future<Map<String, double>> getAnalytics({
    required int colleagueId,
    required int month,
    required int year,
    int? day, // New optional parameter
  }) async {
    try {
      final dio = await _apiClient.dio();
      final resp = await dio.get(
        '/api/colleagues/$colleagueId/analytics',
        queryParameters: {
          'month': month,
          'year': year,
          if (day != null) 'day': day, // Only send if day is selected
        },
      );

      if (resp.data is List) return {};

      final Map<String, dynamic> rawData = resp.data;
      return rawData.map((key, value) => MapEntry(
        key,
        double.tryParse(value.toString()) ?? 0.0,
      ));
    } catch (e) {
      throw Exception('Failed to load analytics: $e');
    }
  }
}