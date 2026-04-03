import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeConfig {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      textTheme: GoogleFonts.outfitTextTheme(),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF673AB7),
        brightness: Brightness.light,
      ),
    );
  }

  static BoxDecoration get mainGradient => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF673AB7), Color(0xFF512DA8), Color(0xFF311B92)],
        ),
      );

  static Color getGradeColor(String grade) {
    switch (grade) {
      case '1': // 최고 (진한 남색/보라)
        return const Color(0xFF311B92);
      case '2': // 좋음 (밝은 파랑)
        return const Color(0xFF03A9F4);
      case '3': // 양호 (청록)
        return const Color(0xFF00BCD4);
      case '4': // 보통 (초록)
        return const Color(0xFF388E3C);
      case '5': // 나쁨 (오렌지)
        return const Color(0xFFF57C00);
      case '6': // 상당히 나쁨 (진한 오렌지)
        return const Color(0xFFE64A19);
      case '7': // 매우 나쁨 (빨강)
        return const Color(0xFFD32F2F);
      case '8': // 최악 (검정)
        return const Color(0xFF212121);
      default:
        return Colors.grey;
    }
  }

  static String getGradeText(String grade) {
    switch (grade) {
      case '1':
        return '최고';
      case '2':
        return '좋음';
      case '3':
        return '양호';
      case '4':
        return '보통';
      case '5':
        return '나쁨';
      case '6':
        return '상당히 나쁨';
      case '7':
        return '매우 나쁨';
      case '8':
        return '최악';
      default:
        return '알 수 없음';
    }
  }
}
