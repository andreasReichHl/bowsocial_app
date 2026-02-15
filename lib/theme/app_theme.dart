import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static const TextTheme appTextTheme = TextTheme(
    displayLarge: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w700),
    displayMedium: TextStyle(
      fontFamily: 'Manrope',
      fontWeight: FontWeight.w600,
    ),
    displaySmall: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w400),
    headlineMedium: TextStyle(
      fontFamily: 'Manrope',
      fontWeight: FontWeight.w100,
      fontSize: 42,
      letterSpacing: 2,
    ),
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    textTheme: appTextTheme,
    colorScheme: ColorScheme(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      brightness: Brightness.light,
      secondary: AppColors.secondary,
      onSecondary: Colors.black,
      error: Colors.red,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: Colors.lightGreen,
    ),
    scaffoldBackgroundColor: AppColors.background,
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    textTheme: appTextTheme,
    fontFamily: 'Inter',
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.darkPrimary,
      onPrimary: Colors.white,
      secondary: Colors.white,
      onSecondary: Colors.white,
      error: Colors.red,
      onError: Colors.red,
      surface: AppColors.darkSurface,
      onSurface: Colors.lightGreen,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
  );
}
