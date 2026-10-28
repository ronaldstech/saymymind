import 'package:flutter/material.dart';

abstract final class AppColors {
  static const softBlue = Color(0xFFADDFF1);
  static const prestigeMauve = Color(0xFF003152);
  static const martianGreen = Color(0xFF99CC33);
  static const darkGreen = Color(0xFF003333);
  static const black = Color(0xFF000000);
  static const orangeYellow = Color(0xFFFDBF2D);

  // Shared semantic colors keep screens aligned with the brand palette.
  static const canvas = softBlue;
  static const muted = darkGreen;
}

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.martianGreen,
          primary: AppColors.prestigeMauve,
          secondary: AppColors.martianGreen,
          tertiary: AppColors.orangeYellow,
          surface: AppColors.softBlue,
          onSurface: AppColors.black,
        ),
        fontFamily: 'Roboto',
      );
}

