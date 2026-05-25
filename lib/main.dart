import 'package:al_medynah/screens/splash.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Almedinah());
}

class Almedinah extends StatelessWidget {
  const Almedinah({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // ✅ حذفنا navigatorObservers — مش محتاجينه مع الـ callback
      home: const SplashScreen(),
    );
  }
}
