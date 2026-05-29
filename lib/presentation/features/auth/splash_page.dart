import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_controller.dart';
import '../onboarding/onboarding_page.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _maybeOnboarding() async {
    final viu = await onboardingJaVisto();
    if (!mounted) return;
    if (viu) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (_, next) {
      if (next.status == AuthStatus.authenticated) {
        _maybeOnboarding();
      } else if (next.status == AuthStatus.unauthenticated) {
        context.go('/login');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.blue900,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, child) {
                final scale = 0.96 + 0.06 * _pulse.value;
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: 104,
                height: 104,
                decoration: const BoxDecoration(color: AppColors.white),
                alignment: Alignment.center,
                child: const Text(
                  'U',
                  style: TextStyle(
                    fontFamily: AppTypography.mono,
                    fontSize: 60,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue900,
                    height: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'UNISISM',
              style: TextStyle(
                fontFamily: AppTypography.mono,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'PACIENTE',
              style: TextStyle(
                fontFamily: AppTypography.mono,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF93C5FD),
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: AppSpacing.huge),
            FadeTransition(
              opacity: _pulse,
              child: const Text(
                'Carregando seus dados...',
                style: TextStyle(
                  fontFamily: AppTypography.sans,
                  fontSize: 14,
                  color: Color(0xFF93C5FD),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
