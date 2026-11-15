import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
import '../../../core/widgets/crystal_toast.dart';

class RecoveryCodesScreen extends StatefulWidget {
  const RecoveryCodesScreen({super.key});

  @override
  State<RecoveryCodesScreen> createState() => _RecoveryCodesScreenState();
}

class _RecoveryCodesScreenState extends State<RecoveryCodesScreen> {
  bool _isCopied = false;

  final List<String> _codes = const [
    'ABCD-1234-EFGH',
    'IJKL-5678-MNOP',
    'QRST-9012-UVWX',
    'YZAB-3456-CDEF',
    'GHIJ-7890-KLMN',
    'OPQR-1234-STUV',
  ];

  Future<void> _copyCodes() async {
    final text = _codes.join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();

    setState(() {
      _isCopied = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        CrystalSnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: AppTheme.success, size: 20),
              SizedBox(width: 8),
              Text(
                'Recovery codes safely copied to clipboard',
                style: TextStyle(fontFamily: AppTheme.fontBody),
              ),
            ],
          ),
          backgroundColor: AppTheme.elevatedSurface,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: const CrystalBackButton(fallbackRoute: '/settings'),
        title: const Text(
          'Recovery Codes',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: const [CrystalHomeButton()],
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: CrystalStageBackdrop(domain: ArmSphereStageDomain.authWalkout),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                      border: Border.all(
                        color: const Color(0x73D4AF37),
                        width: 1.5,
                      ),
                      boxShadow: const [],
                    ),
                child: const Icon(
                  Icons.save_outlined,
                  size: 32,
                  color: AppTheme.goldPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              const Text(
                'Save Your Recovery Codes',
                textAlign: TextAlign.center,
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
                'These cryptographic codes can be used to access your account if you lose your MFA device. Store them in a secure password manager.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontBody,
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppTheme.space24),

              Expanded(
                child: ElevatedActionCard(
                  padding: const EdgeInsets.all(AppTheme.space20),
                  child: RepaintBoundary(
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.4,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _codes.length,
                      itemBuilder: (context, index) {
                        return Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            border: Border.all(
                              color: const Color(0x38FFFFFF),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _codes[index],
                            style: const TextStyle(
                              fontFamily: AppTheme.fontMono,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.goldLight,
                              letterSpacing: 0.8,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space24),

              TactilePressWrapper(
                onTap: _copyCodes,
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _isCopied ? const Color(0x6610B981) : const Color(0x73D4AF37),
                      width: 1.2,
                    ),
                    boxShadow: const [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isCopied ? Icons.check : Icons.copy_rounded,
                        size: 18,
                        color: _isCopied ? AppTheme.success : AppTheme.goldPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isCopied ? 'CODES COPIED' : 'COPY ALL CODES',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 0.8,
                          color: _isCopied ? AppTheme.success : AppTheme.goldPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space12),

              TactilePressWrapper(
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.go('/home');
                },
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x38FFFFFF)),
                  ),
                  child: const Text(
                    'Continue to Dashboard',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
        ],
      ),
    );
  }
}
