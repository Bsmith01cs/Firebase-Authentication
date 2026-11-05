import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

/// Shows the signed-in user's details and lets them manage their account.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final email = authService.currentUser?.email ?? 'Unknown email';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle, size: 72),
              const SizedBox(height: 16),
              Text('Signed in as', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(email, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () => _openChangePasswordDialog(context),
                icon: const Icon(Icons.lock_reset),
                label: const Text('Change Password'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: authService.signOut,
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openChangePasswordDialog(BuildContext context) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );

    if (changed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated.')),
      );
    }
  }
}

/// Collects the current and new password, then updates it through AuthService.
class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  String? _validateCurrent(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter your current password.';
    }
    return null;
  }

  String? _validateNew(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Enter a new password.';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_isLoading || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // The service reauthenticates and retries on requires-recent-login.
      await _authService.updatePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _messageFor(e);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not update your password. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Your current password is incorrect.';
      case 'weak-password':
        return 'Choose a stronger password of at least 6 characters.';
      case 'requires-recent-login':
        return 'Please sign out and sign in again, then retry.';
      case 'no-current-user':
        return 'You are no longer signed in.';
      case 'missing-email':
        return 'This account has no email address to confirm with.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Could not update your password. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current password',
                border: OutlineInputBorder(),
              ),
              validator: _validateCurrent,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New password',
                border: OutlineInputBorder(),
              ),
              validator: _validateNew,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}
