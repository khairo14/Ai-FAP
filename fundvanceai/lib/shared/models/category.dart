/// Category model matching the categories table in Supabase
class Category {
  final String id;
  final String? userId;
  final String name;
  final String? icon;
  final String? color;
  final bool isDefault;
  final String? parentId;
  final DateTime createdAt;

  Category({
    required this.id,
    this.userId,
    required this.name,
    this.icon,
    this.color,
    this.isDefault = false,
    this.parentId,
    required this.createdAt,
  });

  /// Create Category from JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      parentId: json['parent_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert Category to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'icon': icon,
      'color': color,
      'is_default': isDefault,
      'parent_id': parentId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Category copyWith({
    String? id,
    String? userId,
    String? name,
    String? icon,
    String? color,
    bool? isDefault,
    String? parentId,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, icon: $icon, color: $color)';
  }
}
