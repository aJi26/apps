import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import '../../core/routing/app_router.dart';
import '../../core/services/api_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final bool initialRegister;
  const LoginScreen({super.key, this.initialRegister = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false, _busy = false, _obscure = true;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope,
    ],
    serverClientId: '698414565888-l4ccgn1ojergb2uts08b5ccpk1n69a2a.apps.googleusercontent.com',
  );

  @override
  void initState() {
    super.initState();
    _register = widget.initialRegister;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _busy = true);
    try {
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final response = await ApiService.request('POST', 'auth/google-login', body: {
        'id_token': googleAuth.idToken,
        'email': googleUser.email,
        'name': googleUser.displayName,
        'is_register': _register,
      });

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (mounted) {
        if (response.statusCode == 200 || response.statusCode == 201) {
          // 1. Simpan Token Auth
          await ApiService.saveToken(data['access_token'] as String);

          // 2. Sinkronkan Token FCM HP ke Backend Laravel
          await NotificationService.syncFcmTokenWithBackend();

          if (!mounted) return;
          final gateResult = await AppRouter.resolve(context);
          if (!mounted) return;
          if (gateResult == GateResult.retry) {
            _message(
              'Signed in, but we could not load your space yet. Try again when you are online.',
            );
          }
        } else {
          _message(data['message']?.toString() ?? 'Google Sign-In failed.');
        }
      }
    } catch (e) {
      _message('Google Sign-In failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final emailText = _email.text.trim().toLowerCase();
    final passwordText = _password.text;

    if (emailText.isEmpty || passwordText.isEmpty) {
      _message('Please complete each field.');
      return;
    }

    if (_register && passwordText.length < 8) {
      _message('Your password needs at least 8 characters.');
      return;
    }

    setState(() => _busy = true);

    try {
      if (_register) {
        final tempName = emailText.split('@').first;
        final response = await ApiService.register(
          tempName,
          emailText,
          passwordText,
        );
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (response.statusCode == 200 || response.statusCode == 201) {
          _message('Account created successfully! Please log in to continue.');
          setState(() {
            _register = false;
            _password.clear();
          });
        } else {
          _message(
            data['message']?.toString() ?? 'Could not create account. Try again.',
          );
        }
      } else {
        final response = await ApiService.login(emailText, passwordText);
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (response.statusCode == 200 || response.statusCode == 201) {
          // 1. Simpan Token Auth
          await ApiService.saveToken(data['token'] as String);

          // 2. Sinkronkan Token FCM HP ke Backend Laravel
          await NotificationService.syncFcmTokenWithBackend();

          if (!mounted) return;

          final gateResult = await AppRouter.resolve(context);
          if (!mounted) return;
          if (gateResult == GateResult.retry) {
            _message(
              'Signed in, but we could not load your space yet. Try again when you are online.',
            );
          }
        } else {
          _message(
            data['message']?.toString() ??
                'We couldn’t sign you in. Please try again.',
          );
        }
      }
    } catch (_) {
      _message(
        'Unable to reach Her Space. Check your connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 28),
                  Text(
                    'Her Space',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _register
                        ? 'Create a soft place to land.'
                        : 'Come back to your little corner.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(Icons.mail_outline),
                      hintText: 'user@gmail.com',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    autofillHints: [
                      _register
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    decoration: InputDecoration(
                      labelText: _register
                          ? 'Password (8 characters minimum)'
                          : 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_register ? 'Create account' : 'Log in'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _handleGoogleSignIn,
                    icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                    label: Text(_register ? 'Sign up with Google' : 'Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _register = !_register),
                    child: Text(
                      _register
                          ? 'Already have an account? Log in'
                          : 'New here? Create an account',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}