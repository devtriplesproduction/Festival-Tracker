import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/ui_kit.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      await _alert('Enter your email');
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AuthRepository>().forgotPassword(email);
      if (!mounted) return;
      setState(() => _loading = false);
      await _alert('Password reset link sent to $email (if registered).');
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
      await _alert('Error: ${e.toString()}');
    }
  }

  Future<void> _alert(String msg) async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Forgot Password'),
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
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.94),
        border: null,
        middle: Text(
          'Reset Password',
          style: AppFonts.montserrat(size: 17, weight: FontWeight.w700),
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.all(context.pagePadding),
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
                          'Forgot Password',
                          style: AppFonts.montserrat(size: 18, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter your email address to receive a password reset link.',
                          style: AppFonts.helvetica(size: 13),
                        ),
                        const SizedBox(height: 20),
                        FormFieldBlock(
                          label: 'Email',
                          child: AppTextField(
                            controller: _emailCtrl,
                            placeholder: 'e.g. you@example.com',
                            autocorrect: false,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            prefix: const Icon(
                              CupertinoIcons.mail,
                              size: 18,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        PrimaryButton(
                          label: 'Send Reset Link',
                          icon: CupertinoIcons.paperplane_fill,
                          loading: _loading,
                          onPressed: _submit,
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
