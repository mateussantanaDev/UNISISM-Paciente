import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/encaminhamento.dart';
import '../../../providers/encaminhamento_controller.dart';
import '../../shared/widgets/widgets.dart';

/// Lista de encaminhamentos — **100% backend real** via
/// `encaminhamentosProvider` (`GET /paciente-app/meus-encaminhamentos`).
///
/// Status terminais (CONCLUIDO/REJEITADO/CANCELADO) vão pra "Histórico";
/// resto entra em "Em andamento". Sem encaminhamentos: estado vazio amigável.
class EncaminhamentosListPage extends ConsumerWidget {
  const EncaminhamentosListPage({super.key});

  static const _statusTerminais = {'CONCLUIDO', 'REJEITADO', 'CANCELADO'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(encaminhamentosProvider);

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Meus encaminhamentos'),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (_, __) => EmptyView(
          icon: Icons.cloud_off,
          title: 'Não conseguimos carregar',
          message: 'Verifique sua conexão e tente novamente.',
          actionLabel: 'Tentar de novo',
          onAction: () => ref.invalidate(encaminhamentosProvider),
        ),
        data: (todos) {
          if (todos.isEmpty) {
            return EmptyView(
              icon: Icons.medical_services_outlined,
              title: 'Nenhum encaminhamento ainda',
              message:
                  'Quando sua UBS abrir um encaminhamento pra você, ele aparece aqui.',
            );
          }

          final ativos = todos.where(
              (e) => !_statusTerminais.contains(e.status.toUpperCase())).toList()
            ..sort((a, b) => b.atualizadoEm.compareTo(a.atualizadoEm));
          final encerrados = todos.where(
              (e) => _statusTerminais.contains(e.status.toUpperCase())).toList()
            ..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));

          return RefreshIndicator(
            color: AppColors.blue900,
            onRefresh: () async {
              ref.invalidate(encaminhamentosProvider);
              await Future.delayed(const Duration(milliseconds: 400));
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                if (ativos.isNotEmpty) ...[
                  SectionHeader(label: 'Em andamento'),
                  for (final e in ativos) ...[
                    _EncCard(item: e),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (encerrados.isNotEmpty) ...[
                  SectionHeader(label: 'Histórico'),
                  for (final e in encerrados) ...[
                    _EncCard(item: e),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
                const SizedBox(height: AppSpacing.huge),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EncCard extends StatelessWidget {
  const _EncCard({required this.item});
  final Encaminhamento item;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy', 'pt_BR');

    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: () => context.push('/encaminhamento/${item.id}'),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.slate200, width: 1),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    color: AppColors.blue900,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.medical_services_outlined,
                      color: AppColors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.especialidade,
                          style: AppTypography.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.protocolo,
                          style:
                              AppTypography.protocolo.copyWith(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  StatusBadge.fromStatus(item.status,
                      size: StatusBadgeSize.medium),
                  if (!['ELETIVA', 'NORMAL']
                      .contains(item.prioridade.toUpperCase()))
                    StatusBadge.fromPrioridade(item.prioridade,
                        size: StatusBadgeSize.medium),
                  if (item.pendenciasAbertas > 0)
                    StatusBadge(
                      label: 'Pendência aberta',
                      tone: StatusTone.warning,
                      size: StatusBadgeSize.medium,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _MiniRoadmap(statusKey: item.status),
              const SizedBox(height: AppSpacing.md),
              Container(height: 1, color: AppColors.slate100),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Icon(Icons.event_outlined,
                      size: 16, color: AppColors.slate600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Aberto em ${fmt.format(item.criadoEm)}',
                      style: AppTypography.bodySmall.copyWith(
                        fontFamily: AppTypography.mono,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(Icons.arrow_forward,
                      size: 18, color: AppColors.slate400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mini visualização do roadmap (4 bolinhas) — calculado a partir do `status` real.
class _MiniRoadmap extends StatelessWidget {
  const _MiniRoadmap({required this.statusKey});
  final String statusKey;

  int get _activeStep {
    switch (statusKey.toUpperCase()) {
      case 'RASCUNHO':
        return 0;
      case 'AGUARDANDO_REGULACAO':
      case 'EM_ANALISE':
      case 'PENDENCIA_DOCUMENTO':
        return 1;
      case 'APROVADO':
      case 'AGUARDANDO_AGENDAMENTO':
        return 2;
      case 'AGENDADO':
        return 3;
      case 'CONCLUIDO':
        return 4;
      default:
        return 0;
    }
  }

  static const _labels = ['Criado', 'Análise', 'Aprovado', 'Marcado', 'Feito'];

  @override
  Widget build(BuildContext context) {
    final isRejeitado = statusKey.toUpperCase() == 'REJEITADO';
    final isCancelado = statusKey.toUpperCase() == 'CANCELADO';
    final active = _activeStep;

    if (isRejeitado || isCancelado) {
      return Row(
        children: [
          const Icon(Icons.cancel, color: AppColors.red700, size: 18),
          const SizedBox(width: 6),
          Text(
            isRejeitado ? 'Solicitação recusada' : 'Encaminhamento cancelado',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.red800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Row(
      children: List.generate(_labels.length, (i) {
        final done = i < active;
        final current = i == active;
        final color = done
            ? AppColors.emerald700
            : (current ? AppColors.blue900 : AppColors.slate300);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: done ? color : AppColors.white,
                        border: Border.all(color: color, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: done
                          ? const Icon(Icons.check,
                              size: 10, color: AppColors.white)
                          : null,
                    ),
                    if (i < _labels.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: i < active
                              ? AppColors.emerald700
                              : AppColors.slate200,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _labels[i],
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 10,
                    color: done || current
                        ? AppColors.slate900
                        : AppColors.slate500,
                    fontWeight:
                        current ? FontWeight.w700 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
