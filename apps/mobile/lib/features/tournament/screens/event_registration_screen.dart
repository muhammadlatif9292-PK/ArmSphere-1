import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/state_providers.dart';

class EventRegistrationScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const EventRegistrationScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<EventRegistrationScreen> createState() => _EventRegistrationScreenState();
}

class _EventRegistrationScreenState extends ConsumerState<EventRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedDivision = 'Heavyweight (-95kg)';
  String _armChoice = 'BOTH';
  bool _isLoading = false;

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registered successfully for the tournament!'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
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
        title: const Text('Event Registration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: GlassCard(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Select Weight Category',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedDivision,
                  items: const [
                    DropdownMenuItem(value: 'Lightweight (-70kg)', child: Text('Lightweight (-70kg)')),
                    DropdownMenuItem(value: 'Middleweight (-85kg)', child: Text('Middleweight (-85kg)')),
                    DropdownMenuItem(value: 'Heavyweight (-95kg)', child: Text('Heavyweight (-95kg)')),
                    DropdownMenuItem(value: 'Super Heavyweight (95kg+)', child: Text('Super Heavyweight (95kg+)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedDivision = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                const Text(
                  'Pulling Arms Registration',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _armChoice,
                  items: const [
                    DropdownMenuItem(value: 'RIGHT', child: Text('Right Arm Only')),
                    DropdownMenuItem(value: 'LEFT', child: Text('Left Arm Only')),
                    DropdownMenuItem(value: 'BOTH', child: Text('Both Arms')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _armChoice = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Complete and Pay Entry Fee'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
