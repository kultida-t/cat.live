import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static const fontFamily = 'IBMPlexSansThaiLooped';

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.ink,
      brightness: Brightness.light,
      surface: AppColors.page,
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.page,
      splashFactory: NoSplash.splashFactory,
      textTheme: ThemeData.light().textTheme.apply(
        fontFamily: fontFamily,
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      dividerColor: AppColors.line,
    );
  }
}
