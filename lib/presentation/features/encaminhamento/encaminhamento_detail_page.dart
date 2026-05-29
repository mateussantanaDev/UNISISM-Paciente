import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';

/// Tela de detalhe do encaminhamento — **dados 100% hard-coded**.
/// Sem providers, sem async, sem Riverpod. Só widgets stateless.
class EncaminhamentoDetailPage extends StatelessWidget {
  const EncaminhamentoDetailPage({super.key, required this.id});
  final String id;

  // ---------- Dados hard-coded (não dependem de id) ----------
  static const _protocolo = 'UBS-2026-100137';
  static const _especialidade = 'Cardiologia';
  static const _status = 'AGENDADO';
  static const _statusLabel = 'Consulta marcada';
  static const _mensagem =
      'Sua consulta foi marcada. Confira a data e o local abaixo e leve um documento com foto.';
  static const _prioridade = 'PRIORITARIA';
  static const _cid10 = 'I10';
  static const _cid10Descricao = 'Hipertensão essencial';
  static const _justificativa =
      'Paciente apresenta hipertensão de difícil controle, em uso de duas classes de anti-hipertensivos.';
  static const _ubsOrigem = 'UBS Centro - Dr. João Mendes';
  static const _medico = 'Dr. Ricardo Lima — CRM/BA 12345';
  static const _localAgendamento =
      'Hospital Regional de Águas Belas - Ambulatório 3';

  @override
  Widget build(BuildContext context) {
    final dataAgendamento =
        DateTime.now().add(const Duration(days: 12)).copyWith(hour: 9, minute: 30);
    final criadoEm = DateTime.now().subtract(const Duration(days: 8));
    final aprovadoEm = DateTime.now().subtract(const Duration(hours: 36));
    final fmt = DateFormat("EEEE, dd 'de' MMMM 'de' yyyy 'às' HH:mm", 'pt_BR');

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Encaminhamento'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ---------- Card hero ----------
          StatusHeroCard(
            statusKey: _status,
            statusLabel: _statusLabel,
            mensagem: _mensagem,
            protocolo: _protocolo,
            especialidade: _especialidade,
            dataConsulta: dataAgendamento,
            localConsulta: _localAgendamento,
            prioridade: _prioridade,
          ),

          const SizedBox(height: AppSpacing.xl),

          // ---------- Roadmap (Shopee-style) ----------
          SectionHeader(label: 'Rastreio do seu pedido'),
          StatusRoadmap(
            statusKey: _status,
            dataCriacao: criadoEm,
            dataAprovacao: aprovadoEm,
            dataAgendamento: dataAgendamento,
          ),

          const SizedBox(height: AppSpacing.xl),

          // ---------- Bloco da consulta ----------
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
                  valor: fmt.format(dataAgendamento),
                ),
                const Divider(),
                _Linha(
                  icon: Icons.location_on_outlined,
                  label: 'Local',
                  valor: _localAgendamento,
                ),
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
                  valor: _especialidade,
                ),
                const Divider(),
                _Linha(
                  icon: Icons.priority_high_outlined,
                  label: 'Prioridade',
                  valor: 'Prioritária',
                  trailing: StatusBadge.fromPrioridade(_prioridade),
                ),
                const Divider(),
                _Linha(
                  icon: Icons.tag,
                  label: 'CID-10',
                  valor: '$_cid10 — $_cid10Descricao',
                  mono: true,
                ),
                const Divider(),
                _Linha(
                  icon: Icons.local_hospital_outlined,
                  label: 'Médico solicitante',
                  valor: _medico,
                ),
                const Divider(),
                _Linha(
                  icon: Icons.home_work_outlined,
                  label: 'Sua UBS',
                  valor: _ubsOrigem,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ---------- Justificativa médica ----------
          SectionHeader(label: 'Justificativa do médico'),
          PanelCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(_justificativa, style: AppTypography.bodyLarge),
          ),

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
          const SizedBox(height: AppSpacing.md),
          IconCard(
            icon: Icons.directions_bus_filled,
            title: 'Pedir vaga no transporte',
            subtitle: 'TFD — Tratamento Fora de Domicílio',
            iconBg: AppColors.emerald700,
            accent: IconCardAccent.success,
            onTap: () => context.push('/tfd'),
          ),

          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
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
