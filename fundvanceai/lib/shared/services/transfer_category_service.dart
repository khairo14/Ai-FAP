import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transfer_category.dart';
import '../../core/constants/app_constants.dart';

/// Service for reading transfer categories from Supabase
class TransferCategoryService {
  final _supabase = Supabase.instance.client;

  /// Fetch all active transfer categories (system-defined, no user filtering needed)
  Future<List<TransferCategory>> getCategories() async {
    try {
      final response = await _supabase
          .from(AppConstants.transferCategoriesTable)
          .select()
          .eq('is_active', true)
          .order('name');

      return (response as List)
          .map((json) => TransferCategory.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load transfer categories: $e');
    }
  }
}
