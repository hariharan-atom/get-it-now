import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

abstract final class AppColors {
  static const ink = Color(0xFF080909);
  static const lavender = Color(0xFFF0EEFA);
  static const blue = Color(0xFFDFE4F2);
  static const mint = Color(0xFFB8E8C5);
  static const paleGreen = Color(0xFFEDF9F0);
  static const forest = Color(0xFF174D2A);
  static const muted = Color(0xFF62636B);
  static const line = Color(0xFFE1DFE8);
}

TextStyle headline(double size, {Color color = AppColors.ink}) => TextStyle(
  fontFamily: 'Epilogue',
  fontWeight: FontWeight.w900,
  fontSize: size,
  height: 1.08,
  letterSpacing: -1.6,
  color: color,
);

ThemeData appTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'DM Sans',
  scaffoldBackgroundColor: AppColors.lavender,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.forest,
    primary: AppColors.forest,
    onPrimary: Colors.white,
    surface: AppColors.lavender,
    onSurface: AppColors.ink,
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(fontSize: 16, height: 1.5),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.mint,
      foregroundColor: AppColors.ink,
      minimumSize: const Size(48, 58),
      textStyle: const TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.ink,
      minimumSize: const Size(48, 56),
      side: const BorderSide(color: AppColors.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.all(18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.line),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: AppColors.forest,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
);

extension Entrance on Widget {
  Widget enter(BuildContext context, {int delay = 0}) =>
      MediaQuery.disableAnimationsOf(context)
      ? this
      : animate()
            .fadeIn(duration: 380.ms, delay: delay.ms)
            .slideY(
              begin: .06,
              end: 0,
              duration: 380.ms,
              curve: Curves.easeOutCubic,
            );
}

Duration motionDuration(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : const Duration(milliseconds: 260);
