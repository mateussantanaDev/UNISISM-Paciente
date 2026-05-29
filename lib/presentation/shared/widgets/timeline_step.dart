import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Item de timeline vertical.
/// Bolinha colorida por tipo + linha vertical + mini-painel.
class TimelineStep extends StatelessWidget {
  const TimelineStep({
    super.key,
    required this.tipo,
    required this.titulo,
    this.descricao,
    this.autor,
    this.autorPapel,
    this.em,
    this.isLast = false,
  });

  final TimelineTipo tipo;
  final String titulo;
  final String? descricao;
  final String? autor;
  final String? autorPapel;
  final DateTime? em;
  final bool isLast;

  ({Color bg, Color border, IconData icon}) _palette() {
    switch (tipo) {
      case TimelineTipo.criacao:
        return (bg: AppColors.blue50, border: AppColors.blue900, icon: Icons.flag_outlined);
      case TimelineTipo.anexo:
        return (bg: AppColors.slate100, border: AppColors.slate600, icon: Icons.attach_file);
      case TimelineTipo.pendencia:
        return (bg: AppColors.amber50, border: AppColors.amber600, icon: Icons.warning_amber);
      case TimelineTipo.aprovacao:
        return (bg: AppColors.emerald50, border: AppColors.emerald700, icon: Icons.check_circle);
      case TimelineTipo.agendamento:
        return (bg: AppColors.emerald50, border: AppColors.emerald700, icon: Icons.event_available);
      case TimelineTipo.rejeicao:
        return (bg: AppColors.red50, border: AppColors.red700, icon: Icons.cancel);
      case TimelineTipo.atualizacao:
        return (bg: AppColors.blue50, border: AppColors.blue700, icon: Icons.refresh);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette();
    final formatador = DateFormat('dd/MM/yyyy \'às\' HH:mm', 'pt_BR');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: p.bg,
                  border: Border.all(color: p.border, width: 2),
                ),
                child: Icon(p.icon, size: 18, color: p.border),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: AppColors.slate200),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border.all(color: AppColors.slate200, width: 1),
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(titulo, style: AppTypography.titleMedium),
                    if (descricao != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(descricao!, style: AppTypography.bodyMedium),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        if (em != null)
                          Text(
                            formatador.format(em!),
                            style: AppTypography.bodySmall.copyWith(
                              fontFamily: AppTypography.mono,
                              fontSize: 12,
                            ),
                          ),
                        if (autor != null) ...[
                          if (em != null)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                              child: Text('·', style: TextStyle(color: AppColors.slate400)),
                            ),
                          Flexible(
                            child: Text(
                              autorPapel != null ? '$autor ($autorPapel)' : autor!,
                              style: AppTypography.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum TimelineTipo {
  criacao,
  anexo,
  pendencia,
  aprovacao,
  agendamento,
  rejeicao,
  atualizacao,
}
