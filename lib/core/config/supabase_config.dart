import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://ghcumkeaayrrcuxvadxn.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdoY3Vta2VhYXlycmN1eHZhZHhuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc3NjgyMDQsImV4cCI6MjA3MzM0NDIwNH0.m67Fy9gY6Uj7HHHhXnhuTs2t9Qyx6sLlparQnIIkyL0';

  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      // .env file not found, use default values
      print(
        'Warning: .env file not found. Using default Supabase configuration.',
      );
      print('Please create a .env file with your Supabase credentials.');
    }

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? supabaseUrl,
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
