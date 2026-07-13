import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/encaminhamento_controller.dart';
import '../../../providers/tfd_controller.dart';
import '../../shared/widgets/widgets.dart';

class TfdSolicitarPage extends ConsumerStatefulWidget {
  const TfdSolicitarPage({super.key, required this.viagemId});
  final String viagemId;

  @override
  ConsumerState<TfdSolicitarPage> createState() => _TfdSolicitarPageState();
}

class _TfdSolicitarPageState extends ConsumerState<TfdSolicitarPage> {
  final _formKey = GlobalKey<FormState>();
  final _justCtrl = TextEditingController();
  final _acompCtrl = TextEditingController();
  bool _enviando = false;
  String? _erro;
  bool _anexarEnc = false;
  String? _encId;

  @override
  void dispose() {
    _justCtrl.dispose();
    _acompCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_anexarEnc && _encId == null) {
      setState(() => _erro = 'Escolha qual encaminhamento você quer anexar.');
      return;
    }
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      final r = await ref.read(tfdControllerProvider.notifier).solicitar(
            viagemId: widget.viagemId,
            encaminhamentoId: _anexarEnc ? _encId : null,
            justificativa: _justCtrl.text.trim(),
            acompanhante: _acompCtrl.text.trim().isEmpty
                ? null
                : _acompCtrl.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido enviado! Aguarde análise.')),
      );
      context.pushReplacement('/tfd/solicitacao/${r.id}');
    } on ApiException catch (e) {
      setState(() => _erro = e.mensagemAmigavel);
    } catch (_) {
      setState(() => _erro = 'Não conseguimos enviar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viagemAsync = ref.watch(viagemTfdProvider(widget.viagemId));
    final fmt = DateFormat("EEEE, dd/MM 'às' HH'h'", 'pt_BR');

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Pedir vaga no TFD'),
      ),
      body: viagemAsync.when(
        loading: () => const LoadingView(),
        error: (_, __) => ErrorView(
          title: 'Não conseguimos abrir',
          onRetry: () => ref.invalidate(viagemTfdProvider(widget.viagemId)),
        ),
        data: (v) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Resumo da viagem ----------------------------------------
                PanelCard(
                  title: 'Viagem escolhida',
                  index: 'A',
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${v.destinoCidade} · ${v.destinoUf}',
                        style: AppTypography.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        v.destinoLocal,
                        style: AppTypography.bodyMedium,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _info(Icons.calendar_today_outlined, fmt.format(v.dataPartida)),
                      _info(Icons.access_time, 'Saída às ${v.horaPartida}'),
                      _info(Icons.location_on_outlined, 'Embarque: ${v.localEmbarque}'),
                      _info(Icons.event_seat_outlined,
                          '${v.vagasDisponiveis} de ${v.vagasTotal} vagas disponíveis'),
                      if (v.observacoes != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        InfoBlock(
                          message: v.observacoes!,
                          tone: InfoTone.info,
                          icon: Icons.info_outline,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Card de educação sobre prioridade -----------------------
                _PrioridadeEducacaoCard(ativa: _anexarEnc),
                const SizedBox(height: AppSpacing.lg),

                // Toggle anexar encaminhamento ----------------------------
                _AnexarToggle(
                  ativo: _anexarEnc,
                  onChange: (v) => setState(() {
                    _anexarEnc = v;
                    if (!v) _encId = null;
                  }),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Seletor de encaminhamento (aparece apenas se ativo) ----
                if (_anexarEnc)
                  _SelectEncaminhamento(
                    selecionado: _encId,
                    onSelect: (id) => setState(() => _encId = id),
                  ),

                const SizedBox(height: AppSpacing.xl),

                // Justificativa ------------------------------------------
                FormFieldX(
                  label: 'Por que você precisa da vaga?',
                  controller: _justCtrl,
                  hint: 'Conte brevemente o motivo',
                  helpText:
                      'Ex: "Preciso ir a uma consulta médica em outra cidade" — pelo menos 10 letras.',
                  validator: (v) {
                    if ((v ?? '').trim().length < 10) {
                      return 'Explique com pelo menos 10 letras.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Acompanhante -------------------------------------------
                FormFieldX(
                  label: 'Acompanhante (opcional)',
                  controller: _acompCtrl,
                  hint: 'Nome de quem vai com você',
                  helpText: 'Deixe em branco se for sozinho(a).',
                ),

                const SizedBox(height: AppSpacing.xl),
                if (_erro != null) ...[
                  InfoBlock(message: _erro!, tone: InfoTone.critical),
                  const SizedBox(height: AppSpacing.md),
                ],

                PrimaryButton(
                  label: 'Enviar pedido',
                  onPressed: _enviando ? null : _enviar,
                  loading: _enviando,
                  icon: Icons.send_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Cancelar',
                  onPressed: _enviando ? null : () => context.pop(),
                  variant: PrimaryButtonVariant.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _info(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 18, color: AppColors.slate600),
            ),
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
        ),
      );
}

/// Card grande explicando que anexar encaminhamento dá prioridade.
class _PrioridadeEducacaoCard extends StatelessWidget {
  const _PrioridadeEducacaoCard({required this.ativa});
  final bool ativa;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        color: ativa ? AppColors.amber50 : AppColors.blue50,
        border: Border.all(
          color: ativa ? AppColors.amber600 : AppColors.blue900,
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: Container(
              key: ValueKey(ativa),
              width: 56,
              height: 56,
              color: ativa ? AppColors.amber600 : AppColors.blue900,
              alignment: Alignment.center,
              child: Icon(
                ativa ? Icons.star : Icons.tips_and_updates_outlined,
                color: AppColors.white,
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ativa ? 'Pedido com prioridade alta' : 'Quer prioridade na fila?',
                  style: AppTypography.titleLarge.copyWith(
                    color: ativa ? AppColors.amber900 : AppColors.blue900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ativa
                      ? 'Como você anexou seu encaminhamento médico, sua solicitação vai ser analisada antes das demais.'
                      : 'Anexe seu encaminhamento médico abaixo e seu pedido entra na fila prioritária da secretaria.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: ativa ? AppColors.amber900 : AppColors.slate900,
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

/// Toggle visual grande pra anexar (ou não) o encaminhamento.
class _AnexarToggle extends StatelessWidget {
  const _AnexarToggle({required this.ativo, required this.onChange});
  final bool ativo;
  final ValueChanged<bool> onChange;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: () => onChange(!ativo),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: ativo ? AppColors.blue50 : AppColors.white,
            border: Border.all(
              color: ativo ? AppColors.blue900 : AppColors.slate300,
              width: ativo ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 44,
                height: 44,
                color: ativo ? AppColors.blue900 : AppColors.slate200,
                alignment: Alignment.center,
                child: Icon(
                  ativo ? Icons.check : Icons.attach_file,
                  color: ativo ? AppColors.white : AppColors.slate600,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Anexar meu encaminhamento médico',
                      style: AppTypography.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ativo
                          ? 'Pedido entra na fila prioritária'
                          : 'Sem anexo, prioridade normal',
                      style: AppTypography.bodySmall.copyWith(
                        color: ativo ? AppColors.blue900 : AppColors.slate600,
                        fontWeight: ativo ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Switch.adaptive(
                value: ativo,
                onChanged: onChange,
                activeThumbColor: AppColors.white,
                activeTrackColor: AppColors.blue900,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lista de radio cards pra escolher qual encaminhamento anexar.
class _SelectEncaminhamento extends ConsumerWidget {
  const _SelectEncaminhamento({
    super.key,
    required this.selecionado,
    required this.onSelect,
  });

  final String? selecionado;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final encsAsync = ref.watch(encaminhamentosProvider);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(label: 'Qual encaminhamento anexar?'),
          encsAsync.when(
            loading: () => const LoadingView(),
            error: (_, __) => const SizedBox.shrink(),
            data: (list) {
              final ativos = list
                  .where((e) => !['CONCLUIDO', 'REJEITADO', 'CANCELADO'].contains(e.status))
                  .toList();
              if (ativos.isEmpty) {
                return InfoBlock(
                  message:
                      'Você não tem encaminhamentos ativos para anexar. Você pode pedir vaga mesmo assim, sem prioridade.',
                  tone: InfoTone.warning,
                );
              }
              return Column(
                children: ativos.map((e) {
                  final sel = selecionado == e.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Material(
                      color: AppColors.white,
                      child: InkWell(
                        onTap: () => onSelect(e.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.blue50 : AppColors.white,
                            border: Border.all(
                              color: sel ? AppColors.blue900 : AppColors.slate200,
                              width: sel ? 2 : 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              Icon(
                                sel ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: sel ? AppColors.blue900 : AppColors.slate400,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.especialidade,
                                        style: AppTypography.titleMedium),
                                    Text(e.protocolo,
                                        style: AppTypography.protocolo
                                            .copyWith(fontSize: 13)),
                                  ],
                                ),
                              ),
                              StatusBadge.fromStatus(e.status, size: StatusBadgeSize.small),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
