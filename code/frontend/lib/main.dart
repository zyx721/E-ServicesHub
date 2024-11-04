import 'package:flutter/material.dart';
import 'package:camera/camera.dart'; // Ensure you have this package
import 'package:hanini_frontend/screens/SettingsScreen/SettingsScreen.dart';
import 'package:hanini_frontend/screens/auth/forgot_password_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/verification/face_verification_screen.dart';
import 'screens/services/ServiceDetailScreen.dart'; // Import your ServiceDetailScreen
import 'user_role.dart'; // Import your UserRole enum

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras(); // Get the available cameras

  UserRole userRole = await _retrieveUserRole(); // Retrieve the initial user role
  runApp(MyApp(cameras: cameras, userRole: userRole));
}

// Function to simulate retrieving a user role (replace this with actual implementation)
Future<UserRole> _retrieveUserRole() async {
  return UserRole.serviceProvider; // Replace with dynamic retrieval of user role
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  final UserRole userRole;

  const MyApp({Key? key, required this.cameras, required this.userRole}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hanini',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: Theme.of(context).textTheme.apply(
              fontFamily: 'Poppins', // Set global font family
            ),
      ),
      initialRoute: '/',
      routes: _buildRoutes(),
    );
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/': (context) => OnboardingScreen(),
      '/login': (context) => const LoginScreen(),
      '/signup': (context) => const SignupScreen(),
      '/home': (context) => HomeScreen(),
      '/profile': (context) => ProfileScreen(cameras: cameras, userRole: userRole),
      '/verification': (context) => RealTimeDetection(cameras: cameras),
      '/settings': (context) => SettingsScreen(),
      '/forgot_password': (context) => ForgotPasswordScreen(),
      // Add more routes as needed, for example:
      // '/service_detail': (context) => ServiceDetailScreen(...), // You can also dynamically pass the parameters here if needed
    };
  }
}
