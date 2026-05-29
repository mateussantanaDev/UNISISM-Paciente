/// Tokens de espaçamento — múltiplos de 4dp (mesma base do Tailwind v4).
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  /// Altura mínima de touch target (acessibilidade — WCAG AA exige 44, mas
  /// pra paciente com baixo letramento usamos 56 como referência).
  static const double touchTarget = 56;

  /// Altura padrão de botão primário.
  static const double buttonHeight = 60;

  /// Padding horizontal padrão de tela.
  static const double pagePaddingH = 16;
  static const double pagePaddingV = 16;

  /// Largura máxima de conteúdo (pra tablets em retrato).
  static const double contentMaxWidth = 720;
}

/// Cantos arredondados — TUDO ZERO. Brutalista. Único permitido é `sm`.
class AppRadius {
  AppRadius._();

  static const double none = 0;
  static const double sm = 2;
}

/// Larguras de borda.
class AppBorders {
  AppBorders._();

  static const double thin = 1;
  static const double medium = 2;
  static const double thick = 4;
}
