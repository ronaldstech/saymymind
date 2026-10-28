import 'package:flutter/material.dart';

abstract final class AppColors {
  static const canvas = Color(0xFFF6F5EF);
  static const ink = Color(0xFF17211D);
  static const muted = Color(0xFF758078);
  static const lime = Color(0xFFB9F278);
  static const softGreen = Color(0xFFE9EEDF);
  static const lavender = Color(0xFFD8D2F4);
  static const peach = Color(0xFFE8A990);
  static const noteMuted = Color(0xFFC3CDC5);
}

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.canvas,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.lime),
        fontFamily: 'Roboto',
      );
}
