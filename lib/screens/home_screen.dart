import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/air_pollution_model.dart';
import '../providers/dust_provider.dart';
import '../theme_config.dart';
import '../utils/dust_utils.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _regionController = PageController();
  final PageController _forecastController = PageController();
  int _currentRegionPage = 0;
  int _currentForecastPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DustProvider>().loadCurrentLocationDust();
    });
  }

  @override
  void dispose() {
    _regionController.dispose();
    _forecastController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DustProvider>();
    
    final List<AirPollution?> displayItems = [
      provider.currentLocationDust,
      ...provider.favoriteLocationsDust,
    ];

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: ThemeConfig.mainGradient,
        child: SafeArea(
          child: provider.isLoading && provider.currentLocationDust == null && provider.favoriteLocationsDust.isEmpty
              ? const Center(
                  child: SpinKitDoubleBounce(
                    color: Colors.white,
                    size: 50.0,
                  ),
                )
              : Column(
                  children: [
                    _buildHeader(context),
                    // 상단: 지역별 미세먼지 정보 슬라이드
                    Expanded(
                      flex: 11,
                      child: RefreshIndicator(
                        onRefresh: () => provider.loadCurrentLocationDust(),
                        child: Column(
                          children: [
                            Expanded(
                              child: PageView.builder(
                                controller: _regionController,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentRegionPage = index;
                                  });
                                },
                                itemCount: displayItems.length,
                                itemBuilder: (context, index) {
                                  final item = displayItems[index];
                                  if (item == null) {
                                    return _buildErrorPage(provider);
                                  }
                                  return _buildDustPage(item, provider);
                                },
                              ),
                            ),
                            _buildPageIndicator(displayItems.length, _currentRegionPage),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 25),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.white, size: 18),
                          SizedBox(width: 10),
                          Text(
                            '미세먼지 예보',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 하단: 오늘/내일/모레 예보 슬라이드
                    Expanded(
                      flex: 6,
                      child: _buildForecastPageView(provider),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 20),
              const SizedBox(width: 5),
              if (_currentRegionPage == 0)
                const Text('현재 위치', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () => _showStandardSelectionDialog(context),
                tooltip: '기준 설정',
              ),
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () async {
                  final result = await Navigator.push<int>(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  );
                  if (result != null && _regionController.hasClients) {
                    _regionController.animateToPage(
                      result,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showStandardSelectionDialog(BuildContext context) {
    final provider = context.read<DustProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('미세먼지 기준 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<DustStandard>(
              title: const Text('한국환경공단 (4단계)'),
              value: DustStandard.keco,
              groupValue: provider.standard,
              onChanged: (value) {
                if (value != null) provider.setStandard(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<DustStandard>(
              title: const Text('WHO 기준 (8단계)'),
              value: DustStandard.who,
              groupValue: provider.standard,
              onChanged: (value) {
                if (value != null) provider.setStandard(value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDustPage(AirPollution dust, DustProvider provider) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 40), // 좌측 균형을 위한 여백
                Text(
                  dust.stationName,
                  style: const TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70, size: 22),
                  onPressed: () => provider.loadCurrentLocationDust(),
                  tooltip: '실시간 업데이트',
                ),
              ],
            ),
            Text(
              dust.dataTime,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            _buildBigStatus(dust.khaiGrade),
            const SizedBox(height: 5), // 이전 10에서 5로 더 축소
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDustInfoCard('미세먼지(PM10)', dust.pm10Value, dust.pm10Grade),
                _buildDustInfoCard('초미세먼지(PM2.5)', dust.pm25Value, dust.pm25Grade),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastPageView(DustProvider provider) {
    if (provider.forecasts.isEmpty) {
      return const Center(child: Text('예보 데이터가 없습니다.', style: TextStyle(color: Colors.white54)));
    }

    // 예보 데이터 필터링 (최신 3일치 정도만 사용)
    final forecasts = provider.forecasts.take(3).toList();

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _forecastController,
            onPageChanged: (index) {
              setState(() {
                _currentForecastPage = index;
              });
            },
            itemCount: forecasts.length,
            itemBuilder: (context, index) {
              final forecast = forecasts[index];
              return _buildForecastCard(forecast);
            },
          ),
        ),
        _buildPageIndicator(forecasts.length, _currentForecastPage, isSmall: true),
      ],
    );
  }

  Widget _buildForecastCard(DustForecast forecast) {
    String dayLabel = forecast.informData;
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowStr = "${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}";

    if (dayLabel == todayStr) {
      dayLabel += " (오늘)";
    } else if (dayLabel == tomorrowStr) {
      dayLabel += " (내일)";
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 1), // 더 축소
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), // 더 축소
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dayLabel,
            style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14), // 폰트 크기 축소
          ),
          const SizedBox(height: 5), // 간격 축소
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    forecast.informOverall,
                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3), // 폰트 및 높이 축소
                  ),
                  const SizedBox(height: 5), // 간격 축소
                  Text(
                    '예보등급: ${forecast.informGrade}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPage(DustProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            provider.errorMessage ?? '데이터를 불러올 수 없습니다.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => provider.loadCurrentLocationDust(),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int count, int currentPage, {bool isSmall = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        return Container(
          width: isSmall ? 6 : 8,
          height: isSmall ? 6 : 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentPage == index ? Colors.white : Colors.white.withValues(alpha: 0.3),
          ),
        );
      }),
    );
  }

  Widget _buildBigStatus(String grade) {
    return Column(
      children: [
        _getGradeIconWidget(grade),
        const SizedBox(height: 10),
        Text(
          ThemeConfig.getGradeText(grade),
          style: const TextStyle(
            fontSize: 36,
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildDustInfoCard(String label, String value, String grade) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 10),
          Text(
            '$value ㎍/㎥',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ThemeConfig.getGradeColor(grade),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              ThemeConfig.getGradeText(grade),
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getGradeIconWidget(String grade) {
    final double iconSize = 80;
    final Color iconColor = ThemeConfig.getGradeColor(grade);

    switch (grade) {
      case '1':
      case '2':
        return FaIcon(FontAwesomeIcons.solidFaceGrinHearts, size: iconSize, color: iconColor); // 최고, 좋음
      case '3':
        return FaIcon(FontAwesomeIcons.solidFaceSmileWink, size: iconSize, color: iconColor); // 양호
      case '4':
        return FaIcon(FontAwesomeIcons.solidFaceSmile, size: iconSize, color: iconColor); // 보통
      case '5':
        return FaIcon(FontAwesomeIcons.solidFaceFrown, size: iconSize, color: iconColor); // 나쁨
      case '6':
        return FaIcon(FontAwesomeIcons.solidFaceGrimace, size: iconSize, color: iconColor); // 상당히 나쁨
      case '7':
        return FaIcon(FontAwesomeIcons.solidFaceAngry, size: iconSize, color: iconColor); // 매우 나쁨
      case '8':
        return FaIcon(FontAwesomeIcons.maskVentilator, size: iconSize, color: iconColor); // 최악
      default:
        return Icon(Icons.help_outline, size: iconSize, color: iconColor);
    }
  }
}
