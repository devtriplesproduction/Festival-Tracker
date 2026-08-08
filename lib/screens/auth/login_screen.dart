import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../data/repositories/auth_repository.dart';
import '../../providers/auth_state.dart';
import '../../widgets/ui_kit.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = _userCtrl.text.trim();
    final pass = _passCtrl.text;
    if (user.isEmpty || pass.isEmpty) {
      await _alert('Enter username and password');
      return;
    }
    setState(() => _loading = true);
    final ok = await context.read<AuthState>().login(user, pass);
    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok) {
      await _alert(context.read<AuthState>().error ?? 'Login failed');
    }
  }

  Future<void> _submitGoogle() async {
    setState(() => _googleLoading = true);
    final ok = await context.read<AuthState>().loginWithGoogle();
    if (!mounted) return;
    setState(() => _googleLoading = false);
    if (!ok) {
      final err = context.read<AuthState>().error;
      // Cancelled picker leaves error null — stay quiet.
      if (err != null && err.isNotEmpty) {
        await _alert(err);
      }
    }
  }

  Future<void> _alert(String msg) async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Sign in'),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loading || _googleLoading;

    final p = context.pagePadding;
    final logo = context.isCompact ? 64.0 : 72.0;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: p, vertical: p),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: context.isTablet ? 440 : 420,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: logo,
                      height: logo,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.accent, AppColors.accentDeep],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: AppShadows.card,
                      ),
                      child: Icon(
                        CupertinoIcons.calendar_badge_plus,
                        color: Colors.white,
                        size: logo * 0.47,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Festival Tracker',
                    textAlign: TextAlign.center,
                    style: AppFonts.montserrat(
                      size: context.titleFontSize,
                      weight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Triple S Production',
                    textAlign: TextAlign.center,
                    style: AppFonts.poppins(
                      size: 14,
                      weight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: AppShadows.card,
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Sign in',
                          style: AppFonts.montserrat(size: 18, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Team: email/password · Admin may use Google',
                          style: AppFonts.helvetica(size: 13),
                        ),
                        const SizedBox(height: 20),
                        FormFieldBlock(
                          label: 'Email or Username',
                          child: AppTextField(
                            controller: _userCtrl,
                            placeholder: 'username',
                            autocorrect: false,
                            textInputAction: TextInputAction.next,
                            prefix: const Icon(
                              CupertinoIcons.person,
                              size: 18,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FormFieldBlock(
                          label: 'Password',
                          child: AppTextField(
                            controller: _passCtrl,
                            placeholder: '••••••••',
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) {
                              if (!busy) _submit();
                            },
                            prefix: const Icon(
                              CupertinoIcons.lock,
                              size: 18,
                              color: AppColors.textTertiary,
                            ),
                            suffix: CupertinoButton(
                              padding: const EdgeInsets.only(right: 8),
                              onPressed: busy
                                  ? null
                                  : () => setState(() => _obscure = !_obscure),
                              child: Icon(
                                _obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                                size: 20,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        PrimaryButton(
                          label: 'Sign in',
                          icon: CupertinoIcons.arrow_right_circle_fill,
                          loading: _loading,
                          onPressed: busy ? null : _submit,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            const Expanded(child: Divider(color: AppColors.divider)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'or',
                                style: AppFonts.helvetica(
                                  size: 12,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(color: AppColors.divider)),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _GoogleSignInButton(
                          loading: _googleLoading,
                          onPressed: busy ? null : _submitGoogle,
                        ),
                       
                      ],
                    ),
                  ),
         
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Minimal Google-styled button that matches existing PrimaryButton layout.
class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(14),
        color: AppColors.surface,
        onPressed: loading ? null : onPressed,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          alignment: Alignment.center,
          child: loading
              ? const CupertinoActivityIndicator()
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Simple monochrome "G" badge — no asset dependency.
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'G',
                        style: AppFonts.montserrat(
                          size: 13,
                          weight: FontWeight.w800,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Continue with Google (Admin)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.poppins(
                          size: 14,
                          weight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
