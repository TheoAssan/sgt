import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sgt/splash_screen.dart';
import 'package:sgt/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // <-- Load environment variables
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartGlow GT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          // Primary colors
          primary: const Color(0xFF001F54), // Navy blue
          primaryContainer: const Color(0xFF034C8C), // Darker navy
          secondary: Colors.yellow, // Accent color
          secondaryContainer: Colors.yellow[700],

          // Surface colors
          surface: Colors.white, // Main background
          surfaceContainerHighest: Colors.grey[100], // For cards/text fields

          // Text colors
          onPrimary: Colors.white, // Text on primary color
          onSecondary: Colors.black, // Text on yellow
          onSurface: const Color(0xFF001F54), // Main text color

          // Other colors
          outline: Colors.grey[400], // Borders
          shadow: Colors.grey.withAlpha((0.2 * 255).toInt()),
        ),
        // Component themes
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF001F54),
          elevation: 0,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF001F54), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF001F54),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 2,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF001F54),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginPage(),
      },
    );
  }
}
