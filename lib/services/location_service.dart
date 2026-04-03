import 'package:geolocator/geolocator.dart';

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

  // WGS/GRS80(Lat/Lon) -> TM(중부원점) 간단 변환 로직
  Map<String, double> convertToTM(double lat, double lon) {
    // 한국 중부원점 (GRS80 기반 TM 중부원점 가이드 기준) 단순 변환
    // 실제 정교한 변환 대신 근사치 수식 사용 (Lon 1도 당 약 88km, Lat 1도 당 약 111km)
    double tmX = 200000 + (lon - 127) * 88000;
    double tmY = 500000 + (lat - 38) * 111000; 
    return {'tmX': tmX, 'tmY': tmY};
  }
}
