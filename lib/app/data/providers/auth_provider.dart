import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_provider.dart';

/// Authentication transport only. Profile mutation goes through the validated
/// `math_update_profile` RPC, never through direct table writes.
class AuthProvider {
  Future<AuthResponse> signInAnonymously(String displayName) {
    return SupabaseProvider.auth.signInAnonymously(
      data: {'display_name': displayName},
    );
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) {
    return SupabaseProvider.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) {
    return SupabaseProvider.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> resetPassword(String email) {
    return SupabaseProvider.auth.resetPasswordForEmail(email);
  }

  User? get currentUser => SupabaseProvider.auth.currentUser;

  String? get currentUserId => currentUser?.id;

  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges =>
      SupabaseProvider.auth.onAuthStateChange;

  Future<void> signOut() => SupabaseProvider.auth.signOut();

  Future<void> updateDisplayNameMetadata(String displayName) async {
    await SupabaseProvider.auth.updateUser(
      UserAttributes(data: {'display_name': displayName}),
    );
  }

  /// Converts the current anonymous session into a permanent email account
  /// without losing the player's statistics.
  Future<UserResponse> upgradeGuestAccount({
    required String email,
    required String password,
  }) {
    return SupabaseProvider.auth.updateUser(
      UserAttributes(email: email, password: password),
    );
  }
}
