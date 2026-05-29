import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Botão principal — 3 variantes (primary, secondary, danger).
/// Altura 60dp pra touch confortável, NÃO uppercase (vs DS UBS).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = PrimaryButtonVariant.primary,
    this.loading = false,
    this.icon,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final PrimaryButtonVariant variant;
  final bool loading;
  final IconData? icon;
  final bool expanded;

  bool get _disabled => onPressed == null || loading;

  ({Color bg, Color fg, Color border}) _palette() {
    if (_disabled) {
      return (
        bg: AppColors.slate100,
        fg: AppColors.slate400,
        border: AppColors.slate200,
      );
    }
    switch (variant) {
      case PrimaryButtonVariant.primary:
        return (bg: AppColors.blue900, fg: AppColors.white, border: AppColors.blue900);
      case PrimaryButtonVariant.secondary:
        return (bg: AppColors.white, fg: AppColors.slate900, border: AppColors.slate300);
      case PrimaryButtonVariant.danger:
        return (bg: AppColors.red700, fg: AppColors.white, border: AppColors.red700);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette();
    final button = Material(
      color: p.bg,
      child: InkWell(
        onTap: _disabled ? null : onPressed,
        splashColor: variant == PrimaryButtonVariant.primary
            ? AppColors.blue950.withValues(alpha: 0.3)
            : AppColors.slate100,
        highlightColor: variant == PrimaryButtonVariant.primary
            ? AppColors.blue950.withValues(alpha: 0.2)
            : AppColors.slate100,
        child: Container(
          height: AppSpacing.buttonHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          decoration: BoxDecoration(border: Border.all(color: p.border, width: 1)),
          alignment: Alignment.center,
          child: loading
              ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(p.fg),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 22, color: p.fg),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: AppTypography.button.copyWith(color: p.fg),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );

    return expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

enum PrimaryButtonVariant { primary, secondary, danger }
