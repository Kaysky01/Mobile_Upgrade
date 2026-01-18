import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';

void main() async {
  // 1. Inisialisasi binding agar SharedPreferences bisa diakses nantinya
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Styling System UI
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
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Academic Report',
      theme: ThemeData(
        primaryColor: const Color(0xFF1453A3),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1453A3),
          primary: const Color(0xFF1453A3),
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      // SplashScreen tetap sebagai pintu masuk untuk branding
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}