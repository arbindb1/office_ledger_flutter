import 'order_batch_item_model.dart';

class OrderBatch {
  final int id;
  final String? title;
  final String? vendorName;
  final String status;
  final String? orderedAt;
  final String? notes;
  final List<OrderBatchItem> items;
  final int itemsCount;


  OrderBatch({
    required this.id,
    required this.title,
    required this.vendorName,
    required this.status,
    required this.orderedAt,
    required this.notes,
    required this.items,
    required this.itemsCount,
  });

  factory OrderBatch.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List? ?? []);


    return OrderBatch(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String?,
      vendorName: json['vendor_name'] as String?,
      status: (json['status'] ?? 'draft') as String,
      orderedAt: json['ordered_at']?.toString(),
      notes: json['notes'] as String?,
      itemsCount: (json['items_count'] is num)
          ? (json['items_count'] as num).toInt()
          : int.tryParse((json['items_count'] ?? '0').toString()) ?? 0,
      items: rawItems
          .map((e) => OrderBatchItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
