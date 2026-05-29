import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';

const _kOnboardingDone = 'unisism.onboarding.done';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _ctrl = PageController();
  int _i = 0;

  static const _pages = [
    _OnbStep(
      icon: Icons.medical_information,
      titulo: 'Acompanhe seu encaminhamento',
      descricao:
          'Veja onde está seu pedido médico em tempo real: aguardando análise, aprovado, marcado.',
      cor: AppColors.blue900,
    ),
    _OnbStep(
      icon: Icons.directions_bus_filled,
      titulo: 'Peça transporte (TFD)',
      descricao:
          'Sem precisar ir até a UBS, você pode pedir uma vaga nas viagens do município.',
      cor: AppColors.emerald700,
    ),
    _OnbStep(
      icon: Icons.notifications_active,
      titulo: 'Receba avisos importantes',
      descricao:
          'Te avisamos no celular quando algo mudar — agendamento, lembrete, alerta da Secretaria.',
      cor: AppColors.amber600,
    ),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _terminar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingDone, true);
    if (!mounted) return;
    context.go('/home');
  }

  void _proxima() {
    if (_i < _pages.length - 1) {
      _ctrl.nextPage(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOutCubic);
    } else {
      _terminar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ultimo = _i == _pages.length - 1;
    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: Row(
                children: [
                  const _Brand(),
                  const Spacer(),
                  if (!ultimo)
                    TextButton(
                      onPressed: _terminar,
                      child: const Text('Pular'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _i = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _pages[i],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = _i == i;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 28 : 10,
                        height: 6,
                        color: active ? AppColors.blue900 : AppColors.slate300,
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: ultimo ? 'Começar a usar' : 'Continuar',
                    icon: ultimo ? Icons.check : Icons.arrow_forward,
                    onPressed: _proxima,
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

class _OnbStep extends StatelessWidget {
  const _OnbStep({
    required this.icon,
    required this.titulo,
    required this.descricao,
    required this.cor,
  });

  final IconData icon;
  final String titulo;
  final String descricao;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            tween: Tween(begin: 0.85, end: 1),
            builder: (_, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              width: 160,
              height: 160,
              color: cor,
              alignment: Alignment.center,
              child: Icon(icon, size: 88, color: AppColors.white),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(titulo,
              style: AppTypography.displayMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          Text(descricao,
              style: AppTypography.bodyLarge.copyWith(color: AppColors.slate700),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          color: AppColors.blue900,
          alignment: Alignment.center,
          child: const Text(
            'U',
            style: TextStyle(
              fontFamily: AppTypography.mono,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Text(
          'UNISISM',
          style: TextStyle(
            fontFamily: AppTypography.mono,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.blue900,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }
}

/// Lê do shared_preferences se o onboarding já foi mostrado.
Future<bool> onboardingJaVisto() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingDone) ?? false;
}
