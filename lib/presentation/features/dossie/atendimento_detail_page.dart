import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/dossie.dart';
import '../../../providers/dossie_controller.dart';
import '../../shared/widgets/widgets.dart';

/// Detalhe de um atendimento médico.
///
/// Backend não expõe endpoint dedicado (`/dossie/atendimentos/:id`) —
/// usamos `atendimentoByIdProvider` que lê do cache da lista.
class AtendimentoDetailPage extends ConsumerWidget {
  const AtendimentoDetailPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(atendimentoByIdProvider(id));
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop()),
        title: const Text('Atendimento'),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (_, __) => const EmptyView(
          icon: Icons.search_off,
          title: 'Atendimento não encontrado',
          message: 'Este registro não está mais disponível.',
        ),
        data: (a) => _Body(a: a),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.a});
  final Atendimento a;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat("EEEE, dd 'de' MMMM 'de' yyyy 'às' HH:mm", 'pt_BR');
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // ───────── Hero ─────────
        Container(
          decoration: BoxDecoration(
            color: AppColors.blue900,
            border: Border.all(color: AppColors.blue900, width: 2),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                color: AppColors.white,
                alignment: Alignment.center,
                child: Icon(_tipoIcon(a.tipo),
                    color: AppColors.blue900, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ATENDIMENTO',
                      style: AppTypography.labelInstitucional
                          .copyWith(color: const Color(0xFF93C5FD)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      a.tipoLabel,
                      style: AppTypography.titleLarge
                          .copyWith(color: AppColors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR').format(a.data),
                      style: AppTypography.bodyMedium.copyWith(
                        color: const Color(0xFF93C5FD),
                        fontFamily: AppTypography.mono,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // ───────── Dados clínicos ─────────
        SectionHeader(label: 'Dados clínicos'),
        PanelCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Linha(
                icon: Icons.calendar_today_outlined,
                label: 'Data e hora',
                valor: fmt.format(a.data),
                mono: true,
              ),
              const Divider(),
              _Linha(
                icon: Icons.local_hospital_outlined,
                label: 'Local',
                valor: a.localNome,
              ),
              const Divider(),
              _Linha(
                icon: Icons.person_outline,
                label: 'Profissional',
                valor: a.profissionalNome,
              ),
              if (a.profissionalEspecialidade != null &&
                  a.profissionalEspecialidade!.isNotEmpty) ...[
                const Divider(),
                _Linha(
                  icon: Icons.medical_services_outlined,
                  label: 'Especialidade',
                  valor: a.profissionalEspecialidade!,
                ),
              ],
              if (a.cid10 != null && a.cid10!.isNotEmpty) ...[
                const Divider(),
                _Linha(
                  icon: Icons.tag,
                  label: 'CID-10',
                  valor: a.cid10Descricao != null
                      ? '${a.cid10} — ${a.cid10Descricao}'
                      : a.cid10!,
                  mono: true,
                ),
              ],
            ],
          ),
        ),

        // ───────── Queixa principal ─────────
        if (a.queixaPrincipal != null && a.queixaPrincipal!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(label: 'Por que você procurou'),
          PanelCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(a.queixaPrincipal!, style: AppTypography.bodyLarge),
          ),
        ],

        // ───────── Conduta ─────────
        if (a.condutaResumida != null && a.condutaResumida!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(label: 'O que o profissional fez'),
          PanelCard(
            accent: PanelAccent.info,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(a.condutaResumida!, style: AppTypography.bodyLarge),
          ),
        ],

        const SizedBox(height: AppSpacing.huge),
      ],
    );
  }

  static IconData _tipoIcon(String tipo) {
    switch (tipo) {
      case 'CONSULTA_MEDICA':
        return Icons.medical_information_outlined;
      case 'ENFERMAGEM':
        return Icons.healing_outlined;
      case 'VACINACAO':
        return Icons.vaccines_outlined;
      case 'CURATIVO':
        return Icons.healing;
      case 'ODONTOLOGICO':
        return Icons.brush_outlined;
      case 'PROCEDIMENTO':
        return Icons.medical_services_outlined;
      case 'ACOLHIMENTO':
        return Icons.support_agent;
      default:
        return Icons.health_and_safety_outlined;
    }
  }
}

class _Linha extends StatelessWidget {
  const _Linha({
    required this.icon,
    required this.label,
    required this.valor,
    this.mono = false,
  });

  final IconData icon;
  final String label;
  final String valor;
  final bool mono;

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
                Text(label.toUpperCase(),
                    style: AppTypography.labelInstitucional),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: mono
                      ? AppTypography.data.copyWith(
                          color: AppColors.slate900, fontSize: 16)
                      : AppTypography.bodyLarge,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
