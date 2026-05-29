import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Badge de status — quadrado, borda fina, fonte mono uppercase.
/// Mantém a assinatura do DS UBS (única exceção ao "sem uppercase").
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
    this.size = StatusBadgeSize.medium,
  });

  /// Badge a partir de chave de status do backend.
  factory StatusBadge.fromStatus(String status, {StatusBadgeSize size = StatusBadgeSize.medium}) {
    final mapped = _statusMap[status.toUpperCase()] ??
        (label: status, tone: StatusTone.neutral, icon: null);
    return StatusBadge(
      label: mapped.label,
      tone: mapped.tone,
      icon: mapped.icon,
      size: size,
    );
  }

  /// Badge a partir de chave de prioridade.
  factory StatusBadge.fromPrioridade(String prioridade, {StatusBadgeSize size = StatusBadgeSize.medium}) {
    final mapped = _prioridadeMap[prioridade.toUpperCase()] ??
        (label: prioridade, tone: StatusTone.neutral, icon: null);
    return StatusBadge(
      label: mapped.label,
      tone: mapped.tone,
      icon: mapped.icon,
      size: size,
    );
  }

  final String label;
  final StatusTone tone;
  final IconData? icon;
  final StatusBadgeSize size;

  ({Color bg, Color fg, Color border}) _palette() {
    switch (tone) {
      case StatusTone.success:
        return (bg: AppColors.emerald50, fg: AppColors.emerald800, border: AppColors.emerald700);
      case StatusTone.warning:
        return (bg: AppColors.amber50, fg: AppColors.amber800, border: AppColors.amber600);
      case StatusTone.critical:
        return (bg: AppColors.red50, fg: AppColors.red800, border: AppColors.red700);
      case StatusTone.info:
        return (bg: AppColors.blue50, fg: AppColors.blue900, border: AppColors.blue700);
      case StatusTone.neutral:
        return (bg: AppColors.slate50, fg: AppColors.slate700, border: AppColors.slate600);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette();
    final isLarge = size == StatusBadgeSize.large;
    final fontSize = isLarge ? 13.0 : 11.0;
    final iconSize = isLarge ? 16.0 : 13.0;
    final hPad = isLarge ? AppSpacing.md : AppSpacing.sm;
    final vPad = isLarge ? AppSpacing.sm : AppSpacing.xs;

    return Container(
      decoration: BoxDecoration(
        color: p.bg,
        border: Border.all(color: p.border, width: 1),
      ),
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: p.fg),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label.toUpperCase(),
            style: AppTypography.badge.copyWith(color: p.fg, fontSize: fontSize),
          ),
        ],
      ),
    );
  }
}

enum StatusTone { success, warning, critical, info, neutral }

enum StatusBadgeSize { small, medium, large }

/// Mapeamento canônico de status do backend → display.
/// Mesma fonte de verdade que o DS UBS, alinhar com BACKEND_API.md.
const Map<String, ({String label, StatusTone tone, IconData? icon})> _statusMap = {
  'RASCUNHO': (label: 'Rascunho', tone: StatusTone.neutral, icon: Icons.edit_note),
  'AGUARDANDO_REGULACAO': (
    label: 'Aguardando Regulação',
    tone: StatusTone.warning,
    icon: Icons.hourglass_bottom,
  ),
  'PENDENCIA_DOCUMENTO': (
    label: 'Pendência de Documento',
    tone: StatusTone.warning,
    icon: Icons.warning_amber_rounded,
  ),
  'EM_ANALISE': (label: 'Em Análise', tone: StatusTone.info, icon: Icons.search),
  'AGUARDANDO_AGENDAMENTO': (
    label: 'Aguardando Agendamento',
    tone: StatusTone.info,
    icon: Icons.event_available,
  ),
  'AGENDADO': (label: 'Agendado', tone: StatusTone.success, icon: Icons.event),
  'APROVADO': (label: 'Aprovado', tone: StatusTone.success, icon: Icons.check_circle),
  'REJEITADO': (label: 'Rejeitado', tone: StatusTone.critical, icon: Icons.cancel),
  'CANCELADO': (label: 'Cancelado', tone: StatusTone.critical, icon: Icons.block),
  'CONCLUIDO': (label: 'Concluído', tone: StatusTone.success, icon: Icons.task_alt),
};

const Map<String, ({String label, StatusTone tone, IconData? icon})> _prioridadeMap = {
  'ELETIVA': (label: 'Eletiva', tone: StatusTone.neutral, icon: null),
  'PRIORITARIA': (label: 'Prioritária', tone: StatusTone.warning, icon: null),
  'URGENTE': (label: 'Urgente', tone: StatusTone.critical, icon: null),
  'EMERGENCIA': (label: 'Emergência', tone: StatusTone.critical, icon: null),
};
