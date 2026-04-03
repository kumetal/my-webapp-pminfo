import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/dust_provider.dart';
import 'screens/home_screen.dart';
import 'theme_config.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DustProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '미세먼지 정보',
      debugShowCheckedModeBanner: false,
      theme: ThemeConfig.lightTheme,
      home: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: const HomeScreen(),
        ),
      ),
    );
  }
}
