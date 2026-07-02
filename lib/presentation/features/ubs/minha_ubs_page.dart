import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/ubs.dart';
import '../../../providers/providers.dart';
import '../../shared/widgets/widgets.dart';

class MinhaUbsPage extends ConsumerWidget {
  const MinhaUbsPage({super.key});

  Future<void> _abrirMaps(double lat, double lng, String nome) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$nome');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _ligar(String telefone) async {
    final uri = Uri.parse('tel:${telefone.replaceAll(RegExp(r'\D'), '')}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(minhaUbsProvider);

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Minha UBS'),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (_, __) => const EmptyView(
          icon: Icons.local_hospital_outlined,
          title: 'UBS ainda sem informações',
          message:
              'Quando a Secretaria preencher os dados da sua UBS, eles aparecem aqui.',
        ),
        data: (u) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Hero / cabeçalho institucional
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
                    child: const Icon(Icons.home_work,
                        color: AppColors.blue900, size: 30),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SUA UNIDADE DE SAÚDE',
                          style: AppTypography.labelInstitucional
                              .copyWith(color: const Color(0xFF93C5FD)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          u.nome,
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.white,
                            height: 1.2,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          color: const Color(0xFF172554),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time,
                                  size: 12, color: Color(0xFF93C5FD)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  u.horarioFuncionamento,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: const Color(0xFF93C5FD),
                                    fontFamily: AppTypography.mono,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
            ),

            const SizedBox(height: AppSpacing.xl),

            // Ações rápidas — grid 3 colunas com aspect ratio fixo
            // pra garantir que "Como chegar" caiba em telas estreitas
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.92,
              children: [
                if (u.telefone != null && u.telefone!.isNotEmpty)
                  _BigActionTile(
                    icon: Icons.call,
                    label: 'Ligar',
                    bg: AppColors.emerald700,
                    onTap: () => _ligar(u.telefone!),
                  ),
                if (u.whatsapp != null)
                  _BigActionTile(
                    icon: Icons.chat_bubble_outline,
                    label: 'WhatsApp',
                    bg: const Color(0xFF25D366),
                    onTap: () async {
                      final uri = Uri.parse('https://wa.me/${u.whatsapp}');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                if (u.latitude != null && u.longitude != null)
                  _BigActionTile(
                    icon: Icons.directions,
                    label: 'Chegar',
                    bg: AppColors.amber600,
                    onTap: () => _abrirMaps(u.latitude!, u.longitude!, u.nome),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),
            SectionHeader(label: 'Endereço'),
            PanelCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _line(Icons.location_on_outlined,
                      u.endereco ?? 'Endereço não cadastrado'),
                  _line(Icons.map_outlined,
                      '${u.bairro ?? ''}${u.bairro != null ? ' · ' : ''}${u.cidade}/${u.uf}'),
                  if (u.cep != null && u.cep!.isNotEmpty)
                    _line(Icons.markunread_mailbox_outlined, u.cep!, mono: true),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
            SectionHeader(label: 'Horário de atendimento'),
            PanelCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: u.temHorariosEstruturados
                  ? _HorariosTabela(horarios: u.horarios!)
                  : Row(
                      children: [
                        const Icon(Icons.access_time,
                            color: AppColors.blue900, size: 24),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(u.horarioFuncionamento,
                              style: AppTypography.bodyLarge),
                        ),
                      ],
                    ),
            ),

            if (u.observacoes != null) ...[
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(label: 'Serviços e observações'),
              InfoBlock(
                message: u.observacoes!,
                tone: InfoTone.info,
                icon: Icons.info_outline,
              ),
            ],

            if (u.coordenadoresNomes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(label: 'Equipe responsável'),
              PanelCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: u.coordenadoresNomes
                      .map((c) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline,
                                    size: 20, color: AppColors.slate600),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(child: Text(c, style: AppTypography.bodyMedium)),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Falar com a UBS',
              icon: Icons.support_agent,
              onPressed: () => context.push('/ubs/falar'),
            ),
            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
    );
  }

  Widget _line(IconData icon, String text, {bool mono = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.slate600),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                text,
                style: mono
                    ? AppTypography.data.copyWith(color: AppColors.slate900, fontSize: 16)
                    : AppTypography.bodyLarge,
              ),
            ),
          ],
        ),
      );
}

class _BigActionTile extends StatelessWidget {
  const _BigActionTile({
    required this.icon,
    required this.label,
    required this.bg,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  // continua no build abaixo
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.slate200, width: 1),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                color: bg,
                alignment: Alignment.center,
                child: Icon(icon, color: AppColors.white, size: 22),
              ),
              const SizedBox(height: AppSpacing.sm),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: AppTypography.titleMedium,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renderiza tabela compacta dos horários estruturados.
/// Backend pode mandar 7 dias ou menos — quem não vier é "Fechado".
class _HorariosTabela extends StatelessWidget {
  const _HorariosTabela({required this.horarios});
  final Map<String, HorarioDia?> horarios;

  static const _dias = [
    ('segunda', 'Segunda'),
    ('terca', 'Terça'),
    ('quarta', 'Quarta'),
    ('quinta', 'Quinta'),
    ('sexta', 'Sexta'),
    ('sabado', 'Sábado'),
    ('domingo', 'Domingo'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _dias.map((d) {
        final h = horarios[d.$1];
        final aberto = h != null;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  d.$2,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: aberto ? AppColors.slate900 : AppColors.slate500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  aberto ? h.formatado : 'Fechado',
                  style: AppTypography.bodyMedium.copyWith(
                    color: aberto ? AppColors.slate700 : AppColors.slate500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
