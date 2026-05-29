import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Pílula com o protocolo, copiável ao toque.
class ProtocoloPill extends StatelessWidget {
  const ProtocoloPill({
    super.key,
    required this.protocolo,
    this.label = 'Protocolo',
    this.copiable = true,
  });

  final String protocolo;
  final String label;
  final bool copiable;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: protocolo));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Protocolo $protocolo copiado'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: copiable ? () => _copy(context) : null,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.slate300, width: 1),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label.toUpperCase(), style: AppTypography.labelInstitucional),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(protocolo, style: AppTypography.protocolo),
                  if (copiable) ...[
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(Icons.copy, size: 16, color: AppColors.slate500),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
