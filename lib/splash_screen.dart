import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:sgt/login_page.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      duration: 3800,
      splash: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Text: "SMARTGLOW GT" with color formatting
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              children: [
                TextSpan(text: 'SMARTGLOW ', style: TextStyle(color: Colors.white)),
                TextSpan(text: 'GT', style: TextStyle(color: Colors.yellow)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Lottie animation
          Container(
            width: 150,
            height: 150,
            color: Colors.transparent, // Ensures Lottie background isn't filled
            child: Lottie.asset(
              'assets/Smartglow.json',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      backgroundColor: Color(0xFF001F54), // Navy blue background
      nextScreen: const LoginPage(),
      splashIconSize: 250, // Makes room for both text + animation
      splashTransition: SplashTransition.fadeTransition,
    );
  }
}
