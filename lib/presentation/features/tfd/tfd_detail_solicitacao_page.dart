import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/tfd_controller.dart';
import '../../shared/widgets/widgets.dart';

class TfdDetailSolicitacaoPage extends ConsumerWidget {
  const TfdDetailSolicitacaoPage({super.key, required this.id});
  final String id;

  Future<void> _cancelar(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar pedido?'),
        content: const Text('Tem certeza que quer cancelar a sua solicitação?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Não')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Sim')),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    try {
      await ref.read(tfdControllerProvider.notifier).cancelar(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitação cancelada.')),
        );
        context.pop();
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.mensagemAmigavel)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não conseguimos cancelar agora. Tente novamente.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(solicitacaoTfdProvider(id));
    final fmt = DateFormat("EEEE, dd 'de' MMMM", 'pt_BR');

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Sua solicitação de TFD'),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (_, __) => const EmptyView(
          icon: Icons.help_outline,
          title: 'Solicitação não encontrada',
          message: 'Esta solicitação pode ter sido cancelada ou removida.',
        ),
        data: (s) {
          final tone = switch (s.status) {
            'APROVADA' => StatusTone.success,
            'RECUSADA' || 'CANCELADA' => StatusTone.critical,
            'AGUARDANDO' => StatusTone.warning,
            'EMBARCADA' => StatusTone.info,
            _ => StatusTone.neutral,
          };
          final aprovada = s.status == 'APROVADA';

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (aprovada && s.numeroAssento != null)
                _AssentoCard(numero: s.numeroAssento as String, viagem: s.viagem),
              if (!aprovada)
                PanelCard(
                  accent: tone == StatusTone.warning ? PanelAccent.warning : null,
                  title: 'Status do pedido',
                  index: '!',
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatusBadge(label: s.statusLabel, tone: tone, size: StatusBadgeSize.large),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _explicacao(s.status),
                        style: AppTypography.bodyLarge,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: AppSpacing.xl),
              SectionHeader(label: 'Viagem'),
              PanelCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.viagem.destinoCidade} · ${s.viagem.destinoUf}',
                      style: AppTypography.titleLarge,
                    ),
                    Text(s.viagem.destinoLocal, style: AppTypography.bodyMedium),
                    const SizedBox(height: AppSpacing.md),
                    _row(Icons.calendar_today_outlined, fmt.format(s.viagem.dataPartida)),
                    _row(Icons.access_time, 'Saída às ${s.viagem.horaPartida}'),
                    _row(Icons.location_on_outlined, s.viagem.localEmbarque),
                    _row(Icons.directions_bus_filled_outlined,
                        '${s.viagem.veiculoDescricao} · ${s.viagem.veiculoPlaca}'),
                    if (s.viagem.motoristaNome != null)
                      _row(Icons.person_outline, 'Motorista: ${s.viagem.motoristaNome}'),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              SectionHeader(label: 'Detalhes do pedido'),

              // Badge de prioridade
              _PrioridadeBadge(prioridade: s.prioridade),
              const SizedBox(height: AppSpacing.md),

              PanelCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (s.encaminhamentoProtocolo != null) ...[
                      if (s.encaminhamentoId != null) ...[
                        InkWell(
                          onTap: () => context.push('/encaminhamento/${s.encaminhamentoId}'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('ENCAMINHAMENTO ANEXADO', style: AppTypography.labelInstitucional),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              s.encaminhamentoProtocolo!,
                                              style: AppTypography.data.copyWith(
                                                color: AppColors.blue900,
                                                decoration: TextDecoration.underline,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.xs),
                                          const Icon(
                                            Icons.open_in_new,
                                            size: 14,
                                            color: AppColors.blue900,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.slate600,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        _sub('Encaminhamento anexado', s.encaminhamentoProtocolo!, mono: true),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                    ] else ...[
                      _sub('Anexo de encaminhamento', 'Sem encaminhamento anexado'),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (s.justificativaPaciente != null) ...[
                      _sub('Sua justificativa', s.justificativaPaciente!),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (s.acompanhante != null) ...[
                      _sub('Acompanhante', s.acompanhante!),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (s.motivoRecusa != null)
                      InfoBlock(
                        title: 'Motivo da recusa',
                        message: s.motivoRecusa!,
                        tone: InfoTone.critical,
                      ),
                  ],
                ),
              ),

              if (s.status == 'AGUARDANDO') ...[
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: 'Cancelar este pedido',
                  variant: PrimaryButtonVariant.danger,
                  icon: Icons.cancel_outlined,
                  onPressed: () => _cancelar(context, ref),
                ),
              ],
              const SizedBox(height: AppSpacing.huge),
            ],
          );
        },
      ),
    );
  }

  String _explicacao(String status) {
    switch (status) {
      case 'AGUARDANDO':
        return 'Seu pedido está sendo analisado pela regulação. Você receberá um aviso quando houver resposta.';
      case 'RECUSADA':
        return 'A regulação não pôde aprovar sua vaga. Veja o motivo abaixo e procure sua UBS.';
      case 'CANCELADA':
        return 'Este pedido foi cancelado.';
      case 'EMBARCADA':
        return 'Você está em viagem. Boa sorte na sua consulta!';
      case 'CONCLUIDA':
        return 'Viagem concluída. Esperamos que esteja tudo bem.';
      default:
        return '';
    }
  }

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 18, color: AppColors.slate600),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: AppTypography.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  Widget _sub(String label, String value, {bool mono = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTypography.labelInstitucional),
        const SizedBox(height: 2),
        Text(
          value,
          style: mono ? AppTypography.data.copyWith(color: AppColors.slate900) : AppTypography.bodyMedium.copyWith(color: AppColors.slate900),
        ),
      ],
    );
  }
}

