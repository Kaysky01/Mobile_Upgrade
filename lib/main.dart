import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';

// 🔥 GLOBAL NAVIGATOR KEY
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // System UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ✅ SATU-SATUNYA YANG BOLEH DI main()
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 🔥 INI KUNCI UTAMA
      navigatorKey: navigatorKey,

      title: 'Academic Report',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        primaryColor: const Color(0xFF1453A3),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1453A3),
          primary: const Color(0xFF1453A3),
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),

      home: const SplashScreen(),
    );
  }
}
