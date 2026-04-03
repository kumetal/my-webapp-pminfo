import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/air_pollution_model.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../utils/dust_utils.dart';

class DustProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();

  AirPollution? _currentLocationDust;
  final List<AirPollution> _favoriteLocationsDust = [];
  List<DustForecast> _forecasts = [];
  bool _isLoading = false;
  String? _errorMessage;
  DustStandard _standard = DustStandard.who;

  List<Station> _searchResults = [];

  AirPollution? get currentLocationDust => _currentLocationDust;
  List<AirPollution> get favoriteLocationsDust => _favoriteLocationsDust;
  List<DustForecast> get forecasts => _forecasts;
  List<Station> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DustStandard get standard => _standard;

  DustProvider() {
    _loadStandard();
  }

  // 설정된 기준 로드
  Future<void> _loadStandard() async {
    final prefs = await SharedPreferences.getInstance();
    final standardIndex = prefs.getInt('dust_standard') ?? DustStandard.who.index;
    _standard = DustStandard.values[standardIndex];
    notifyListeners();
  }

  // 기준 변경 및 저장
  Future<void> setStandard(DustStandard standard) async {
    _standard = standard;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dust_standard', standard.index);
    
    // 기준이 변경되면 현재 데이터의 등급을 다시 계산하여 반영
    if (_currentLocationDust != null) {
      _currentLocationDust = _recalculateGrade(_currentLocationDust!);
    }
    for (int i = 0; i < _favoriteLocationsDust.length; i++) {
      _favoriteLocationsDust[i] = _recalculateGrade(_favoriteLocationsDust[i]);
    }
    
    notifyListeners();
  }

  // 수치를 기반으로 현재 설정된 기준에 맞는 등급 재계산
  AirPollution _recalculateGrade(AirPollution dust) {
    final pm10Val = int.tryParse(dust.pm10Value) ?? 0;
    final pm25Val = int.tryParse(dust.pm25Value) ?? 0;
    
    final newPm10Grade = DustUtils.getPm10Grade(pm10Val, _standard);
    final newPm25Grade = DustUtils.getPm25Grade(pm25Val, _standard);
    
    return AirPollution(
      stationName: dust.stationName,
      pm10Value: dust.pm10Value,
      pm25Value: dust.pm25Value,
      dataTime: dust.dataTime,
      pm10Grade: newPm10Grade,
      pm25Grade: newPm25Grade,
      khaiValue: dust.khaiValue,
      khaiGrade: DustUtils.getWorseGrade(newPm10Grade, newPm25Grade),
    );
  }

  // 현재 위치 정보 로드
  Future<void> loadCurrentLocationDust() async {
    _isLoading = true;
    notifyListeners();

    _errorMessage = null;
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        final tmCoords = _locationService.convertToTM(position.latitude, position.longitude);
        final stations = await _apiService.getNearbyStations(tmCoords['tmX']!, tmCoords['tmY']!); 
        
        if (stations.isNotEmpty) {
          final closestStation = stations[0].stationName;
          final dust = await _apiService.getAirPollution(closestStation);
          if (dust != null) {
            _currentLocationDust = _recalculateGrade(dust);
          } else {
            _errorMessage = '측정 데이터가 없습니다. ($closestStation)';
          }
        } else {
          _errorMessage = '가까운 측정소를 찾을 수 없습니다.';
          debugPrint('No nearby station found for TM: $tmCoords');
        }
      } else {
        _errorMessage = '위치 정보를 가져올 수 없습니다. GPS와 권한을 확인해주세요.';
      }
      
      final rawForecasts = await _apiService.getDustForecast();
      final Map<String, DustForecast> uniqueForecasts = {};
      for (var f in rawForecasts) {
        if (!uniqueForecasts.containsKey(f.informData) || 
            f.dataTime.compareTo(uniqueForecasts[f.informData]!.dataTime) > 0) {
          uniqueForecasts[f.informData] = f;
        }
      }
      _forecasts = uniqueForecasts.values.toList();
      _forecasts.sort((a, b) => a.informData.compareTo(b.informData));
    } catch (e) {
      _errorMessage = '오류 발생: ${e.toString()}';
      debugPrint('Detailed error loading dust data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // 주소로 측정소 검색 (최대 3개 결과 저장)
  Future<void> searchNearbyStations(String address) async {
    _isLoading = true;
    _searchResults = [];
    _errorMessage = null;
    notifyListeners();

    try {
      final tmCoords = await _apiService.getTMCoordinates(address);
      if (tmCoords != null) {
        _searchResults = await _apiService.getNearbyStations(tmCoords['tmX']!, tmCoords['tmY']!);
        if (_searchResults.isEmpty) {
          _errorMessage = '검색된 측정소가 없습니다.';
        }
      } else {
        _errorMessage = '입력하신 주소의 좌표를 찾을 수 없습니다.';
      }
    } catch (e) {
      _errorMessage = '검색 중 오류가 발생했습니다.';
      debugPrint('Error searching stations: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // 검색 결과 초기화
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  // 선택한 측정소 즐겨찾기에 추가
  Future<bool> addFavoriteStation(String stationName) async {
    _isLoading = true;
    notifyListeners();

    try {
      final dust = await _apiService.getAirPollution(stationName);
      if (dust != null) {
        if (!_favoriteLocationsDust.any((e) => e.stationName == dust.stationName)) {
          _favoriteLocationsDust.add(_recalculateGrade(dust));
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error adding station: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // 관심 지역 삭제
  void removeFavoriteLocation(int index) {
    _favoriteLocationsDust.removeAt(index);
    notifyListeners();
  }
}
