/// Account type model representing different types of financial accounts
/// Valid categories: bank, online_bank, wallet, credit, cash, crypto, investment
class AccountType {
  final String id;
  final String code;
  final String name;
  final String? description;
  final String icon;
  final String color;
  final String category;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AccountType({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.icon,
    required this.color,
    required this.category,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AccountType.fromJson(Map<String, dynamic> json) {
    return AccountType(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String,
      color: json['color'] as String,
      category: json['category'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'category': category,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AccountType copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
    String? icon,
    String? color,
    String? category,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AccountType(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'AccountType(id: $id, name: $name, code: $code, category: $category)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountType && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
