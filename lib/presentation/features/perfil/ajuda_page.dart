import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';

class AjudaPage extends StatelessWidget {
  const AjudaPage({super.key});

  static const _faq = <_Faq>[
    _Faq(
      pergunta: 'O que é um encaminhamento médico?',
      resposta:
          'É quando seu médico da UBS encaminha você para uma consulta especializada (cardiologista, oftalmologista, etc.) em outro local. O sistema controla todo o caminho até você ser atendido.',
    ),
    _Faq(
      pergunta: 'Quanto tempo demora para minha consulta ser marcada?',
      resposta:
          'Depende da especialidade e da prioridade clínica do seu caso. A secretaria municipal analisa cada pedido e marca pela ordem de chegada e gravidade. Você é avisado a cada mudança.',
    ),
    _Faq(
      pergunta: 'O que é o TFD?',
      resposta:
          'TFD significa Tratamento Fora de Domicílio. Quando sua consulta acontece em outra cidade, a Secretaria de Saúde oferece transporte em vans/ônibus. Você pode pedir uma vaga nesse transporte direto pelo app.',
    ),
    _Faq(
      pergunta: 'Anexar o encaminhamento ao pedir TFD adianta?',
      resposta:
          'Sim! Quando você anexa o encaminhamento, sua solicitação entra na fila prioritária da secretaria e é analisada antes das demais.',
    ),
    _Faq(
      pergunta: 'Recebo lembretes da consulta?',
      resposta:
          'Sim — você receberá notificações no celular quando: o pedido for analisado, aprovado, marcado, e antes do dia da consulta.',
    ),
    _Faq(
      pergunta: 'Esqueci minha senha. E agora?',
      resposta:
          'Na tela de login, toque em "Esqueci minha senha". Você receberá as instruções no telefone ou email cadastrado na sua UBS.',
    ),
    _Faq(
      pergunta: 'Meus dados estão seguros?',
      resposta:
          'Sim. Suas informações são protegidas e usadas apenas pelo SUS para te atender. Não compartilhamos dados com empresas.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Ajuda e dúvidas'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          InfoBlock(
            title: 'Suporte',
            message:
                'Não encontrou o que precisa? Procure sua UBS ou ligue para a Secretaria de Saúde.',
            tone: InfoTone.info,
            icon: Icons.support_agent,
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(label: 'Perguntas frequentes'),
          ..._faq.map((f) => _ExpandableFaq(faq: f)),
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(label: 'Contatos importantes'),
          _ContatoTile(
            icon: Icons.local_hospital,
            iconBg: AppColors.red700,
            label: 'SAMU',
            telefone: '192',
            descricao: 'Emergências médicas',
          ),
          const SizedBox(height: AppSpacing.sm),
          _ContatoTile(
            icon: Icons.health_and_safety_outlined,
            iconBg: AppColors.amber600,
            label: 'Disque Saúde',
            telefone: '136',
            descricao: 'Ministério da Saúde',
          ),
          const SizedBox(height: AppSpacing.sm),
          _ContatoTile(
            icon: Icons.shield_outlined,
            iconBg: AppColors.blue900,
            label: 'Ouvidoria do SUS',
            telefone: '136',
            descricao: 'Denúncias e reclamações',
          ),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }
}

class _Faq {
  const _Faq({required this.pergunta, required this.resposta});
  final String pergunta;
  final String resposta;
}

class _ExpandableFaq extends StatefulWidget {
  const _ExpandableFaq({required this.faq});
  final _Faq faq;

  @override
  State<_ExpandableFaq> createState() => _ExpandableFaqState();
}

class _ExpandableFaqState extends State<_ExpandableFaq> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.white,
        child: InkWell(
          onTap: () => setState(() => _open = !_open),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              color: _open ? AppColors.blue50 : AppColors.white,
              border: Border.all(
                color: _open ? AppColors.blue900 : AppColors.slate200,
                width: _open ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(widget.faq.pergunta,
                          style: AppTypography.titleMedium),
                    ),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: _open ? 0.5 : 0,
                      child: const Icon(Icons.expand_more,
                          color: AppColors.slate600),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeInOutCubic,
                  child: _open
                      ? Padding(
                          padding:
                              const EdgeInsets.only(top: AppSpacing.sm),
                          child: Text(widget.faq.resposta,
                              style: AppTypography.bodyMedium
                                  .copyWith(color: AppColors.slate900)),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContatoTile extends StatelessWidget {
  const _ContatoTile({
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.telefone,
    required this.descricao,
  });

  final IconData icon;
  final Color iconBg;
  final String label;
  final String telefone;
  final String descricao;

  Future<void> _ligar() async {
    final uri = Uri.parse('tel:$telefone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: _ligar,
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: AppColors.slate200, width: 1)),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                color: iconBg,
                alignment: Alignment.center,
                child: Icon(icon, color: AppColors.white, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTypography.titleMedium),
                    Text(descricao, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.emerald700,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.call, color: AppColors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(telefone,
                        style: AppTypography.button.copyWith(fontSize: 14)),
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
