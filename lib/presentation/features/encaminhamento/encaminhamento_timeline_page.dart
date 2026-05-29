import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../shared/widgets/widgets.dart';

/// Tela de timeline — **dados hard-coded, sem providers**.
class EncaminhamentoTimelinePage extends StatelessWidget {
  const EncaminhamentoTimelinePage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final agora = DateTime.now();
    final eventos = [
      (
        tipo: TimelineTipo.criacao,
        titulo: 'Encaminhamento criado pela sua UBS',
        descricao:
            'Sua UBS Centro registrou seu encaminhamento para Cardiologia e enviou à Regulação Municipal.',
        autor: 'Bianca Lopes',
        papel: 'Atendente UBS',
        em: agora.subtract(const Duration(days: 8)),
      ),
      (
        tipo: TimelineTipo.anexo,
        titulo: 'Eletrocardiograma anexado',
        descricao: null as String?,
        autor: 'Bianca Lopes',
        papel: 'Atendente UBS',
        em: agora.subtract(const Duration(days: 7)),
      ),
      (
        tipo: TimelineTipo.atualizacao,
        titulo: 'Em análise pela Regulação',
        descricao:
            'Sua solicitação está sendo analisada pelos médicos reguladores.',
        autor: 'Sistema',
        papel: 'UNISISM',
        em: agora.subtract(const Duration(days: 5)),
      ),
      (
        tipo: TimelineTipo.aprovacao,
        titulo: 'Solicitação aprovada',
        descricao:
            'A regulação aprovou seu encaminhamento. Estamos buscando a melhor data para a consulta.',
        autor: 'Dr. André Carvalho',
        papel: 'Médico Regulador SMS',
        em: agora.subtract(const Duration(hours: 36)),
      ),
      (
        tipo: TimelineTipo.agendamento,
        titulo: 'Consulta marcada!',
        descricao:
            'Sua consulta foi marcada no Hospital Regional. Confira os detalhes e leve um documento com foto.',
        autor: 'Daniel Rocha',
        papel: 'Agendamento SMS',
        em: agora.subtract(const Duration(hours: 6)),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Linha do tempo'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: eventos.length,
        itemBuilder: (_, i) {
          final ev = eventos[i];
          return TimelineStep(
            tipo: ev.tipo,
            titulo: ev.titulo,
            descricao: ev.descricao,
            autor: ev.autor,
            autorPapel: ev.papel,
            em: ev.em,
            isLast: i == eventos.length - 1,
          );
        },
      ),
    );
  }
}
