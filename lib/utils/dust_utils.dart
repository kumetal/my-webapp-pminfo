enum DustStandard {
  keco, // 한국환경공단
  who, // WHO
}

class DustUtils {
  /// 수치에 따른 미세먼지(PM10) 등급 계산
  static String getPm10Grade(int value, DustStandard standard) {
    if (standard == DustStandard.keco) {
      if (value <= 30) return '2'; // 좋음
      if (value <= 80) return '4'; // 보통
      if (value <= 150) return '5'; // 나쁨
      return '7'; // 매우 나쁨
    } else {
      // WHO 기준 (8단계 확장)
      // 최고: 0~10, 좋음: 11~22, 양호: 23~35, 보통: 36~45, 나쁨: 46~75, 상당히 나쁨: 76~100, 매우 나쁨: 101~150, 최악: 151~
      if (value <= 10) return '1'; // 최고
      if (value <= 22) return '2'; // 좋음
      if (value <= 35) return '3'; // 양호
      if (value <= 45) return '4'; // 보통
      if (value <= 75) return '5'; // 나쁨
      if (value <= 100) return '6'; // 상당히 나쁨
      if (value <= 150) return '7'; // 매우 나쁨
      return '8'; // 최악
    }
  }

  /// 수치에 따른 초미세먼지(PM2.5) 등급 계산
  static String getPm25Grade(int value, DustStandard standard) {
    if (standard == DustStandard.keco) {
      if (value <= 15) return '2'; // 좋음
      if (value <= 35) return '4'; // 보통
      if (value <= 75) return '5'; // 나쁨
      return '7'; // 매우 나쁨
    } else {
      // WHO 기준 (8단계 확장)
      // 최고: 0~5, 좋음: 6~9, 양호: 10~12, 보통: 13~15, 나쁨: 16~37, 상당히 나쁨: 38~50, 매우 나쁨: 51~75, 최악: 76~
      if (value <= 5) return '1';
      if (value <= 9) return '2';
      if (value <= 12) return '3';
      if (value <= 15) return '4';
      if (value <= 37) return '5';
      if (value <= 50) return '6';
      if (value <= 75) return '7';
      return '8';
    }
  }

  /// 두 등급 중 더 나쁜 등급을 반환 (종합 등급용)
  static String getWorseGrade(String grade1, String grade2) {
    int g1 = int.tryParse(grade1) ?? 8;
    int g2 = int.tryParse(grade2) ?? 8;
    return (g1 > g2) ? g1.toString() : g2.toString();
  }
}
