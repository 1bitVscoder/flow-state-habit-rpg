import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const FlowStateApp());
}

class FlowStateApp extends StatelessWidget {
  const FlowStateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlowState',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xff0B0F19), // Dark background canvas default fallback
        colorScheme: const ColorScheme.dark(
          primary: Color(0xff4FACFE),
          secondary: Color(0xff00F2C3),
          surface: Color(0xff111625),
        ),
      ),
      home: const SplashScreen(),
    );
  }
} 