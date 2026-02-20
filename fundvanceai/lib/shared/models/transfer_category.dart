/// Transfer category model matching the transfer_categories table in Supabase
class TransferCategory {
  final String id;
  final String name;
  final String? description;
  final String icon;
  final String color;
  final bool isActive;

  const TransferCategory({
    required this.id,
    required this.name,
    this.description,
    this.icon = 'swap_horiz',
    this.color = '#2196F3',
    this.isActive = true,
  });

  factory TransferCategory.fromJson(Map<String, dynamic> json) {
    return TransferCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String? ?? 'swap_horiz',
      color: json['color'] as String? ?? '#2196F3',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': icon,
        'color': color,
        'is_active': isActive,
      };
}
