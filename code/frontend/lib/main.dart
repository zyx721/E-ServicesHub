import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hanini_frontend/screens/SettingsScreen/SettingsScreen.dart';
import 'package:hanini_frontend/screens/auth/forgot_password_screen.dart';
import 'package:hanini_frontend/screens/auth/login_screen.dart';
import 'package:hanini_frontend/screens/auth/signup_screen.dart';
import 'package:hanini_frontend/screens/home/home_screen.dart';
import 'package:hanini_frontend/screens/onboarding/onboarding_screen.dart';
import 'package:hanini_frontend/screens/profile/profile_screen.dart';
import 'package:hanini_frontend/screens/verification/face_verification_screen.dart';
import 'localization/app_localization.dart'; // Update this path as needed
import 'user_role.dart'; // Your UserRole enum and other imports...

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();

  UserRole userRole = await _retrieveUserRole();
  runApp(MyApp(cameras: cameras, userRole: userRole));
}

Future<UserRole> _retrieveUserRole() async {
  // Here you can implement dynamic retrieval of the user role
  return UserRole.serviceProvider; // Replace with your actual logic
}

class MyApp extends StatefulWidget {
  final List<CameraDescription> cameras;
  final UserRole userRole;

  const MyApp({Key? key, required this.cameras, required this.userRole})
      : super(key: key);

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en'); // Default language is English

  void changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hanini',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: Theme.of(context).textTheme.apply(
              fontFamily: 'Poppins',
            ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizationsDelegate(), // Ensure this is included
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('ar', ''), // Arabic
        Locale('fr', ''), // French
      ],
      locale: _locale,
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
      '/profile': (context) =>
          ProfileScreen(cameras: widget.cameras, userRole: widget.userRole),
      '/verification': (context) => RealTimeDetection(cameras: widget.cameras),
      '/settings': (context) => SettingsScreen(),
      '/forgot_password': (context) => ForgotPasswordScreen(),
    };
  }
}
