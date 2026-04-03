class AirPollution {
  final String stationName;
  final String pm10Value;
  final String pm25Value;
  final String dataTime;
  final String pm10Grade;
  final String pm25Grade;
  final String khaiValue;
  final String khaiGrade;

  AirPollution({
    required this.stationName,
    required this.pm10Value,
    required this.pm25Value,
    required this.dataTime,
    required this.pm10Grade,
    required this.pm25Grade,
    required this.khaiValue,
    required this.khaiGrade,
  });

  factory AirPollution.fromJson(Map<String, dynamic> json, String stationName) {
    return AirPollution(
      stationName: stationName,
      pm10Value: json['pm10Value'] ?? '-',
      pm25Value: json['pm25Value'] ?? '-',
      dataTime: json['dataTime'] ?? '-',
      pm10Grade: json['pm10Grade'] ?? '-',
      pm25Grade: json['pm25Grade'] ?? '-',
      khaiValue: json['khaiValue'] ?? '-',
      khaiGrade: json['khaiGrade'] ?? '-',
    );
  }
}

class DustForecast {
  final String informData;
  final String informOverall;
  final String informGrade;
  final String dataTime;
  final String actionKnack;

  DustForecast({
    required this.informData,
    required this.informOverall,
    required this.informGrade,
    required this.dataTime,
    required this.actionKnack,
  });

  factory DustForecast.fromJson(Map<String, dynamic> json) {
    return DustForecast(
      informData: json['informData'] ?? '-',
      informOverall: json['informOverall'] ?? '-',
      informGrade: json['informGrade'] ?? '-',
      dataTime: json['dataTime'] ?? '-',
      actionKnack: json['actionKnack'] ?? '-',
    );
  }
}

class Station {
  final String stationName;
  final String addr;
  final double tm;

  Station({
    required this.stationName,
    required this.addr,
    required this.tm,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      stationName: json['stationName'] ?? '',
      addr: json['addr'] ?? '',
      tm: double.tryParse(json['tm']?.toString() ?? '0.0') ?? 0.0,
    );
  }
}
