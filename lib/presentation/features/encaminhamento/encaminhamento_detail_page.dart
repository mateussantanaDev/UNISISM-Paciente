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

/// Tela de detalhe do encaminhamento — **dados 100% reais** vindos do backend
/// via `encaminhamentoByIdProvider(id)`.
class EncaminhamentoDetailPage extends ConsumerWidget {
  const EncaminhamentoDetailPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEnc = ref.watch(encaminhamentoByIdProvider(id));

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Encaminhamento'),
      ),
      body: asyncEnc.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => EmptyView(
          icon: Icons.search_off,
          title: 'Encaminhamento não encontrado',
          message:
              'Este encaminhamento não está disponível. Procure sua UBS.',
        ),
        data: (enc) => _DetailBody(id: id, enc: enc),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.id, required this.enc});

  final String id;
  final Encaminhamento enc;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat("EEEE, dd 'de' MMMM 'de' yyyy 'às' HH:mm", 'pt_BR');

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // ---------- Card hero ----------
        StatusHeroCard(
          statusKey: enc.status,
          statusLabel: enc.statusLabel,
          mensagem: enc.mensagemPaciente,
          protocolo: enc.protocolo,
          especialidade: enc.especialidade,
          dataConsulta: enc.dataAgendamento,
          localConsulta: enc.localAgendamento,
          prioridade: enc.prioridade,
        ),

        const SizedBox(height: AppSpacing.xl),

        // ---------- Roadmap (Shopee-style) ----------
        SectionHeader(label: 'Rastreio do seu pedido'),
        StatusRoadmap(
          statusKey: enc.status,
          dataCriacao: enc.criadoEm,
          dataAprovacao: enc.status == 'APROVADO' ||
                  enc.status == 'AGENDADO' ||
                  enc.status == 'CONCLUIDO'
              ? enc.atualizadoEm
              : null,
          dataAgendamento: enc.dataAgendamento,
        ),

        const SizedBox(height: AppSpacing.xl),

        // ---------- Bloco da consulta (só se agendado) ----------
        if (enc.dataAgendamento != null) ...[
          SectionHeader(label: 'Sua consulta'),
          PanelCard(
            accent: PanelAccent.success,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Linha(
                  icon: Icons.calendar_today_outlined,
                  label: 'Dia e hora',
                  valor: fmt.format(enc.dataAgendamento!),
                ),
                if (enc.localAgendamento != null) ...[
                  const Divider(),
                  _Linha(
                    icon: Icons.location_on_outlined,
                    label: 'Local',
                    valor: enc.localAgendamento!,
                  ),
                ],
                const Divider(),
                _Linha(
                  icon: Icons.assignment_outlined,
                  label: 'O que levar',
                  valor:
                      'Documento com foto · Cartão SUS · Lista de remédios em uso',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],

        // ---------- Motivo de rejeição (se rejeitado) ----------
        if (enc.status == 'REJEITADO' && enc.motivoRejeicao != null) ...[
          SectionHeader(label: 'Por que foi recusado'),
          PanelCard(
            accent: PanelAccent.critical,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(enc.motivoRejeicao!,
                style: AppTypography.bodyLarge),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],

        // ---------- Pendência aberta ----------
        if (enc.pendenciasAbertas > 0) ...[
          SectionHeader(label: 'Pendência aberta'),
          PanelCard(
            accent: PanelAccent.warning,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.amber600),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'A regulação pediu mais documentos. Procure sua UBS '
                    'para resolver.',
                    style: AppTypography.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],

        // ---------- Resumo clínico ----------
        SectionHeader(label: 'Resumo clínico'),
        PanelCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Linha(
                icon: Icons.medical_services_outlined,
                label: 'Especialidade',
                valor: enc.especialidade,
              ),
              const Divider(),
              _Linha(
                icon: Icons.priority_high_outlined,
                label: 'Prioridade',
                valor: _prioridadeLabel(enc.prioridade),
                trailing: StatusBadge.fromPrioridade(enc.prioridade),
              ),
              if (enc.cid10 != null) ...[
                const Divider(),
                _Linha(
                  icon: Icons.tag,
                  label: 'CID-10',
                  valor: enc.cid10Descricao != null
                      ? '${enc.cid10} — ${enc.cid10Descricao}'
                      : enc.cid10!,
                  mono: true,
                ),
              ],
              if (enc.medicoSolicitanteNome != null) ...[
                const Divider(),
                _Linha(
                  icon: Icons.local_hospital_outlined,
                  label: 'Médico solicitante',
                  valor: enc.medicoSolicitanteNome!,
                ),
              ],
              if (enc.ubsOrigemNome != null) ...[
                const Divider(),
                _Linha(
                  icon: Icons.home_work_outlined,
                  label: 'Sua UBS',
                  valor: enc.ubsOrigemNome!,
                ),
              ],
            ],
          ),
        ),

        // ---------- Justificativa médica ----------
        if (enc.justificativaResumida != null) ...[
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(label: 'Justificativa do médico'),
          PanelCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(enc.justificativaResumida!,
                style: AppTypography.bodyLarge),
          ),
        ],

        // ---------- Recomendações (v0.10+) ----------
        if (enc.recomendacoes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(label: 'Orientações pra essa consulta'),
          PanelCard(
            accent: PanelAccent.info,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: enc.recomendacoes.map((rec) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Icon(Icons.check_circle_outline,
                            size: 18, color: AppColors.blue900),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(rec, style: AppTypography.bodyLarge),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        // ---------- Observações da regulação ----------
        if (enc.observacoesRegulacao != null) ...[
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(label: 'Observações da regulação'),
          PanelCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(enc.observacoesRegulacao!,
                style: AppTypography.bodyLarge),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),

        // ---------- Próximas ações ----------
        SectionHeader(label: 'Próximas ações'),

        IconCard(
          icon: Icons.timeline,
          title: 'Ver linha do tempo',
          subtitle: 'Tudo que aconteceu até agora',
          iconBg: AppColors.blue900,
          onTap: () => context.push('/encaminhamento/$id/timeline'),
        ),
        const SizedBox(height: AppSpacing.md),
        IconCard(
          icon: Icons.folder_open_outlined,
          title: 'Documentos anexados',
          subtitle: 'Baixar, abrir ou compartilhar',
          iconBg: AppColors.slate700,
          onTap: () => context.push('/encaminhamento/$id/anexos'),
        ),
        if (enc.podeSolicitarTfd) ...[
          const SizedBox(height: AppSpacing.md),
          IconCard(
            icon: Icons.directions_bus_filled,
            title: 'Pedir vaga no transporte',
            subtitle: 'TFD — Tratamento Fora de Domicílio',
            iconBg: AppColors.emerald700,
            accent: IconCardAccent.success,
            onTap: () => context.push('/tfd'),
          ),
        ],

        const SizedBox(height: AppSpacing.huge),
      ],
    );
  }

  static String _prioridadeLabel(String p) {
    switch (p) {
      case 'EMERGENCIA':
        return 'Emergência';
      case 'URGENTE':
        return 'Urgente';
      case 'PRIORITARIA':
        return 'Prioritária';
      case 'ELETIVA':
      default:
        return 'Eletiva';
    }
  }
}

class _Linha extends StatelessWidget {
  const _Linha({
    required this.icon,
    required this.label,
    required this.valor,
    this.mono = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String valor;
  final bool mono;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.slate500),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTypography.labelInstitucional,
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: mono
                      ? AppTypography.data.copyWith(
                          color: AppColors.slate900, fontSize: 16)
                      : AppTypography.bodyLarge,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}
