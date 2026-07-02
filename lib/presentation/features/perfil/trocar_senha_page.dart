import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_controller.dart';
import '../../shared/widgets/widgets.dart';

/// Tela de troca de senha.
///
/// Dois modos:
///   - **Provisório** (`requiresPasswordChange=true`): primeiro acesso.
///     Sem botão de fechar, bloqueia back (PopScope), exige mínimo 8 chars,
///     hint da senha atual = CPF. Após sucesso navega via `context.go('/home')`
///     (não `pop` — a rota foi atingida por redirect do router, não há rota
///     anterior na pilha).
///   - **Normal**: acessível pelo perfil. Tem botão X, mínimo 6 chars,
///     após sucesso usa `context.pop()` para voltar pro perfil.
class TrocarSenhaPage extends ConsumerStatefulWidget {
  const TrocarSenhaPage({super.key});

  @override
  ConsumerState<TrocarSenhaPage> createState() => _TrocarSenhaPageState();
}

class _TrocarSenhaPageState extends ConsumerState<TrocarSenhaPage> {
  final _formKey = GlobalKey<FormState>();
  final _atualCtrl = TextEditingController();
  final _novaCtrl = TextEditingController();
  final _confCtrl = TextEditingController();
  bool _enviando = false;
  bool _sucesso = false;
  String? _erro;

  @override
  void dispose() {
    _atualCtrl.dispose();
    _novaCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool provisoria}) async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).trocarSenha(
            senhaAtual: _atualCtrl.text,
            novaSenha: _novaCtrl.text,
          );
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _sucesso = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _erro = _humanize(e);
      });
    }
  }

  String _humanize(Object e) {
    if (e is ApiException) return e.mensagemAmigavel;
    return 'Não foi possível trocar a senha. Tente de novo.';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final provisoria = auth.requiresPasswordChange;

    return PopScope(
      // Em modo provisório bloqueia voltar (Android back / swipe iOS).
      // Após sucesso libera — o paciente vai navegar via botão.
      canPop: !provisoria || _sucesso,
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(provisoria ? 'Crie sua senha' : 'Trocar senha'),
          leading: provisoria
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _sucesso
              ? _Sucesso(key: const ValueKey('ok'), provisoria: provisoria)
              : _Form(
                  key: const ValueKey('form'),
                  formKey: _formKey,
                  atualCtrl: _atualCtrl,
                  novaCtrl: _novaCtrl,
                  confCtrl: _confCtrl,
                  enviando: _enviando,
                  erro: _erro,
                  provisoria: provisoria,
                  onSubmit: () => _submit(provisoria: provisoria),
                  onSairMaisTarde: provisoria
                      ? () async {
                          await ref
                              .read(authControllerProvider.notifier)
                              .logout();
                        }
                      : null,
                ),
        ),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({
    super.key,
    required this.formKey,
    required this.atualCtrl,
    required this.novaCtrl,
    required this.confCtrl,
    required this.enviando,
    required this.erro,
    required this.provisoria,
    required this.onSubmit,
    this.onSairMaisTarde,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController atualCtrl;
  final TextEditingController novaCtrl;
  final TextEditingController confCtrl;
  final bool enviando;
  final String? erro;
  final bool provisoria;
  final VoidCallback onSubmit;
  final VoidCallback? onSairMaisTarde;

  int get _minimo => provisoria ? 8 : 6;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (provisoria)
              InfoBlock(
                title: 'Bem-vindo(a) ao app',
                message:
                    'Este é seu primeiro acesso. Por segurança, troque a '
                    'senha agora. A senha atual é o seu CPF (apenas os '
                    'números, sem pontos ou traços).',
                tone: InfoTone.warning,
                icon: Icons.lock_outline,
              )
            else
              const InfoBlock(
                title: 'Sua segurança',
                message:
                    'Use uma senha que ninguém saiba. Não compartilhe com '
                    'ninguém.',
                tone: InfoTone.info,
                icon: Icons.lock_outline,
              ),
            const SizedBox(height: AppSpacing.lg),
            if (erro != null) ...[
              InfoBlock(
                title: 'Não foi possível trocar',
                message: erro!,
                tone: InfoTone.critical,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            FormFieldX(
              label: provisoria ? 'Senha atual (seu CPF)' : 'Senha atual',
              controller: atualCtrl,
              obscureText: true,
              validator: (v) {
                if ((v ?? '').isEmpty) return 'Informe sua senha atual';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            FormFieldX(
              label: 'Nova senha',
              controller: novaCtrl,
              obscureText: true,
              validator: (v) {
                if ((v ?? '').length < _minimo) {
                  return 'Mínimo de $_minimo caracteres';
                }
                if (v == atualCtrl.text) {
                  return 'Escolha uma senha diferente da atual';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            FormFieldX(
              label: 'Repita a nova senha',
              controller: confCtrl,
              obscureText: true,
              validator: (v) {
                if ((v ?? '').isEmpty) return 'Repita sua nova senha';
                if (v != novaCtrl.text) return 'As senhas não combinam';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: provisoria ? 'Criar minha senha' : 'Salvar nova senha',
              loading: enviando,
              icon: Icons.save_outlined,
              onPressed: enviando ? null : onSubmit,
            ),
            if (onSairMaisTarde != null) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: enviando ? null : onSairMaisTarde,
                child: const Text('Sair e tentar mais tarde'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Sucesso extends StatelessWidget {
  const _Sucesso({super.key, required this.provisoria});

  final bool provisoria;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              color: AppColors.emerald700,
              alignment: Alignment.center,
              child: const Icon(Icons.check, color: AppColors.white, size: 60),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              provisoria ? 'Senha criada!' : 'Senha trocada!',
              style: AppTypography.displayMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              provisoria
                  ? 'Pronto! Agora você pode acessar seus encaminhamentos e avisos.'
                  : 'Da próxima vez que entrar no app, use sua nova senha.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: provisoria ? 'Ir para o início' : 'Voltar',
              icon: provisoria ? Icons.home : Icons.arrow_back,
              // ⚠️ FIX BUG (turn 2): a flag `provisoria` é derivada de
              // `auth.requiresPasswordChange`. Quando a troca conclui com
              // sucesso, o backend zera `senhaProvisoria` → `requiresPasswordChange`
              // vira `false` → `provisoria` aqui já é `false` MESMO que o usuário
              // tenha entrado em modo bloqueante. Antes, o botão chamava
              // `context.pop()` e estourava "nothing to pop" porque a rota foi
              // atingida via redirect do router (sem rota anterior na pilha).
              //
              // Solução: usar `context.canPop()` que pergunta ao router se
              // existe rota pra voltar. Funciona em AMBOS os fluxos:
              //   - Provisória (redirect): canPop=false → go('/home')
              //   - Normal (push da PerfilPage): canPop=true → pop()
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
