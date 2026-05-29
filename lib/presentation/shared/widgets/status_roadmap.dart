import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Roadmap de rastreio — estilo Shopee / Mercado Livre.
///
/// Mostra a jornada do encaminhamento em checkpoints visuais.
/// Cada passo tem um estado (completed / current / pending) com cor e ícone próprios.
///
/// Mapeia automaticamente o status backend → passo ativo.
class StatusRoadmap extends StatelessWidget {
  StatusRoadmap({
    super.key,
    required this.statusKey,
    this.dataCriacao,
    this.dataAprovacao,
    this.dataAgendamento,
    this.dataConclusao,
    this.motivoRejeicao,
  }) : steps = _stepsFor(statusKey,
            dataCriacao: dataCriacao,
            dataAprovacao: dataAprovacao,
            dataAgendamento: dataAgendamento,
            dataConclusao: dataConclusao,
            motivoRejeicao: motivoRejeicao);

  final String statusKey;
  final DateTime? dataCriacao;
  final DateTime? dataAprovacao;
  final DateTime? dataAgendamento;
  final DateTime? dataConclusao;
  final String? motivoRejeicao;
  final List<RoadmapStep> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.slate200, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < steps.length; i++)
            _RoadmapNode(
              step: steps[i],
              isLast: i == steps.length - 1,
              index: i,
            ),
        ],
      ),
    );
  }

  static List<RoadmapStep> _stepsFor(
    String statusKey, {
    DateTime? dataCriacao,
    DateTime? dataAprovacao,
    DateTime? dataAgendamento,
    DateTime? dataConclusao,
    String? motivoRejeicao,
  }) {
    final s = statusKey.toUpperCase();
    final isRejeitado = s == 'REJEITADO';
    final isCancelado = s == 'CANCELADO';

    // Map de "qual step está ativo" pra cada status
    int currentIdx;
    switch (s) {
      case 'RASCUNHO':
        currentIdx = 0;
        break;
      case 'AGUARDANDO_REGULACAO':
      case 'EM_ANALISE':
      case 'PENDENCIA_DOCUMENTO':
        currentIdx = 1;
        break;
      case 'APROVADO':
      case 'AGUARDANDO_AGENDAMENTO':
        currentIdx = 2;
        break;
      case 'AGENDADO':
        currentIdx = 3;
        break;
      case 'CONCLUIDO':
        currentIdx = 4;
        break;
      case 'REJEITADO':
      case 'CANCELADO':
        currentIdx = 1;
        break;
      default:
        currentIdx = 0;
    }

    // Fluxo "feliz" padrão
    final baseSteps = <RoadmapStep>[
      RoadmapStep(
        titulo: 'Encaminhamento criado',
        descricao: 'Sua UBS registrou o pedido médico e enviou à Regulação.',
        icone: Icons.medical_information_outlined,
        iconeCompleto: Icons.check,
        em: dataCriacao,
      ),
      RoadmapStep(
        titulo: s == 'PENDENCIA_DOCUMENTO'
            ? 'Pendência aberta'
            : 'Em análise pela Regulação',
        descricao: s == 'PENDENCIA_DOCUMENTO'
            ? 'A regulação pediu mais documentos. Procure sua UBS.'
            : 'Médicos da Secretaria estão avaliando seu pedido.',
        icone: s == 'PENDENCIA_DOCUMENTO'
            ? Icons.warning_amber_rounded
            : Icons.search,
        iconeCompleto: Icons.check,
        warning: s == 'PENDENCIA_DOCUMENTO',
      ),
      RoadmapStep(
        titulo: 'Solicitação aprovada',
        descricao: 'A regulação aprovou. Buscando uma data para você.',
        icone: Icons.thumb_up_outlined,
        iconeCompleto: Icons.check,
        em: dataAprovacao,
      ),
      RoadmapStep(
        titulo: 'Consulta marcada',
        descricao: dataAgendamento != null
            ? 'Sua consulta foi agendada. Veja os detalhes acima.'
            : 'Estamos aguardando uma data com o especialista.',
        icone: Icons.event_available,
        iconeCompleto: Icons.check,
        em: dataAgendamento,
      ),
      RoadmapStep(
        titulo: 'Atendimento realizado',
        descricao: 'Você foi atendido. Acompanhe os retornos com sua UBS.',
        icone: Icons.task_alt,
        iconeCompleto: Icons.check,
        em: dataConclusao,
      ),
    ];

    // Trilha alternativa: rejeição substitui o passo 2 com tom crítico
    if (isRejeitado) {
      return [
        baseSteps[0].copyWith(state: RoadmapState.completed),
        RoadmapStep(
          titulo: 'Solicitação recusada',
          descricao: motivoRejeicao ??
              'A regulação não pôde aprovar seu encaminhamento.',
          icone: Icons.cancel,
          iconeCompleto: Icons.cancel,
          state: RoadmapState.rejected,
          em: dataAprovacao,
        ),
      ];
    }

    if (isCancelado) {
      return [
        baseSteps[0].copyWith(state: RoadmapState.completed),
        RoadmapStep(
          titulo: 'Encaminhamento cancelado',
          descricao: 'Este encaminhamento foi encerrado.',
          icone: Icons.block,
          iconeCompleto: Icons.block,
          state: RoadmapState.rejected,
        ),
      ];
    }

    // Aplica estado nos steps baseado no current
    return [
      for (var i = 0; i < baseSteps.length; i++)
        baseSteps[i].copyWith(
          state: i < currentIdx
              ? RoadmapState.completed
              : (i == currentIdx
                  ? RoadmapState.current
                  : RoadmapState.pending),
        ),
    ];
  }
}

