import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      // 1) Create the auth user with metadata
      final AuthResponse response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': role,
        },
      );

      final User? user = response.user;
      if (user == null) {
        throw Exception('Signup failed: user is null');
      }

      // 2) Insert into users table
      await _client.from('users').insert({
        'id': user.id,
        'email': email,
        'name': name,
        'role': role,
      });
    } on PostgrestException catch (e) {
      // Handle database errors (like missing table)
      throw AuthException(e.message);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<String> getUserRole() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    // First try: get from user metadata (stored during signup)
    final metadata = user.userMetadata;
    if (metadata != null && metadata['role'] != null) {
      return metadata['role'] as String;
    }

    // Fallback: fetch from users table
    try {
      final response = await _client
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();

      return response['role'] as String? ?? 'worker';
    } catch (e) {
      // If table doesn't exist or query fails, default to worker
      return 'worker';
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}

