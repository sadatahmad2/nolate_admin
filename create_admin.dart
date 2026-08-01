import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/core/constants/supabase_config.dart';

void main() async {
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey, // ignore: deprecated_member_use
  );

  final client = Supabase.instance.client;

  try {
    final res = await client.auth.signUp(
      email: 'admin@nolate.com',
      password: 'Password123!',
    );
    print('✅ Admin user created successfully: ${res.user?.email}');
  } catch (e) {
    print('❌ Error creating user: $e');
  }
}
