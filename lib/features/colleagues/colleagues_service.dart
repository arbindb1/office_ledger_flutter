import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import 'colleague_model.dart';

class ColleaguesService {
  ColleaguesService(this._apiClient);
  final ApiClient _apiClient;

  Future<List<Colleague>> fetchColleagues({bool includeInactive = false}) async {
    final dio = await _apiClient.dio();
    final res = await dio.get(
      Endpoints.colleagues,
      queryParameters: {
        if (includeInactive) 'include_inactive': 1,
      },
    );

    final data = (res.data is Map) ? (res.data['data'] ?? res.data) : res.data;
    final list = List<Map<String, dynamic>>.from(data as List);
    return list.map(Colleague.fromJson).toList();
  }


  Future<Colleague> createColleague({
    required String name,
    bool? isActive,
  }) async {
    final dio = await _apiClient.dio();

    final res = await dio.post(Endpoints.colleagues, data: {
      'display_name': name,
      if (isActive != null) 'is_active': isActive,
    });


    final data = (res.data is Map) ? (res.data['data'] ?? res.data) : res.data;
    return Colleague.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deactivateColleague(int id) async {
    final dio = await _apiClient.dio();
    await dio.post(Endpoints.colleagueDeactivate(id));
  }

  // OPTIONAL: only if you want aliases in Flutter now
  Future<void> addAlias({
    required int id,
    required String alias,
  }) async {
    final dio = await _apiClient.dio();
    await dio.post(Endpoints.colleagueAliases(id), data: {'alias': alias});
  }

  // OPTIONAL: only if you want ledger screen now
  Future<dynamic> fetchLedger(int id) async {
    final dio = await _apiClient.dio();
    final res = await dio.get(Endpoints.colleagueLedger(id));
    return res.data;
  }

// NOTE:
// updateColleague() REMOVED because backend has no PUT /api/colleagues/{id}.
// If you add that route later, we can re-add updateColleague safely.
}
