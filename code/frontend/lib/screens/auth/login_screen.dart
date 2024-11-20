import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/localization/app_localization.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Google Sign-In

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // Initialize GoogleSignIn


  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;


// Function to handle login
  Future<void> handleLogin() async {
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isNotEmpty && password.isNotEmpty) {
        // Attempt to sign in with Firebase Auth
        final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        final User? user = userCredential.user;
        if (user != null) {
          print('Login Successful. User: ${user.email}');
          // Show success SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login Successful. Welcome ${user.email}'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to home page after successful login
          Navigator.pushNamed(context, '/home');
        } else {
          // Show error SnackBar if no user is found
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No user found.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Show SnackBar if email or password is empty
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter both email and password.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (error) {
      // Show SnackBar for any errors during login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
      print('Login Error: $error');
    }
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      await _googleSignIn.signIn();
      // Navigate to home or handle the signed-in user
      Navigator.pushNamed(context, '/home');
    } catch (error) {
      print("Google Sign-In Error: $error");
      // Handle error (show a message, etc.)
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!; // Access localized strings

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A237E), // Deep indigo
              Color(0xFF42A5F5), // Lighter blue
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(0, 8),
                              blurRadius: 200,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/onboarding3_b.png', // Replace with your logo path
                          height: 220,
                          width: 220,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    localizations.loginTitle, // Localized title
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildTextField(localizations.email, false, _emailController), // Bind email controller
                  const SizedBox(height: 15),
                  _buildTextField(localizations.password, true, _passwordController), // Bind password controller
                  // Localized password label
                  const SizedBox(height: 30),
                  _buildLoginButton(context, localizations.loginButton), // Localized login button text
                  const SizedBox(height: 20),
                  _buildGoogleSignInButton(), // Add Google Sign-In Button
                  _buildForgotPasswordButton(context, localizations.forgotPassword), // Localized forgot password text
                  _buildSignupPrompt(context, localizations.createAccount), // Localized sign-up prompt
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, bool obscureText, TextEditingController controller) {
  return TextField(
    controller: controller, // Bind the controller here
    obscureText: obscureText,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.white),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
    ),
    style: GoogleFonts.poppins(color: Colors.white),
  );
}


  Widget _buildLoginButton(BuildContext context, String buttonText) {
    return ElevatedButton(
      onPressed: handleLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        elevation: 6,
      ),
      child: Text(
        buttonText,
        style: GoogleFonts.poppins(
          fontSize: 18,
          color: const Color(0xFF1A237E),
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
  final localizations = AppLocalizations.of(context)!; // Access localized strings

  return ElevatedButton.icon(
    onPressed: _handleGoogleSignIn,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      elevation: 6,
    ),
    icon: Image.asset(
      'assets/images/google_logo.png', // Add your Google logo path
      height: 24,
      width: 24,
    ),
    label: Text(
      localizations.googleSignIn, // Use localized text here
      style: GoogleFonts.poppins(
        fontSize: 18,
        color: const Color(0xFF1A237E),
      ),
    ),
  );
}


  Widget _buildForgotPasswordButton(BuildContext context, String forgotPasswordText) {
    return TextButton(
      onPressed: () {
        Navigator.pushNamed(context, '/forgot_password');
      },
      child: Text(
        forgotPasswordText,
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildSignupPrompt(BuildContext context, String signupPromptText) {
    return TextButton(
      onPressed: () {
        Navigator.pushNamed(context, '/signup');
      },
      child: Text(
        signupPromptText,
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: Colors.white70,
        ),
      ),
    );
  }
}
