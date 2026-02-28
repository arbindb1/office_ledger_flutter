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
}
