/// Account model representing a user's financial account (bank, wallet, credit card, etc.)
class Account {
  final String id;
  final String userId;
  final String accountTypeId;
  final String? accountTypeName;
  final String? accountTypeCategory;
  
  // Basic information
  final String name;
  final String? description;
  final String currency;
  final bool currencyManuallySet; // Track if currency was manually changed
  
  // Balance tracking
  final double initialBalance;
  final double currentBalance;
  final double availableBalance;
  
  // Account details
  final String? institutionName;
  final String? accountNickname;
  
  // Credit account specific
  final double? creditLimit;
  final double? creditUsed;
  
  // Status and settings
  final bool isActive;
  final bool includeInTotal;
  final bool isHidden;
  
  // Metadata
  final Map<String, dynamic>? accountSettings;
  final DateTime? lastTransactionDate;
  
  // Audit fields
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Account({
    required this.id,
    required this.userId,
    required this.accountTypeId,
    this.accountTypeName,
    this.accountTypeCategory,
    required this.name,
    this.description,
    required this.currency,
    this.currencyManuallySet = false,
    this.initialBalance = 0,
    this.currentBalance = 0,
    this.availableBalance = 0,
    this.institutionName,
    this.accountNickname,
    this.creditLimit,
    this.creditUsed,
    this.isActive = true,
    this.includeInTotal = true,
    this.isHidden = false,
    this.accountSettings,
    this.lastTransactionDate,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    // Handle nested account_types data from join
    final accountTypes = json['account_types'] as Map<String, dynamic>?;
    
    return Account(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      accountTypeId: json['account_type_id'] as String,
      accountTypeName: accountTypes?['name'] as String?,
      accountTypeCategory: accountTypes?['category'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      currencyManuallySet: json['currency_manually_set'] as bool? ?? false,
      currency: json['currency'] as String? ?? 'USD',
      initialBalance: (json['initial_balance'] as num?)?.toDouble() ?? 0,
      currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0,
      availableBalance: (json['available_balance'] as num?)?.toDouble() ?? 0,
      institutionName: json['institution_name'] as String?,
      accountNickname: json['account_nickname'] as String?,
      creditLimit: (json['credit_limit'] as num?)?.toDouble(),
      creditUsed: (json['credit_used'] as num?)?.toDouble(),
      isActive: json['is_active'] as bool? ?? true,
      includeInTotal: json['include_in_total'] as bool? ?? true,
      isHidden: json['is_hidden'] as bool? ?? false,
      accountSettings: json['account_settings'] as Map<String, dynamic>?,
      lastTransactionDate: json['last_transaction_date'] != null
          ? DateTime.parse(json['last_transaction_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'account_type_id': accountTypeId,
      'name': name,
      'description': description,
      'currency_manually_set': currencyManuallySet,
      'currency': currency,
      'initial_balance': initialBalance,
      'current_balance': currentBalance,
      'available_balance': availableBalance,
      'institution_name': institutionName,
      'account_nickname': accountNickname,
      'credit_limit': creditLimit,
      'credit_used': creditUsed,
      'is_active': isActive,
      'include_in_total': includeInTotal,
      'is_hidden': isHidden,
      'account_settings': accountSettings,
      'last_transaction_date': lastTransactionDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  Account copyWith({
    String? id,
    String? userId,
    String? accountTypeId,
    String? accountTypeName,
    String? accountTypeCategory,
    String? name,
    bool? currencyManuallySet,
    String? description,
    String? currency,
    double? initialBalance,
    double? currentBalance,
    double? availableBalance,
    String? institutionName,
    String? accountNickname,
    double? creditLimit,
    double? creditUsed,
    bool? isActive,
    bool? includeInTotal,
    bool? isHidden,
    Map<String, dynamic>? accountSettings,
    DateTime? lastTransactionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Account(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountTypeId: accountTypeId ?? this.accountTypeId,
      accountTypeName: accountTypeName ?? this.accountTypeName,
      accountTypeCategory: accountTypeCategory ?? this.accountTypeCategory,
      name: name ?? this.name,
      description: description ?? this.description,
      currency: currency ?? this.currency,
      currencyManuallySet: currencyManuallySet ?? this.currencyManuallySet,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      availableBalance: availableBalance ?? this.availableBalance,
      institutionName: institutionName ?? this.institutionName,
      accountNickname: accountNickname ?? this.accountNickname,
      creditLimit: creditLimit ?? this.creditLimit,
      creditUsed: creditUsed ?? this.creditUsed,
      isActive: isActive ?? this.isActive,
      includeInTotal: includeInTotal ?? this.includeInTotal,
      isHidden: isHidden ?? this.isHidden,
      accountSettings: accountSettings ?? this.accountSettings,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  /// Check if this is a credit account
  bool get isCreditAccount => creditLimit != null && creditLimit! > 0;

  /// Get credit utilization percentage (0-100)
  double get creditUtilization {
    if (!isCreditAccount) return 0;
    if (creditLimit == 0) return 0;
    return ((creditUsed ?? 0) / creditLimit!) * 100;
  }

  /// Check if account is deleted (soft delete)
  bool get isDeleted => deletedAt != null;

  @override
  String toString() => 'Account(id: $id, name: $name, balance: $currentBalance $currency)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Account && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
