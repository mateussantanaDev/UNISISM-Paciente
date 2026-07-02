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

class DossieVacinacoesPage extends ConsumerWidget {
  const DossieVacinacoesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(vacinacoesProvider);

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Minhas vacinas'),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (_, __) => const EmptyView(
          icon: Icons.vaccines_outlined,
          title: 'Sua carteirinha está vazia',
          message:
              'Quando você tomar uma vacina na rede pública, ela aparece aqui.',
        ),
        data: (lista) {
          if (lista.isEmpty) {
            return EmptyView(
              icon: Icons.vaccines,
              title: 'Sem vacinas registradas',
              message: 'Procure sua UBS para atualizar sua carteira de vacinação.',
            );
          }

          return RefreshIndicator(
            color: AppColors.blue900,
            onRefresh: () async {
              ref.invalidate(vacinacoesProvider);
              await Future.delayed(const Duration(milliseconds: 400));
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // Header com total
                _ResumoCarteira(total: lista.length),
                const SizedBox(height: AppSpacing.xl),

                SectionHeader(label: 'Histórico de vacinação'),
                ...lista.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _VacinaCard(v: e.value, index: e.key),
                    )),
                const SizedBox(height: AppSpacing.huge),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ResumoCarteira extends StatelessWidget {
  const _ResumoCarteira({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.emerald700,
        border: Border.all(color: AppColors.emerald700, width: 2),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            color: AppColors.white,
            alignment: Alignment.center,
            child: const Icon(Icons.vaccines,
                color: AppColors.emerald700, size: 36),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CARTEIRA DE VACINAÇÃO',
                  style: AppTypography.labelInstitucional
                      .copyWith(color: const Color(0xFFA7F3D0)),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$total',
                      style: AppTypography.metric.copyWith(
                        color: AppColors.white,
                        fontSize: 36,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      total == 1 ? 'vacina aplicada' : 'vacinas aplicadas',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VacinaCard extends StatelessWidget {
  const _VacinaCard({required this.v, required this.index});
  final Vacinacao v;
  final int index;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat("dd 'de' MMMM 'de' yyyy", 'pt_BR');
    final diasAtras = DateTime.now().difference(v.aplicadaEm).inDays;

    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: () => context.push('/dossie/vacinacao/${v.id}'),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.slate200, width: 1),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone check verde
          Container(
            width: 52,
            height: 52,
            color: AppColors.emerald700,
            alignment: Alignment.center,
            child: const Icon(Icons.check, color: AppColors.white, size: 30),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  v.vacina,
                  style: AppTypography.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.blue50,
                    border: Border.all(color: AppColors.blue700, width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  child: Text(
                    v.dose.toUpperCase(),
                    style: AppTypography.badge.copyWith(
                      color: AppColors.blue900,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _Linha(
                  icon: Icons.calendar_today_outlined,
                  text: fmt.format(v.aplicadaEm),
                ),
                _Linha(
                  icon: Icons.schedule,
                  text: _humanDiff(diasAtras),
                  textColor: AppColors.slate600,
                ),
                _Linha(
                  icon: Icons.location_on_outlined,
                  text: v.localAplicacao,
                ),
                if (v.aplicadorNome != null && v.aplicadorNome!.isNotEmpty)
                  _Linha(
                    icon: Icons.person_outline,
                    text: 'Aplicado por ${v.aplicadorNome!}',
                  ),
                if (v.via != null && v.via!.isNotEmpty)
                  _Linha(
                    icon: Icons.colorize_outlined,
                    text: 'Via ${_viaLabel(v.via!)}',
                  ),
                if (v.fabricante != null && v.fabricante!.isNotEmpty)
                  _Linha(
                    icon: Icons.factory_outlined,
                    text: v.fabricante!,
                  ),
                if (v.lote != null && v.lote!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: AppColors.slate50,
                    child: Text(
                      'LOTE ${v.lote}',
                      style: AppTypography.labelInstitucional.copyWith(
                        fontFamily: AppTypography.mono,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  static String _viaLabel(String via) {
    switch (via.toUpperCase()) {
      case 'INTRAMUSCULAR':
        return 'intramuscular';
      case 'SUBCUTANEA':
        return 'subcutânea';
      case 'INTRADERMICA':
        return 'intradérmica';
      case 'ORAL':
        return 'oral';
      case 'INTRANASAL':
        return 'intranasal';
      default:
        return via.toLowerCase();
    }
  }

  String _humanDiff(int dias) {
    if (dias < 1) return 'Aplicada hoje';
    if (dias == 1) return 'Aplicada há 1 dia';
    if (dias < 30) return 'Aplicada há $dias dias';
    if (dias < 365) {
      final meses = (dias / 30).round();
      return 'Aplicada há $meses ${meses == 1 ? "mês" : "meses"}';
    }
    final anos = (dias / 365).round();
    return 'Aplicada há $anos ${anos == 1 ? "ano" : "anos"}';
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.icon, required this.text, this.textColor});
  final IconData icon;
  final String text;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.slate500),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 13,
                color: textColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
