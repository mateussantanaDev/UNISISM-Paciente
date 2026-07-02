import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/notificacao_controller.dart';
import '../../shared/widgets/widgets.dart';

class NotificacoesPage extends ConsumerWidget {
  const NotificacoesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificacoesListProvider);
    final fmt = DateFormat("dd/MM 'às' HH:mm", 'pt_BR');

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Avisos'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => ref.read(notificacaoControllerProvider.notifier).marcarTodasLidas(),
            child: const Text('Marcar todas lidas'),
          ),
        ],
      ),
      padded: false,
      scrollable: false,
      refresh: () async {
        ref.invalidate(notificacoesListProvider);
        ref.invalidate(naoLidasCountProvider);
        await Future.delayed(const Duration(milliseconds: 400));
      },
      body: async.when(
        loading: () => const LoadingView(),
        // Erros viram empty pra não tirar o paciente do app. Pull-to-refresh
        // tenta de novo silenciosamente.
        error: (_, __) => const EmptyView(
          icon: Icons.notifications_off_outlined,
          title: 'Nenhum aviso por aqui',
          message:
              'Quando a Secretaria de Saúde mandar algo pra você, vai aparecer aqui.',
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyView(
              icon: Icons.notifications_none,
              title: 'Nenhum aviso',
              message: 'Você receberá aqui todas as atualizações do seu encaminhamento e da Secretaria.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) {
              final n = list[i];
              return Material(
                color: AppColors.white,
                child: InkWell(
                  onTap: () async {
                    await ref.read(notificacaoControllerProvider.notifier).marcarLida(n.id);
                    if (n.deepLink != null && context.mounted) {
                      context.push(n.deepLink!);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: n.lida ? AppColors.white : AppColors.blue50,
                      border: Border.all(
                        color: n.lida ? AppColors.slate200 : AppColors.blue700,
                        width: n.lida ? 1 : 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          color: _bgFor(n.tone),
                          alignment: Alignment.center,
                          child: Icon(_iconFor(n.tipo), color: AppColors.white, size: 22),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(n.titulo, style: AppTypography.titleLarge),
                                  ),
                                  if (!n.lida)
                                    Container(width: 10, height: 10, color: AppColors.red700),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(n.corpo, style: AppTypography.bodyMedium),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                fmt.format(n.em),
                                style: AppTypography.bodySmall.copyWith(fontFamily: AppTypography.mono),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(String tipo) {
    switch (tipo) {
      case 'TFD':
        return Icons.directions_bus_filled_outlined;
      case 'CAMPANHA':
        return Icons.campaign_outlined;
      case 'ALERTA':
        return Icons.warning_amber_rounded;
      case 'SISTEMA':
        return Icons.settings;
      case 'ENCAMINHAMENTO':
      default:
        return Icons.medical_information_outlined;
    }
  }

  Color _bgFor(String tone) {
    switch (tone) {
      case 'SUCCESS':
        return AppColors.emerald700;
      case 'WARNING':
        return AppColors.amber600;
      case 'CRITICAL':
        return AppColors.red700;
      case 'INFO':
      default:
        return AppColors.blue900;
    }
  }
}
