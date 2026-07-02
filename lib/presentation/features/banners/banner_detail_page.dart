import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/banner.dart';
import '../../../providers/banner_controller.dart';
import '../../shared/widgets/widgets.dart';

class BannerDetailPage extends ConsumerWidget {
  const BannerDetailPage({super.key, required this.id});
  final String id;

  ({Color bg, Color border, Color fg, IconData icon, String tag}) _palette(
      String tone) {
    switch (tone) {
      case 'URGENTE':
        return (
          bg: AppColors.red50,
          border: AppColors.red700,
          fg: AppColors.red900,
          icon: Icons.warning_amber_rounded,
          tag: 'ALERTA',
        );
      case 'CAMPANHA':
        return (
          bg: AppColors.emerald50,
          border: AppColors.emerald700,
          fg: AppColors.emerald900,
          icon: Icons.campaign_outlined,
          tag: 'CAMPANHA',
        );
      case 'ATENCAO':
        return (
          bg: AppColors.amber50,
          border: AppColors.amber600,
          fg: AppColors.amber900,
          icon: Icons.notification_important_outlined,
          tag: 'ATENÇÃO',
        );
      default:
        return (
          bg: AppColors.blue50,
          border: AppColors.blue900,
          fg: AppColors.slate900,
          icon: Icons.info_outline,
          tag: 'INFORMATIVO',
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(bannersAtivosProvider);
    final fmt = DateFormat("dd 'de' MMMM 'de' yyyy", 'pt_BR');

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Comunicado'),
      ),
      body: bannersAsync.when(
        loading: () => const LoadingView(),
        error: (_, __) => const EmptyView(
          icon: Icons.campaign_outlined,
          title: 'Aviso não disponível',
          message: 'Este comunicado pode ter sido removido pela Secretaria.',
        ),
        data: (banners) {
          final b = banners
              .cast<SmsBannerModel?>()
              .firstWhere((x) => x?.id == id, orElse: () => null);
          if (b == null) {
            return EmptyView(
              icon: Icons.campaign_outlined,
              title: 'Comunicado não disponível',
              message: 'Esse aviso pode ter sido encerrado.',
            );
          }
          final p = _palette(b.tone);
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              if (b.imagemUrl != null)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: b.imagemUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.slate100),
                    errorWidget: (_, __, ___) => Container(
                      color: p.bg,
                      alignment: Alignment.center,
                      child: Icon(p.icon, size: 64, color: p.border),
                    ),
                  ),
                )
              else
                Container(height: 4, color: p.border),

              Container(
                color: p.bg,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(p.icon, size: 20, color: p.border),
                    const SizedBox(width: AppSpacing.xs),
                    Text(p.tag,
                        style: AppTypography.labelInstitucional
                            .copyWith(color: p.border)),
                    const Spacer(),
                    Text(
                      'PUBLICADO EM ${fmt.format(b.publicadoEm).toUpperCase()}',
                      style: AppTypography.labelInstitucional,
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.titulo, style: AppTypography.displayMedium),
                    const SizedBox(height: AppSpacing.lg),
                    Text(b.corpo,
                        style: AppTypography.bodyLarge.copyWith(height: 1.6)),

                    if (b.expiraEm != null) ...[
                      const SizedBox(height: AppSpacing.xl),
                      InfoBlock(
                        message:
                            'Este aviso fica disponível até ${fmt.format(b.expiraEm!)}.',
                        tone: InfoTone.info,
                        icon: Icons.schedule,
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),
                    if (b.ctaUrl != null && b.ctaLabel != null)
                      PrimaryButton(
                        label: b.ctaLabel!,
                        icon: Icons.open_in_new,
                        onPressed: () async {
                          final uri = Uri.tryParse(b.ctaUrl!);
                          if (uri != null && await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    const SizedBox(height: AppSpacing.huge),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
