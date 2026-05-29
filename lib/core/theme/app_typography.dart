import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tipografia adaptada para paciente.
///
/// **Inversão deliberada do DS UBS**: o DS de operadores usa `text-xs`/`text-[11px]`
/// com `font-mono` em quase tudo. Aqui, paciente com baixo letramento → tamanhos
/// maiores, sans em tudo, mono apenas em protocolo/CPF/datas (tokens de dados).
class AppTypography {
  AppTypography._();

  static const String sans = 'Inter';
  static const String mono = 'JetBrainsMono';

  // --- Sans (Inter) — corpo, títulos, ações ---

  /// Título de tela. Ex: "Meu Encaminhamento".
  static const TextStyle displayLarge = TextStyle(
    fontFamily: sans,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.5,
    color: AppColors.slate900,
  );

  /// Título de seção. Ex: "Próximos passos".
  static const TextStyle displayMedium = TextStyle(
    fontFamily: sans,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.4,
    color: AppColors.slate900,
  );

  /// Headline em cards grandes.
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: sans,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.slate900,
  );

  /// Headline em painéis e modais.
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: sans,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.slate900,
  );

  /// Título dentro de cards. Ex: "Documentos anexados".
  static const TextStyle titleLarge = TextStyle(
    fontFamily: sans,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.slate900,
  );

  /// Título compacto.
  static const TextStyle titleMedium = TextStyle(
    fontFamily: sans,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: AppColors.slate900,
  );

  /// **Corpo padrão** — sempre 16px+ pra paciente. Quase tudo da UI.
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: sans,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.slate900,
  );

  /// Corpo secundário (descrições, sublabels).
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: sans,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.slate700,
  );

  /// Texto auxiliar (timestamps, metadados).
  static const TextStyle bodySmall = TextStyle(
    fontFamily: sans,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.slate600,
  );

  /// Label de botão primário (NÃO uppercase pra paciente — diferença vs DS UBS).
  static const TextStyle button = TextStyle(
    fontFamily: sans,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.2,
    color: AppColors.white,
  );

  /// Label compacto pra chip/tag/sublabel.
  static const TextStyle label = TextStyle(
    fontFamily: sans,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: AppColors.slate600,
  );

  /// **Único uso de uppercase tracking-widest** — manter assinatura do DS
  /// em labels de identidade (PROTOCOLO, CPF, CARTÃO SUS).
  static const TextStyle labelInstitucional = TextStyle(
    fontFamily: mono,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: 1.6,
    color: AppColors.slate500,
  );

  // --- Mono (JetBrains Mono) — dados estruturados ---

  /// Protocolo. Ex: UBS-2026-100137.
  static const TextStyle protocolo = TextStyle(
    fontFamily: mono,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.5,
    color: AppColors.blue900,
  );

  /// Número grande (métrica em painel).
  static const TextStyle metric = TextStyle(
    fontFamily: mono,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: -1.0,
    color: AppColors.slate900,
  );

  /// CPF, CRM, datas, timestamps.
  static const TextStyle data = TextStyle(
    fontFamily: mono,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.slate700,
  );

  /// Badge de status.
  static const TextStyle badge = TextStyle(
    fontFamily: mono,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 1.0,
  );
}
