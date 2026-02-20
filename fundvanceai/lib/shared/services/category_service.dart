import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';
import '../../core/constants/app_constants.dart';

/// Service for managing categories in Supabase
class CategoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all categories (default + user custom)
  Future<List<Category>> getCategories({
    bool includeDefault = true,
    String? parentId,
  }) async {
    try {
      var query = _supabase
          .from(AppConstants.categoriesTable)
          .select();

      // Filter by user or default categories
      if (includeDefault) {
        query = query.or('user_id.is.null,user_id.eq.${_supabase.auth.currentUser!.id}');
      } else {
        query = query.eq('user_id', _supabase.auth.currentUser!.id);
      }

      // Filter by parent category if specified
      if (parentId != null) {
        query = query.eq('parent_id', parentId);
      } else {
        // Only get top-level categories (no parent)
        query = query.isFilter('parent_id', null);
      }

      final orderedQuery = query
          .order('is_default', ascending: false)
          .order('name');

      final response = await orderedQuery;

      final categories = (response as List)
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .toList();

      // Remove duplicates by ID
      final seen = <String>{};
      return categories.where((category) {
        if (seen.contains(category.id)) {
          return false;
        }
        seen.add(category.id);
        return true;
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get subcategories for a parent category
  Future<List<Category>> getSubcategories(String parentId) async {
    try {
      final response = await _supabase
          .from(AppConstants.categoriesTable)
          .select()
          .eq('parent_id', parentId)
          .order('name');

      return (response as List)
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new custom category
  Future<Category> createCategory({
    required String name,
    String? icon,
    String? color,
    String? parentId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from(AppConstants.categoriesTable)
          .insert({
            'user_id': userId,
            'name': name,
            'icon': icon,
            'color': color,
            'parent_id': parentId,
            'is_default': false,
            'is_system': false,  // Required for RLS policy
          })
          .select()
          .single();

      return Category.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing category (only custom categories can be edited)
  Future<Category> updateCategory({
    required String categoryId,
    String? name,
    String? icon,
    String? color,
    String? parentId,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (name != null) updateData['name'] = name;
      if (icon != null) updateData['icon'] = icon;
      if (color != null) updateData['color'] = color;
      if (parentId != null) {
        updateData['parent_id'] = parentId;
      }

      final response = await _supabase
          .from(AppConstants.categoriesTable)
          .update(updateData)
          .eq('id', categoryId)
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('is_default', false) // Only allow updating custom categories
          .select()
          .single();

      return Category.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a custom category
  /// If reassignToCategoryId is provided, all expenses will be reassigned
  /// Otherwise, expenses will be set to null category
  Future<void> deleteCategory({
    required String categoryId,
    String? reassignToCategoryId,
  }) async {
    try {
      // First, reassign or clear expenses
      if (reassignToCategoryId != null) {
        await _supabase
            .from(AppConstants.expensesTable)
            .update({'category_id': reassignToCategoryId})
            .eq('category_id', categoryId);
      } else {
        await _supabase
            .from(AppConstants.expensesTable)
            .update({'category_id': null})
            .eq('category_id', categoryId);
      }

      // Also update budgets (set to null or reassign)
      if (reassignToCategoryId != null) {
        await _supabase
            .from(AppConstants.budgetsTable)
            .update({'category_id': reassignToCategoryId})
            .eq('category_id', categoryId);
      } else {
        await _supabase
            .from(AppConstants.budgetsTable)
            .update({'category_id': null})
            .eq('category_id', categoryId);
      }

      // Update subcategories to remove parent reference
      await _supabase
          .from(AppConstants.categoriesTable)
          .update({'parent_id': null})
          .eq('parent_id', categoryId);

      // Finally, delete the category
      await _supabase
          .from(AppConstants.categoriesTable)
          .delete()
          .eq('id', categoryId)
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('is_default', false); // Only allow deleting custom categories
    } catch (e) {
      rethrow;
    }
  }

  /// Get count of expenses using a category
  Future<int> getCategoryExpenseCount(String categoryId) async {
    try {
      final response = await _supabase
          .from(AppConstants.expensesTable)
          .select('id')
          .eq('category_id', categoryId)
          .count();

      return response.count;
    } catch (e) {
      rethrow;
    }
  }

  /// Get count of budgets using a category
  Future<int> getCategoryBudgetCount(String categoryId) async {
    try {
      final response = await _supabase
          .from(AppConstants.budgetsTable)
          .select('id')
          .eq('category_id', categoryId)
          .count();

      return response.count;
    } catch (e) {
      rethrow;
    }
  }

  /// Check if a category can be deleted (not default, not used)
  Future<bool> canDeleteCategory(String categoryId) async {
    try {
      // Check if it's a default category
      final category = await _supabase
          .from(AppConstants.categoriesTable)
          .select()
          .eq('id', categoryId)
          .single();

      final cat = Category.fromJson(category);
      
      if (cat.isDefault) {
        return false; // Cannot delete default categories
      }

      return true; // Custom categories can always be deleted (with reassignment)
    } catch (e) {
      return false;
    }
  }
}
