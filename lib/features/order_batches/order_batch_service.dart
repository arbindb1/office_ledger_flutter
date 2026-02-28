import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import 'order_batch_model.dart';
import 'order_batch_detail_model.dart';

class OrderBatchService {
  OrderBatchService(this._apiClient);
  final ApiClient _apiClient;

  Future<OrderBatch> createBatch({
    required String title,
    String? vendorName,
  }) async {
    final dio = await _apiClient.dio();
    final res = await dio.post(Endpoints.orderBatches, data: {
      'title': title,
      'vendor_name': vendorName,
    });

    final body = Map<String, dynamic>.from(res.data as Map);
    final data = Map<String, dynamic>.from(body['data'] as Map);
    return OrderBatch.fromJson(data);
  }


  Future<OrderBatchDetail> getBatch(int id) async {
    final dio = await _apiClient.dio();
    final res = await dio.get(Endpoints.orderBatch(id));
    return OrderBatchDetail.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<void> addBatchItem({
    required int batchId,
    required int colleagueId,
    required int itemId,
    required int quantity,
    required double unitPrice,
  }) async {
    final dio = await _apiClient.dio();
    await dio.post(Endpoints.orderBatchItems(batchId), data: {
      'colleague_id': colleagueId,
      'item_id': itemId,
      'quantity': quantity,
      'unit_price': unitPrice,
    });
  }

  Future<List<OrderBatch>> listBatches({String? status}) async {
    final dio = await _apiClient.dio();

    final res = await dio.get(
      Endpoints.orderBatches,
      queryParameters: {
        if (status != null) 'status': status,
      },
    );

    final body = Map<String, dynamic>.from(res.data as Map);
    final data = List<Map<String, dynamic>>.from(body['data'] as List);

    return data.map(OrderBatch.fromJson).toList();
  }



  Future<void> finalize(int batchId) async {
    final dio = await _apiClient.dio();
    await dio.post(Endpoints.finalizeOrderBatch(batchId));
  }

  Future<void> deleteBatch(int id) async {
    final dio = await _apiClient.dio();
    // Using the DELETE method as defined in your Laravel route
    await dio.delete('${Endpoints.orderBatchDelete}/$id');  }
}
