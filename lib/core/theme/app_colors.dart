import 'package:flutter/material.dart';

/// Tokens de cor — herdados do DS UBS (Tailwind v4 stock).
/// Apenas `slate-*`, `blue-900`/`950` + paletas semânticas.
class AppColors {
  AppColors._();

  // --- Neutros ---
  static const Color slate50 = Color(0xFFF8FAFC); // Fundo de página
  static const Color slate100 = Color(0xFFF1F5F9); // Hover, divisores
  static const Color slate200 = Color(0xFFE2E8F0); // Borda padrão
  static const Color slate300 = Color(0xFFCBD5E1); // Borda secundária / input
  static const Color slate400 = Color(0xFF94A3B8); // Placeholders, ícones neutros
  static const Color slate500 = Color(0xFF64748B); // Labels
  static const Color slate600 = Color(0xFF475569); // Texto secundário
  static const Color slate700 = Color(0xFF334155); // Texto de corpo
  static const Color slate900 = Color(0xFF0F172A); // Texto primário, modal brutalista

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // --- Institucional (ação) ---
  static const Color blue900 = Color(0xFF1E3A8A); // Primário
  static const Color blue950 = Color(0xFF172554); // Hover do primário
  static const Color blue700 = Color(0xFF1D4ED8); // Borda info / tab ativa
  static const Color blue50 = Color(0xFFEFF6FF); // Background info

  // --- Sucesso ---
  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color emerald700 = Color(0xFF047857);
  static const Color emerald800 = Color(0xFF065F46);
  static const Color emerald900 = Color(0xFF064E3B);

  // --- Atenção ---
  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber600 = Color(0xFFD97706);
  static const Color amber800 = Color(0xFF92400E);
  static const Color amber900 = Color(0xFF78350F);

  // --- Crítico ---
  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red700 = Color(0xFFB91C1C);
  static const Color red800 = Color(0xFF991B1B);
  static const Color red900 = Color(0xFF7F1D1D);

  /// Selection / highlight (definido no CSS reset original).
  static const Color selectionBg = blue900;

  /// Não usar gradiente colorido — apenas este sutil em headers.
  static const LinearGradient panelHeaderGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [white, slate50],
  );
}
