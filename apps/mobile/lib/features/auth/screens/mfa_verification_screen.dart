import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_formatter.dart';

class MfaVerificationScreen extends ConsumerStatefulWidget {
  final String? email;
  final String? password;

  const MfaVerificationScreen({
    super.key,
    this.email,
    this.password,
  });

  @override
  ConsumerState<MfaVerificationScreen> createState() => _MfaVerificationScreenState();
}

class _MfaVerificationScreenState extends ConsumerState<MfaVerificationScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) return;

    HapticFeedback.lightImpact();

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authProvider.notifier).verifyMfa(code);
      // GoRouter handles redirection to dashboard because state changes
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppErrorFormatter.format(e),
              style: const TextStyle(fontFamily: AppTheme.fontBody),
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'MFA Verification',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppTheme.textSecondary),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: RepaintBoundary(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.cardSurface,
                          border: Border.all(
                            color: AppTheme.goldPrimary.withValues(alpha: 0.6),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.goldGlow,
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.security_outlined,
                          size: 36,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space20),
                      const Text(
                        'Two-Factor Authentication',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: AppTheme.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space8),
                      const Text(
                        'Enter the 6-digit verification code from your authenticator application to verify your session.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTheme.fontBody,
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space32),

                ElevatedActionCard(
                  padding: const EdgeInsets.all(AppTheme.space24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 10.0,
                          color: AppTheme.goldPrimary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                        decoration: InputDecoration(
                          labelText: 'Enter 6-Digit Code',
                          labelStyle: const TextStyle(
                            fontFamily: AppTheme.fontBody,
                            color: AppTheme.textMuted,
                            letterSpacing: 0.5,
                          ),
                          alignLabelWithHint: true,
                          counterText: '',
                          filled: true,
                          fillColor: AppTheme.elevatedSurface,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            borderSide: const BorderSide(color: AppTheme.goldPrimary, width: 1.5),
                          ),
                        ),
                        onChanged: (val) {
                          if (val.isNotEmpty) {
                            HapticFeedback.selectionClick();
                          }
                          if (val.length == 6) {
                            _verify();
                          }
                        },
                      ),
                      const SizedBox(height: AppTheme.space24),
                      TactilePressWrapper(
                        onTap: _isLoading ? null : _verify,
                        child: Container(
                          width: double.infinity,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _isLoading
                                ? AppTheme.goldPrimary.withValues(alpha: 0.5)
                                : AppTheme.goldPrimary,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.goldGlow,
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0B0F19)),
                                  ),
                                )
                              : const Text(
                                  'VERIFY & LOGIN',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    letterSpacing: 1.0,
                                    color: Color(0xFF0B0F19),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space20),

                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.go('/login');
                  },
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(
                      fontFamily: AppTheme.fontBody,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