enum RoadmapState { completed, current, pending, rejected }

class RoadmapStep {
  const RoadmapStep({
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.iconeCompleto,
    this.em,
    this.state = RoadmapState.pending,
    this.warning = false,
  });

  final String titulo;
  final String descricao;
  final IconData icone;
  final IconData iconeCompleto;
  final DateTime? em;
  final RoadmapState state;
  final bool warning;

  RoadmapStep copyWith({RoadmapState? state}) => RoadmapStep(
        titulo: titulo,
        descricao: descricao,
        icone: icone,
        iconeCompleto: iconeCompleto,
        em: em,
        warning: warning,
        state: state ?? this.state,
      );
}

class _RoadmapNode extends StatefulWidget {
  const _RoadmapNode({
    required this.step,
    required this.isLast,
    required this.index,
  });

  final RoadmapStep step;
  final bool isLast;
  final int index;

  @override
  State<_RoadmapNode> createState() => _RoadmapNodeState();
}

class _RoadmapNodeState extends State<_RoadmapNode>
    with TickerProviderStateMixin {
  late final AnimationController _entry;
  AnimationController? _pulse;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    Future.delayed(Duration(milliseconds: widget.index * 110), () {
      if (mounted) _entry.forward();
    });

    if (widget.step.state == RoadmapState.current) {
      _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _entry.dispose();
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    final p = _palette(step);
    final fmt = DateFormat("dd/MM 'às' HH:mm", 'pt_BR');

    final dot = AnimatedBuilder(
      animation: _pulse ?? const AlwaysStoppedAnimation(0),
      builder: (_, __) {
        final pulseScale = step.state == RoadmapState.current
            ? 1.0 + 0.08 * (_pulse?.value ?? 0)
            : 1.0;
        return Transform.scale(
          scale: pulseScale,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: p.bg,
              border: Border.all(color: p.border, width: 2),
              boxShadow: step.state == RoadmapState.current
                  ? [
                      BoxShadow(
                        color: p.border.withValues(alpha: 0.25),
                        blurRadius: 0,
                        spreadRadius: 4 * (_pulse?.value ?? 0),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Icon(
              step.state == RoadmapState.completed
                  ? step.iconeCompleto
                  : step.icone,
              color: p.fg,
              size: 22,
            ),
          ),
        );
      },
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: _entry,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  dot,
                  if (!widget.isLast)
                    Expanded(
                      child: Container(
                        width: 3,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: step.state == RoadmapState.completed
                            ? AppColors.emerald700
                            : (step.state == RoadmapState.rejected
                                ? AppColors.red700
                                : AppColors.slate200),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: widget.isLast ? 0 : AppSpacing.lg,
                    top: 2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        step.titulo,
                        style: AppTypography.titleMedium.copyWith(
                          color: step.state == RoadmapState.pending
                              ? AppColors.slate500
                              : (step.state == RoadmapState.rejected
                                  ? AppColors.red900
                                  : AppColors.slate900),
                          fontWeight: step.state == RoadmapState.current
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.descricao,
                        style: AppTypography.bodySmall.copyWith(
                          color: step.state == RoadmapState.pending
                              ? AppColors.slate400
                              : (step.state == RoadmapState.rejected
                                  ? AppColors.red800
                                  : AppColors.slate700),
                          height: 1.4,
                        ),
                      ),
                      if (step.em != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          color: AppColors.slate50,
                          child: Text(
                            fmt.format(step.em!),
                            style: AppTypography.bodySmall.copyWith(
                              fontFamily: AppTypography.mono,
                              fontSize: 11,
                              color: AppColors.slate600,
                            ),
                          ),
                        ),
                      ],
                      if (step.state == RoadmapState.current) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          decoration: BoxDecoration(
                            color: p.bg,
                            border: Border.all(color: p.border, width: 1),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedBuilder(
                                animation: _pulse ?? const AlwaysStoppedAnimation(0),
                                builder: (_, __) => Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: p.border.withValues(
                                      alpha: 0.4 + 0.6 * (_pulse?.value ?? 0),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'ETAPA ATUAL',
                                style: AppTypography.labelInstitucional.copyWith(
                                  color: p.border,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ({Color bg, Color border, Color fg}) _palette(RoadmapStep s) {
    if (s.state == RoadmapState.rejected) {
      return (bg: AppColors.red50, border: AppColors.red700, fg: AppColors.red700);
    }
    if (s.warning && s.state == RoadmapState.current) {
      return (bg: AppColors.amber50, border: AppColors.amber600, fg: AppColors.amber600);
    }
    switch (s.state) {
      case RoadmapState.completed:
        return (bg: AppColors.emerald50, border: AppColors.emerald700, fg: AppColors.emerald700);
      case RoadmapState.current:
        return (bg: AppColors.blue50, border: AppColors.blue900, fg: AppColors.blue900);
      case RoadmapState.pending:
        return (bg: AppColors.slate50, border: AppColors.slate300, fg: AppColors.slate400);
      case RoadmapState.rejected:
        return (bg: AppColors.red50, border: AppColors.red700, fg: AppColors.red700);
    }
  }
}