/// Badge dedicado pra prioridade do TFD (acima de detalhes).
class _PrioridadeBadge extends StatelessWidget {
  const _PrioridadeBadge({required this.prioridade});
  final String prioridade;

  @override
  Widget build(BuildContext context) {
    final p = switch (prioridade) {
      'PRIORITARIA' => (
        bg: AppColors.amber50,
        border: AppColors.amber600,
        fg: AppColors.amber900,
        icon: Icons.star,
        titulo: 'Pedido prioritário',
        descricao: 'Você anexou seu encaminhamento — análise antes da fila normal.',
      ),
      'URGENTE' => (
        bg: AppColors.red50,
        border: AppColors.red700,
        fg: AppColors.red900,
        icon: Icons.priority_high,
        titulo: 'Pedido urgente',
        descricao: 'Sua solicitação foi marcada como urgente.',
      ),
      _ => (
        bg: AppColors.slate50,
        border: AppColors.slate400,
        fg: AppColors.slate900,
        icon: Icons.outbox_outlined,
        titulo: 'Prioridade normal',
        descricao: 'Análise por ordem de chegada.',
      ),
    };
    return Container(
      decoration: BoxDecoration(
        color: p.bg,
        border: Border.all(color: p.border, width: 1),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            color: p.border,
            alignment: Alignment.center,
            child: Icon(p.icon, color: AppColors.white, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(p.titulo, style: AppTypography.titleMedium.copyWith(color: p.fg)),
                Text(p.descricao, style: AppTypography.bodySmall.copyWith(color: p.fg)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssentoCard extends StatelessWidget {
  const _AssentoCard({required this.numero, required this.viagem});
  final String numero;
  final dynamic viagem;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.emerald50,
        border: Border.all(color: AppColors.emerald700, width: 2),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'VAGA CONFIRMADA',
            style: AppTypography.labelInstitucional.copyWith(color: AppColors.emerald800),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 96,
            height: 96,
            color: AppColors.emerald700,
            alignment: Alignment.center,
            child: Text(
              numero,
              style: const TextStyle(
                fontFamily: AppTypography.mono,
                fontSize: 52,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Seu assento', style: AppTypography.headlineMedium.copyWith(color: AppColors.emerald900)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${viagem.veiculoDescricao} · placa ${viagem.veiculoPlaca}',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.emerald900),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
