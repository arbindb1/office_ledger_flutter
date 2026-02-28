import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import 'payment_notification_model.dart';

class NotificationsService {
  NotificationsService(this._apiClient);
  final ApiClient _apiClient;

  Future<List<PaymentNotification>> fetchUnmatched() async {
    final dio = await _apiClient.dio();
    final res = await dio.get(Endpoints.notificationsUnmatched);

    final data = (res.data is Map) ? (res.data['data'] ?? res.data) : res.data;
    final list = List<Map<String, dynamic>>.from(data as List);
    return list.map(PaymentNotification.fromJson).toList();
  }

  Future<void> assign({
    required int notificationId,
    required int colleagueId,
  }) async {
    final dio = await _apiClient.dio();
    await dio.post(Endpoints.notificationAssign(notificationId), data: {
      'colleague_id': colleagueId,
    });
  }

  Future<void> ignore(int notificationId) async {
    final dio = await _apiClient.dio();
    await dio.post(Endpoints.notificationIgnore(notificationId));
  }

  Future<void> apply(int notificationId) async {
    final dio = await _apiClient.dio();
    await dio.post(Endpoints.notificationApply(notificationId));
  }
}
