import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';

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

  @override
  void dispose() {
    _atualCtrl.dispose();
    _novaCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _enviando = true);
    await Future.delayed(const Duration(milliseconds: 800)); // mock
    if (!mounted) return;
    setState(() {
      _enviando = false;
      _sucesso = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Trocar senha'),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _sucesso ? _Sucesso(key: const ValueKey('ok')) : _Form(
          key: const ValueKey('form'),
          formKey: _formKey,
          atualCtrl: _atualCtrl,
          novaCtrl: _novaCtrl,
          confCtrl: _confCtrl,
          enviando: _enviando,
          onSubmit: _submit,
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
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController atualCtrl;
  final TextEditingController novaCtrl;
  final TextEditingController confCtrl;
  final bool enviando;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InfoBlock(
              title: 'Crie uma senha segura',
              message:
                  'Use uma senha que ninguém saiba. Mínimo de 6 letras ou números.',
              tone: InfoTone.info,
              icon: Icons.lock_outline,
            ),
            const SizedBox(height: AppSpacing.xl),
            FormFieldX(
              label: 'Senha atual',
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
                if ((v ?? '').length < 6) return 'Mínimo de 6 caracteres';
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
              label: 'Salvar nova senha',
              loading: enviando,
              icon: Icons.save_outlined,
              onPressed: enviando ? null : onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class _Sucesso extends StatelessWidget {
  const _Sucesso({super.key});

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
            Text('Senha trocada!', style: AppTypography.displayMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Da próxima vez que entrar no app, use sua nova senha.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Voltar para o perfil',
              icon: Icons.arrow_back,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}
