import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/providers.dart';
import '../../shared/widgets/widgets.dart';

class FalarComUbsPage extends ConsumerWidget {
  const FalarComUbsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(minhaUbsProvider);

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Falar com a UBS'),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (_, __) => const EmptyView(
          icon: Icons.phone_disabled_outlined,
          title: 'Contatos não disponíveis',
          message:
              'Procure presencialmente sua UBS — os contatos online ainda não foram cadastrados.',
        ),
        data: (u) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            InfoBlock(
              title: u.nome,
              message: u.horarioFuncionamento,
              tone: InfoTone.info,
              icon: Icons.home_work_outlined,
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(label: 'Escolha como falar'),

            if (u.telefone != null && u.telefone!.isNotEmpty)
              _Canal(
                icon: Icons.call,
                iconBg: AppColors.emerald700,
                titulo: 'Ligar agora',
                descricao: u.telefone!,
                cta: 'Iniciar ligação',
                onTap: () async {
                  final uri = Uri.parse(
                      'tel:${u.telefone!.replaceAll(RegExp(r"\D"), "")}');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
              ),
            const SizedBox(height: AppSpacing.md),

            if (u.whatsapp != null) ...[
              _Canal(
                icon: Icons.chat_bubble_outline,
                iconBg: const Color(0xFF25D366),
                titulo: 'WhatsApp',
                descricao:
                    'Mande mensagem direta — mais rápido pra dúvidas simples.',
                cta: 'Abrir conversa',
                onTap: () async {
                  final uri = Uri.parse(
                      'https://wa.me/${u.whatsapp}?text=Ol%C3%A1%2C%20preciso%20de%20uma%20informa%C3%A7%C3%A3o.');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            if (u.email != null) ...[
              _Canal(
                icon: Icons.mail_outline,
                iconBg: AppColors.blue900,
                titulo: 'Email',
                descricao: u.email!,
                cta: 'Abrir email',
                onTap: () async {
                  final uri = Uri.parse('mailto:${u.email}');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            _Canal(
              icon: Icons.directions,
              iconBg: AppColors.amber600,
              titulo: 'Ir até a UBS',
              descricao: u.enderecoCompleto,
              cta: 'Como chegar',
              onTap: () async {
                final lat = u.latitude;
                final lng = u.longitude;
                final uri = (lat != null && lng != null)
                    ? Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=$lat,$lng')
                    : Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(u.enderecoCompleto)}');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),

            const SizedBox(height: AppSpacing.xl),
            InfoBlock(
              title: 'Emergência?',
              message:
                  'Em casos urgentes, ligue para o SAMU 192 ou procure o Pronto-Socorro mais próximo.',
              tone: InfoTone.critical,
              icon: Icons.local_hospital_outlined,
              action: TextButton(
                onPressed: () async {
                  final uri = Uri.parse('tel:192');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                child: const Text('Ligar para o SAMU (192)'),
              ),
            ),
            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
    );
  }
}

class _Canal extends StatelessWidget {
  const _Canal({
    required this.icon,
    required this.iconBg,
    required this.titulo,
    required this.descricao,
    required this.cta,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final String titulo;
  final String descricao;
  final String cta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: AppColors.slate200, width: 1)),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                color: iconBg,
                alignment: Alignment.center,
                child: Icon(icon, color: AppColors.white, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(titulo, style: AppTypography.titleLarge),
                    const SizedBox(height: 2),
                    Text(descricao, style: AppTypography.bodyMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Text(
                          cta,
                          style: AppTypography.button.copyWith(
                            color: AppColors.blue900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward,
                            color: AppColors.blue900, size: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
