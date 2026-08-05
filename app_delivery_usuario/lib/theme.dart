import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF0077CC);
  static const primaryDark = Color(0xFF005FA3);
  static const primaryLight = Color(0xFF35A7E8);
  static const primaryTint = Color(0xFFE7F4FC);
  static const secondary = Color(0xFF00B4D8);
  static const secondaryTint = Color(0xFFE2F8FC);

  static const appText = Color(0xFF17212B);
  static const textMuted = Color(0xFF667684);
  static const textSubtle = Color(0xFF93A1AD);
  static const border = Color(0xFFE2E8EE);
  static const bg = Color(0xFFF5F7FA);
  static const bgAlt = Color(0xFFEDF2F6);
  static const surface = Color(0xFFFFFFFF);

  static const darkBg = Color(0xFF0F151B);
  static const darkSurface = Color(0xFF182128);
  static const darkSurfaceHigh = Color(0xFF202C35);
  static const darkBorder = Color(0xFF34434E);
  static const darkText = Color(0xFFF0F5F8);
  static const darkTextMuted = Color(0xFFB5C1CA);
  static const darkPrimary = Color(0xFF45A9EE);
  static const darkSecondary = Color(0xFF42C6E3);

  static const star = Color(0xFFFFB703);
  static const success = Color(0xFF15976C);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFD9363E);
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const section = 32.0;
}

abstract final class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
}

abstract final class AppShadows {
  static const card = [
    BoxShadow(color: Color(0x0D17212B), blurRadius: 16, offset: Offset(0, 5)),
  ];
  static const raised = [
    BoxShadow(color: Color(0x260077CC), blurRadius: 18, offset: Offset(0, 7)),
  ];
}

abstract final class AppTextStyles {
  static const pageTitle = TextStyle(
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w800,
  );
  static const sectionTitle = TextStyle(
    fontSize: 18,
    height: 1.25,
    fontWeight: FontWeight.w800,
  );
  static const cardTitle = TextStyle(
    fontSize: 15,
    height: 1.25,
    fontWeight: FontWeight.w700,
  );
  static const body = TextStyle(fontSize: 14, height: 1.45);
  static const caption = TextStyle(fontSize: 12, height: 1.35);
}

@immutable
class DeliSemanticColors extends ThemeExtension<DeliSemanticColors> {
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarningContainer;
  final Color warningContainer;
  final Color info;
  final Color infoContainer;
  final Color onInfoContainer;

  const DeliSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarningContainer,
    required this.warningContainer,
    required this.info,
    required this.infoContainer,
    required this.onInfoContainer,
  });

  static const light = DeliSemanticColors(
    success: Color(0xFF087A56),
    onSuccess: Colors.white,
    successContainer: Color(0xFFDDF5EA),
    onSuccessContainer: Color(0xFF075A42),
    warning: Color(0xFFB86A00),
    warningContainer: Color(0xFFFFE9C7),
    onWarningContainer: Color(0xFF6B3B00),
    info: AppColors.primary,
    infoContainer: AppColors.primaryTint,
    onInfoContainer: AppColors.primaryDark,
  );

  static const dark = DeliSemanticColors(
    success: Color(0xFF55D4A4),
    onSuccess: Color(0xFF062E22),
    successContainer: Color(0xFF123E31),
    onSuccessContainer: Color(0xFFA7EBCD),
    warning: Color(0xFFFFC266),
    warningContainer: Color(0xFF4A3514),
    onWarningContainer: Color(0xFFFFD99C),
    info: AppColors.darkPrimary,
    infoContainer: Color(0xFF14364D),
    onInfoContainer: Color(0xFFA9D9F8),
  );

  @override
  DeliSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarningContainer,
    Color? warningContainer,
    Color? info,
    Color? infoContainer,
    Color? onInfoContainer,
  }) => DeliSemanticColors(
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    successContainer: successContainer ?? this.successContainer,
    onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    warning: warning ?? this.warning,
    onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    warningContainer: warningContainer ?? this.warningContainer,
    info: info ?? this.info,
    infoContainer: infoContainer ?? this.infoContainer,
    onInfoContainer: onInfoContainer ?? this.onInfoContainer,
  );

  @override
  DeliSemanticColors lerp(
    covariant ThemeExtension<DeliSemanticColors>? other,
    double t,
  ) {
    if (other is! DeliSemanticColors) return this;
    return DeliSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
    );
  }
}

