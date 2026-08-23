import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/payment_methods_provider.dart';

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  bool _isLoading = false;

  Future<void> _addPaymentMethod() async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment card linked securely via Stripe')),
        );
      }
    } catch (e) {
      if (mounted) {
        final errString = e.toString();
        if (!errString.contains('canceled') && !errString.contains('Canceled')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Stripe setup failed: $e')),
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
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(paymentMethodsProvider.notifier).deletePaymentMethod(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment method removed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete payment method: $e')),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'LINKED STRIPE CARDS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),

            methodsAsyncValue.when(
              data: (methods) {
                if (methods.isEmpty) {
                  return const GlassCard(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No payment methods linked.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: methods.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = methods[index];
                    final brand = item['brand']?.toString() ?? 'Card';
                    final last4 = item['last4']?.toString() ?? '••••';
                    final id = item['id']?.toString() ?? '';

                    return GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: ListTile(
                        leading: const Icon(
                          Icons.credit_card,
                          size: 32,
                          color: Colors.amber,
                        ),
                        title: Text(
                          '$brand •••• $last4',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: _isLoading || id.isEmpty
                              ? null
                              : () => _deleteCard(id),
                        ),
                      ),
                    );
                  },
                );
              },
              error: (err, stack) => GlassCard(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'Error: $err',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              'LINK NEW CARD',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'We partner with Stripe to ensure secure and seamless credit card processing. We never store your raw card details.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _addPaymentMethod,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Add Payment Method'),
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
