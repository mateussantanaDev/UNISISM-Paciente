import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'status_badge.dart';

/// Card hero do encaminhamento ativo.
///
/// Layout: header colorido com **especialidade em destaque** (porque o paciente
/// pode ter vários ativos), seguido de mensagem + protocolo + data + CTA.
class StatusHeroCard extends StatelessWidget {
  const StatusHeroCard({
    super.key,
    required this.statusKey,
    required this.statusLabel,
    required this.mensagem,
    required this.protocolo,
    required this.especialidade,
    this.dataConsulta,
    this.localConsulta,
    this.prioridade,
    this.onTap,
    this.ctaLabel,
  });

  final String statusKey;
  final String statusLabel;
  final String mensagem;
  final String protocolo;
  final String especialidade;
  final DateTime? dataConsulta;
  final String? localConsulta;
  final String? prioridade;
  final VoidCallback? onTap;
  final String? ctaLabel;

  ({Color bg, Color border, Color fg, Color labelFg, IconData icon}) _palette() {
    switch (statusKey.toUpperCase()) {
      case 'AGUARDANDO_REGULACAO':
      case 'EM_ANALISE':
        return (
          bg: AppColors.amber50,
          border: AppColors.amber600,
          fg: AppColors.amber900,
          labelFg: AppColors.amber800,
          icon: Icons.hourglass_top,
        );
      case 'PENDENCIA_DOCUMENTO':
        return (
          bg: AppColors.amber50,
          border: AppColors.amber600,
          fg: AppColors.amber900,
          labelFg: AppColors.amber800,
          icon: Icons.warning_amber_rounded,
        );
      case 'AGUARDANDO_AGENDAMENTO':
        return (
          bg: AppColors.blue50,
          border: AppColors.blue900,
          fg: AppColors.slate900,
          labelFg: AppColors.blue900,
          icon: Icons.event_available,
        );
      case 'AGENDADO':
      case 'APROVADO':
        return (
          bg: AppColors.emerald50,
          border: AppColors.emerald700,
          fg: AppColors.emerald900,
          labelFg: AppColors.emerald800,
          icon: Icons.event,
        );
      case 'REJEITADO':
      case 'CANCELADO':
        return (
          bg: AppColors.red50,
          border: AppColors.red700,
          fg: AppColors.red900,
          labelFg: AppColors.red800,
          icon: Icons.cancel_outlined,
        );
      case 'CONCLUIDO':
        return (
          bg: AppColors.slate50,
          border: AppColors.slate600,
          fg: AppColors.slate900,
          labelFg: AppColors.slate700,
          icon: Icons.task_alt,
        );
      default:
        return (
          bg: AppColors.slate50,
          border: AppColors.slate400,
          fg: AppColors.slate900,
          labelFg: AppColors.slate600,
          icon: Icons.info_outline,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette();
    final fmt = DateFormat("EEEE, dd/MM 'às' HH:mm", 'pt_BR');

    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: p.border, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // -------- Header com especialidade em DESTAQUE --------
              Container(
                color: p.bg,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(color: p.border),
                      alignment: Alignment.center,
                      child: Icon(p.icon, color: AppColors.white, size: 32),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ENCAMINHAMENTO',
                            style: AppTypography.labelInstitucional
                                .copyWith(color: p.labelFg, fontSize: 10),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            especialidade,
                            style: AppTypography.displayMedium.copyWith(
                              color: p.fg,
                              fontSize: 22,
                              height: 1.15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // -------- Body --------
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status badge + prioridade
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        StatusBadge.fromStatus(statusKey,
                            size: StatusBadgeSize.medium),
                        if (prioridade != null &&
                            prioridade!.toUpperCase() != 'ELETIVA' &&
                            prioridade!.toUpperCase() != 'NORMAL')
                          StatusBadge.fromPrioridade(prioridade!,
                              size: StatusBadgeSize.medium),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Mensagem de status
                    Text(mensagem, style: AppTypography.bodyLarge),

                    // Data e local agendados — destaque
                    if (dataConsulta != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.emerald50,
                          border: Border.all(
                              color: AppColors.emerald700, width: 1),
                        ),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    color: AppColors.emerald700, size: 18),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    fmt.format(dataConsulta!),
                                    style: AppTypography.titleMedium.copyWith(
                                      color: AppColors.emerald900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (localConsulta != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Text(
                                      localConsulta!,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.emerald900,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.md),

                    // Protocolo
                    Row(
                      children: [
                        const Icon(Icons.tag, size: 16, color: AppColors.slate500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            protocolo,
                            style: AppTypography.protocolo.copyWith(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // CTA
                    if (ctaLabel != null && onTap != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        decoration: const BoxDecoration(color: AppColors.blue900),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(ctaLabel!, style: AppTypography.button),
                            const SizedBox(width: AppSpacing.sm),
                            const Icon(Icons.arrow_forward,
                                color: AppColors.white, size: 20),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
