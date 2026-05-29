import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Tile de documento anexo — ícone do tipo + nome + tamanho + ações.
class DocumentTile extends StatelessWidget {
  const DocumentTile({
    super.key,
    required this.nome,
    required this.tamanhoBytes,
    this.tipo,
    this.onView,
    this.onDownload,
    this.onShare,
    this.downloading = false,
    this.progress,
  });

  final String nome;
  final int tamanhoBytes;
  final String? tipo;
  final VoidCallback? onView;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;
  final bool downloading;
  final double? progress;

  String get _tamanhoFmt {
    if (tamanhoBytes < 1024) return '$tamanhoBytes B';
    if (tamanhoBytes < 1024 * 1024) {
      return '${(tamanhoBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(tamanhoBytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  IconData get _icon {
    final ext = (tipo ?? '').toLowerCase();
    if (ext.contains('pdf')) return Icons.picture_as_pdf;
    if (ext.contains('image') || ext.contains('jpg') || ext.contains('png')) {
      return Icons.image;
    }
    if (ext.contains('doc')) return Icons.description;
    return Icons.insert_drive_file_outlined;
  }

  Color get _iconBg {
    final ext = (tipo ?? '').toLowerCase();
    if (ext.contains('pdf')) return AppColors.red700;
    if (ext.contains('image')) return AppColors.emerald700;
    return AppColors.blue900;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: onView,
        splashColor: AppColors.slate100,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.slate200, width: 1),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                color: _iconBg,
                child: Icon(_icon, color: AppColors.white, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      nome,
                      style: AppTypography.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_tamanhoFmt${tipo != null ? ' · ${tipo!.toUpperCase()}' : ''}',
                      style: AppTypography.bodySmall,
                    ),
                    if (downloading) ...[
                      const SizedBox(height: AppSpacing.xs),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: AppColors.slate100,
                        color: AppColors.blue900,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (onShare != null)
                IconButton(
                  onPressed: onShare,
                  icon: const Icon(Icons.share_outlined),
                  tooltip: 'Compartilhar',
                  color: AppColors.slate700,
                ),
              if (onDownload != null)
                IconButton(
                  onPressed: downloading ? null : onDownload,
                  icon: const Icon(Icons.download_outlined),
                  tooltip: 'Baixar',
                  color: AppColors.slate700,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
