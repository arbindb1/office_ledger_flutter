import '../../core/api/json_parsers.dart';

class OrderBatchItem {
  final int id;
  final int colleagueId;
  final String colleagueName;
  final String itemName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  OrderBatchItem({
    required this.id,
    required this.colleagueId,
    required this.colleagueName,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory OrderBatchItem.fromJson(Map<String, dynamic> json) {
    return OrderBatchItem(
      id: asInt(json['id']),
      colleagueId: asInt(json['colleague_id']),
      colleagueName: asString(json['colleague']?['display_name'] ?? json['colleague_name']),
      itemName: asString(json['item_name']),
      quantity: asInt(json['quantity']),
      unitPrice: asDouble(json['unit_price']),
      lineTotal: asDouble(json['line_total']),
    );
  }
}
