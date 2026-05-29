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

class DossieExamesPage extends ConsumerStatefulWidget {
  const DossieExamesPage({super.key});

  @override
  ConsumerState<DossieExamesPage> createState() => _DossieExamesPageState();
}

class _DossieExamesPageState extends ConsumerState<DossieExamesPage> {
  bool _apenasAlterados = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(examesProvider);

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Meus exames'),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (_, __) => ErrorView(
          title: 'Não conseguimos abrir',
          onRetry: () => ref.invalidate(examesProvider),
        ),
        data: (lista) {
          if (lista.isEmpty) {
            return EmptyView(
              icon: Icons.biotech_outlined,
              title: 'Sem exames registrados',
              message: 'Quando seus exames forem realizados, eles aparecerão aqui.',
            );
          }

          final qtdAlterados = lista.where((e) => e.alterado).length;
          final filtrada = _apenasAlterados
              ? lista.where((e) => e.alterado).toList()
              : lista;

          return RefreshIndicator(
            color: AppColors.blue900,
            onRefresh: () async {
              ref.invalidate(examesProvider);
              await Future.delayed(const Duration(milliseconds: 400));
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // Header com resumo
                _Resumo(total: lista.length, alterados: qtdAlterados),
                const SizedBox(height: AppSpacing.lg),

                // Toggle filtro
                if (qtdAlterados > 0)
                  _ToggleAlterados(
                    value: _apenasAlterados,
                    onChanged: (v) => setState(() => _apenasAlterados = v),
                  ),
                const SizedBox(height: AppSpacing.lg),

                if (filtrada.isEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  EmptyView(
                    icon: Icons.check_circle_outline,
                    title: 'Tudo dentro do normal',
                    message: 'Nenhum exame alterado por aqui.',
                  ),
                ] else ...[
                  SectionHeader(
                    label: _apenasAlterados ? 'Exames alterados' : 'Todos os exames',
                  ),
                  ...filtrada.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _ExameCard(e: e),
                    ),
                  ),
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

class _Resumo extends StatelessWidget {
  const _Resumo({required this.total, required this.alterados});
  final int total;
  final int alterados;

  @override
  Widget build(BuildContext context) {
    final temAlterado = alterados > 0;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(
          color: temAlterado ? AppColors.amber600 : AppColors.emerald700,
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            color: temAlterado ? AppColors.amber600 : AppColors.emerald700,
            alignment: Alignment.center,
            child: Icon(
              temAlterado ? Icons.warning_amber : Icons.check,
              color: AppColors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  temAlterado
                      ? '$alterados ${alterados == 1 ? "exame alterado" : "exames alterados"}'
                      : 'Todos os exames normais',
                  style: AppTypography.titleLarge.copyWith(
                    color: temAlterado
                        ? AppColors.amber900
                        : AppColors.emerald900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  total == 1
                      ? '1 exame no total'
                      : '$total exames no total',
                  style: AppTypography.bodyMedium,
                ),
                if (temAlterado) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Procure sua UBS para conversar sobre os exames alterados.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.amber900,
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

class _ToggleAlterados extends StatelessWidget {
  const _ToggleAlterados({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Container(
          decoration: BoxDecoration(
            color: value ? AppColors.amber50 : AppColors.white,
            border: Border.all(
              color: value ? AppColors.amber600 : AppColors.slate300,
              width: value ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.filter_alt_outlined,
                  color: AppColors.amber600, size: 22),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'Mostrar apenas alterados',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AppColors.amber600,
                activeThumbColor: AppColors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExameCard extends StatelessWidget {
  const _ExameCard({required this.e});
  final Exame e;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat("dd/MM/yyyy", 'pt_BR');
    final alterado = e.alterado;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.slate200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Faixa lateral colorida no topo
          Container(
            height: 4,
            color: alterado ? AppColors.amber600 : AppColors.emerald700,
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Linha topo: ícone + nome do exame
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      color: alterado
                          ? AppColors.amber600
                          : AppColors.emerald700,
                      alignment: Alignment.center,
                      child: Icon(
                        alterado ? Icons.warning_amber : Icons.check,
                        color: AppColors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            e.nome,
                            style: AppTypography.titleLarge,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          StatusBadge(
                            label: alterado ? 'Alterado' : 'Normal',
                            tone: alterado
                                ? StatusTone.warning
                                : StatusTone.success,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Meta info
                _Meta(
                  icon: Icons.calendar_today_outlined,
                  text: 'Realizado em ${fmt.format(e.realizadoEm)}',
                  mono: true,
                ),
                _Meta(
                  icon: Icons.person_outline,
                  text: 'Solicitado por ${e.solicitanteNome}',
                ),

                const SizedBox(height: AppSpacing.md),

                // Resultado em destaque
                Container(
                  decoration: BoxDecoration(
                    color: alterado ? AppColors.amber50 : AppColors.slate50,
                    border: Border(
                      left: BorderSide(
                        color: alterado
                            ? AppColors.amber600
                            : AppColors.emerald700,
                        width: 4,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'RESULTADO',
                        style: AppTypography.labelInstitucional.copyWith(
                          color: alterado
                              ? AppColors.amber900
                              : AppColors.slate700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.resultadoResumo,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.slate900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, this.mono = false});
  final IconData icon;
  final String text;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.slate500),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: mono
                  ? AppTypography.data
                      .copyWith(color: AppColors.slate700, fontSize: 13)
                  : AppTypography.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
