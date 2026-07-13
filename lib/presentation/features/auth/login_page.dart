import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_controller.dart';
import '../../shared/widgets/widgets.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _cpfCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _senhaFocus = FocusNode();
  final _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'\d')},
  );

  @override
  void dispose() {
    _cpfCtrl.dispose();
    _senhaCtrl.dispose();
    _senhaFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(authControllerProvider.notifier).login(
          cpf: _cpfCtrl.text,
          senha: _senhaCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final loading = auth.status == AuthStatus.signingIn;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        body: SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.huge),
                    _Brand(),
                    const SizedBox(height: AppSpacing.huge),
                    Text('Entrar', style: AppTypography.displayLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Use seu CPF e a senha cadastrada na sua UBS para acessar o app.',
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (auth.errorMessage != null) ...[
                      InfoBlock(
                        message: auth.errorMessage!,
                        tone: InfoTone.critical,
                        title: 'Não conseguimos entrar',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    FormFieldX(
                      label: 'CPF',
                      controller: _cpfCtrl,
                      hint: '000.000.000-00',
                      keyboardType: TextInputType.number,
                      inputFormatters: [_cpfMask],
                      mono: true,
                      autofocus: true,
                      textInputAction: TextInputAction.next,
                      suffix: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _cpfCtrl,
                        builder: (context, value, _) {
                          final digits = value.text.replaceAll(RegExp(r'\D'), '');
                          if (digits.length == 11) {
                            return IconButton(
                              icon: const Icon(Icons.arrow_forward, color: AppColors.blue900),
                              onPressed: () => FocusScope.of(context).requestFocus(_senhaFocus),
                              tooltip: 'Prosseguir',
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      onChanged: (v) {
                        final digits = v.replaceAll(RegExp(r'\D'), '');
                        if (digits.length == 11) {
                          FocusScope.of(context).requestFocus(_senhaFocus);
                        }
                      },
                      onSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_senhaFocus);
                      },
                      validator: (v) {
                        final raw = (v ?? '').replaceAll(RegExp(r'\D'), '');
                        if (raw.isEmpty) return 'Informe seu CPF';
                        if (raw.length != 11) return 'CPF incompleto';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FormFieldX(
                      label: 'Senha',
                      controller: _senhaCtrl,
                      hint: 'Digite sua senha',
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      focusNode: _senhaFocus,
                      onSubmitted: (_) => _submit(),
                      validator: (v) {
                        if ((v ?? '').isEmpty) return 'Informe sua senha';
                        if (v!.length < 4) return 'Senha muito curta';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/esqueci-senha'),
                        child: const Text('Esqueci minha senha'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: 'Entrar',
                      onPressed: loading ? null : _submit,
                      loading: loading,
                      icon: Icons.login,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),);
  }
}

class _Brand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(color: AppColors.blue900),
          alignment: Alignment.center,
          child: const Text(
            'U',
            style: TextStyle(
              fontFamily: AppTypography.mono,
              fontSize: 42,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'UNISISM',
          style: TextStyle(
            fontFamily: AppTypography.mono,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.blue900,
            letterSpacing: 3,
          ),
        ),
        const Text(
          'PACIENTE',
          style: TextStyle(
            fontFamily: AppTypography.mono,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.slate500,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }
}
