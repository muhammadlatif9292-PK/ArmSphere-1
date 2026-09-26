import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/providers/dependency_providers.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_formatter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _canUseBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final bioService = ref.read(biometricServiceProvider);
      final isAvailable = await bioService.isBiometricUnlockAvailable();
      final secureStorage = ref.read(secureStorageProvider);
      final token = await secureStorage.getRefreshToken();
      if (mounted) {
        setState(() {
          _canUseBiometrics = isAvailable && token != null && token.isNotEmpty;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _canUseBiometrics = false;
        });
      }
    }
  }

  Future<void> _unlockWithBiometrics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bioService = ref.read(biometricServiceProvider);
      final result = await bioService.authenticate(
        localizedReason: 'Sign in to your ArmSphere account',
        allowDeviceCredentials: true,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        await ref.read(authProvider.notifier).checkInitialSession();
        final currentStatus = ref.read(authProvider).status;
        if (currentStatus == AuthStatus.authenticated ||
            currentStatus == AuthStatus.onboardingRequired) {
          return;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Stored session expired. Please sign in with your email and password.',
              ),
            ),
          );
        }
      } else if (result.status == BiometricAuthStatus.canceled) {
        // Voluntary cancel by user; remain on standard login form without error
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message ??
                  'Biometric authentication failed. Please enter your password.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Biometrics unavailable: ${AppErrorFormatter.format(e)}. Please enter your password.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorFormatter.format(e)),
            backgroundColor: Theme.of(context).colorScheme.error,
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.cardSurface,
                        border: Border.all(
                          color: AppTheme.goldPrimary.withValues(alpha: 0.6),
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: AppTheme.goldGlow,
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.sports_kabaddi,
                          size: 38,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ArmSphere',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontWeight: FontWeight.w800,
                        fontSize: 30,
                        letterSpacing: -1.0,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sign in to your competitive account',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              Form(
                key: _formKey,
                child: ElevatedActionCard(
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined, color: AppTheme.goldPrimary),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.goldPrimary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: AppTheme.textMuted,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.push('/forgot-password'),
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(
                              color: AppTheme.goldPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Submit Button
                      FilledButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                _submit();
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.goldPrimary,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                ),
                              )
                            : const Text('Sign In to Account'),
                      ),

                      if (_canUseBiometrics) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  HapticFeedback.lightImpact();
                                  _unlockWithBiometrics();
                                },
                          icon: const Icon(Icons.fingerprint, size: 20, color: AppTheme.goldPrimary),
                          label: const Text('Sign in with Biometrics'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary,
                            side: const BorderSide(color: AppTheme.border, width: 1.2),
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                            textStyle: const TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Register Prompt
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
