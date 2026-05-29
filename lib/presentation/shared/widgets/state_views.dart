import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'primary_button.dart';

/// Loading com spinner brutalista (border 3px, blue-900).
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label = 'Carregando...'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(AppColors.blue900),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(label, style: AppTypography.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Vazio amigável com ícone grande e CTA opcional.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(color: AppColors.slate100),
              child: Icon(icon, size: 48, color: AppColors.slate500),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              style: AppTypography.headlineMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: PrimaryButtonVariant.primary,
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Caixa de erro com borda dupla vermelha.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.title,
    this.message,
    this.onRetry,
    this.retryLabel = 'Tentar de novo',
  });

  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.red50,
            border: Border.all(color: AppColors.red700, width: AppBorders.medium),
          ),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.red700),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: AppTypography.titleLarge.copyWith(color: AppColors.red900),
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message!,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.red800),
                  textAlign: TextAlign.center,
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: retryLabel,
                  onPressed: onRetry,
                  variant: PrimaryButtonVariant.secondary,
                  expanded: false,
                  icon: Icons.refresh,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
