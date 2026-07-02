import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../providers/encaminhamento_controller.dart';
import '../../shared/widgets/widgets.dart';

/// Tela de timeline — **dados reais** vindos de `timelineProvider(id)`
/// (`GET /paciente-app/encaminhamentos/:id/timeline` indiretamente via cache
/// do `EncaminhamentoRepositoryHttp.timeline()`).
class EncaminhamentoTimelinePage extends ConsumerWidget {
  const EncaminhamentoTimelinePage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(timelineProvider(id));

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Linha do tempo'),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (_, __) => EmptyView(
          icon: Icons.cloud_off,
          title: 'Não conseguimos carregar',
          message: 'Tente novamente em alguns instantes.',
          actionLabel: 'Tentar de novo',
          onAction: () => ref.invalidate(timelineProvider(id)),
        ),
        data: (eventos) {
          if (eventos.isEmpty) {
            return EmptyView(
              icon: Icons.timeline,
              title: 'Sem eventos registrados',
              message:
                  'Quando algo acontecer com seu encaminhamento, registramos aqui.',
            );
          }
          // Backend manda em ASC (mais antigo primeiro) — mantém ordem.
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: eventos.length,
            itemBuilder: (_, i) {
              final ev = eventos[i];
              return TimelineStep(
                tipo: _toTimelineTipo(ev.tipo),
                titulo: ev.titulo,
                descricao: ev.descricao,
                autor: ev.autorNome ?? 'UNISISM',
                autorPapel: ev.autorPapel ?? '—',
                em: ev.em,
                isLast: i == eventos.length - 1,
              );
            },
          );
        },
      ),
    );
  }

  /// Backend manda enum app-friendly: CRIACAO/ANEXO/PENDENCIA/APROVACAO/
  /// AGENDAMENTO/REJEICAO/ATUALIZACAO. Aqui só converte pro enum visual.
  static TimelineTipo _toTimelineTipo(String backend) {
    switch (backend.toUpperCase()) {
      case 'CRIACAO':
        return TimelineTipo.criacao;
      case 'ANEXO':
        return TimelineTipo.anexo;
      case 'PENDENCIA':
        return TimelineTipo.pendencia;
      case 'APROVACAO':
        return TimelineTipo.aprovacao;
      case 'AGENDAMENTO':
        return TimelineTipo.agendamento;
      case 'REJEICAO':
        return TimelineTipo.rejeicao;
      case 'ATUALIZACAO':
      default:
        return TimelineTipo.atualizacao;
    }
  }
}
