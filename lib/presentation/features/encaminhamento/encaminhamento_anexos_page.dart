import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/services/anexo_download_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/encaminhamento.dart';
import '../../../providers/encaminhamento_controller.dart';
import '../../../providers/providers.dart';
import '../../shared/widgets/widgets.dart';

/// Tela de anexos — **100% real**.
///
/// Lista vem de `anexosProvider(encaminhamentoId)`. Download via
/// `AnexoDownloadService` com Bearer header, parse de Content-Disposition,
/// progress bar, e tratamento dos erros do backend (ANEXO_NAO_LIBERADO/
/// RATE_LIMIT_EXCEDIDO/ANEXO_NAO_ENCONTRADO).
class EncaminhamentoAnexosPage extends ConsumerWidget {
  const EncaminhamentoAnexosPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAnexos = ref.watch(anexosProvider(id));

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Documentos'),
      ),
      body: asyncAnexos.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => EmptyView(
          icon: Icons.error_outline,
          title: 'Não conseguimos carregar',
          message: 'Tente novamente em alguns instantes.',
        ),
        data: (anexos) {
          if (anexos.isEmpty) {
            return EmptyView(
              icon: Icons.folder_open_outlined,
              title: 'Nenhum documento anexado',
              message:
                  'Quando sua UBS anexar um documento, ele aparece aqui.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: anexos.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) => _AnexoTile(anexo: anexos[i]),
          );
        },
      ),
    );
  }
}

/// Tile individual com estados: idle / baixando / erro / pronto.
class _AnexoTile extends ConsumerStatefulWidget {
  const _AnexoTile({required this.anexo});
  final Anexo anexo;

  @override
  ConsumerState<_AnexoTile> createState() => _AnexoTileState();
}

class _AnexoTileState extends ConsumerState<_AnexoTile> {
  DownloadProgress? _progress;
  DownloadResult? _result;
  String? _erro;
  bool _baixando = false;

  Future<DownloadResult?> _ensureBaixado() async {
    if (_result != null) return _result;
    setState(() {
      _baixando = true;
      _erro = null;
      _progress = const DownloadProgress(recebido: 0, total: 0);
    });
    try {
      final svc = ref.read(anexoDownloadServiceProvider);
      final r = await svc.baixar(
        anexoId: widget.anexo.id,
        nomeSugerido: widget.anexo.nome,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (mounted) {
        setState(() {
          _result = r;
          _baixando = false;
          _progress = null;
        });
      }
      return r;
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _erro = e.mensagemAmigavel;
          _baixando = false;
          _progress = null;
        });
      }
      return null;
    } catch (_) {
      if (mounted) {
        setState(() {
          _erro = 'Falha ao baixar. Tente novamente.';
          _baixando = false;
          _progress = null;
        });
      }
      return null;
    }
  }

  Future<void> _abrir() async {
    final r = await _ensureBaixado();
    if (r == null || !mounted) return;
    try {
      await ref.read(anexoDownloadServiceProvider).abrir(r);
    } on ApiException catch (e) {
      if (mounted) _toast(e.mensagemAmigavel);
    }
  }

  Future<void> _compartilhar() async {
    final r = await _ensureBaixado();
    if (r == null || !mounted) return;
    await ref.read(anexoDownloadServiceProvider).compartilhar(r);
  }

  Future<void> _baixar() async {
    final r = await _ensureBaixado();
    if (r == null || !mounted) return;
    _toast('Baixado em ${r.filename}');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.anexo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DocumentTile(
          nome: a.nome,
          tamanhoBytes: a.tamanhoBytes,
          tipo: _mimeFromTipo(a.tipo, a.nome),
          onView: _baixando ? null : _abrir,
          onDownload: _baixando ? null : _baixar,
          onShare: _baixando ? null : _compartilhar,
        ),
        if (_baixando) ...[
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: _progress?.fraction,
            backgroundColor: AppColors.slate100,
          ),
          const SizedBox(height: 4),
          Text(
            _progress?.formatado ?? 'Iniciando…',
            style: AppTypography.bodySmall.copyWith(color: AppColors.slate500),
          ),
        ],
        if (_erro != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.red50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    size: 18, color: AppColors.red900),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_erro!,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.red900)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static String _mimeFromTipo(String tipo, String nome) {
    switch (tipo) {
      case 'PDF':
        return 'application/pdf';
      case 'IMG':
        final low = nome.toLowerCase();
        if (low.endsWith('.png')) return 'image/png';
        if (low.endsWith('.webp')) return 'image/webp';
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }
}
