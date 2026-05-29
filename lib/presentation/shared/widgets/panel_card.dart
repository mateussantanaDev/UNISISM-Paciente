import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Painel padrão — equivalente ao `<PanelHeader>` + body do DS UBS.
///
/// Para paciente, mantém a moldura institucional (borda fina `slate-200`,
/// header com gradiente sutil from-white to-slate-50, índice numerado opcional)
/// mas com tipografia **maior** e espaçamento generoso.
class PanelCard extends StatelessWidget {
  const PanelCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.index,
    this.trailing,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.accent,
  });

  final Widget child;
  final String? title;
  final String? subtitle;

  /// Marcador numerado opcional (ex: "01"). Renderiza chip azul.
  final String? index;

  /// Widget no canto direito do header (badge, ação).
  final Widget? trailing;

  /// Padding do conteúdo.
  final EdgeInsetsGeometry padding;

  /// Barra lateral de acento — usado pra destacar (`critical`, `warning`...).
  final PanelAccent? accent;

  Color get _accentColor {
    switch (accent) {
      case PanelAccent.critical:
        return AppColors.red700;
      case PanelAccent.warning:
        return AppColors.amber600;
      case PanelAccent.success:
        return AppColors.emerald700;
      case PanelAccent.info:
        return AppColors.blue900;
      case null:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasHeader = title != null || index != null || trailing != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.slate200, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (accent != null)
            Container(
              width: 4,
              decoration: BoxDecoration(color: _accentColor),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasHeader) _Header(
                  title: title,
                  subtitle: subtitle,
                  index: index,
                  trailing: trailing,
                ),
                Padding(padding: padding, child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum PanelAccent { critical, warning, success, info }

class _Header extends StatelessWidget {
  const _Header({this.title, this.subtitle, this.index, this.trailing});

  final String? title;
  final String? subtitle;
  final String? index;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.panelHeaderGradient,
        border: Border(
          bottom: BorderSide(color: AppColors.slate200, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (index != null) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(color: AppColors.blue900),
              alignment: Alignment.center,
              child: Text(
                index!,
                style: AppTypography.badge.copyWith(
                  color: AppColors.white,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Text(title!, style: AppTypography.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppTypography.bodySmall),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
    );
  }
}
