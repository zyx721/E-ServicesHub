import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hanini_frontend/screens/SettingsScreen/SettingsScreen.dart';
import 'package:hanini_frontend/screens/auth/forgot_password_screen.dart';
import 'package:hanini_frontend/screens/auth/login_screen.dart';
import 'package:hanini_frontend/screens/auth/signup_screen.dart';
import 'package:hanini_frontend/screens/become_provider_screen/NameEntryScreen.dart';
import 'package:hanini_frontend/screens/onboarding/onboarding_screen.dart';
import 'package:hanini_frontend/screens/verification/id_verification_screen.dart';
import 'localization/app_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_role.dart';
import 'navbar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  await Firebase.initializeApp();

  final initialRoute = await _determineInitialRoute();
  final userRole = await _retrieveUserRole();
  
  runApp(MyApp(cameras: cameras, userRole: userRole, initialRoute: initialRoute));
}

Future<String> _determineInitialRoute() async {
  final prefs = await SharedPreferences.getInstance();
  final bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  if (isFirstLaunch) {
    await prefs.setBool('isFirstLaunch', false);
    return '/'; // Show onboarding screen
  }

  if (isLoggedIn) {
    return '/navbar'; // Show navbar if logged in
  }
  return '/login'; // Default to login if not logged in
}

// Updated to retrieve user role from SharedPreferences
Future<UserRole> _retrieveUserRole() async {
  final prefs = await SharedPreferences.getInstance();
  String? savedRoleString = prefs.getString('userRole');
  
  if (savedRoleString != null) {
    return UserRole.values.firstWhere(
      (role) => role.toString() == savedRoleString,
      orElse: () => UserRole.client, // Default to client if not found
    );
  }
  
  return UserRole.client; // Default role if no role is saved
}

class MyApp extends StatefulWidget {
  final List<CameraDescription> cameras;
  final UserRole userRole;
  final String initialRoute;

  const MyApp({
    Key? key,
    required this.cameras,
    required this.userRole,
    required this.initialRoute,
  }) : super(key: key);

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late UserRole _currentUserRole;
  Locale _locale = const Locale('en'); // Default language is English

  @override
  void initState() {
    super.initState();
    _currentUserRole = widget.userRole;
  }

  void changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  // Method to update user role and save it
  Future<void> updateUserRole(UserRole newRole) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userRole', newRole.toString());
    
    setState(() {
      _currentUserRole = newRole;
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
        AppLocalizationsDelegate(),
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('ar', ''), // Arabic
        Locale('fr', ''), // French
      ],
      locale: _locale,
      initialRoute: widget.initialRoute,
      routes: _buildRoutes(),
    );
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/': (context) => OnboardingScreen(),
      '/login': (context) => const LoginScreen(),
      '/signup': (context) => const SignupScreen(),
      '/navbar': (context) => NavbarPage(userRole: _currentUserRole),
      '/name_entry': (context) => NameEntryScreen(),
      '/verification': (context) => RealTimeDetection(cameras: widget.cameras),
      '/settings': (context) => SettingsScreen(),
      '/forgot_password': (context) => ForgotPasswordScreen(),
    };
  }
}