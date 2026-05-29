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

class DossieAtendimentosPage extends ConsumerStatefulWidget {
  const DossieAtendimentosPage({super.key});

  @override
  ConsumerState<DossieAtendimentosPage> createState() =>
      _DossieAtendimentosPageState();
}

class _DossieAtendimentosPageState extends ConsumerState<DossieAtendimentosPage> {
  String _filtroTipo = 'TODOS';

  static const _filtros = [
    ('TODOS', 'Todos'),
    ('CONSULTA', 'Consultas'),
    ('EMERGENCIA', 'Emergências'),
    ('EXAME', 'Exames'),
    ('VACINACAO', 'Vacinas'),
    ('RETORNO', 'Retornos'),
  ];

  ({IconData icon, Color bg, String label}) _tipo(String t) {
    switch (t) {
      case 'EMERGENCIA':
        return (
          icon: Icons.local_hospital_outlined,
          bg: AppColors.red700,
          label: 'Emergência'
        );
      case 'EXAME':
        return (
          icon: Icons.biotech_outlined,
          bg: AppColors.amber600,
          label: 'Exame'
        );
      case 'VACINACAO':
        return (
          icon: Icons.vaccines,
          bg: AppColors.emerald700,
          label: 'Vacinação'
        );
      case 'RETORNO':
        return (
          icon: Icons.refresh,
          bg: AppColors.slate700,
          label: 'Retorno'
        );
      case 'CONSULTA':
      default:
        return (
          icon: Icons.medical_information_outlined,
          bg: AppColors.blue900,
          label: 'Consulta'
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(atendimentosProvider);

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Atendimentos'),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (_, __) => ErrorView(
          title: 'Não conseguimos abrir',
          onRetry: () => ref.invalidate(atendimentosProvider),
        ),
        data: (lista) {
          final filtrada = _filtroTipo == 'TODOS'
              ? lista
              : lista.where((a) => a.tipo == _filtroTipo).toList();

          return RefreshIndicator(
            color: AppColors.blue900,
            onRefresh: () async {
              ref.invalidate(atendimentosProvider);
              await Future.delayed(const Duration(milliseconds: 400));
            },
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Filtros horizontais ----------------------------------
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${lista.length} ${lista.length == 1 ? "atendimento" : "atendimentos"} no total',
                        style: AppTypography.labelInstitucional,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filtros.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (_, i) {
                            final (key, label) = _filtros[i];
                            final selected = _filtroTipo == key;
                            return _Chip(
                              label: label,
                              selected: selected,
                              onTap: () => setState(() => _filtroTipo = key),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                if (filtrada.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: EmptyView(
                      icon: Icons.event_busy,
                      title: 'Nenhum atendimento aqui',
                      message: 'Tente outro filtro acima.',
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.huge),
                    child: Column(
                      children: [
                        for (var i = 0; i < filtrada.length; i++) ...[
                          _AtendimentoCard(
                            a: filtrada[i],
                            tipo: _tipo(filtrada[i].tipo),
                          ),
                          if (i < filtrada.length - 1)
                            const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.blue900 : AppColors.white,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: selected ? AppColors.blue900 : AppColors.white,
            border: Border.all(
              color: selected ? AppColors.blue900 : AppColors.slate300,
              width: selected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.titleMedium.copyWith(
              color: selected ? AppColors.white : AppColors.slate900,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _AtendimentoCard extends StatelessWidget {
  const _AtendimentoCard({required this.a, required this.tipo});
  final Atendimento a;
  final ({IconData icon, Color bg, String label}) tipo;

  @override
  Widget build(BuildContext context) {
    final fmtData = DateFormat("dd 'de' MMMM 'de' yyyy", 'pt_BR');
    final fmtDia = DateFormat('dd', 'pt_BR');
    final fmtMes = DateFormat('MMM', 'pt_BR');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.slate200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header com data destacada + tipo
          Container(
            color: AppColors.slate50,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Bloco da data
                Container(
                  width: 56,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.slate300, width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      Text(
                        fmtDia.format(a.data),
                        style: AppTypography.metric.copyWith(
                          fontSize: 22,
                          color: AppColors.slate900,
                        ),
                      ),
                      Text(
                        fmtMes.format(a.data).toUpperCase().replaceAll('.', ''),
                        style: AppTypography.labelInstitucional,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            color: tipo.bg,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(tipo.icon,
                                    size: 12, color: AppColors.white),
                                const SizedBox(width: 4),
                                Text(
                                  tipo.label.toUpperCase(),
                                  style: AppTypography.badge.copyWith(
                                    color: AppColors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fmtData.format(a.data),
                        style: AppTypography.bodySmall.copyWith(
                          fontFamily: AppTypography.mono,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profissional
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.person_outline,
                        size: 20, color: AppColors.slate500),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.profissionalNome,
                            style: AppTypography.titleLarge,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            a.profissionalEspecialidade,
                            style: AppTypography.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Local
                _Linha(
                  icon: Icons.location_on_outlined,
                  text: a.localNome,
                ),

                if (a.queixaPrincipal != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _Bloco(
                    label: 'Motivo da consulta',
                    valor: a.queixaPrincipal!,
                  ),
                ],

                if (a.cid10 != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _Bloco(
                    label: 'CID-10',
                    valor:
                        '${a.cid10}${a.cid10Descricao != null ? " — ${a.cid10Descricao}" : ""}',
                    mono: true,
                  ),
                ],

                if (a.condutaResumida != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.blue50,
                      border: const Border(
                        left: BorderSide(color: AppColors.blue900, width: 4),
                      ),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CONDUTA',
                          style: AppTypography.labelInstitucional
                              .copyWith(color: AppColors.blue900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          a.condutaResumida!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.slate900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.slate500),
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
    );
  }
}

class _Bloco extends StatelessWidget {
  const _Bloco({required this.label, required this.valor, this.mono = false});
  final String label;
  final String valor;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: AppTypography.labelInstitucional),
        const SizedBox(height: 2),
        Text(
          valor,
          style: mono
              ? AppTypography.data.copyWith(color: AppColors.slate900)
              : AppTypography.bodyMedium
                  .copyWith(color: AppColors.slate900),
        ),
      ],
    );
  }
}
