import 'package:supabase_flutter/supabase_flutter.dart';

class AppSupabase {
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://vupaefcmaekoblnngizc.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ1cGFlZmNtYWVrb2Jsbm5naXpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNDk3NDIsImV4cCI6MjA3OTcyNTc0Mn0.G-GANVrLl8IH1OVgNJt7ig3AtddJO1th2rKe3G-NPOA',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
