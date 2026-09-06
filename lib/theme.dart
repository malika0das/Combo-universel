import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// ---------------------------------------------------------------------------
/// Brand palette
/// ---------------------------------------------------------------------------
/// A deep, slightly desaturated indigo-blue reads as "professional tool"
/// rather than "consumer app", and keeps the amber highlight legible on top.
const Color brandSeed = Color(0xFF1B4FD8);
const Color brandAccent = Color(0xFFF0A500);
const Color brandInk = Color(0xFF0B1220);

/// Surface tints used for the light theme. Material's default surfaces are a
/// little flat for a list-heavy app, so we hand-pick a soft neutral stack.
const Color _lightBg = Color(0xFFF4F6FB);
const Color _lightSurface = Color(0xFFFFFFFF);
const Color _darkBg = Color(0xFF0B0F17);
const Color _darkSurface = Color(0xFF141A24);

/// ---------------------------------------------------------------------------
/// Typography
/// ---------------------------------------------------------------------------
/// Sora for headings (geometric, premium), Inter for body/UI (dense-list
/// legibility), JetBrains Mono for part codes (unambiguous 0/O and 1/l).
///
/// `google_fonts` resolves these from `assets/google_fonts/` when the TTFs are
/// bundled (see tools/fetch_fonts.sh) and silently falls back to the platform
/// font otherwise, so the app never blocks on a network call.
class AppFonts {
  const AppFonts._();

  static TextStyle display(TextStyle? base) => GoogleFonts.sora(textStyle: base);
  static TextStyle body(TextStyle? base) => GoogleFonts.inter(textStyle: base);
  static TextStyle mono(TextStyle? base) =>
      GoogleFonts.jetBrainsMono(textStyle: base);

