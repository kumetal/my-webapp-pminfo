import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/air_pollution_model.dart';

class ApiService {
  static const String _baseUrl = 'https://apis.data.go.kr/B552584';
  static const String _apiKey = '58bf1f622579d5e10cf8fd8c59032b5ce42ecef7541495f853329cc6b0587b2a';

  // 근접 측정소 목록 조회 (최대 3개)
  Future<List<Station>> getNearbyStations(double tmX, double tmY) async {
    final url = '$_baseUrl/MsrstnInfoInqireSvc/getNearbyMsrstnList?serviceKey=$_apiKey&returnType=json&tmX=$tmX&tmY=$tmY&ver=1.1';
    try {
      final response = await http.get(Uri.parse(url));
      debugPrint('Nearby Stations Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['response']['body']['items'];
        if (items != null && items is List) {
          return items.take(3).map((x) => Station.fromJson(x)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error getting nearby stations: $e');
    }
    return [];
  }

  // 측정소별 실시간 측정정보 조회
  Future<AirPollution?> getAirPollution(String stationName) async {
    final url = '$_baseUrl/ArpltnInforInqireSvc/getMsrstnAcctoRltmMesureDnsty?serviceKey=$_apiKey&returnType=json&stationName=${Uri.encodeComponent(stationName)}&dataTerm=daily&ver=1.4';
    try {
      final response = await http.get(Uri.parse(url));
      debugPrint('Air Pollution Response ($stationName): ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['response']['body']['items'];
        if (items != null && items.isNotEmpty) {
          return AirPollution.fromJson(items[0], stationName);
        }
      }
    } catch (e) {
      debugPrint('Error getting air pollution: $e');
    }
    return null;
  }

  // 대기질 예보통보 조회
  Future<List<DustForecast>> getDustForecast() async {
    final url = '$_baseUrl/ArpltnInforInqireSvc/getMinuDustFrcstDspth?serviceKey=$_apiKey&returnType=json&searchDate=${DateTime.now().toString().split(' ')[0]}&InformCode=PM10';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['response']['body']['items'];
        if (items != null) {
          return List<DustForecast>.from(items.map((x) => DustForecast.fromJson(x)));
        }
      }
    } catch (e) {
      debugPrint('Error getting dust forecast: $e');
    }
    return [];
  }

  // TM 좌표 조회 (읍면동 이름으로)
  Future<Map<String, double>?> getTMCoordinates(String umdName) async {
    final url = '$_baseUrl/MsrstnInfoInqireSvc/getTMStdrCrdnt?serviceKey=$_apiKey&returnType=json&umdName=${Uri.encodeComponent(umdName)}';
    try {
      final response = await http.get(Uri.parse(url));
      debugPrint('TM Coordinate Response ($umdName): ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['response']['body']['items'];
        if (items != null && items.isNotEmpty) {
          return {
            'tmX': double.tryParse(items[0]['tmX']?.toString() ?? '0.0') ?? 0.0,
            'tmY': double.tryParse(items[0]['tmY']?.toString() ?? '0.0') ?? 0.0,
          };
        }
      }
    } catch (e) {
      debugPrint('Error getting TM coordinates: $e');
    }
    return null;
  }
}
