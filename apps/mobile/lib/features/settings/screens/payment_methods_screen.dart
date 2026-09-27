import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/providers/payment_methods_provider.dart';

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  bool _isLoading = false;

  Future<void> _addPaymentMethod() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
    });

    try {
      final notifier = ref.read(paymentMethodsProvider.notifier);
      final setupIntentData = await notifier.createSetupIntent();
      final clientSecret = setupIntentData['clientSecret'] as String;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          setupIntentClientSecret: clientSecret,
          merchantDisplayName: 'ArmSphere',
          style: ThemeMode.dark,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      // Refresh the payment methods provider on success
      ref.invalidate(paymentMethodsProvider);

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment card linked securely via Stripe'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errString = e.toString();
        if (!errString.contains('canceled') && !errString.contains('Canceled')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Stripe setup failed: $e'),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteCard(String id) async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(paymentMethodsProvider.notifier).deletePaymentMethod(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment method removed successfully'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete payment method: $e'),
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
    final methodsAsyncValue = ref.watch(paymentMethodsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'LINKED STRIPE CARDS',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppTheme.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: AppTheme.space12),

            methodsAsyncValue.when(
              data: (methods) {
                if (methods.isEmpty) {
                  return const ElevatedActionCard(
                    padding: EdgeInsets.all(AppTheme.space24),
                    child: Center(
                      child: Text(
                        'No payment methods linked yet.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: methods.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space10),
                  itemBuilder: (context, index) {
                    final item = methods[index];
                    final brand = (item['brand']?.toString() ?? 'Card').toUpperCase();
                    final last4 = item['last4']?.toString() ?? '••••';
                    final id = item['id']?.toString() ?? '';

                    return RepaintBoundary(
                      child: ElevatedActionCard(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppTheme.space10),
                              decoration: BoxDecoration(
                                color: AppTheme.goldPrimary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                border: Border.all(
                                  color: AppTheme.goldPrimary.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.credit_card,
                                size: 24,
                                color: AppTheme.goldPrimary,
                              ),
                            ),
                            const SizedBox(width: AppTheme.space14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    brand,
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.space4),
                                  Text(
                                    '•••• •••• •••• $last4',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                      fontFeatures: [FontFeature.tabularFigures()],
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Delete Card',
                              icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                              onPressed: _isLoading || id.isEmpty
                                  ? null
                                  : () => _deleteCard(id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              error: (err, stack) => ElevatedActionCard(
                padding: const EdgeInsets.all(AppTheme.space20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 36, color: AppTheme.error),
                    const SizedBox(height: AppTheme.space8),
                    Center(
                      child: Text(
                        'Error: $err',
                        style: const TextStyle(color: AppTheme.error, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space12),
                    TextButton(
                      onPressed: () => ref.invalidate(paymentMethodsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.space24),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space32),

            const Text(
              'LINK NEW PAYMENT CARD',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppTheme.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            ElevatedActionCard(
              padding: const EdgeInsets.all(AppTheme.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.space8),
                        decoration: BoxDecoration(
                          color: AppTheme.info.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: const Icon(Icons.lock_outline, size: 20, color: AppTheme.info),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      const Expanded(
                        child: Text(
                          'PCI-DSS Certified Security',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space12),
                  const Text(
                    'We partner with Stripe to ensure military-grade 256-bit encryption for payment processing. ArmSphere never stores or sees your raw credit card numbers.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: AppTheme.space20),
                  ElevatedButton.icon(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.add_card, size: 18),
                    label: const Text('Add Payment Method'),
                    onPressed: _isLoading ? null : _addPaymentMethod,
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
