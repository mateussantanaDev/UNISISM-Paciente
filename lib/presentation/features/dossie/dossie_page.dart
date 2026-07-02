import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_controller.dart';
import '../../../providers/dossie_controller.dart';
import '../../shared/widgets/widgets.dart';

class DossiePage extends ConsumerWidget {
  const DossiePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paciente = ref.watch(authControllerProvider).paciente;
    final resumoAsync = ref.watch(dossieResumoProvider);

    return AppScaffold(
      appBar: AppBar(title: const Text('Minha saúde'), automaticallyImplyLeading: false),
      refresh: () async {
        ref.invalidate(dossieResumoProvider);
        await Future.delayed(const Duration(milliseconds: 400));
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (paciente != null) _CartaoIdentidade(paciente: paciente),
          const SizedBox(height: AppSpacing.xl),

          resumoAsync.when(
            loading: () => const LoadingView(),
            error: (_, __) => const EmptyView(
              icon: Icons.health_and_safety_outlined,
              title: 'Seu histórico está sendo preparado',
              message:
                  'Assim que sua UBS registrar atendimentos, vacinas e exames, eles aparecem aqui.',
            ),
            data: (r) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(label: 'Visão geral'),
                // Grid 2x2 — evita overflow da label "ENCAMINHAMENTOS" em
                // telas estreitas. Tipo sanguíneo entra como 4ª célula.
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.5,
                  children: [
                    _Metric(
                      label: 'Consultas',
                      valor: '${r.totalAtendimentos}',
                      icon: Icons.event_note,
                    ),
                    _Metric(
                      label: 'Vacinas',
                      valor: '${r.totalVacinas}',
                      icon: Icons.vaccines,
                    ),
                    _Metric(
                      label: 'Pedidos médicos',
                      valor: '${r.totalEncaminhamentos}',
                      icon: Icons.send_outlined,
                    ),
                    if (r.tipoSanguineo != null)
                      _Metric(
                        label: 'Tipo sangue',
                        valor: r.tipoSanguineo!,
                        icon: Icons.water_drop_outlined,
                        iconColor: AppColors.red700,
                        mono: true,
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                if (r.alergias.isNotEmpty) ...[
                  InfoBlock(
                    title: 'Suas alergias',
                    message: r.alergias.join(' · '),
                    tone: InfoTone.critical,
                    icon: Icons.dangerous_outlined,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (r.condicoesCronicas.isNotEmpty) ...[
                  InfoBlock(
                    title: 'Condições contínuas',
                    message: r.condicoesCronicas.join(' · '),
                    tone: InfoTone.warning,
                    icon: Icons.favorite_outlined,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (r.medicamentosUsoContinuo.isNotEmpty) ...[
                  InfoBlock(
                    title: 'Remédios de uso contínuo',
                    message: r.medicamentosUsoContinuo.join(' · '),
                    tone: InfoTone.info,
                    icon: Icons.medication_outlined,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
          SectionHeader(label: 'Histórico detalhado'),
          IconCard(
            icon: Icons.event_note,
            title: 'Atendimentos',
            subtitle: 'Consultas, emergências e retornos',
            iconBg: AppColors.blue900,
            onTap: () => context.push('/dossie/atendimentos'),
          ),
          const SizedBox(height: AppSpacing.md),
          IconCard(
            icon: Icons.vaccines,
            title: 'Vacinas',
            subtitle: 'Suas vacinas e datas de aplicação',
            iconBg: AppColors.emerald700,
            onTap: () => context.push('/dossie/vacinacoes'),
          ),
          const SizedBox(height: AppSpacing.md),
          IconCard(
            icon: Icons.biotech_outlined,
            title: 'Exames',
            subtitle: 'Resultados de exames realizados',
            iconBg: AppColors.amber600,
            onTap: () => context.push('/dossie/exames'),
          ),

          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.valor,
    required this.icon,
    this.iconColor,
    this.mono = false,
  });
  final String label;
  final String valor;
  final IconData icon;
  final Color? iconColor;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.slate200, width: 1),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 22, color: iconColor ?? AppColors.blue900),
          Text(
            valor,
            style: AppTypography.metric.copyWith(
              fontSize: mono ? 26 : 30,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label.toUpperCase(),
            style: AppTypography.labelInstitucional.copyWith(letterSpacing: 1.2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CartaoIdentidade extends StatelessWidget {
  const _CartaoIdentidade({required this.paciente});
  final dynamic paciente;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.slate900,
        border: Border.all(color: AppColors.slate900, width: 2),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                color: AppColors.blue900,
                alignment: Alignment.center,
                child: Text(
                  paciente.iniciais,
                  style: AppTypography.headlineMedium.copyWith(color: AppColors.white),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CIDADÃO',
                      style: AppTypography.labelInstitucional.copyWith(color: const Color(0xFF93C5FD)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      paciente.nome,
                      style: AppTypography.titleLarge.copyWith(color: AppColors.white),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(height: 1, color: const Color(0xFF334155)),
          const SizedBox(height: AppSpacing.md),
          // CPF e Cartão SUS empilhados — evita overflow lateral
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CPF',
                style: AppTypography.labelInstitucional
                    .copyWith(color: const Color(0xFF94A3B8)),
              ),
              Text(
                paciente.cpf,
                style: AppTypography.data
                    .copyWith(color: AppColors.white, fontSize: 15),
              ),
              if (paciente.cartaoSus != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CARTÃO SUS',
                            style: AppTypography.labelInstitucional
                                .copyWith(color: const Color(0xFF94A3B8)),
                          ),
                          Text(
                            paciente.cartaoSus,
                            style: AppTypography.data.copyWith(
                                color: AppColors.white, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
