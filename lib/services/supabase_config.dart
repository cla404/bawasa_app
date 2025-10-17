import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://uckdfqnwzyowaobsdnbe.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVja2RmcW53enlvd2FvYnNkbmJlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc1MDY5OTYsImV4cCI6MjA3MzA4Mjk5Nn0.-CuU6tyUG24HiFqHZmnVL-bhPsnWkjCp-Z27jUSbd28';

  static Future<void> initialize() async {
    print('🚀 [SupabaseConfig] Initializing Supabase...');

    try {
      await dotenv.load(fileName: ".env");
      print('✅ [SupabaseConfig] .env file loaded successfully');
    } catch (e) {
      // .env file not found, use default values
      print(
        '⚠️ [SupabaseConfig] .env file not found. Using default Supabase configuration.',
      );
      print('Please create a .env file with your Supabase credentials.');
    }

    final url = dotenv.env['SUPABASE_URL'] ?? supabaseUrl;
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? supabaseAnonKey;

    print('🔗 [SupabaseConfig] Supabase URL: $url');
    print('🔑 [SupabaseConfig] Anon Key: ${anonKey.substring(0, 20)}...');

    await Supabase.initialize(url: url, anonKey: anonKey);

    print('✅ [SupabaseConfig] Supabase initialized successfully');
    print(
      '👤 [SupabaseConfig] Current user: ${Supabase.instance.client.auth.currentUser?.id}',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
