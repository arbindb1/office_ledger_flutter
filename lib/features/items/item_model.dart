class Item {
  final int id;
  final String name;
  final double default_price;
  final bool isActive;

  Item({
    required this.id,
    required this.name,
    required this.default_price,
    required this.isActive,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      default_price: (json['default_price'] is num)
          ? (json['default_price'] as num).toDouble()
          : double.tryParse((json['default_price'] ?? '0').toString()) ?? 0.0,
      isActive: (json['is_active'] == true) ||
          (json['is_active']?.toString() == '1'),
    );
  }
}
