import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Bloco informativo com borda lateral (4dp) — equivalente ao `border-l-4` do DS.
/// 4 tons semânticos.
class InfoBlock extends StatelessWidget {
  const InfoBlock({
    super.key,
    required this.message,
    this.title,
    this.tone = InfoTone.info,
    this.icon,
    this.action,
  });

  final String message;
  final String? title;
  final InfoTone tone;
  final IconData? icon;
  final Widget? action;

  ({Color bg, Color border, Color fg, Color titleFg, IconData? defaultIcon}) _palette() {
    switch (tone) {
      case InfoTone.success:
        return (
          bg: AppColors.emerald50,
          border: AppColors.emerald700,
          fg: AppColors.emerald900,
          titleFg: AppColors.emerald800,
          defaultIcon: Icons.check_circle_outline,
        );
      case InfoTone.warning:
        return (
          bg: AppColors.amber50,
          border: AppColors.amber600,
          fg: AppColors.amber900,
          titleFg: AppColors.amber800,
          defaultIcon: Icons.warning_amber_outlined,
        );
      case InfoTone.critical:
        return (
          bg: AppColors.red50,
          border: AppColors.red700,
          fg: AppColors.red900,
          titleFg: AppColors.red800,
          defaultIcon: Icons.error_outline,
        );
      case InfoTone.info:
        return (
          bg: AppColors.blue50,
          border: AppColors.blue900,
          fg: AppColors.slate900,
          titleFg: AppColors.blue900,
          defaultIcon: Icons.info_outline,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette();
    final iconData = icon ?? p.defaultIcon;
    return Container(
      decoration: BoxDecoration(
        color: p.bg,
        border: Border(
          left: BorderSide(color: p.border, width: AppBorders.thick),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (iconData != null) ...[
            Icon(iconData, size: 22, color: p.border),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: AppTypography.titleMedium.copyWith(color: p.titleFg),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  message,
                  style: AppTypography.bodyMedium.copyWith(color: p.fg),
                ),
                if (action != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  action!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum InfoTone { success, warning, critical, info }
