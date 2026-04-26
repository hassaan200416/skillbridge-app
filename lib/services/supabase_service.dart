
// ---------------------------------------------------------------------------
// supabase_service.dart
//
// Purpose: Singleton wrapper around the Supabase client.
// Provides a single access point to the Supabase instance and exposes
// helper methods for auth state and current user.
//
// All repositories use this service — never import supabase_flutter
// directly in repositories or UI.
//
// ---------------------------------------------------------------------------

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  /// The underlying Supabase client
  SupabaseClient get client => Supabase.instance.client;

  /// Current authenticated user — null if not logged in
  User? get currentUser => client.auth.currentUser;

  /// Current user's UUID — null if not logged in
  String? get currentUserId => client.auth.currentUser?.id;

  /// Whether a user is currently logged in
  bool get isLoggedIn => client.auth.currentUser != null;

  /// Stream of auth state changes — used by auth provider
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  /// Shortcut to the auth object
  GoTrueClient get auth => client.auth;

  /// Shortcut to storage
  SupabaseStorageClient get storage => client.storage;

  /// Helper: get a table reference
  SupabaseQueryBuilder from(String table) => client.from(table);

  /// Helper: call an RPC function
  dynamic rpc(String fn, {Map<String, dynamic>? params}) =>
      client.rpc(fn, params: params);
}
