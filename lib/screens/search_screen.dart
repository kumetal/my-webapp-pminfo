import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dust_provider.dart';
import '../theme_config.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  Future<void> _searchLocation() async {
    final provider = context.read<DustProvider>();
    final address = _controller.text.trim();
    if (address.isNotEmpty) {
      await provider.searchNearbyStations(address);
    }
  }

  Future<void> _selectStation(String stationName) async {
    final provider = context.read<DustProvider>();
    final success = await provider.addFavoriteStation(stationName);
    if (success && mounted) {
      provider.clearSearchResults(); // 검색 결과 초기화 (사라지게 함)
      // 추가 성공 시 홈 화면으로 돌아가 해당 페이지 표시
      Navigator.pop(context, provider.favoriteLocationsDust.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DustProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('지역 추가', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: ThemeConfig.mainGradient,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '지역 또는 주소를 입력하세요 (예: 강남구, 역삼동)',
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _searchLocation(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.white, size: 30),
                      onPressed: _searchLocation,
                    ),
                  ],
                ),
              ),
              
              // 검색 결과 섹션
              if (provider.searchResults.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  child: Text(
                    '검색 결과 (가까운 측정소)',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.searchResults.length,
                  itemBuilder: (context, index) {
                    final station = provider.searchResults[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: ListTile(
                        title: Text(station.stationName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(station.addr, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        trailing: const Icon(Icons.add_circle_outline, color: Colors.cyanAccent),
                        onTap: () => _selectStation(station.stationName),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],

              if (provider.errorMessage != null && provider.searchResults.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: Colors.amberAccent, fontSize: 13),
                  ),
                ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                child: Text(
                  '나의 관심 지역',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.favoriteLocationsDust.length,
                  itemBuilder: (context, index) {
                    final dust = provider.favoriteLocationsDust[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        onTap: () => Navigator.pop(context, index + 1),
                        title: Text(dust.stationName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '상태: ${ThemeConfig.getGradeText(dust.pm10Grade)} (PM10: ${dust.pm10Value})',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white38),
                          onPressed: () => provider.removeFavoriteLocation(index),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
