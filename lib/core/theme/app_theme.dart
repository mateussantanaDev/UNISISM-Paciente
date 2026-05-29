import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Theme central — Material 3 esqueleto, mas com todos os ajustes pra parecer
/// **NÃO Material**: zero radius, zero elevation, bordas finas, fonte Inter.
class AppTheme {
  AppTheme._();

  static const _zeroShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.zero,
  );

  static const _slateBorder = BorderSide(
    color: AppColors.slate200,
    width: AppBorders.thin,
  );

  static const _slateBorderInput = BorderSide(
    color: AppColors.slate300,
    width: AppBorders.thin,
  );

  static const _blueFocusBorder = BorderSide(
    color: AppColors.blue900,
    width: AppBorders.thin,
  );

  static const _redErrorBorder = BorderSide(
    color: AppColors.red700,
    width: AppBorders.thin,
  );

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);

    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.blue900,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.blue50,
      onPrimaryContainer: AppColors.blue900,
      secondary: AppColors.slate700,
      onSecondary: AppColors.white,
      secondaryContainer: AppColors.slate100,
      onSecondaryContainer: AppColors.slate900,
      tertiary: AppColors.emerald700,
      onTertiary: AppColors.white,
      tertiaryContainer: AppColors.emerald50,
      onTertiaryContainer: AppColors.emerald900,
      error: AppColors.red700,
      onError: AppColors.white,
      errorContainer: AppColors.red50,
      onErrorContainer: AppColors.red900,
      surface: AppColors.white,
      onSurface: AppColors.slate900,
      surfaceContainerLowest: AppColors.white,
      surfaceContainerLow: AppColors.slate50,
      surfaceContainer: AppColors.slate50,
      surfaceContainerHigh: AppColors.slate100,
      surfaceContainerHighest: AppColors.slate100,
      onSurfaceVariant: AppColors.slate600,
      outline: AppColors.slate300,
      outlineVariant: AppColors.slate200,
      shadow: AppColors.slate900,
      scrim: AppColors.slate900,
      inverseSurface: AppColors.slate900,
      onInverseSurface: AppColors.white,
      inversePrimary: AppColors.blue50,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.slate50,
      canvasColor: AppColors.white,
      dividerColor: AppColors.slate200,
      splashColor: AppColors.slate100,
      highlightColor: AppColors.slate100,
      hoverColor: AppColors.slate100,
      focusColor: AppColors.blue50,

      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.blue900,
        selectionColor: Color(0x331E3A8A),
        selectionHandleColor: AppColors.blue900,
      ),

      textTheme: const TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        displaySmall: AppTypography.headlineLarge,
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        headlineSmall: AppTypography.titleLarge,
        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        titleSmall: AppTypography.titleMedium,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.button,
        labelMedium: AppTypography.label,
        labelSmall: AppTypography.bodySmall,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.slate900,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: AppSpacing.lg,
        toolbarHeight: 64,
        shape: Border(bottom: BorderSide(color: AppColors.slate200, width: 1)),
        titleTextStyle: AppTypography.headlineMedium,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        iconTheme: IconThemeData(color: AppColors.slate900, size: 26),
        actionsIconTheme: IconThemeData(color: AppColors.slate900, size: 26),
      ),

      iconTheme: const IconThemeData(
        color: AppColors.slate700,
        size: 24,
      ),

      // --- Botões: ZERO radius, ZERO elevation ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue900,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.slate300,
          disabledForegroundColor: AppColors.slate500,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: _zeroShape,
          textStyle: AppTypography.button,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.slate900,
          side: const BorderSide(color: AppColors.slate300, width: 1),
          shape: _zeroShape,
          elevation: 0,
          textStyle: AppTypography.button.copyWith(color: AppColors.slate900),
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.blue900,
          shape: _zeroShape,
          textStyle: AppTypography.bodyLarge.copyWith(
            color: AppColors.blue900,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.blue900,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.blue900,
          foregroundColor: AppColors.white,
          shape: _zeroShape,
          elevation: 0,
          textStyle: AppTypography.button,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
        ),
      ),

      // --- Inputs ---
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: TextStyle(
          fontFamily: AppTypography.sans,
          fontSize: 17,
          color: AppColors.slate400,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(
          fontFamily: AppTypography.sans,
          fontSize: 15,
          color: AppColors.slate600,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          fontFamily: AppTypography.sans,
          fontSize: 13,
          color: AppColors.blue900,
          fontWeight: FontWeight.w600,
        ),
        errorStyle: TextStyle(
          fontFamily: AppTypography.mono,
          fontSize: 12,
          color: AppColors.red800,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: _slateBorderInput,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: _slateBorderInput,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: _blueFocusBorder,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: _redErrorBorder,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: _redErrorBorder,
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: _slateBorder,
        ),
      ),

      // --- Cards ---
      cardTheme: const CardThemeData(
        color: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.slate200, width: 1),
        ),
      ),

      // --- Divisores ---
      dividerTheme: const DividerThemeData(
        color: AppColors.slate200,
        thickness: 1,
        space: 1,
      ),

      // --- Listas ---
      listTileTheme: const ListTileThemeData(
        tileColor: AppColors.white,
        textColor: AppColors.slate900,
        iconColor: AppColors.slate700,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        minVerticalPadding: AppSpacing.md,
        shape: _zeroShape,
        titleTextStyle: AppTypography.bodyLarge,
        subtitleTextStyle: AppTypography.bodyMedium,
      ),

      // --- Diálogos ---
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.slate900, width: 2),
        ),
        titleTextStyle: AppTypography.headlineMedium,
        contentTextStyle: AppTypography.bodyMedium,
      ),

      // --- Bottom sheet ---
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.white,
        elevation: 0,
        modalElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.slate900, width: 2),
        ),
      ),

      // --- Bottom nav (NavigationBar Material 3) ---
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.blue900,
        indicatorShape: _zeroShape,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppTypography.label.copyWith(
                  color: AppColors.blue900,
                  fontWeight: FontWeight.w700,
                )
              : AppTypography.label.copyWith(color: AppColors.slate600),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.white
                : AppColors.slate700,
            size: 26,
          ),
        ),
      ),

      // --- Snackbar ---
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.slate900,
        contentTextStyle: TextStyle(
          fontFamily: AppTypography.sans,
          fontSize: 15,
          color: AppColors.white,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: AppColors.blue50,
        elevation: 0,
        shape: _zeroShape,
        behavior: SnackBarBehavior.floating,
      ),

      // --- Progress ---
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.blue900,
        linearTrackColor: AppColors.slate100,
        circularTrackColor: AppColors.slate100,
        strokeWidth: 3,
      ),

      // --- Switch / Checkbox / Radio ---
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.white
              : AppColors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.blue900
              : AppColors.slate300,
        ),
        trackOutlineColor: WidgetStateProperty.all(AppColors.slate300),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.blue900
              : AppColors.white,
        ),
        checkColor: WidgetStateProperty.all(AppColors.white),
        side: const BorderSide(color: AppColors.slate400, width: 1.5),
        shape: _zeroShape,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.blue900
              : AppColors.slate400,
        ),
      ),

      // --- Chip / Tooltip ---
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.slate100,
        deleteIconColor: AppColors.slate600,
        labelStyle: AppTypography.label,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.slate200, width: 1),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.slate900,
          borderRadius: BorderRadius.zero,
        ),
        textStyle: TextStyle(
          fontFamily: AppTypography.sans,
          fontSize: 13,
          color: AppColors.white,
          fontWeight: FontWeight.w500,
        ),
      ),

      // --- Tabs ---
      tabBarTheme: const TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.white,
          border: Border(
            top: BorderSide(color: AppColors.blue900, width: 2),
            left: BorderSide(color: AppColors.slate200, width: 1),
            right: BorderSide(color: AppColors.slate200, width: 1),
            bottom: BorderSide(color: AppColors.white, width: 1),
          ),
        ),
        labelColor: AppColors.blue900,
        labelStyle: TextStyle(
          fontFamily: AppTypography.sans,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelColor: AppColors.slate600,
        unselectedLabelStyle: TextStyle(
          fontFamily: AppTypography.sans,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        dividerColor: AppColors.slate200,
        dividerHeight: 1,
        overlayColor: WidgetStatePropertyAll(AppColors.slate100),
      ),
    );
  }
}
