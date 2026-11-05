import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'authentication_screen.dart';
import 'profile_screen.dart';

/// Routes between the authentication and profile screens based on auth state.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authService = AuthService();

  /// Created once so rebuilds reuse the same subscription.
  late final Stream<User?> _authState = _authService.authStateChanges();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: const Text(
                  'Something went wrong while checking your sign-in status. '
                  'Please restart the app and try again.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return snapshot.data == null
            ? const AuthenticationScreen()
            : const ProfileScreen();
      },
    );
  }
}
