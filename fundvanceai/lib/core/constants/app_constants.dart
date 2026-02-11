/// App-wide constants
class AppConstants {
  // App Info
  static const String appName = 'FundVance AI';
  static const String appVersion = '1.0.0';
  
  // Database Tables
  static const String profilesTable = 'profiles';
  static const String categoriesTable = 'categories';
  static const String expensesTable = 'expenses';
  static const String budgetsTable = 'budgets';
  
  // Storage Buckets
  static const String receiptsBucket = 'receipts';
  static const String avatarsBucket = 'avatars';
  
  // Default Values
  static const String defaultCurrency = 'USD';
  static const int expensesPageSize = 20;
  
  // Date Formats
  static const String displayDateFormat = 'MMM dd, yyyy';
  static const String apiDateFormat = 'yyyy-MM-dd';
  
  // Budget Periods
  static const String periodWeekly = 'weekly';
  static const String periodMonthly = 'monthly';
  static const String periodYearly = 'yearly';
}
