import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';

class PreferenciasNotificacaoPage extends ConsumerStatefulWidget {
  const PreferenciasNotificacaoPage({super.key});

  @override
  ConsumerState<PreferenciasNotificacaoPage> createState() =>
      _PreferenciasNotificacaoPageState();
}

class _PreferenciasNotificacaoPageState
    extends ConsumerState<PreferenciasNotificacaoPage> {
  bool _encaminhamento = true;
  bool _tfd = true;
  bool _campanhas = true;
  bool _alertas = true;
  bool _vibrar = true;
  bool _som = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Avisos do app'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          InfoBlock(
            message:
                'Escolha quais avisos você quer receber. Alertas urgentes da Secretaria de Saúde sempre são enviados.',
            tone: InfoTone.info,
            icon: Icons.notifications_active_outlined,
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(label: 'Tipos de aviso'),
          _Pref(
            icon: Icons.medical_information_outlined,
            iconBg: AppColors.blue900,
            titulo: 'Meu encaminhamento',
            descricao: 'Atualizações de status, agendamento, pendências',
            value: _encaminhamento,
            onChanged: (v) => setState(() => _encaminhamento = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Pref(
            icon: Icons.directions_bus_filled_outlined,
            iconBg: AppColors.emerald700,
            titulo: 'TFD — Transporte',
            descricao: 'Confirmações, recusas e lembretes de viagem',
            value: _tfd,
            onChanged: (v) => setState(() => _tfd = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Pref(
            icon: Icons.campaign_outlined,
            iconBg: AppColors.amber600,
            titulo: 'Campanhas da Secretaria',
            descricao: 'Vacinação, mutirões, novos serviços',
            value: _campanhas,
            onChanged: (v) => setState(() => _campanhas = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Pref(
            icon: Icons.warning_amber_outlined,
            iconBg: AppColors.red700,
            titulo: 'Alertas urgentes',
            descricao: 'Surtos, epidemias, riscos à saúde — sempre ativo',
            value: _alertas,
            onChanged: null, // bloqueado
            travado: true,
          ),

          const SizedBox(height: AppSpacing.xl),
          SectionHeader(label: 'Como você quer ser avisado'),
          _Pref(
            icon: Icons.volume_up_outlined,
            iconBg: AppColors.slate700,
            titulo: 'Som',
            descricao: 'Tocar som ao receber',
            value: _som,
            onChanged: (v) => setState(() => _som = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Pref(
            icon: Icons.vibration,
            iconBg: AppColors.slate700,
            titulo: 'Vibração',
            descricao: 'Vibrar ao receber',
            value: _vibrar,
            onChanged: (v) => setState(() => _vibrar = v),
          ),

          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Salvar preferências',
            icon: Icons.save_outlined,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preferências salvas')),
              );
              context.pop();
            },
          ),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }
}

class _Pref extends StatelessWidget {
  const _Pref({
    required this.icon,
    required this.iconBg,
    required this.titulo,
    required this.descricao,
    required this.value,
    required this.onChanged,
    this.travado = false,
  });
  final IconData icon;
  final Color iconBg;
  final String titulo;
  final String descricao;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool travado;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(
          color: value && !travado ? AppColors.blue900 : AppColors.slate200,
          width: value && !travado ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            color: iconBg,
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.white, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(titulo, style: AppTypography.titleMedium)),
                    if (travado)
                      const Icon(Icons.lock,
                          size: 16, color: AppColors.slate500),
                  ],
                ),
                const SizedBox(height: 2),
                Text(descricao, style: AppTypography.bodySmall),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.blue900,
            activeThumbColor: AppColors.white,
          ),
        ],
      ),
    );
  }
}
