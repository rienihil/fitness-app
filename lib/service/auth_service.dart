import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Auth change stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user data to shared preferences
      await _saveUserData(credential.user);

      // Ensure guest mode is turned off
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isGuestMode', false);

      return credential;
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  // Create user with email and password
  Future<UserCredential?> createUserWithEmailAndPassword(String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(name);

      // Save user data to shared preferences
      await _saveUserData(credential.user);

      // Ensure guest mode is turned off
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isGuestMode', false);

      return credential;
    } catch (e) {
      debugPrint('Sign up error: $e');
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Save user data to shared preferences
      await _saveUserData(userCredential.user);

      // Ensure guest mode is turned off
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isGuestMode', false);

      return userCredential;
    } catch (e) {
      debugPrint('Google sign in error: $e');
      rethrow;
    }
  }

  // Sign in as guest
  Future<void> signInAsGuest() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Set guest flag
      await prefs.setBool('isGuestMode', true);

      // Save minimal user data
      await prefs.setString('name', 'Guest User');
      await prefs.setString('email', 'guest@example.com');
      await prefs.setString('uid', 'guest-user-id');

      debugPrint('Signed in as guest');
    } catch (e) {
      debugPrint('Guest sign in error: $e');
      rethrow;
    }
  }

  // Check if user is in guest mode
  Future<bool> isGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isGuestMode') ?? false;
  }

  // Save user data to shared preferences
  Future<void> _saveUserData(User? user) async {
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', user.displayName ?? 'User');
    await prefs.setString('email', user.email ?? 'No email');
    await prefs.setString('uid', user.uid);

    // Save profile picture URL if available
    if (user.photoURL != null) {
      await prefs.setString('photoURL', user.photoURL!);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();

      // Clear only auth-related preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('name');
      await prefs.remove('email');
      await prefs.remove('uid');
      await prefs.remove('photoURL');
      await prefs.remove('isGuestMode');
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Password reset error: $e');
      rethrow;
    }
  }
}