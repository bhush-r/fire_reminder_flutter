import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final authControllerProvider =
StateNotifierProvider<AuthController, AsyncValue<User?>>(
      (ref) => AuthController(
    firebaseAuth: FirebaseAuth.instance,
    googleSignIn: GoogleSignIn(),
  ),
);

class AuthController extends StateNotifier<AsyncValue<User?>> {
  AuthController({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn,
        super(AsyncValue.data(firebaseAuth.currentUser)) {
    _sub = _firebaseAuth.authStateChanges().listen((user) {
      // keep state in sync even after app restarts
      state = AsyncValue.data(user);
    });
  }

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  StreamSubscription<User?>? _sub;

  bool get isSigningIn => state.isLoading;

  Future<void> signInWithGoogle() async {
    if (isSigningIn) return;

    // Keep current user data while showing loading to avoid flicker.
    final previous = state.valueOrNull;
    state = AsyncValue.loading();
    if (previous != null) {
      state = AsyncValue<User?>.loading().copyWithPrevious(AsyncValue.data(previous));
    }

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // user cancelled - just go back to previous state
        state = AsyncValue.data(_firebaseAuth.currentUser);
        return;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _firebaseAuth.signInWithCredential(credential);

      // authStateChanges listener will update state, but set explicitly too.
      state = AsyncValue.data(_firebaseAuth.currentUser);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      // ensure account is fully disconnected (helps prevent auto selecting old account)
      await _googleSignIn.disconnect();
    } catch (_) {
      // ignore disconnect errors (already disconnected etc.)
    }

    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
    state = const AsyncValue.data(null);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}