  /// Monospaced style for part codes, battery numbers and SKUs.
  static TextStyle code(BuildContext context, {double size = 12.5, Color? color}) =>
      GoogleFonts.jetBrainsMono(
        textStyle: TextStyle(
          fontSize: size,
          height: 1.2,
          letterSpacing: 0.2,
          fontWeight: FontWeight.w500,
          color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
}

/// A hand-tuned type scale. Sizes step on a ~1.2 ratio; tracking tightens as
/// size grows, which is what makes large headings feel designed rather than
/// merely big.
TextTheme _buildTextTheme(ColorScheme scheme) {
  final onSurface = scheme.onSurface;
  final muted = scheme.onSurfaceVariant;

  TextStyle heading(double size, FontWeight weight, double tracking,
          {double height = 1.18, Color? color}) =>
      AppFonts.display(TextStyle(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: tracking,
        height: height,
        color: color ?? onSurface,
      ));

  TextStyle text(double size, FontWeight weight, double tracking,
          {double height = 1.42, Color? color}) =>
      AppFonts.body(TextStyle(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: tracking,
        height: height,
        color: color ?? onSurface,
      ));

  return TextTheme(
    displayLarge: heading(44, FontWeight.w700, -1.2),
    displayMedium: heading(36, FontWeight.w700, -1.0),
    displaySmall: heading(30, FontWeight.w700, -0.8),
    headlineLarge: heading(28, FontWeight.w700, -0.7),
    headlineMedium: heading(24, FontWeight.w700, -0.5),
    headlineSmall: heading(21, FontWeight.w700, -0.4),
    titleLarge: heading(19, FontWeight.w700, -0.3, height: 1.25),
    titleMedium: heading(16, FontWeight.w600, -0.15, height: 1.3),
    titleSmall: heading(14, FontWeight.w600, 0.0, height: 1.3),
    bodyLarge: text(15.5, FontWeight.w400, 0.0),
    bodyMedium: text(14, FontWeight.w400, 0.05),
    bodySmall: text(12.5, FontWeight.w400, 0.1, height: 1.38, color: muted),
    labelLarge: text(14, FontWeight.w600, 0.1, height: 1.2),
    labelMedium: text(12.5, FontWeight.w600, 0.3, height: 1.2),
    labelSmall: text(11, FontWeight.w600, 0.6, height: 1.2, color: muted),
  );
}

/// ---------------------------------------------------------------------------
/// Theme
/// ---------------------------------------------------------------------------
ThemeData buildTheme(Brightness brightness) {
  final isLight = brightness == Brightness.light;

  final base = ColorScheme.fromSeed(
    seedColor: brandSeed,
    brightness: brightness,
  );

  final scheme = base.copyWith(
    surface: isLight ? _lightSurface : _darkSurface,
    // The amber accent carries the search highlight and "hot" badges.
    tertiary: brandAccent,
    tertiaryContainer: isLight ? const Color(0xFFFFECC2) : const Color(0xFF4A3505),
    onTertiaryContainer: isLight ? const Color(0xFF4A3505) : const Color(0xFFFFDFA0),
    outlineVariant: isLight ? const Color(0xFFE2E7F0) : const Color(0xFF27303E),
  );

  final textTheme = _buildTextTheme(scheme);
  final radius = BorderRadius.circular(18);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    scaffoldBackgroundColor: isLight ? _lightBg : _darkBg,
    canvasColor: isLight ? _lightBg : _darkBg,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,

    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: isLight ? _lightBg : _darkBg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      titleSpacing: 20,
      titleTextStyle: textTheme.titleLarge,
      systemOverlayStyle:
          isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      iconTheme: IconThemeData(color: scheme.onSurface, size: 22),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      hintStyle: textTheme.bodyMedium?.copyWith(color: scheme.outline),
      labelStyle: textTheme.bodyMedium,
      prefixIconColor: scheme.onSurfaceVariant,
      suffixIconColor: scheme.onSurfaceVariant,
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),

    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: radius),
      titleTextStyle: textTheme.titleSmall,
      subtitleTextStyle: textTheme.bodySmall,
      iconColor: scheme.onSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),

    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide(color: scheme.outlineVariant),
      backgroundColor: isLight ? const Color(0xFFF7F9FC) : const Color(0xFF1B2330),
      selectedColor: scheme.primaryContainer,
      labelStyle: textTheme.labelMedium,
      secondaryLabelStyle: textTheme.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      showCheckmark: false,
      elevation: 0,
      pressElevation: 0,
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 50),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: textTheme.labelLarge,
      ),
    ),

    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface),
      backgroundColor: scheme.inverseSurface,
      insetPadding: const EdgeInsets.all(16),
    ),

    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor: scheme.primary,
      inactiveTrackColor: scheme.outlineVariant,
      thumbColor: scheme.primary,
      overlayColor: scheme.primary.withValues(alpha: 0.12),
      trackHeight: 4,
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
    ),

    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.outlineVariant,
    ),

    iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 22),

    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
  );
}

/// ---------------------------------------------------------------------------
/// Spacing scale — use these instead of magic numbers so rhythm stays even.
/// ---------------------------------------------------------------------------
class Gap {
  const Gap._();
  static const xs = SizedBox(height: 4);
  static const sm = SizedBox(height: 8);
  static const md = SizedBox(height: 12);
  static const lg = SizedBox(height: 16);
  static const xl = SizedBox(height: 24);
  static const xxl = SizedBox(height: 32);

  static const wXs = SizedBox(width: 4);
  static const wSm = SizedBox(width: 8);
  static const wMd = SizedBox(width: 12);
  static const wLg = SizedBox(width: 16);
}

/// Per-category accent colour, so the eye can tell part types apart in a list.
Color accentFor(String key, ColorScheme scheme) {
  switch (key) {
    case 'battery':
      return const Color(0xFF17A673);
    case 'glass':
      return const Color(0xFF00A3C4);
    case 'board':
      return const Color(0xFF9B5DE5);
    case 'case':
      return const Color(0xFFE8618C);
    case 'frame':
      return const Color(0xFFF0A500);
    default:
      return scheme.primary;
  }
}

IconData iconFor(String key) {
  switch (key) {
    case 'battery':
      return Icons.battery_charging_full_rounded;
    case 'glass':
      return Icons.shield_moon_outlined;
    case 'board':
      return Icons.developer_board_rounded;
    case 'frame':
      return Icons.crop_square_rounded;
    case 'case':
      return Icons.phonelink_ring_rounded;
    default:
      return Icons.smartphone_rounded;
  }
}
