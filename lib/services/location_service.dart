import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class LocationService {
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  // WGS84(Lat/Lon) -> TM(중부원점, GRS80) 변환 로직
  // 에어코리아 API에서 사용하는 중부원점(127도, 38도) 기준 TM 좌표계 (EPSG:5186 가이드 기반)
  Map<String, double> convertToTM(double lat, double lon) {
    const double a = 6378137.0; // GRS80 장축
    const double f = 1 / 298.257222101; // GRS80 편평률
    const double k0 = 1.0; // 투영 계수
    const double lat0 = 38.0 * (math.pi / 180.0); // 원점 위도
    const double lon0 = 127.0 * (math.pi / 180.0); // 원점 경도
    const double x0 = 200000.0; // False Easting
    const double y0 = 500000.0; // False Northing

    final double latRad = lat * (math.pi / 180.0);
    final double lonRad = lon * (math.pi / 180.0);

    final double b = a * (1 - f);
    final double e2 = (a * a - b * b) / (a * a);
    final double ep2 = (a * a - b * b) / (b * b);

    final double nu = a / math.sqrt(1 - e2 * math.sin(latRad) * math.sin(latRad));
    final double p = lonRad - lon0;

    // Meridional Distance M
    final double m = a * ((1 - e2 / 4 - 3 * e2 * e2 / 64 - 5 * e2 * e2 * e2 / 256) * latRad -
            (3 * e2 / 8 + 3 * e2 * e2 / 32 + 45 * e2 * e2 * e2 / 1024) * math.sin(2 * latRad) +
            (15 * e2 * e2 / 256 + 45 * e2 * e2 * e2 / 1024) * math.sin(4 * latRad) -
            (35 * e2 * e2 * e2 / 3072) * math.sin(6 * latRad));

    final double m0 = a * ((1 - e2 / 4 - 3 * e2 * e2 / 64 - 5 * e2 * e2 * e2 / 256) * lat0 -
            (3 * e2 / 8 + 3 * e2 * e2 / 32 + 45 * e2 * e2 * e2 / 1024) * math.sin(2 * lat0) +
            (15 * e2 * e2 / 256 + 45 * e2 * e2 * e2 / 1024) * math.sin(4 * lat0) -
            (35 * e2 * e2 * e2 / 3072) * math.sin(6 * lat0));

    final double t = math.tan(latRad) * math.tan(latRad);
    final double c = ep2 * math.cos(latRad) * math.cos(latRad);
    final double aVal = p * math.cos(latRad);

    final double x = x0 +
        k0 *
            nu *
            (aVal +
                (1 - t + c) * math.pow(aVal, 3) / 6 +
                (5 - 18 * t + t * math.pow(t, 2) + 72 * c - 58 * ep2) * math.pow(aVal, 5) / 120);
    final double y = y0 +
        k0 *
            (m -
                m0 +
                nu *
                    math.tan(latRad) *
                    (math.pow(aVal, 2) / 2 +
                        (5 - t + 9 * c + 4 * math.pow(c, 2)) * math.pow(aVal, 4) / 24 +
                        (61 - 58 * t + math.pow(t, 2) + 600 * c - 330 * ep2) * math.pow(aVal, 6) / 720));

    return {'tmX': x, 'tmY': y};
  }
}
