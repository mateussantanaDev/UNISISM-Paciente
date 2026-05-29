import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/tfd_controller.dart';
import '../../shared/widgets/widgets.dart';

class TfdListPage extends ConsumerStatefulWidget {
  const TfdListPage({super.key});

  @override
  ConsumerState<TfdListPage> createState() => _TfdListPageState();
}

class _TfdListPageState extends ConsumerState<TfdListPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Transporte (TFD)'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Viagens disponíveis'),
            Tab(text: 'Minhas solicitações'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [_Disponiveis(), _Minhas()],
      ),
    );
  }
}

class _Disponiveis extends ConsumerWidget {
  const _Disponiveis();

  String _formatData(DateTime d) =>
      DateFormat("EEEE, dd/MM 'às' HH'h'", 'pt_BR').format(d);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(viagensTfdProvider);
    return async.when(
      loading: () => const LoadingView(),
      error: (_, __) => ErrorView(
        title: 'Não conseguimos abrir',
        onRetry: () => ref.invalidate(viagensTfdProvider),
      ),
      data: (list) {
        if (list.isEmpty) {
          return EmptyView(
            icon: Icons.directions_bus,
            title: 'Nenhuma viagem programada',
            message: 'A Secretaria divulgará novas viagens em breve.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(viagensTfdProvider);
            await Future.delayed(const Duration(milliseconds: 400));
          },
          color: AppColors.blue900,
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) {
              final v = list[i];
              return Material(
                color: AppColors.white,
                child: InkWell(
                  onTap: v.temVaga
                      ? () => context.push('/tfd/solicitar/${v.id}')
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border.all(
                        color: v.temVaga ? AppColors.slate200 : AppColors.slate300,
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              color: v.temVaga
                                  ? AppColors.emerald700
                                  : AppColors.slate400,
                              alignment: Alignment.center,
                              child: const Icon(Icons.directions_bus,
                                  color: AppColors.white, size: 28),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${v.destinoCidade} · ${v.destinoUf}',
                                    style: AppTypography.titleLarge,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    v.destinoLocal,
                                    style: AppTypography.bodyMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _Linha(
                          icon: Icons.calendar_today_outlined,
                          text: _formatData(v.dataPartida),
                        ),
                        const SizedBox(height: 4),
                        _Linha(
                          icon: Icons.location_on_outlined,
                          text: 'Embarque: ${v.localEmbarque}',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _Vagas(v: v),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
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
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: AppColors.slate600),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.slate900),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Vagas extends StatelessWidget {
  const _Vagas({required this.v});
  final dynamic v;

  @override
  Widget build(BuildContext context) {
    final disp = v.vagasDisponiveis as int;
    final total = v.vagasTotal as int;
    final temVaga = disp > 0;
    final pct = (v.ocupacaoPct as double).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                temVaga ? '$disp vaga${disp == 1 ? "" : "s"} disponível${disp == 1 ? "" : "is"}' : 'Sem vagas',
                style: AppTypography.titleMedium.copyWith(
                  color: temVaga ? AppColors.emerald800 : AppColors.red800,
                ),
              ),
            ),
            Text('$total no total',
                style: AppTypography.labelInstitucional),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Stack(
          children: [
            Container(height: 6, color: AppColors.slate200),
            FractionallySizedBox(
              widthFactor: pct,
              child: Container(height: 6, color: temVaga ? AppColors.emerald700 : AppColors.red700),
            ),
          ],
        ),
        if (temVaga) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            color: AppColors.blue900,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle_outline, color: AppColors.white, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text('Pedir vaga', style: AppTypography.button),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Minhas extends ConsumerWidget {
  const _Minhas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(solicitacoesTfdProvider);
    final fmt = DateFormat("dd/MM/yyyy", 'pt_BR');
    return async.when(
      loading: () => const LoadingView(),
      error: (_, __) => ErrorView(
        title: 'Não conseguimos abrir',
        onRetry: () => ref.invalidate(solicitacoesTfdProvider),
      ),
      data: (list) {
        if (list.isEmpty) {
          return EmptyView(
            icon: Icons.airline_seat_recline_normal_outlined,
            title: 'Você ainda não pediu nenhuma vaga',
            message: 'Toque em uma viagem disponível para pedir um assento.',
          );
        }
        return RefreshIndicator(
          color: AppColors.blue900,
          onRefresh: () async {
            ref.invalidate(solicitacoesTfdProvider);
            await Future.delayed(const Duration(milliseconds: 400));
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) {
              final s = list[i];
              final tone = switch (s.status) {
                'APROVADA' => StatusTone.success,
                'RECUSADA' || 'CANCELADA' => StatusTone.critical,
                'AGUARDANDO' => StatusTone.warning,
                'EMBARCADA' => StatusTone.info,
                _ => StatusTone.neutral,
              };
              return Material(
                color: AppColors.white,
                child: InkWell(
                  onTap: () => context.push('/tfd/solicitacao/${s.id}'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border.all(color: AppColors.slate200, width: 1),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${s.viagem.destinoCidade} · ${s.viagem.destinoUf}',
                                style: AppTypography.titleLarge,
                              ),
                            ),
                            StatusBadge(label: s.statusLabel, tone: tone),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(s.viagem.destinoLocal, style: AppTypography.bodyMedium),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.slate600),
                            const SizedBox(width: 6),
                            Text(fmt.format(s.viagem.dataPartida), style: AppTypography.data.copyWith(color: AppColors.slate900)),
                            const SizedBox(width: AppSpacing.md),
                            const Icon(Icons.access_time, size: 16, color: AppColors.slate600),
                            const SizedBox(width: 6),
                            Text(s.viagem.horaPartida, style: AppTypography.data.copyWith(color: AppColors.slate900)),
                          ],
                        ),
                        if (s.numeroAssento != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            color: AppColors.emerald50,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                const Icon(Icons.airline_seat_recline_normal,
                                    color: AppColors.emerald700, size: 22),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Seu assento: ${s.numeroAssento}',
                                  style: AppTypography.titleLarge.copyWith(color: AppColors.emerald900),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
