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

/// Detalhe de um exame realizado.
class ExameDetailPage extends ConsumerWidget {
  const ExameDetailPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(exameByIdProvider(id));
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop()),
        title: const Text('Exame'),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (_, __) => const EmptyView(
          icon: Icons.search_off,
          title: 'Exame não encontrado',
          message: 'Este registro não está mais disponível.',
        ),
        data: (e) => _Body(e: e),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.e});
  final Exame e;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat("EEEE, dd 'de' MMMM 'de' yyyy", 'pt_BR');
    final tone = _toneFromStatus(e.resultadoStatus);
    final destacar = e.alterado;
    final cor = destacar ? AppColors.amber600 : AppColors.emerald700;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // ───────── Hero ─────────
        Container(
          decoration: BoxDecoration(
            color: cor,
            border: Border.all(color: cor, width: 2),
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
                child: Icon(
                  destacar ? Icons.warning_amber : Icons.science_outlined,
                  color: cor,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'EXAME',
                      style: AppTypography.labelInstitucional
                          .copyWith(color: AppColors.white.withValues(alpha: .7)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      e.nome,
                      style: AppTypography.titleLarge
                          .copyWith(color: AppColors.white),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    StatusBadge(
                      label: _statusLabel(e.resultadoStatus),
                      tone: tone,
                      size: StatusBadgeSize.medium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // ───────── Resultado em destaque ─────────
        SectionHeader(label: 'Resultado'),
        PanelCard(
          accent: destacar ? PanelAccent.warning : PanelAccent.success,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STATUS',
                style: AppTypography.labelInstitucional,
              ),
              const SizedBox(height: 4),
              Text(
                _statusLabel(e.resultadoStatus),
                style: AppTypography.titleLarge.copyWith(
                  color: destacar ? AppColors.amber900 : AppColors.emerald700,
                ),
              ),
              if (e.resultadoResumo != null &&
                  e.resultadoResumo!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(height: 1, color: AppColors.slate100),
                const SizedBox(height: AppSpacing.md),
                Text('LAUDO RESUMIDO',
                    style: AppTypography.labelInstitucional),
                const SizedBox(height: 4),
                Text(e.resultadoResumo!, style: AppTypography.bodyLarge),
              ],
            ],
          ),
        ),

        // ───────── Quando e onde ─────────
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(label: 'Quando e onde'),
        PanelCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Linha(
                icon: Icons.calendar_today_outlined,
                label: 'Data',
                valor: fmt.format(e.realizadoEm),
                mono: true,
              ),
              const Divider(),
              _Linha(
                icon: Icons.person_outline,
                label: 'Solicitante',
                valor: e.solicitanteNome,
              ),
              if (e.unidadeExecutora != null &&
                  e.unidadeExecutora!.isNotEmpty) ...[
                const Divider(),
                _Linha(
                  icon: Icons.local_hospital_outlined,
                  label: 'Onde foi realizado',
                  valor: e.unidadeExecutora!,
                ),
              ],
              if (e.categoria != null && e.categoria!.isNotEmpty) ...[
                const Divider(),
                _Linha(
                  icon: Icons.category_outlined,
                  label: 'Categoria',
                  valor: _categoriaLabel(e.categoria!),
                ),
              ],
            ],
          ),
        ),

        // ───────── Observações ─────────
        if (e.observacoes != null && e.observacoes!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(label: 'Observações'),
          PanelCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(e.observacoes!, style: AppTypography.bodyLarge),
          ),
        ],

        // ───────── Aviso quando alterado ─────────
        if (destacar) ...[
          const SizedBox(height: AppSpacing.xl),
          PanelCard(
            accent: PanelAccent.warning,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.amber600, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Este exame foi marcado como alterado. Procure sua UBS '
                    'para discutir o resultado com um profissional.',
                    style: AppTypography.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.huge),
      ],
    );
  }

  static String _statusLabel(String s) {
    switch (s.toUpperCase()) {
      case 'NORMAL':
        return 'Normal';
      case 'ALTERADO':
        return 'Alterado';
      case 'CRITICO':
        return 'Crítico';
      case 'PENDENTE':
        return 'Aguardando resultado';
      default:
        return s;
    }
  }

  static StatusTone _toneFromStatus(String s) {
    switch (s.toUpperCase()) {
      case 'CRITICO':
        return StatusTone.critical;
      case 'ALTERADO':
        return StatusTone.warning;
      case 'NORMAL':
        return StatusTone.success;
      case 'PENDENTE':
      default:
        return StatusTone.neutral;
    }
  }

  static String _categoriaLabel(String c) {
    switch (c.toUpperCase()) {
      case 'LABORATORIAL':
        return 'Laboratorial';
      case 'IMAGEM':
        return 'Imagem';
      case 'FUNCIONAL':
        return 'Funcional';
      case 'OUTROS':
        return 'Outros';
      default:
        return c;
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
