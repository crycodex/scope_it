class Category {
  final int? id;
  final String name;
  final String? description;
  final int colorValue;

  const Category({
    this.id,
    required this.name,
    this.description,
    this.colorValue = 0xFF1B9CFC,
  });

  Category copyWith({
    int? id,
    String? name,
    String? description,
    int? colorValue,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'colorValue': colorValue,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      colorValue: map['colorValue'] as int? ?? 0xFF1B9CFC,
    );
  }
}
