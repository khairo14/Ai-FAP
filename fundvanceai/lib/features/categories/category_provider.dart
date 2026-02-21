import 'package:flutter/foundation.dart' hide Category;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/category.dart';
import '../../shared/models/transfer_category.dart';
import '../../shared/services/category_service.dart';
import '../../core/constants/app_constants.dart';

/// Provider for managing category state and operations
class CategoryProvider with ChangeNotifier {
  final CategoryService _categoryService = CategoryService();
  final _supabase = Supabase.instance.client;

  List<Category> _categories = [];
  final Map<String, List<Category>> _subcategories = {};
  // System categories from income_categories and transfer_categories tables
  List<TransferCategory> _incomeSystemCategories = [];
  List<TransferCategory> _transferSystemCategories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Category> get categories => _categories;
  Map<String, List<Category>> get subcategories => _subcategories;
  List<TransferCategory> get incomeSystemCategories => _incomeSystemCategories;
  List<TransferCategory> get transferSystemCategories => _transferSystemCategories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Get only custom (user-created) categories
  List<Category> get customCategories =>
      _categories.where((cat) => !cat.isDefault).toList();

  /// Get only default (system) categories
  List<Category> get defaultCategories =>
      _categories.where((cat) => cat.isDefault).toList();

  /// Get top-level categories (no parent)
  List<Category> get topLevelCategories =>
      _categories.where((cat) => cat.parentId == null).toList();

  /// Load all categories (expense + income system + transfer system)
  Future<void> loadCategories({bool includeDefault = true}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load expense categories (with subcategories)
      _categories = await _categoryService.getCategories(
        includeDefault: includeDefault,
      );
      
      _subcategories.clear();
      for (final category in _categories) {
        if (category.parentId == null) {
          final subs = await _categoryService.getSubcategories(category.id);
          if (subs.isNotEmpty) {
            _subcategories[category.id] = subs;
          }
        }
      }

      // Load income system categories (read-only)
      final incomeResp = await _supabase
          .from(AppConstants.incomeCategoriesTable)
          .select()
          .eq('is_active', true)
          .order('name');
      _incomeSystemCategories = (incomeResp as List)
          .map((j) => TransferCategory.fromJson(j as Map<String, dynamic>))
          .toList();

      // Load transfer system categories (read-only)
      final transferResp = await _supabase
          .from(AppConstants.transferCategoriesTable)
          .select()
          .eq('is_active', true)
          .order('name');
      _transferSystemCategories = (transferResp as List)
          .map((j) => TransferCategory.fromJson(j as Map<String, dynamic>))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load subcategories for a specific parent
  Future<void> loadSubcategories(String parentId) async {
    try {
      final subs = await _categoryService.getSubcategories(parentId);
      _subcategories[parentId] = subs;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Create a new custom category
  Future<Category?> createCategory({
    required String name,
    String? icon,
    String? color,
    String? parentId,
    String categoryType = 'expense',
  }) async {
    try {
      final category = await _categoryService.createCategory(
        name: name,
        icon: icon,
        color: color,
        parentId: parentId,
        categoryType: categoryType,
      );

      if (parentId != null) {
        if (_subcategories.containsKey(parentId)) {
          _subcategories[parentId]!.add(category);
        } else {
          _subcategories[parentId] = [category];
        }
      } else {
        _categories.add(category);
      }

      notifyListeners();
      return category;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update an existing category
  Future<bool> updateCategory({
    required String categoryId,
    String? name,
    String? icon,
    String? color,
    String? parentId,
    String? categoryType,
    bool clearParent = false,
  }) async {
    try {
      final updatedCategory = await _categoryService.updateCategory(
        categoryId: categoryId,
        name: name,
        icon: icon,
        color: color,
        parentId: parentId,
        categoryType: categoryType,
        clearParent: clearParent,
      );

      final index = _categories.indexWhere((cat) => cat.id == categoryId);
      if (index != -1) {
        _categories[index] = updatedCategory;
      }

      for (final entry in _subcategories.entries) {
        final subIndex =
            entry.value.indexWhere((cat) => cat.id == categoryId);
        if (subIndex != -1) {
          entry.value[subIndex] = updatedCategory;
          break;
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete a category with optional expense reassignment
  Future<bool> deleteCategory({
    required String categoryId,
    String? reassignToCategoryId,
  }) async {
    try {
      await _categoryService.deleteCategory(
        categoryId: categoryId,
        reassignToCategoryId: reassignToCategoryId,
      );

      // Remove from main list
      _categories.removeWhere((cat) => cat.id == categoryId);

      // Remove from subcategories
      for (final entry in _subcategories.entries) {
        entry.value.removeWhere((cat) => cat.id == categoryId);
      }

      // Remove subcategory list if this was a parent
      _subcategories.remove(categoryId);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get count of expenses using a category
  Future<int> getCategoryExpenseCount(String categoryId) async {
    try {
      return await _categoryService.getCategoryExpenseCount(categoryId);
    } catch (e) {
      return 0;
    }
  }

  /// Get count of budgets using a category
  Future<int> getCategoryBudgetCount(String categoryId) async {
    try {
      return await _categoryService.getCategoryBudgetCount(categoryId);
    } catch (e) {
      return 0;
    }
  }

  /// Check if a category can be deleted
  Future<bool> canDeleteCategory(String categoryId) async {
    try {
      return await _categoryService.canDeleteCategory(categoryId);
    } catch (e) {
      return false;
    }
  }

  /// Get a category by ID
  Category? getCategoryById(String categoryId) {
    // Search in main categories
    try {
      return _categories.firstWhere((cat) => cat.id == categoryId);
    } catch (e) {
      // Search in subcategories
      for (final subs in _subcategories.values) {
        try {
          return subs.firstWhere((cat) => cat.id == categoryId);
        } catch (e) {
          continue;
        }
      }
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
