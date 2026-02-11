import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration and initialization
class SupabaseConfig {
  // Supabase credentials
  static const String supabaseUrl = 'https://vczxtjxerczfisubjlff.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZjenh0anhlcmN6ZmlzdWJqbGZmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA4MTQ0NzgsImV4cCI6MjA4NjM5MDQ3OH0.OrwkKF6OVYAfy7e9ZuG6gp3rhkegaVXP1bEujG90Q3k';

  /// Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  /// Get Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  /// Get auth instance
  static GoTrueClient get auth => client.auth;
}
