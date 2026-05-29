import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_controller.dart';
import '../../shared/widgets/widgets.dart';

class PerfilPage extends ConsumerWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paciente = ref.watch(authControllerProvider).paciente;
    if (paciente == null) {
      return const Scaffold(body: LoadingView());
    }
    final fmt = DateFormat("dd/MM/yyyy", 'pt_BR');

    return AppScaffold(
      appBar: AppBar(title: const Text('Meu perfil'), automaticallyImplyLeading: false),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.slate200, width: 1),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  color: AppColors.blue900,
                  alignment: Alignment.center,
                  child: Text(
                    paciente.iniciais,
                    style: AppTypography.displayLarge.copyWith(
                      color: AppColors.white,
                      fontSize: 36,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  paciente.nome,
                  style: AppTypography.headlineMedium,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_idade(paciente.dataNascimento)} anos · nascido em ${fmt.format(paciente.dataNascimento)}',
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
          SectionHeader(label: 'Seus dados'),
          PanelCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _info('CPF', paciente.cpf, mono: true),
                if (paciente.cartaoSus != null) ...[
                  const Divider(),
                  _info('Cartão SUS', paciente.cartaoSus!, mono: true),
                ],
                const Divider(),
                _info('Nascimento', fmt.format(paciente.dataNascimento), mono: true),
                if (paciente.telefone != null) ...[
                  const Divider(),
                  _info('Telefone', paciente.telefone!, mono: true),
                ],
                if (paciente.email != null) ...[
                  const Divider(),
                  _info('Email', paciente.email!),
                ],
                if (paciente.ubsVinculadaNome != null) ...[
                  const Divider(),
                  _info('Sua UBS', paciente.ubsVinculadaNome!),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
          SectionHeader(label: 'Sua conta'),
          IconCard(
            icon: Icons.lock_outline,
            title: 'Trocar minha senha',
            iconBg: AppColors.slate700,
            onTap: () => context.push('/perfil/trocar-senha'),
          ),
          const SizedBox(height: AppSpacing.md),
          IconCard(
            icon: Icons.notifications_outlined,
            title: 'Avisos do app',
            subtitle: 'Escolher quais avisos quer receber',
            iconBg: AppColors.blue900,
            onTap: () => context.push('/perfil/notificacoes'),
          ),
          const SizedBox(height: AppSpacing.md),
          IconCard(
            icon: Icons.home_work_outlined,
            title: 'Minha UBS',
            subtitle: 'Endereço, contato e horário',
            iconBg: AppColors.emerald700,
            onTap: () => context.push('/ubs'),
          ),
          const SizedBox(height: AppSpacing.md),
          IconCard(
            icon: Icons.help_outline,
            title: 'Ajuda e dúvidas',
            subtitle: 'Perguntas frequentes e contatos',
            iconBg: AppColors.amber600,
            onTap: () => context.push('/perfil/ajuda'),
          ),

          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Sair do app',
            variant: PrimaryButtonVariant.danger,
            icon: Icons.logout,
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sair do app'),
                  content: const Text('Tem certeza que quer sair? Você precisará entrar de novo com CPF e senha.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Voltar')),
                    TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Sair')),
                  ],
                ),
              );
              if (ok == true) {
                await ref.read(authControllerProvider.notifier).logout();
              }
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Text(
              'UNISISM Paciente · v${AppConstants.appVersion} · BUILD ${AppConstants.buildCode}',
              style: AppTypography.labelInstitucional,
            ),
          ),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }

  int _idade(DateTime nasc) {
    final hoje = DateTime.now();
    var anos = hoje.year - nasc.year;
    if (hoje.month < nasc.month || (hoje.month == nasc.month && hoje.day < nasc.day)) {
      anos--;
    }
    return anos;
  }

  Widget _info(String label, String value, {bool mono = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: AppTypography.labelInstitucional),
            const SizedBox(height: 2),
            Text(
              value,
              style: mono ? AppTypography.data.copyWith(color: AppColors.slate900, fontSize: 16) : AppTypography.bodyLarge,
            ),
          ],
        ),
      );
}
