import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/banner.dart';
import '../../../data/models/encaminhamento.dart';
import '../../../providers/auth_controller.dart';
import '../../../providers/banner_controller.dart';
import '../../../providers/encaminhamento_controller.dart';
import '../../../providers/notificacao_controller.dart';
import '../../shared/widgets/widgets.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paciente = ref.watch(authControllerProvider).paciente;
    final encsAtivos = ref.watch(encaminhamentosAtivosProvider);
    final banners = ref.watch(bannersAtivosProvider);
    final notifsAsync = ref.watch(notificacoesListProvider);

    return AppScaffold(
      refresh: () async {
        ref.invalidate(encaminhamentosAtivosProvider);
        ref.invalidate(encaminhamentoAtivoProvider);
        ref.invalidate(bannersAtivosProvider);
        ref.invalidate(notificacoesListProvider);
        ref.invalidate(naoLidasCountProvider);
        await Future.delayed(const Duration(milliseconds: 600));
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FadeIn(child: _Greeting(nome: paciente?.primeiroNome ?? 'Paciente')),
          const SizedBox(height: AppSpacing.lg),

          // --- Carrossel de encaminhamentos ativos ---
          FadeIn(
            delay: const Duration(milliseconds: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EncaminhamentosSectionHeader(encsAtivos: encsAtivos),
                encsAtivos.when(
                  data: (list) {
                    if (list.isEmpty) {
                      return EmptyView(
                        icon: Icons.medical_information_outlined,
                        title: 'Nenhum encaminhamento ativo',
                        message:
                            'Quando sua UBS criar um encaminhamento médico, ele aparecerá aqui.',
                      );
                    }
                    return _EncaminhamentosCarousel(
                      encaminhamentos: list,
                    );
                  },
                  loading: () => const HeroCardSkeleton(),
                  // Em telas de lista, qualquer erro vira "nada por aqui" — não
                  // tira o paciente do app por causa de glitch de rede momentâneo.
                  // Pull-to-refresh tenta de novo silenciosamente.
                  error: (e, _) => EmptyView(
                    icon: Icons.medical_information_outlined,
                    title: 'Nenhum encaminhamento ativo',
                    message:
                        'Quando sua UBS criar um encaminhamento médico, ele aparecerá aqui.',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // --- Banners da SMS ---
          banners.maybeWhen(
            data: (list) => list.isEmpty
                ? const SizedBox.shrink()
                : FadeIn(
                    delay: const Duration(milliseconds: 160),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SectionHeader(label: 'Comunicados da Secretaria'),
                        _BannerCarousel(banners: list),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),

          // --- Ações rápidas ---
          FadeIn(
            delay: const Duration(milliseconds: 240),
            child: SectionHeader(label: 'O que você quer fazer?'),
          ),
          _AcoesGrid(
            encAtivo: encsAtivos.maybeWhen(
                data: (l) => l.isEmpty ? null : l.first, orElse: () => null),
          ),

          const SizedBox(height: AppSpacing.xl),

          // --- Últimas notificações ---
          notifsAsync.maybeWhen(
            data: (list) {
              final recentes = list.take(3).toList();
              if (recentes.isEmpty) return const SizedBox.shrink();
              return FadeIn(
                delay: const Duration(milliseconds: 540),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(
                      label: 'Últimas mensagens',
                      trailing: TextButton(
                        onPressed: () => context.go('/notificacoes'),
                        child: const Text('Ver todas'),
                      ),
                    ),
                    ...recentes.map((n) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _NotificacaoTile(notif: n),
                        )),
                  ],
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),

          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }
}

class _Greeting extends ConsumerWidget {
  const _Greeting({required this.nome});
  final String nome;

  String _saudacao() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paciente = ref.watch(authControllerProvider).paciente;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            color: AppColors.blue900,
            alignment: Alignment.center,
            child: Text(
              paciente?.iniciais ?? '?',
              style: AppTypography.headlineMedium.copyWith(color: AppColors.white),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_saudacao()},',
                  style: AppTypography.bodyMedium,
                ),
                Text(
                  nome,
                  style: AppTypography.displayMedium.copyWith(fontSize: 22),
                  maxLines: 1,
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

class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel({required this.banners});
  final List<SmsBannerModel> banners;

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final _ctrl = PageController(viewportFraction: 0.95);
  int _i = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _i = i),
            itemCount: widget.banners.length,
            itemBuilder: (_, i) {
              final b = widget.banners[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: GestureDetector(
                  onTap: () => context.push('/banner/${b.id}'),
                  child: SmsBanner(
                    titulo: b.titulo,
                    corpo: b.corpo,
                    imagemUrl: b.imagemUrl,
                    tone: _toneFromKey(b.tone),
                    ctaLabel: 'Ver detalhes',
                    onCta: () => context.push('/banner/${b.id}'),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.banners.length, (i) {
            final active = _i == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 24 : 8,
              height: 4,
              color: active ? AppColors.blue900 : AppColors.slate300,
            );
          }),
        ),
      ],
    );
  }

  SmsBannerTone _toneFromKey(String k) {
    switch (k.toUpperCase()) {
      case 'URGENTE':
        return SmsBannerTone.urgente;
      case 'CAMPANHA':
        return SmsBannerTone.campanha;
      case 'ATENCAO':
        return SmsBannerTone.atencao;
      default:
        return SmsBannerTone.info;
    }
  }
}

class _AcoesGrid extends StatelessWidget {
  const _AcoesGrid({required this.encAtivo});
  final dynamic encAtivo;

  @override
  Widget build(BuildContext context) {
    final podeTfd = encAtivo?.podeSolicitarTfd ?? false;
    final cards = <Widget>[
      IconCard(
        icon: Icons.medical_information_outlined,
        title: 'Meu histórico de saúde',
        subtitle: 'Atendimentos, vacinas e exames anteriores',
        accent: IconCardAccent.info,
        onTap: () => context.push('/dossie'),
      ),
      IconCard(
        icon: Icons.directions_bus_filled_outlined,
        title: podeTfd ? 'Pedir vaga no transporte (TFD)' : 'Ver minhas viagens',
        subtitle: podeTfd
            ? 'Reserve uma vaga para sua próxima consulta'
            : 'Acompanhe suas solicitações de TFD',
        accent: IconCardAccent.success,
        iconBg: AppColors.emerald700,
        onTap: () => context.push('/tfd'),
      ),
      IconCard(
        icon: Icons.location_on_outlined,
        title: 'Minha UBS',
        subtitle: 'Endereço, contato e horário',
        accent: IconCardAccent.warning,
        iconBg: AppColors.amber600,
        onTap: () => context.push('/ubs'),
      ),
      IconCard(
        icon: Icons.phone_in_talk_outlined,
        title: 'Falar com a UBS',
        subtitle: 'Telefone, WhatsApp ou email',
        accent: IconCardAccent.critical,
        iconBg: AppColors.red700,
        onTap: () => context.push('/ubs/falar'),
      ),
      IconCard(
        icon: Icons.history,
        title: 'Meus encaminhamentos anteriores',
        subtitle: 'Veja seu histórico completo',
        iconBg: AppColors.slate700,
        onTap: () => context.push('/encaminhamentos'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          FadeIn(
            delay: Duration(milliseconds: 300 + i * 60),
            child: cards[i],
          ),
          if (i < cards.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _NotificacaoTile extends ConsumerWidget {
  const _NotificacaoTile({required this.notif});
  final dynamic notif;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat("dd/MM 'às' HH:mm", 'pt_BR');
    final IconData icon;
    final Color iconBg;
    switch ((notif.tone as String).toUpperCase()) {
      case 'SUCCESS':
        icon = Icons.check_circle_outline;
        iconBg = AppColors.emerald700;
        break;
      case 'WARNING':
        icon = Icons.warning_amber;
        iconBg = AppColors.amber600;
        break;
      case 'CRITICAL':
        icon = Icons.error_outline;
        iconBg = AppColors.red700;
        break;
      default:
        icon = Icons.notifications_active_outlined;
        iconBg = AppColors.blue900;
    }
    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: () async {
          await ref.read(notificacaoControllerProvider.notifier).marcarLida(notif.id);
          if (notif.deepLink != null && context.mounted) {
            context.push(notif.deepLink as String);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.slate200, width: 1),
            color: notif.lida ? AppColors.white : AppColors.blue50,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                color: iconBg,
                alignment: Alignment.center,
                child: Icon(icon, color: AppColors.white, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(notif.titulo, style: AppTypography.titleMedium),
                        ),
                        if (!notif.lida)
                          Container(
                            width: 10,
                            height: 10,
                            color: AppColors.red700,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(notif.corpo,
                        style: AppTypography.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(fmt.format(notif.em),
                        style: AppTypography.bodySmall.copyWith(fontFamily: AppTypography.mono)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// SectionHeader que mostra "Seu encaminhamento" ou "Seus encaminhamentos (N)".
class _EncaminhamentosSectionHeader extends StatelessWidget {
  const _EncaminhamentosSectionHeader({required this.encsAtivos});
  final AsyncValue<List<Encaminhamento>> encsAtivos;

  @override
  Widget build(BuildContext context) {
    final n = encsAtivos.maybeWhen(data: (l) => l.length, orElse: () => 0);
    final label = n <= 1 ? 'Seu encaminhamento' : 'Seus encaminhamentos';
    return SectionHeader(
      label: label,
      trailing: n > 1
          ? Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 2),
              color: AppColors.blue900,
              child: Text(
                '$n ATIVOS',
                style: AppTypography.badge.copyWith(
                  color: AppColors.white,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            )
          : null,
    );
  }
}

/// Carrossel de encaminhamentos ativos (PageView).
/// Swipe horizontal entre os múltiplos encaminhamentos ativos do paciente.
class _EncaminhamentosCarousel extends StatefulWidget {
  const _EncaminhamentosCarousel({super.key, required this.encaminhamentos});
  final List<Encaminhamento> encaminhamentos;

  @override
  State<_EncaminhamentosCarousel> createState() =>
      _EncaminhamentosCarouselState();
}

class _EncaminhamentosCarouselState extends State<_EncaminhamentosCarousel> {
  late final PageController _ctrl;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController(
      viewportFraction:
          widget.encaminhamentos.length == 1 ? 1.0 : 0.94,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unico = widget.encaminhamentos.length == 1;

    if (unico) {
      final e = widget.encaminhamentos.first;
      return StatusHeroCard(
        statusKey: e.status,
        statusLabel: e.statusLabel,
        mensagem: e.mensagemPaciente,
        protocolo: e.protocolo,
        especialidade: e.especialidade,
        dataConsulta: e.dataAgendamento,
        localConsulta: e.localAgendamento,
        prioridade: e.prioridade,
        onTap: () => context.push('/encaminhamento/${e.id}'),
        ctaLabel: 'Ver detalhes',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          // Altura suficiente pra acomodar o card mais "alto" (com data e local)
          height: 520,
          child: PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _i = i),
            itemCount: widget.encaminhamentos.length,
            itemBuilder: (_, i) {
              final e = widget.encaminhamentos[i];
              return Padding(
                padding: EdgeInsets.only(
                  right: i == widget.encaminhamentos.length - 1 ? 0 : AppSpacing.sm,
                ),
                child: StatusHeroCard(
                  statusKey: e.status,
                  statusLabel: e.statusLabel,
                  mensagem: e.mensagemPaciente,
                  protocolo: e.protocolo,
                  especialidade: e.especialidade,
                  dataConsulta: e.dataAgendamento,
                  localConsulta: e.localAgendamento,
                  prioridade: e.prioridade,
                  onTap: () => context.push('/encaminhamento/${e.id}'),
                  ctaLabel: 'Ver detalhes',
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Indicadores de página
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.encaminhamentos.length, (i) {
            final active = _i == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 28 : 8,
              height: 6,
              color: active ? AppColors.blue900 : AppColors.slate300,
            );
          }),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Dica "deslize pra ver outros"
        Center(
          child: Text(
            'Deslize para ver os outros encaminhamentos',
            style: AppTypography.bodySmall.copyWith(color: AppColors.slate500),
          ),
        ),
      ],
    );
  }
}
