import 'package:flutter/material.dart';

import 'motion.dart';

/// The visual identity (docs/DESIGN.md §2): soft blues from the logo on a warm off-white,
/// with restrained wood and beige accents. Every screen takes its colours, type, shapes
/// and spacing from here; contrast of each text pairing is checked in DESIGN.md.
abstract final class AppColors {
  // Blues from the logo.
  static const primary = Color(0xFF2F5F97); // deep logo blue: buttons, links (white text 6.6:1)
  static const onPrimary = Color(0xFFFFFFFF);
  static const softBlue = Color(0xFFDCEAF6); // the hat's light blue: soft containers
  static const onSoftBlue = Color(0xFF173A5E);
  static const brandBlue = Color(0xFF3E7DB3); // icons, progress, focus; never body text

  // Warm accents from the utensils.
  static const wood = Color(0xFF8A5A2E);
  static const woodLight = Color(0xFFDBAC81); // decoration only
  static const beige = Color(0xFFF3E6D6);
  static const onBeige = Color(0xFF5A3A1C);

  // Surfaces: warm off-white, never pure white.
  static const background = Color(0xFFF8F6F1);
  static const card = Color(0xFFFFFDF9);
  static const surfaceLow = Color(0xFFF4F1EB);
  static const surfaceMid = Color(0xFFEFEBE4);
  static const surfaceHigh = Color(0xFFE9E4DC);

  // Text and lines.
  static const ink = Color(0xFF1F2A36);
  static const inkSoft = Color(0xFF56616D);
  static const outline = Color(0xFF7D868F);
  static const hairline = Color(0xFFE3DED5);

  // States.
  static const error = Color(0xFFB3261E);
  static const errorContainer = Color(0xFFF9DEDC);
  static const onErrorContainer = Color(0xFF5F1410);
  static const success = Color(0xFF2E7D4F);
  static const successContainer = Color(0xFFE2F0E6);
  static const timerDone = Color(0xFF9A5B00);
  static const timerDoneContainer = Color(0xFFFBEBD3);
  static const onTimerDoneContainer = Color(0xFF6B4A1F);
}

/// Spacing scale (4-point grid).
abstract final class Space {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// Screen side padding.
  static const page = 16.0;

  /// Content never grows wider than this (tablets, landscape).
  static const maxContentWidth = 640.0;
}

abstract final class Radii {
  static const card = 20.0;
  static const input = 14.0;
  static const chip = 12.0;
  static const sheet = 28.0;
  static const dialog = 24.0;
}

/// Colours outside Material's [ColorScheme] roles.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette();

  Color get success => AppColors.success;
  Color get successContainer => AppColors.successContainer;
  Color get timerDone => AppColors.timerDone;
  Color get timerDoneContainer => AppColors.timerDoneContainer;
  Color get onTimerDoneContainer => AppColors.onTimerDoneContainer;
  Color get wood => AppColors.wood;
  Color get woodLight => AppColors.woodLight;
  Color get beige => AppColors.beige;
  Color get onBeige => AppColors.onBeige;
  Color get brandBlue => AppColors.brandBlue;

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) => this;
}

extension AppThemeX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>() ?? const AppPalette();
}

const _scheme = ColorScheme(
  brightness: Brightness.light,
  primary: AppColors.primary,
  onPrimary: AppColors.onPrimary,
  primaryContainer: AppColors.softBlue,
  onPrimaryContainer: AppColors.onSoftBlue,
  secondary: AppColors.wood,
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: AppColors.beige,
  onSecondaryContainer: AppColors.onBeige,
  tertiary: AppColors.brandBlue,
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: AppColors.successContainer,
  onTertiaryContainer: Color(0xFF1C4A2F),
  error: AppColors.error,
  onError: Color(0xFFFFFFFF),
  errorContainer: AppColors.errorContainer,
  onErrorContainer: AppColors.onErrorContainer,
  surface: AppColors.background,
  onSurface: AppColors.ink,
  onSurfaceVariant: AppColors.inkSoft,
  surfaceContainerLowest: AppColors.card,
  surfaceContainerLow: AppColors.surfaceLow,
  surfaceContainer: AppColors.surfaceMid,
  surfaceContainerHigh: AppColors.surfaceHigh,
  surfaceContainerHighest: Color(0xFFE2DCD2),
  outline: AppColors.outline,
  outlineVariant: AppColors.hairline,
  inverseSurface: AppColors.ink,
  onInverseSurface: AppColors.background,
  inversePrimary: Color(0xFFA9C8EC),
  shadow: Color(0xFF1F2A36),
  scrim: Color(0xFF1F2A36),
  // No blue tint on raised surfaces: elevation stays warm.
  surfaceTint: Colors.transparent,
);

