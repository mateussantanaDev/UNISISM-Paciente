import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/providers.dart';
import '../../shared/widgets/widgets.dart';

class EsqueciSenhaPage extends ConsumerStatefulWidget {
  const EsqueciSenhaPage({super.key});

  @override
  ConsumerState<EsqueciSenhaPage> createState() => _EsqueciSenhaPageState();
}

class _EsqueciSenhaPageState extends ConsumerState<EsqueciSenhaPage> {
  final _cpfCtrl = TextEditingController();
  final _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'\d')},
  );
  bool _enviando = false;
  bool _enviado = false;
  String? _erro;

  Future<void> _enviar() async {
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await ref.read(authRepositoryProvider).esqueciSenha(cpf: _cpfCtrl.text);
      if (!mounted) return;
      setState(() => _enviado = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = 'Não conseguimos enviar. Tente de novo em instantes.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text('Recuperar acesso'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: _enviado ? _Sucesso(cpf: _cpfCtrl.text) : _Form(
                cpfCtrl: _cpfCtrl,
                cpfMask: _cpfMask,
                enviando: _enviando,
                erro: _erro,
                onSubmit: _enviar,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.cpfCtrl,
    required this.cpfMask,
    required this.enviando,
    required this.erro,
    required this.onSubmit,
  });

  final TextEditingController cpfCtrl;
  final MaskTextInputFormatter cpfMask;
  final bool enviando;
  final String? erro;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Esqueceu a senha?', style: AppTypography.displayMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Informe seu CPF. Enviaremos as instruções para o telefone ou email cadastrado na sua UBS.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        if (erro != null) ...[
          InfoBlock(message: erro!, tone: InfoTone.critical),
          const SizedBox(height: AppSpacing.lg),
        ],
        FormFieldX(
          label: 'CPF',
          controller: cpfCtrl,
          mono: true,
          hint: '000.000.000-00',
          keyboardType: TextInputType.number,
          inputFormatters: [cpfMask, FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Enviar instruções',
          onPressed: enviando ? null : onSubmit,
          loading: enviando,
          icon: Icons.send,
        ),
      ],
    );
  }
}

class _Sucesso extends StatelessWidget {
  const _Sucesso({required this.cpf});
  final String cpf;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 88,
          height: 88,
          alignment: Alignment.center,
          color: AppColors.emerald700,
          child: const Icon(Icons.check, color: AppColors.white, size: 56),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Instruções enviadas', style: AppTypography.displayMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Se houver cadastro no município, você receberá as instruções nos próximos minutos. '
          'Verifique seu SMS e email.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Voltar para o login',
          onPressed: () => context.go('/login'),
          variant: PrimaryButtonVariant.primary,
        ),
      ],
    );
  }
}
