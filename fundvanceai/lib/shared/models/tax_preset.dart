/// Model for a tax preset from the tax_presets table
class TaxPreset {
  final String id;
  final String countryCode;
  final String taxName;
  final String? description;
  final String taxType; // 'percentage', 'fixed', 'hybrid'
  final double? taxPercentage;
  final double? taxFixedAmount;
  final String currency;
  final String? categorySuggestion;
  final bool isMandatory;
  final String? taxAuthority;
  final double? minimumIncomeThreshold;
  final double? maximumTaxCap;
  final int effectiveTaxYear;
  final bool isActive;

  const TaxPreset({
    required this.id,
    required this.countryCode,
    required this.taxName,
    this.description,
    required this.taxType,
    this.taxPercentage,
    this.taxFixedAmount,
    required this.currency,
    this.categorySuggestion,
    this.isMandatory = false,
    this.taxAuthority,
    this.minimumIncomeThreshold,
    this.maximumTaxCap,
    required this.effectiveTaxYear,
    this.isActive = true,
  });

  factory TaxPreset.fromJson(Map<String, dynamic> json) {
    return TaxPreset(
      id: json['id'] as String,
      countryCode: json['country_code'] as String? ?? 'WLD',
      taxName: json['tax_name'] as String,
      description: json['description'] as String?,
      taxType: json['tax_type'] as String,
      taxPercentage: (json['tax_percentage'] as num?)?.toDouble(),
      taxFixedAmount: (json['tax_fixed_amount'] as num?)?.toDouble(),
      currency: json['currency'] as String,
      categorySuggestion: json['category_suggestion'] as String?,
      isMandatory: json['is_mandatory'] as bool? ?? false,
      taxAuthority: json['tax_authority'] as String?,
      minimumIncomeThreshold:
          (json['minimum_income_threshold'] as num?)?.toDouble(),
      maximumTaxCap: (json['maximum_tax_cap'] as num?)?.toDouble(),
      effectiveTaxYear: json['effective_tax_year'] as int? ?? DateTime.now().year,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Human-readable rate string, e.g. "25%" or "₱500" or "25% + ₱500"
  String get rateLabel {
    switch (taxType) {
      case 'percentage':
        return '${taxPercentage?.toStringAsFixed(1) ?? '0'}%';
      case 'fixed':
        return '$currency ${taxFixedAmount?.toStringAsFixed(2) ?? '0'}';
      case 'hybrid':
        final pct = taxPercentage?.toStringAsFixed(1) ?? '0';
        final fixed = taxFixedAmount?.toStringAsFixed(2) ?? '0';
        return '$pct% + $currency $fixed';
      default:
        return '';
    }
  }

  /// Full country name for display
  String get countryLabel {
    switch (countryCode) {
      case 'PHL':
        return 'Philippines';
      case 'USA':
        return 'United States';
      default:
        return 'World / Generic';
    }
  }
}

/// Model for a user's saved default tax rate (default_tax_rates table)
class UserDefaultTaxRate {
  final String id;
  final String userId;
  final String? incomeCategoryId;
  final String? categoryName; // from join
  final String taxType;
  final double? taxPercentage;
  final double? taxFixedAmount;
  final String currency;
  final String? taxName;
  final bool isMandatory;
  final bool isDefaultForCategory;
  final bool applyAutomatically;
  final bool isActive;

  const UserDefaultTaxRate({
    required this.id,
    required this.userId,
    this.incomeCategoryId,
    this.categoryName,
    required this.taxType,
    this.taxPercentage,
    this.taxFixedAmount,
    required this.currency,
    this.taxName,
    this.isMandatory = false,
    this.isDefaultForCategory = false,
    this.applyAutomatically = true,
    this.isActive = true,
  });

  factory UserDefaultTaxRate.fromJson(Map<String, dynamic> json) {
    final catData = json['income_categories'] as Map<String, dynamic>?;
    return UserDefaultTaxRate(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      incomeCategoryId: json['income_category_id'] as String?,
      categoryName: catData?['name'] as String?,
      taxType: json['tax_type'] as String,
      taxPercentage: (json['tax_percentage'] as num?)?.toDouble(),
      taxFixedAmount: (json['tax_fixed_amount'] as num?)?.toDouble(),
      currency: json['currency'] as String,
      taxName: json['tax_name'] as String?,
      isMandatory: json['is_mandatory'] as bool? ?? false,
      isDefaultForCategory:
          json['is_default_for_category'] as bool? ?? false,
      applyAutomatically: json['apply_automatically'] as bool? ?? true,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Human-readable rate string
  String get rateLabel {
    switch (taxType) {
      case 'percentage':
        return '${taxPercentage?.toStringAsFixed(1) ?? '0'}%';
      case 'fixed':
        return '$currency ${taxFixedAmount?.toStringAsFixed(2) ?? '0'}';
      case 'hybrid':
        final pct = taxPercentage?.toStringAsFixed(1) ?? '0';
        final fixed = taxFixedAmount?.toStringAsFixed(2) ?? '0';
        return '$pct% + $currency $fixed';
      default:
        return '';
    }
  }
}
