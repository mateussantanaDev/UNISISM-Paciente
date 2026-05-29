import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Banner da Secretaria de Saúde — campanha de vacinação, alerta de surto, etc.
///
/// Versão grande (carrossel) e compacta (notificação inline).
class SmsBanner extends StatelessWidget {
  const SmsBanner({
    super.key,
    required this.titulo,
    required this.corpo,
    this.imagemUrl,
    this.tone = SmsBannerTone.info,
    this.ctaLabel,
    this.onCta,
    this.expandido = false,
  });

  final String titulo;
  final String corpo;
  final String? imagemUrl;
  final SmsBannerTone tone;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final bool expandido;

  ({Color border, Color bg, Color fg, IconData icon, String tag}) _palette() {
    switch (tone) {
      case SmsBannerTone.urgente:
        return (
          border: AppColors.red700,
          bg: AppColors.red50,
          fg: AppColors.red900,
          icon: Icons.warning_amber_rounded,
          tag: 'ALERTA',
        );
      case SmsBannerTone.campanha:
        return (
          border: AppColors.emerald700,
          bg: AppColors.emerald50,
          fg: AppColors.emerald900,
          icon: Icons.campaign_outlined,
          tag: 'CAMPANHA',
        );
      case SmsBannerTone.info:
        return (
          border: AppColors.blue900,
          bg: AppColors.blue50,
          fg: AppColors.slate900,
          icon: Icons.info_outline,
          tag: 'INFORMATIVO',
        );
      case SmsBannerTone.atencao:
        return (
          border: AppColors.amber600,
          bg: AppColors.amber50,
          fg: AppColors.amber900,
          icon: Icons.notification_important_outlined,
          tag: 'ATENÇÃO',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: p.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imagemUrl != null)
            AspectRatio(
              aspectRatio: expandido ? 16 / 9 : 21 / 9,
              child: CachedNetworkImage(
                imageUrl: imagemUrl!,
                fit: BoxFit.cover,
                placeholder: (c, _) => Container(
                  color: AppColors.slate100,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.slate400,
                    ),
                  ),
                ),
                errorWidget: (c, _, __) => Container(
                  color: p.bg,
                  alignment: Alignment.center,
                  child: Icon(p.icon, size: 48, color: p.border),
                ),
              ),
            )
          else
            Container(
              height: 4,
              color: p.border,
            ),
          Container(
            color: p.bg,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(p.icon, size: 18, color: p.border),
                const SizedBox(width: AppSpacing.xs),
                Text(p.tag, style: AppTypography.labelInstitucional.copyWith(color: p.border)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(titulo, style: AppTypography.headlineMedium.copyWith(color: p.fg)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  corpo,
                  style: AppTypography.bodyMedium.copyWith(color: p.fg),
                  maxLines: expandido ? null : 3,
                  overflow: expandido ? null : TextOverflow.ellipsis,
                ),
                if (ctaLabel != null && onCta != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Material(
                    color: p.border,
                    child: InkWell(
                      onTap: onCta,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ctaLabel!,
                              style: AppTypography.button.copyWith(color: AppColors.white),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            const Icon(Icons.arrow_forward, size: 18, color: AppColors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum SmsBannerTone { urgente, campanha, info, atencao }
