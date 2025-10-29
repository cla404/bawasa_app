import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // These are now the ONLY source of configuration
  static const String supabaseUrl = 'https://ghcumkeaayrrcuxvadxn.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdoY3Vta2VhYXlycmN1eHZhZHhuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc3NjgyMDQsImV4cCI6MjA3MzM0NDIwNH0.m67Fy9gY6Uj7HHHhXnhuTs2t9Qyx6sLlparQnIIkyL0';

  static Future<void> initialize() async {
    // Try to load .env file if present (for local development)
    // In production builds, these values will be the hardcoded constants above
    try {
      await dotenv.load(fileName: ".env");
      print('✅ Loaded .env file successfully');
    } catch (e) {
      print('ℹ️  No .env file found, using hardcoded configuration');
    }

    // Use .env values if available, otherwise use hardcoded values
    final url = dotenv.env['SUPABASE_URL'] ?? supabaseUrl;
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? supabaseAnonKey;

    await Supabase.initialize(url: url, anonKey: anonKey);

    print('✅ Supabase initialized with URL: $url');
  }

  static SupabaseClient get client => Supabase.instance.client;
}
