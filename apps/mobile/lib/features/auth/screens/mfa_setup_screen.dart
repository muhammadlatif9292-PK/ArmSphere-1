import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';

class MfaSetupScreen extends StatefulWidget {
  const MfaSetupScreen({super.key});

  @override
  State<MfaSetupScreen> createState() => _MfaSetupScreenState();
}

class _MfaSetupScreenState extends State<MfaSetupScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_codeController.text.trim().length != 6) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final code = _codeController.text.trim();
      final authRepository = ref.read(authRepositoryProvider);
      final authState = ref.read(authProvider);
      final currentUser = authState.userProfile?['user'] as Map<String, dynamic>? ?? authState.userProfile ?? {};
      final userId = currentUser['id']?.toString() ?? currentUser['userId']?.toString();
      await authRepository.verifyMfa(code, userId: userId);
      
      if (mounted) {
        context.pushReplacement('/recovery-codes');
      }
    } catch (_) {
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup MFA'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Secure Your Account',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan the QR code with an authenticator app (Google Authenticator, Authy, etc.) and enter the 6-digit code below.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),

            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Icon(Icons.qr_code_2, size: 160, color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(height: 32),

            GlassCard(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8.0),
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
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verify,
                    child: _isLoading ? const CircularProgressIndicator() : const Text('Enable MFA'),
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