const _font = 'Heebo';

// Sizes are a little above Material's defaults: the phone is often read from a counter.
const _text = TextTheme(
  displaySmall: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.2),
  headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.25),
  headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.3),
  titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.35),
  titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, height: 1.4),
  titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.4),
  bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, height: 1.55),
  bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
  bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.45),
  labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.25),
  labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.3),
  labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.3),
);

/// Countdowns and quantities: digits of equal width, so a ticking timer doesn't jitter.
const tabularFigures = [FontFeature.tabularFigures()];

ThemeData buildAppTheme() {
  final text = _text.apply(fontFamily: _font, bodyColor: AppColors.ink, displayColor: AppColors.ink);
  const stadium = StadiumBorder();
  final cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Radii.card),
    side: const BorderSide(color: AppColors.hairline),
  );
  OutlineInputBorder inputBorder(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.input),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: _scheme,
    fontFamily: _font,
    textTheme: text,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    extensions: const [AppPalette()],
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: DirectionalPageTransitionsBuilder(),
        TargetPlatform.iOS: DirectionalPageTransitionsBuilder(),
        TargetPlatform.windows: DirectionalPageTransitionsBuilder(),
        TargetPlatform.linux: DirectionalPageTransitionsBuilder(),
        TargetPlatform.macOS: DirectionalPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: AppColors.hairline,
      centerTitle: false,
      titleSpacing: Space.s,
      titleTextStyle: text.titleLarge,
      iconTheme: const IconThemeData(color: AppColors.ink),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        padding: const EdgeInsets.symmetric(horizontal: Space.xl, vertical: Space.m),
        shape: stadium,
        textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.s),
        shape: stadium,
        side: const BorderSide(color: AppColors.outline),
        foregroundColor: AppColors.primary,
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: Space.m),
        shape: stadium,
        foregroundColor: AppColors.primary,
        textStyle: text.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(minimumSize: const Size(48, 48))),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: Space.xs + 2),
      shape: cardShape,
      clipBehavior: Clip.antiAlias,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m + 2),
      hintStyle: text.bodyMedium?.copyWith(color: AppColors.inkSoft),
      border: inputBorder(AppColors.hairline),
      enabledBorder: inputBorder(AppColors.outline.withValues(alpha: 0.55)),
      focusedBorder: inputBorder(AppColors.primary, 2),
      errorBorder: inputBorder(AppColors.error),
      disabledBorder: inputBorder(AppColors.hairline),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.card,
      selectedColor: AppColors.softBlue,
      side: const BorderSide(color: AppColors.hairline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.chip)),
      labelStyle: text.labelLarge?.copyWith(color: AppColors.ink),
      padding: const EdgeInsets.symmetric(horizontal: Space.s, vertical: Space.xs + 2),
      checkmarkColor: AppColors.onSoftBlue,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: AppColors.outline,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet))),
      clipBehavior: Clip.antiAlias,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.dialog)),
      titleTextStyle: text.titleLarge,
      contentTextStyle: text.bodyMedium,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: text.bodyMedium?.copyWith(color: AppColors.background),
      actionTextColor: const Color(0xFFA9C8EC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.input)),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: AppColors.brandBlue,
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.l),
      minVerticalPadding: Space.s + 2,
      titleTextStyle: text.titleMedium,
      subtitleTextStyle: text.bodySmall?.copyWith(color: AppColors.inkSoft),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.input)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.brandBlue,
      linearTrackColor: AppColors.softBlue,
      linearMinHeight: 6,
      circularTrackColor: AppColors.softBlue,
      borderRadius: BorderRadius.all(Radius.circular(3)),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      width: 300,
    ),
    navigationDrawerTheme: NavigationDrawerThemeData(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.softBlue,
      tileHeight: 52,
      labelTextStyle: WidgetStatePropertyAll(text.titleMedium),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.hairline, thickness: 1, space: Space.l),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: const BorderSide(color: AppColors.outline, width: 1.5),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.inkSoft,
      indicatorColor: AppColors.primary,
      dividerColor: AppColors.hairline,
      labelStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      unselectedLabelStyle: text.labelLarge,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: AppColors.softBlue,
        selectedForegroundColor: AppColors.onSoftBlue,
        side: const BorderSide(color: AppColors.hairline),
        minimumSize: const Size(48, 48),
        textStyle: text.labelLarge,
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(8)),
      textStyle: text.bodySmall?.copyWith(color: AppColors.background),
      waitDuration: Motion.long,
    ),
  );
}

final appTheme = buildAppTheme();
