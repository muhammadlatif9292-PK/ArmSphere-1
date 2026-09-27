import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/providers/state_providers.dart';
import '../../auth/providers/auth_provider.dart';

class MfaSetupScreen extends ConsumerStatefulWidget {
  const MfaSetupScreen({super.key});

  @override
  ConsumerState<MfaSetupScreen> createState() => _MfaSetupScreenState();
}

class _MfaSetupScreenState extends ConsumerState<MfaSetupScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_codeController.text.trim().length != 6) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
    });

    try {
      final code = _codeController.text.trim();
      final authRepository = ref.read(authRepositoryProvider);
      final authState = ref.read(authProvider);
      final currentUser = authState.userProfile?['user'] as Map<String, dynamic>? ?? authState.userProfile ?? {};
      final userId = currentUser['id']?.toString() ?? currentUser['userId']?.toString();
      if (userId == null || userId.isEmpty) return;
      await authRepository.verifyMfa(code, userId: userId);
      
      if (mounted) {
        HapticFeedback.lightImpact();
        context.pushReplacement('/recovery-codes');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid verification code. Please check your authenticator app.'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
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
      appBar: AppBar(
        title: const Text('Setup Two-Factor Auth'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space14),
                    decoration: BoxDecoration(
                      color: AppTheme.goldPrimary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.goldPrimary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(Icons.security, size: 40, color: AppTheme.goldPrimary),
                  ),
                  const SizedBox(height: AppTheme.space16),
                  const Text(
                    'Secure Your Account',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  const Text(
                    'Scan the QR code with an authenticator app (Google Authenticator, Authy) and enter the 6-digit code below.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space24),

            Center(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Icon(Icons.qr_code_2, size: 148, color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space24),

            ElevatedActionCard(
              padding: const EdgeInsets.all(AppTheme.space20),
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
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8.0,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Verification Code',
                      alignLabelWithHint: true,
                      counterText: '',
                    ),
                    onChanged: (val) {
                      if (val.length == 6) {
                        _verify();
                      }
                    },
                  ),
                  const SizedBox(height: AppTheme.space20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verify,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Enable MFA Protection'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
