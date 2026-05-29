import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Divisor de seção — label uppercase com tracking, em mono.
/// Mantém a assinatura institucional sem comprometer legibilidade
/// (label fica num bloco visualmente separado, não dentro do conteúdo).
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.label,
    this.trailing,
    this.icon,
  });

  final String label;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, AppSpacing.sm),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.slate500),
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: AppTypography.labelInstitucional,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
