import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_env.dart';

/// Inicializa el cliente Supabase (PostgreSQL, Auth, y Realtime)
class SupabaseBootstrap {
  SupabaseBootstrap._();

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
