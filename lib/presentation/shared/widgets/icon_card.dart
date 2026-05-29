import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Card de navegação grande — elemento PRINCIPAL pra paciente.
///
/// Ícone grande (40dp) + título legível + subtítulo + chevron.
/// Touch target generoso (min 72dp). É o que substitui o menu mono compacto
/// do DS UBS.
class IconCard extends StatelessWidget {
  const IconCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.accent,
    this.iconColor,
    this.iconBg,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Barra lateral de cor (3px).
  final IconCardAccent? accent;

  /// Override de cor do ícone (default: branco sobre fundo blue-900).
  final Color? iconColor;

  /// Override de fundo do ícone (default: blue-900).
  final Color? iconBg;

  /// Badge no canto direito (notificação, contador).
  final Widget? badge;

  Color get _accentColor {
    switch (accent) {
      case IconCardAccent.success:
        return AppColors.emerald700;
      case IconCardAccent.warning:
        return AppColors.amber600;
      case IconCardAccent.critical:
        return AppColors.red700;
      case IconCardAccent.info:
        return AppColors.blue900;
      case null:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconBgColor = iconBg ?? AppColors.blue900;
    final iconFg = iconColor ?? AppColors.white;

    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.slate100,
        highlightColor: AppColors.slate50,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.slate200, width: 1),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                if (accent != null)
                  Container(width: 4, color: _accentColor),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: iconBgColor),
                    child: Icon(icon, size: 30, color: iconFg),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                      horizontal: 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: AppTypography.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: AppTypography.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (badge != null) ...[
                        badge!,
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      if (trailing != null)
                        trailing!
                      else
                        const Icon(
                          Icons.chevron_right,
                          size: 28,
                          color: AppColors.slate400,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum IconCardAccent { success, warning, critical, info }

/// Contador pequeno em badge (ex: notificações não lidas).
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count, this.tone = StatusTone2.critical});

  final int count;
  final StatusTone2 tone;

  Color get _bg => switch (tone) {
        StatusTone2.critical => AppColors.red700,
        StatusTone2.warning => AppColors.amber600,
        StatusTone2.info => AppColors.blue900,
      };

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: _bg),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: AppTypography.badge.copyWith(
          color: AppColors.white,
          fontSize: 13,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

enum StatusTone2 { critical, warning, info }
