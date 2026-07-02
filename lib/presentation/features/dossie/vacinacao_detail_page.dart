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

/// Detalhe de uma vacina aplicada.
class VacinacaoDetailPage extends ConsumerWidget {
  const VacinacaoDetailPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(vacinacaoByIdProvider(id));
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop()),
        title: const Text('Vacina'),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (_, __) => const EmptyView(
          icon: Icons.search_off,
          title: 'Vacina não encontrada',
          message: 'Este registro não está mais disponível.',
        ),
        data: (v) => _Body(v: v),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.v});
  final Vacinacao v;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat("EEEE, dd 'de' MMMM 'de' yyyy", 'pt_BR');
    final diasAtras = DateTime.now().difference(v.aplicadaEm).inDays;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // ───────── Hero ─────────
        Container(
          decoration: BoxDecoration(
            color: AppColors.emerald700,
            border: Border.all(color: AppColors.emerald700, width: 2),
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
                child: const Icon(Icons.vaccines,
                    color: AppColors.emerald700, size: 30),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'VACINA APLICADA',
                      style: AppTypography.labelInstitucional.copyWith(
                        color: const Color(0xFFA7F3D0),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      v.vacina,
                      style: AppTypography.titleLarge
                          .copyWith(color: AppColors.white),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF064E3B),
                      ),
                      child: Text(
                        v.dose.toUpperCase(),
                        style: AppTypography.badge.copyWith(
                          color: const Color(0xFFA7F3D0),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // ───────── Aplicação ─────────
        SectionHeader(label: 'Quando e onde'),
        PanelCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Linha(
                icon: Icons.calendar_today_outlined,
                label: 'Data da aplicação',
                valor: fmt.format(v.aplicadaEm),
                mono: true,
              ),
              const Divider(),
              _Linha(
                icon: Icons.schedule,
                label: 'Há quanto tempo',
                valor: _humanDiff(diasAtras),
              ),
              const Divider(),
              _Linha(
                icon: Icons.location_on_outlined,
                label: 'Local da aplicação',
                valor: v.localAplicacao,
              ),
              if (v.aplicadorNome != null && v.aplicadorNome!.isNotEmpty) ...[
                const Divider(),
                _Linha(
                  icon: Icons.person_outline,
                  label: 'Profissional que aplicou',
                  valor: v.aplicadorNome!,
                ),
              ],
            ],
          ),
        ),

        // ───────── Dados técnicos ─────────
        if (v.lote != null ||
            v.fabricante != null ||
            v.via != null) ...[
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(label: 'Dados do imunobiológico'),
          PanelCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (v.lote != null && v.lote!.isNotEmpty) ...[
                  _Linha(
                    icon: Icons.qr_code_2,
                    label: 'Lote',
                    valor: v.lote!,
                    mono: true,
                  ),
                ],
                if (v.fabricante != null && v.fabricante!.isNotEmpty) ...[
                  const Divider(),
                  _Linha(
                    icon: Icons.factory_outlined,
                    label: 'Fabricante',
                    valor: v.fabricante!,
                  ),
                ],
                if (v.via != null && v.via!.isNotEmpty) ...[
                  const Divider(),
                  _Linha(
                    icon: Icons.colorize_outlined,
                    label: 'Via de administração',
                    valor: _viaLabel(v.via!),
                  ),
                ],
              ],
            ),
          ),
        ],

        // ───────── Info útil ─────────
        const SizedBox(height: AppSpacing.xl),
        PanelCard(
          accent: PanelAccent.info,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.blue900, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Em caso de dúvida sobre essa vacina ou reação tardia, '
                  'procure a UBS onde foi aplicada com o número do lote acima.',
                  style: AppTypography.bodyMedium,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.huge),
      ],
    );
  }

  static String _viaLabel(String via) {
    switch (via.toUpperCase()) {
      case 'INTRAMUSCULAR':
        return 'Intramuscular';
      case 'SUBCUTANEA':
        return 'Subcutânea';
      case 'INTRADERMICA':
        return 'Intradérmica';
      case 'ORAL':
        return 'Oral';
      case 'INTRANASAL':
        return 'Intranasal';
      default:
        return via;
    }
  }

  static String _humanDiff(int dias) {
    if (dias < 1) return 'Aplicada hoje';
    if (dias == 1) return 'Há 1 dia';
    if (dias < 30) return 'Há $dias dias';
    if (dias < 365) {
      final meses = (dias / 30).round();
      return 'Há $meses ${meses == 1 ? "mês" : "meses"}';
    }
    final anos = (dias / 365).round();
    return 'Há $anos ${anos == 1 ? "ano" : "anos"}';
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
