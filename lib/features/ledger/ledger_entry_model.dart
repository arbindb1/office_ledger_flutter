class LedgerEntryModel {
  final int id;
  final String entryType; // debit|credit
  final double amount;
  final String source;
  final DateTime createdAt;
  final Map<String, dynamic>? meta;

  LedgerEntryModel({
    required this.id,
    required this.entryType,
    required this.amount,
    required this.source,
    required this.createdAt,
    this.meta,
  });

  factory LedgerEntryModel.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];

    return LedgerEntryModel(
      id: (json['id'] as num).toInt(),
      entryType: (json['entry_type'] ?? '').toString(),
      amount: (rawAmount is num)
          ? rawAmount.toDouble()
          : double.tryParse((rawAmount ?? '0').toString()) ?? 0.0,
      source: (json['source'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      meta: (json['meta'] is Map)
          ? Map<String, dynamic>.from(json['meta'])
          : null,
    );
  }
}
