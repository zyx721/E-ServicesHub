import 'package:flutter/material.dart';
import 'package:camera/camera.dart'; // Import camera package
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/verification/face_verification_screen.dart';
import 'screens/auth/forgot_password_screen.dart'; // Import the Forgot Password Screen
import 'user_role.dart'; // Import your UserRole enum

// Define a class for managing routes
class AppRoutes {
  static final Map<String, WidgetBuilder> routes = {
    '/': (context) =>  OnboardingScreen(),
    '/login': (context) => const LoginScreen(),
    '/signup': (context) => const SignupScreen(),
    '/home': (context) =>  HomeScreen(),
    // Ensure cameras and userRole are passed as needed
    '/profile': (context) {
      final args = ModalRoute.of(context)!.settings.arguments as RouteArguments;
      return ProfileScreen(cameras: args.cameras, userRole: args.userRole);
    },
    '/verification': (context) {
      final cameras = ModalRoute.of(context)!.settings.arguments as List<CameraDescription>;
      return RealTimeDetection(cameras: cameras);
    },
    '/forgot_password': (context) => const ForgotPasswordScreen(), // Add forgot password route
  };
}

// Create a class for route arguments to hold both cameras and user role
class RouteArguments {
  final List<CameraDescription> cameras;
  final UserRole userRole;

  RouteArguments(this.cameras, this.userRole);
}
