import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/paciente.dart';
import '../../../providers/auth_controller.dart';
import '../../shared/widgets/widgets.dart';

/// Tela de perfil — **renderiza TODOS os 27 campos** do paciente retornados
/// pelo backend em `GET /paciente-app/me` (v0.18.3+).
///
/// Organização em seções:
///   1. Hero (foto/iniciais + nome + idade + sexo)
///   2. Identificação (nome social, CPF, cartão SUS, nascimento, sexo, grupo sanguíneo)
///   3. Atenção primária (UBS, agente comunitário, microárea, equipe SF)
///   4. Contato (email, telefone, telefone secundário)
///   5. Endereço (rua, bairro, município/UF, CEP)
///   6. Filiação (mãe, pai)
///   7. Perfil sócio-demográfico (estado civil, escolaridade, profissão, raça/cor)
///   8. Conta (trocar senha, notif, ajuda, logout)
class PerfilPage extends ConsumerWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(authControllerProvider).paciente;
    if (p == null) return const Scaffold(body: LoadingView());

    final fmt = DateFormat("dd/MM/yyyy", 'pt_BR');

    return AppScaffold(
      appBar:
          AppBar(title: const Text('Meu perfil'), automaticallyImplyLeading: false),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── 1. Hero ─────────────────────────────────────────────
          _HeroPaciente(p: p, fmt: fmt),

          const SizedBox(height: AppSpacing.xl),

          // ─── 2. Identificação ───────────────────────────────────
          _Secao(label: 'Identificação', children: [
            _Linha(label: 'CPF', valor: p.cpfDisplay, mono: true),
            if (p.nomeSocial != null && p.nomeSocial!.isNotEmpty)
              _Linha(label: 'Nome social', valor: p.nomeSocial!),
            if (p.cartaoSus != null)
              _Linha(label: 'Cartão SUS', valor: p.cartaoSus!, mono: true),
            if (p.dataNascimento != null)
              _Linha(
                label: 'Nascimento',
                valor: fmt.format(p.dataNascimento!),
                mono: true,
              ),
            if (Paciente.labelSexo(p.sexo) != null)
              _Linha(label: 'Sexo', valor: Paciente.labelSexo(p.sexo)!),
            if (Paciente.labelGrupoSanguineo(p.grupoSanguineo) != null)
              _Linha(
                label: 'Tipo sanguíneo',
                valor: Paciente.labelGrupoSanguineo(p.grupoSanguineo)!,
                mono: true,
              ),
          ]),

          // ─── 3. Atenção primária ───────────────────────────────
          if (_temAtencaoPrimaria(p)) ...[
            const SizedBox(height: AppSpacing.xl),
            _Secao(label: 'Sua equipe de saúde', children: [
              if (p.ubsVinculadaNome != null)
                _Linha(
                  icon: Icons.home_work_outlined,
                  label: 'UBS de vínculo',
                  valor: p.ubsVinculadaNome!,
                ),
              if (p.equipeSaudeFamilia != null)
                _Linha(
                  icon: Icons.groups_outlined,
                  label: 'Equipe Saúde da Família',
                  valor: p.equipeSaudeFamilia!,
                ),
              if (p.agenteComunitario != null)
                _Linha(
                  icon: Icons.person_pin_outlined,
                  label: 'Agente comunitário (ACS)',
                  valor: p.agenteComunitario!,
                ),
              if (p.microarea != null)
                _Linha(
                  icon: Icons.map_outlined,
                  label: 'Microárea',
                  valor: p.microarea!,
                  mono: true,
                ),
            ]),
          ],

          // ─── 4. Contato ───────────────────────────────────────
          if (_temContato(p)) ...[
            const SizedBox(height: AppSpacing.xl),
            _Secao(label: 'Contato', children: [
              if (p.telefone != null)
                _Linha(
                  icon: Icons.phone_outlined,
                  label: 'Celular',
                  valor: _telDisplay(p.telefone!),
                  mono: true,
                ),
              if (p.telefoneSecundario != null)
                _Linha(
                  icon: Icons.phone_in_talk_outlined,
                  label: 'Telefone fixo',
                  valor: _telDisplay(p.telefoneSecundario!),
                  mono: true,
                ),
              if (p.email != null)
                _Linha(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  valor: p.email!,
                ),
            ]),
          ],

          // ─── 5. Endereço ──────────────────────────────────────
          if (_temEndereco(p)) ...[
            const SizedBox(height: AppSpacing.xl),
            _Secao(label: 'Endereço', children: [
              if (p.endereco != null)
                _Linha(
                  icon: Icons.location_on_outlined,
                  label: 'Logradouro',
                  valor: p.endereco!,
                ),
              if (p.bairro != null)
                _Linha(
                  icon: Icons.signpost_outlined,
                  label: 'Bairro',
                  valor: p.bairro!,
                ),
              if (p.municipio != null)
                _Linha(
                  icon: Icons.location_city_outlined,
                  label: 'Município',
                  valor: p.uf != null ? '${p.municipio}/${p.uf}' : p.municipio!,
                ),
              if (p.cep != null)
                _Linha(
                  icon: Icons.markunread_mailbox_outlined,
                  label: 'CEP',
                  valor: _cepDisplay(p.cep!),
                  mono: true,
                ),
            ]),
          ],

          // ─── 6. Filiação ──────────────────────────────────────
          if (p.nomeMae != null || p.nomePai != null) ...[
            const SizedBox(height: AppSpacing.xl),
            _Secao(label: 'Filiação', children: [
              if (p.nomeMae != null)
                _Linha(
                  icon: Icons.family_restroom,
                  label: 'Mãe',
                  valor: p.nomeMae!,
                ),
              if (p.nomePai != null)
                _Linha(
                  icon: Icons.family_restroom,
                  label: 'Pai',
                  valor: p.nomePai!,
                ),
            ]),
          ],

          // ─── 7. Perfil sócio-demográfico ──────────────────────
          if (_temPerfilSocio(p)) ...[
            const SizedBox(height: AppSpacing.xl),
            _Secao(label: 'Perfil', children: [
              if (Paciente.labelEstadoCivil(p.estadoCivil) != null)
                _Linha(
                  label: 'Estado civil',
                  valor: Paciente.labelEstadoCivil(p.estadoCivil)!,
                ),
              if (p.escolaridade != null && p.escolaridade!.isNotEmpty)
                _Linha(label: 'Escolaridade', valor: p.escolaridade!),
              if (p.profissao != null && p.profissao!.isNotEmpty)
                _Linha(label: 'Profissão', valor: p.profissao!),
              if (Paciente.labelRacaCor(p.racaCor) != null)
                _Linha(
                  label: 'Raça / cor',
                  valor: Paciente.labelRacaCor(p.racaCor)!,
                ),
            ]),
          ],

          // ─── Aviso de dados incompletos ──────────────────────
          if (!_temPerfilCompleto(p)) ...[
            const SizedBox(height: AppSpacing.xl),
            PanelCard(
              accent: PanelAccent.info,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.blue900, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Alguns dados do seu cadastro estão em branco. '
                      'Procure sua UBS para atualizar — facilita o atendimento '
                      'e a busca por encaminhamentos.',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ─── 8. Sua conta ──────────────────────────────────────
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
                  content: const Text(
                      'Tem certeza que quer sair? Você precisará entrar de novo com CPF e senha.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Voltar')),
                    TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Sair')),
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

  // ─── Helpers de visibilidade ───────────────────────────────
  static bool _temAtencaoPrimaria(Paciente p) =>
      p.ubsVinculadaNome != null ||
      p.equipeSaudeFamilia != null ||
      p.agenteComunitario != null ||
      p.microarea != null;

  static bool _temContato(Paciente p) =>
      p.telefone != null || p.telefoneSecundario != null || p.email != null;

  static bool _temEndereco(Paciente p) =>
      p.endereco != null ||
      p.bairro != null ||
      p.municipio != null ||
      p.cep != null;

  static bool _temPerfilSocio(Paciente p) =>
      Paciente.labelEstadoCivil(p.estadoCivil) != null ||
      (p.escolaridade != null && p.escolaridade!.isNotEmpty) ||
      (p.profissao != null && p.profissao!.isNotEmpty) ||
      Paciente.labelRacaCor(p.racaCor) != null;

  static bool _temPerfilCompleto(Paciente p) =>
      _temEndereco(p) &&
      _temContato(p) &&
      p.nomeMae != null &&
      p.dataNascimento != null;

  // ─── Formatters ─────────────────────────────────────────────
  static String _telDisplay(String t) {
    final d = t.replaceAll(RegExp(r'\D'), '');
    if (d.length == 11) {
      return '(${d.substring(0, 2)}) ${d.substring(2, 7)}-${d.substring(7)}';
    }
    if (d.length == 10) {
      return '(${d.substring(0, 2)}) ${d.substring(2, 6)}-${d.substring(6)}';
    }
    return t;
  }

  static String _cepDisplay(String c) {
    final d = c.replaceAll(RegExp(r'\D'), '');
    if (d.length == 8) return '${d.substring(0, 5)}-${d.substring(5)}';
    return c;
  }
}

// ─── Widgets internos ───────────────────────────────────────────

class _HeroPaciente extends StatelessWidget {
  const _HeroPaciente({required this.p, required this.fmt});
  final Paciente p;
  final DateFormat fmt;

  @override
  Widget build(BuildContext context) {
    final subtitulos = <String>[];
    if (p.dataNascimento != null) {
      subtitulos.add('${p.idade} anos');
    }
    final sexoLabel = Paciente.labelSexo(p.sexo);
    if (sexoLabel != null) subtitulos.add(sexoLabel);
    if (p.dataNascimento != null) {
      subtitulos.add('nasc. ${fmt.format(p.dataNascimento!)}');
    }

    return Container(
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
              p.iniciais,
              style: AppTypography.displayLarge.copyWith(
                color: AppColors.white,
                fontSize: 36,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            p.nomeExibido,
            style: AppTypography.headlineMedium,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (p.nomeSocial != null &&
              p.nomeSocial!.isNotEmpty &&
              p.nomeSocial != p.nome) ...[
            const SizedBox(height: 2),
            Text(
              'Registro: ${p.nome}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.slate500,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (subtitulos.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitulos.join(' · '),
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao({required this.label, required this.children});
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(label: label),
        PanelCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _intercalaDivider(children),
          ),
        ),
      ],
    );
  }

  static List<Widget> _intercalaDivider(List<Widget> children) {
    if (children.isEmpty) return const [];
    final out = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      out.add(children[i]);
      if (i < children.length - 1) {
        out.add(const Divider(height: 1, color: AppColors.slate100));
      }
    }
    return out;
  }
}

class _Linha extends StatelessWidget {
  const _Linha({
    required this.label,
    required this.valor,
    this.icon,
    this.mono = false,
  });

  final IconData? icon;
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
          if (icon != null) ...[
            Icon(icon, size: 20, color: AppColors.slate500),
            const SizedBox(width: AppSpacing.md),
          ],
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
