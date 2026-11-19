import 'dart:async';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/math_api_models.dart';
import '../data/providers/auth_provider.dart';
import '../data/providers/math_api_provider.dart';
import '../domain/models/math_models.dart';

class SignUpOutcome {
  const SignUpOutcome({required this.signedIn, this.message});

  final bool signedIn;
  final String? message;
}

/// Application-level session and profile state.
///
/// The Supabase session is the identity; the database `players` row is the
/// authoritative game profile. Controllers observe [profile] instead of
/// querying tables directly.
class SessionService extends GetxService {
  SessionService(this._auth, this._api);

  final AuthProvider _auth;
  final MathApiProvider _api;

  final Rx<MathProfile?> profile = Rx<MathProfile?>(null);
  final RxBool isLoading = RxBool(false);
  final RxString error = RxString('');
  final RxBool isSignedIn = RxBool(false);
  final RxBool tutorialCompleted = RxBool(false);

  StreamSubscription<AuthState>? _authSub;
  bool _refreshing = false;

  String? get userId => _auth.currentUserId;

  bool get isGuest => _auth.currentUser?.isAnonymous ?? true;

  bool get soundEnabled => profile.value?.soundEnabled ?? true;

  bool get reducedMotion => profile.value?.reducedMotion ?? false;

  GradeLevel get grade => profile.value?.grade ?? GradeLevel.grade1;

  bool get isKindergarten => grade == GradeLevel.kindergarten;

  /// Competitive play waits until a Kindergarten player has finished the
  /// guided tutorial. Older grades can jump straight in.
  bool get needsKindergartenTutorial =>
      isKindergarten && !tutorialCompleted.value;

  @override
  void onInit() {
    super.onInit();
    isSignedIn.value = _auth.isAuthenticated;
    _authSub = _auth.authStateChanges.listen((state) {
      isSignedIn.value = state.session != null;
      if (state.event == AuthChangeEvent.signedOut) {
        profile.value = null;
      }
    });
    if (_auth.isAuthenticated) {
      unawaited(refreshProfile());
    }
  }

  @override
  void onClose() {
    _authSub?.cancel();
    super.onClose();
  }

  Future<MathProfile?> refreshProfile() async {
    if (!_auth.isAuthenticated || _refreshing) return profile.value;
    _refreshing = true;
    try {
      error.value = '';
      final next = await _api.profile();
      profile.value = next;
      isSignedIn.value = true;
      try {
        tutorialCompleted.value = await _api.tutorialCompleted();
      } catch (_) {
        // Older deployments may predate the tutorial RPC. Play stays
        // available, but the guided intro is shown once per session.
      }
      return next;
    } on MathApiException catch (exception) {
      // The auth trigger normally creates the row. If a legacy account is
      // missing one, healing through the validated RPC is safe.
      if (exception.message.toLowerCase().contains('not found')) {
        final metadataName =
            _auth.currentUser?.userMetadata?['display_name'] as String?;
        try {
          await _api.updateProfile(
            displayName: _sanitizeName(metadataName ?? 'Player'),
          );
          final next = await _api.profile();
          profile.value = next;
          tutorialCompleted.value = await _api.tutorialCompleted();
          return next;
        } catch (_) {
          error.value = exception.message;
          return null;
        }
      }
      error.value = exception.message;
      return null;
    } catch (_) {
      error.value = 'Your profile could not be loaded.';
      return null;
    } finally {
      _refreshing = false;
    }
  }

  Future<void> signInAsGuest({
    required String displayName,
    required GradeLevel grade,
    required int avatarIndex,
    required String avatarColor,
  }) async {
    isLoading.value = true;
    error.value = '';
    try {
      await _auth.signInAnonymously(displayName);
      await _api.updateProfile(
        displayName: _sanitizeName(displayName),
        avatarIndex: avatarIndex,
        avatarColor: avatarColor,
        grade: grade,
      );
      await refreshProfile();
      isSignedIn.value = true;
    } on MathApiException catch (exception) {
      error.value = exception.message;
      rethrow;
    } on AuthException catch (exception) {
      error.value = exception.message;
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<SignUpOutcome> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    required GradeLevel grade,
    required int avatarIndex,
    required String avatarColor,
  }) async {
    isLoading.value = true;
    error.value = '';
    try {
      final response = await _auth.signUpWithEmail(
        email: email.trim(),
        password: password,
        displayName: _sanitizeName(displayName),
      );
      if (response.session == null) {
        return const SignUpOutcome(
          signedIn: false,
          message: 'Check your email to confirm your account, then sign in.',
        );
      }
      await _api.updateProfile(
        displayName: _sanitizeName(displayName),
        avatarIndex: avatarIndex,
        avatarColor: avatarColor,
        grade: grade,
      );
      await refreshProfile();
      isSignedIn.value = true;
      return const SignUpOutcome(signedIn: true);
    } on MathApiException catch (exception) {
      error.value = exception.message;
      rethrow;
    } on AuthException catch (exception) {
      error.value = exception.message;
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    isLoading.value = true;
    error.value = '';
    try {
      await _auth.signInWithEmail(email: email.trim(), password: password);
      await refreshProfile();
      isSignedIn.value = true;
    } on MathApiException catch (exception) {
      error.value = exception.message;
      rethrow;
    } on AuthException catch (exception) {
      error.value = exception.message;
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword(String email) async {
    await _auth.resetPassword(email.trim());
  }

  /// Saves an anonymous guest's progress by attaching an email and password
  /// to the existing Supabase user. The player row is preserved.
  Future<void> upgradeGuestAccount({
    required String email,
    required String password,
  }) async {
    isLoading.value = true;
    error.value = '';
    try {
      await _auth.upgradeGuestAccount(email: email.trim(), password: password);
      await refreshProfile();
      isSignedIn.value = true;
    } on AuthException catch (exception) {
      error.value = exception.message;
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile({
    String? displayName,
    int? avatarIndex,
    String? avatarColor,
    GradeLevel? grade,
  }) async {
    final current = profile.value;
    if (current == null) {
      throw const MathApiException('Your profile is still loading.');
    }
    await _api.updateProfile(
      displayName: _sanitizeName(displayName ?? current.displayName),
      avatarIndex: avatarIndex ?? current.avatarIndex,
      avatarColor: avatarColor ?? current.avatarColor,
      grade: grade ?? current.grade,
    );
    await refreshProfile();
  }

  Future<void> updateSettings({
    bool? soundEnabled,
    bool? reducedMotion,
    bool? leaderboardVisible,
  }) async {
    await _api.updateSettings(
      soundEnabled: soundEnabled,
      reducedMotion: reducedMotion,
      leaderboardVisible: leaderboardVisible,
    );
    await refreshProfile();
  }

  Future<void> completeTutorial() async {
    // Mark the tutorial complete locally first. If the network is down, the
    // child still moves on to play instead of being sent back to the intro.
    tutorialCompleted.value = true;
    await _api.completeTutorial();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    profile.value = null;
    isSignedIn.value = false;
    tutorialCompleted.value = false;
  }

  Future<void> deleteAccount() async {
    await _api.deleteAccount();
    await _auth.signOut();
    profile.value = null;
    isSignedIn.value = false;
    tutorialCompleted.value = false;
  }

  String _sanitizeName(String value) {
    final cleaned = value
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r"[^A-Za-z0-9 ._'-]"), '');
    if (cleaned.length < 2) return 'Player';
    return cleaned.length > 20 ? cleaned.substring(0, 20) : cleaned;
  }
}
