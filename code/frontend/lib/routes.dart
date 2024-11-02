import 'package:flutter/material.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/verification/face_verification_screen.dart'; // Adjust import for the new detection screen

final Map<String, WidgetBuilder> routes = {
  '/': (context) => OnboardingScreen(),
  '/login': (context) => LoginScreen(),
  '/signup': (context) => SignupScreen(),
  '/home': (context) => HomeScreen(),
  '/profile': (context) => ProfileScreen(cameras: []), // Pass the camera list as needed
  '/verification': (context) => RealTimeDetection(cameras: []), // Adjust as needed
};
