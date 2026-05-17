import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/services/supabase_service.dart';
import '../../../data/models/user_profile_model.dart';

// Selected university during onboarding
final selectedUniversityProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

// Selected role during onboarding (student / staff / admin)
final selectedRoleProvider = StateProvider<String?>((ref) => null);

// Current Supabase session
final sessionProvider = StreamProvider<AuthState>((ref) {
  return SupabaseService.authStateStream;
});

// Current user profile
final myProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) return null;
  final data = await SupabaseService.getMyProfile();
  if (data == null) return null;
  return UserProfile.fromMap(data);
});

// Auth notifier
class AuthNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      state = const AsyncValue.data(null);
      return;
    }
    await _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await SupabaseService.getMyProfile();
      if (data == null) {
        state = const AsyncValue.data(null);
      } else {
        state = AsyncValue.data(UserProfile.fromMap(data));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String?> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.signIn(email, password);
      await _loadProfile();
      return null;
    } on AuthException catch (e) {
      state = const AsyncValue.data(null);
      return e.message;
    } catch (e) {
      state = const AsyncValue.data(null);
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await SupabaseService.signOut();
    state = const AsyncValue.data(null);
  }

  Future<String?> resetPassword(String email) async {
    try {
      await SupabaseService.resetPassword(email);
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserProfile?>>(
  (_) => AuthNotifier(),
);