extension DeliThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  DeliSemanticColors get semantic =>
      Theme.of(this).extension<DeliSemanticColors>() ??
      (isDark ? DeliSemanticColors.dark : DeliSemanticColors.light);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

abstract final class AppTheme {
  static const lightScheme = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primaryTint,
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.secondary,
    onSecondary: Color(0xFF003640),
    secondaryContainer: AppColors.secondaryTint,
    onSecondaryContainer: Color(0xFF004955),
    error: AppColors.danger,
    onError: Colors.white,
    errorContainer: Color(0xFFFDE7E9),
    onErrorContainer: Color(0xFF7B1720),
    surface: AppColors.surface,
    onSurface: AppColors.appText,
    onSurfaceVariant: AppColors.textMuted,
    outline: AppColors.textSubtle,
    outlineVariant: AppColors.border,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: AppColors.bg,
    surfaceContainer: AppColors.bgAlt,
    surfaceContainerHigh: Color(0xFFE6EDF2),
    surfaceContainerHighest: Color(0xFFDCE5EB),
    shadow: Color(0x3317212B),
  );

  static const darkScheme = ColorScheme.dark(
    primary: AppColors.darkPrimary,
    onPrimary: Color(0xFF002F4D),
    primaryContainer: Color(0xFF123C57),
    onPrimaryContainer: Color(0xFFB9E1FA),
    secondary: AppColors.darkSecondary,
    onSecondary: Color(0xFF003640),
    secondaryContainer: Color(0xFF123D45),
    onSecondaryContainer: Color(0xFFB7EAF2),
    error: Color(0xFFFF818B),
    onError: Color(0xFF4A0710),
    errorContainer: Color(0xFF501D24),
    onErrorContainer: Color(0xFFFFC2C7),
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkText,
    onSurfaceVariant: AppColors.darkTextMuted,
    outline: Color(0xFF81909B),
    outlineVariant: AppColors.darkBorder,
    surfaceContainerLowest: AppColors.darkBg,
    surfaceContainerLow: Color(0xFF131C22),
    surfaceContainer: AppColors.darkSurface,
    surfaceContainerHigh: AppColors.darkSurfaceHigh,
    surfaceContainerHighest: Color(0xFF293740),
    shadow: Colors.black,
  );

  static final ThemeData light = _build(lightScheme, DeliSemanticColors.light);
  static final ThemeData dark = _build(darkScheme, DeliSemanticColors.dark);

  static ThemeData _build(ColorScheme scheme, DeliSemanticColors semantic) {
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      brightness: scheme.brightness,
      scaffoldBackgroundColor: scheme.surfaceContainerLowest,
      canvasColor: scheme.surfaceContainerLowest,
      visualDensity: VisualDensity.standard,
      extensions: [semantic],
    );
    final textTheme = base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );

    return base.copyWith(
      textTheme: textTheme,
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      primaryIconTheme: IconThemeData(color: scheme.onPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: scheme.onSurface),
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        hintStyle: textTheme.bodyMedium?.copyWith(color: scheme.outline),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        disabledBorder: inputBorder.copyWith(
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 54),
          foregroundColor: scheme.onPrimary,
          backgroundColor: scheme.primary,
          disabledBackgroundColor: scheme.surfaceContainerHighest,
          disabledForegroundColor: scheme.outline,
          shape: rounded,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 52),
          foregroundColor: scheme.onPrimary,
          backgroundColor: scheme.primary,
          disabledBackgroundColor: scheme.surfaceContainerHighest,
          disabledForegroundColor: scheme.outline,
          elevation: 0,
          shape: rounded,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 50),
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outlineVariant),
          shape: rounded,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.primaryContainer,
        disabledColor: scheme.surfaceContainerLow,
        labelStyle: textTheme.labelMedium?.copyWith(color: scheme.onSurface),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onPrimaryContainer,
        ),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        shape: rounded,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest,
        ),
        trackOutlineColor: WidgetStateProperty.all(scheme.outlineVariant),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(scheme.onPrimary),
        side: BorderSide(color: scheme.outline),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.outline,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        modalBackgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: scheme.outline,
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        elevation: 0,
      ),
    );
  }
}

ThemeData buildTheme() => AppTheme.light;
