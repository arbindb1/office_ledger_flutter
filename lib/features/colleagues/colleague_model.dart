class Colleague {
  final int id;
  final String name;
  final double balance;
  final bool isActive;

  Colleague({
    required this.id,
    required this.name,
    required this.balance,
    required this.isActive,
  });

  factory Colleague.fromJson(Map<String, dynamic> json) {
    final rawBal = json['outstanding'] ?? json['balance'] ?? 0; // backend uses outstanding
    final bal = (rawBal is num)
        ? rawBal.toDouble()
        : double.tryParse(rawBal.toString()) ?? 0.0;

    return Colleague(
      id: (json['id'] as num).toInt(),
      name: (json['display_name'] ?? json['name'] ?? '').toString(),
      isActive: (json['is_active'] == null) ? true : (json['is_active'] as bool),
      balance: bal,
    );
  }
}
