class PaymentNotification {
  final int id;
  final String provider;
  final String rawMessage;
  final double amount;
  final DateTime createdAt;

  final int? assignedColleagueId;
  final String? assignedColleagueName;

  PaymentNotification({
    required this.id,
    required this.provider,
    required this.rawMessage,
    required this.amount,
    required this.createdAt,
    this.assignedColleagueId,
    this.assignedColleagueName,
  });

  factory PaymentNotification.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse((v ?? '0').toString()) ?? 0.0;
    }

    return PaymentNotification(
      id: (json['id'] as num).toInt(),
      provider: (json['provider'] ?? '').toString(),
      rawMessage: (json['raw_message'] ?? json['message'] ?? '').toString(),
      amount: parseAmount(json['amount']),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.now(),
      assignedColleagueId: (json['assigned_colleague_id'] is num)
          ? (json['assigned_colleague_id'] as num).toInt()
          : null,
      assignedColleagueName: (json['assigned_colleague_name'] ?? '').toString().isEmpty
          ? null
          : (json['assigned_colleague_name'] ?? '').toString(),
    );
  }
}
