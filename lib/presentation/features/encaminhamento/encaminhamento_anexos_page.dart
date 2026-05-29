import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../shared/widgets/widgets.dart';

/// Tela de anexos — **dados hard-coded, sem providers nem download real**.
/// O onTap mostra um snackbar avisando que a integração real virá com o backend.
class EncaminhamentoAnexosPage extends StatelessWidget {
  const EncaminhamentoAnexosPage({super.key, required this.id});
  final String id;

  static const _anexos = [
    (
      nome: 'Solicitacao_Medica_Cardiologia.pdf',
      tipo: 'application/pdf',
      tamanho: 248310,
    ),
    (
      nome: 'Eletrocardiograma_recente.pdf',
      tipo: 'application/pdf',
      tamanho: 1540200,
    ),
    (
      nome: 'Cartao_SUS.jpg',
      tipo: 'image/jpeg',
      tamanho: 412000,
    ),
  ];

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Documentos'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _anexos.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, i) {
          final a = _anexos[i];
          return DocumentTile(
            nome: a.nome,
            tamanhoBytes: a.tamanho,
            tipo: a.tipo,
            onView: () => _toast(context, 'Abrir ${a.nome} (mock)'),
            onDownload: () => _toast(context, 'Baixar ${a.nome} (mock)'),
            onShare: () => _toast(context, 'Compartilhar ${a.nome} (mock)'),
          );
        },
      ),
    );
  }
}
