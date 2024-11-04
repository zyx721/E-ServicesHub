import 'package:flutter/material.dart';
import 'package:camera/camera.dart'; // Ensure you have this package
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
  
  // Set the initial user role; this could be set dynamically based on user authentication
  UserRole userRole = await getUserRole(); // Implement this function to retrieve the user role
  runApp(MyApp(cameras: cameras, userRole: userRole));
}

// Function to simulate retrieving a user role (replace this with actual implementation)
Future<UserRole> getUserRole() async {
  // Logic to determine user role (e.g., from shared preferences or a server)
  // For demonstration, we'll return a client role
  return UserRole.serviceProvider; // Replace with dynamic retrieval of user role
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  final UserRole userRole;

  MyApp({required this.cameras, required this.userRole});

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
      routes: {
        '/': (context) => OnboardingScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/home': (context) => HomeScreen(),
        '/profile': (context) => ProfileScreen(cameras: cameras, userRole: userRole),
        '/verification': (context) => RealTimeDetection(cameras: cameras),
      },
    );
  }
}
