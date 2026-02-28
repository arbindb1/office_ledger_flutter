import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import 'item_model.dart';

class ItemsService {
  ItemsService(this._apiClient);
  final ApiClient _apiClient;

  Future<List<Item>> fetchItems({bool includeInactive = false}) async {
    final dio = await _apiClient.dio();
    final res = await dio.get(Endpoints.items, queryParameters: {
      'include_inactive': includeInactive ? 1 : 0,
    });

    final data = res.data;

    if (data is List) {
      return data
          .map((e) => Item.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => Item.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    throw Exception('Unexpected response shape');
  }

  Future<Item> createItem({required String name, required double default_price}) async {
    final dio = await _apiClient.dio();
    final res = await dio.post(Endpoints.items, data: {
      'name': name,
      'default_price': default_price,
    });
    return Item.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<Item> updateItem({
    required int id,
    String? name,
    double? default_price,
  }) async {
    final dio = await _apiClient.dio();
    final res = await dio.patch(Endpoints.item(id), data: {
      if (name != null) 'name': name,
      if (default_price != null) 'default_price': default_price,
    });
    return Item.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<void> deactivateItem(int id) async {
    final dio = await _apiClient.dio();
    await dio.post(Endpoints.deactivateItem(id));
  }
}
