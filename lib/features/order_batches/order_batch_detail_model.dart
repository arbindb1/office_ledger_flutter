import 'order_batch_model.dart';

class BatchColleagueTotal {
  final int colleagueId;
  final double total;

  BatchColleagueTotal({
    required this.colleagueId,
    required this.total,
  });

  factory BatchColleagueTotal.fromJson(Map<String, dynamic> json) {
    final rawId = json['colleague_id'];
    final rawTotal = json['total'];

    final id = (rawId is num)
        ? rawId.toInt()
        : int.tryParse(rawId?.toString() ?? '0') ?? 0;

    final total = (rawTotal is num)
        ? rawTotal.toDouble()
        : double.tryParse(rawTotal?.toString() ?? '0') ?? 0.0;

    return BatchColleagueTotal(colleagueId: id, total: total);
  }
}


class OrderBatchDetail {
  final OrderBatch batch;
  final double total;
  final List<BatchColleagueTotal> totalsByColleague;

  OrderBatchDetail({
    required this.batch,
    required this.total,
    required this.totalsByColleague,
  });

  factory OrderBatchDetail.fromJson(Map<String, dynamic> json) {
    final data = Map<String, dynamic>.from(json['data'] as Map);
    final batchJson = Map<String, dynamic>.from(data['batch'] as Map);

    final totalsRaw = (data['totals_by_colleague'] as List? ?? []);

    final rawTotal = data['total'];
    final total = (rawTotal is num)
        ? rawTotal.toDouble()
        : double.tryParse(rawTotal?.toString() ?? '0') ?? 0.0;

    return OrderBatchDetail(
      batch: OrderBatch.fromJson(batchJson),
      total: total,
      totalsByColleague: totalsRaw
          .map((e) => BatchColleagueTotal.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

}
