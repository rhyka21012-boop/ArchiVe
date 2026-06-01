import 'dart:io';

import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'l10n/app_localizations.dart';

/// サインイン画面
/// Navigator.pop で bool を返す（true: サインイン成功 / false: キャンセル）
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  Future<void> _signInWithApple() async {
    // Apple アカウントは Android で共有不可な旨を事前警告
    final confirmed = await _showAppleSigninWarning();
    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    // ignore: avoid_print
    print('==== Apple Sign-In tap ====');
    try {
      final user = await AuthService.signInWithApple();
      // ignore: avoid_print
      print('==== Apple Sign-In result: user=$user ====');
      if (!mounted) return;
      if (user != null) {
        Navigator.pop(context, true);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('==== Apple Sign-In ERROR ====');
      // ignore: avoid_print
      print('$e');
      // ignore: avoid_print
      print('$st');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showFailedSnack(detail: '$e');
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.signInWithGoogle();
      if (!mounted) return;
      if (user != null) {
        Navigator.pop(context, true);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showFailedSnack(detail: '$e');
    }
  }

  /// Apple サインイン前の警告ダイアログ（Android で共有できない旨）
  Future<bool?> _showAppleSigninWarning() {
    final colorScheme = Theme.of(context).colorScheme;
    final l = L10n.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.secondary,
        title: Row(
          children: [
            Icon(Icons.info_outline, color: colorScheme.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l.apple_signin_warning_title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          l.apple_signin_warning_description,
          style: const TextStyle(fontSize: 13, height: 1.6),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(L10n.of(ctx)!.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.apple_signin_warning_continue),
          ),
        ],
      ),
    );
  }

  void _showFailedSnack({String? detail}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(L10n.of(ctx)!.login_failed),
        content: SingleChildScrollView(
          child: SelectableText(
            detail ?? '(no detail)',
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l = L10n.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.lock_outline,
                size: 60,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 20),
              Text(
                l.login_page_title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.login_page_description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                // Apple は iOS で必須（他のサインインを提供する場合）
                if (Platform.isIOS) ...[
                  _buildSignInButton(
                    label: l.login_with_apple,
                    icon: Icons.apple,
                    onTap: _signInWithApple,
                    bgColor: Colors.black,
                    fgColor: Colors.white,
                  ),
                  const SizedBox(height: 12),
                ],
                _buildSignInButton(
                  label: l.login_with_google,
                  icon: Icons.g_mobiledata,
                  onTap: _signInWithGoogle,
                  bgColor: Colors.white,
                  fgColor: Colors.black87,
                  borderColor: Colors.grey[400],
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required Color bgColor,
    required Color fgColor,
    Color? borderColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: fgColor, size: 24),
        label: Text(
          label,
          style: TextStyle(
            color: fgColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: borderColor != null
                ? BorderSide(color: borderColor, width: 1)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
