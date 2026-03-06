class ServiceItem {
  final int? id;
  final int categoryId;
  final String name;
  final String? description;
  final double basePrice;
  final String unit;

  const ServiceItem({
    this.id,
    required this.categoryId,
    required this.name,
    this.description,
    required this.basePrice,
    this.unit = 'hora',
  });

  ServiceItem copyWith({
    int? id,
    int? categoryId,
    String? name,
    String? description,
    double? basePrice,
    String? unit,
  }) {
    return ServiceItem(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      basePrice: basePrice ?? this.basePrice,
      unit: unit ?? this.unit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'basePrice': basePrice,
      'unit': unit,
    };
  }

  factory ServiceItem.fromMap(Map<String, dynamic> map) {
    return ServiceItem(
      id: map['id'] as int?,
      categoryId: map['categoryId'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      basePrice: (map['basePrice'] as num).toDouble(),
      unit: map['unit'] as String? ?? 'hora',
    );
  }
}
