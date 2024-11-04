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
import 'user_role.dart'; // Import your UserRole enum

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras(); // Get the available cameras

  // Retrieve the initial user role; this could be set dynamically based on user authentication
  UserRole userRole = await _retrieveUserRole(); // Implement this function to retrieve the user role
  runApp(MyApp(cameras: cameras, userRole: userRole));
}

// Function to simulate retrieving a user role (replace this with actual implementation)
Future<UserRole> _retrieveUserRole() async {
  // Logic to determine user role (e.g., from shared preferences or a server)
  // For demonstration, we'll return a service provider role
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
      '/forgot_password': (context) => ForgotPasswordScreen(), // Corrected line
    };
  }
}
