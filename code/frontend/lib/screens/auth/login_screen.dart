import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/localization/app_localization.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

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

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> handleLogin() async {
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      print('Email: $email');
      print('Password: $password');

      // Validate email format using a simple regex pattern
      final emailPattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$";
      final emailRegex = RegExp(emailPattern);

      if (email.isNotEmpty && password.isNotEmpty) {
        if (!emailRegex.hasMatch(email)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid email format.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final UserCredential userCredential =
            await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        final User? user = userCredential.user;

        if (user != null) {
          // Update lastSignIn and isConnected in Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'lastSignIn': DateTime.now(),
            'isConnected': true,
          }, SetOptions(merge: true));

          print('Login Successful. User: ${user.email}');
          // Show success SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login Successful. Welcome ${user.email}'),
              backgroundColor: Colors.green,
            ),
          );
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          // Navigate to home page after successful signup
          Navigator.pushNamed(context, '/navbar');
        } else {
          // Show error SnackBar if no user is found
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No user found.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Show SnackBar if email or password is empty
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter both email and password.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (error) {
      print('Login Error: $error');
      if (error is FirebaseAuthException) {
        if (error.code == 'user-not-found') {
          print('No user found for that email.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No user found for that email.'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (error.code == 'wrong-password') {
          print('Wrong password provided.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Incorrect password.'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (error.code == 'invalid-credential') {
          print('The supplied auth credential is incorrect or malformed.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid credentials provided.'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          print('Error: ${error.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${error.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Handle any other error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    _emailController.dispose(); // Dispose controllers to free resources
    _passwordController.dispose();
    super.dispose();
  }

Future<void> _handleGoogleSignIn() async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser != null) {
      try {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        final User? user = userCredential.user;

        if (user != null) {
          // First, check if the user document already exists
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          // Prepare the user data
          Map<String, dynamic> userData = {
            'uid': user.uid,
            'email': user.email ?? 'No Email',
            'lastSignIn': DateTime.now(),
            'isConnected': true,  // Add the isConnected field
          };

          // Only update name if it's not already set
          if (!userDoc.exists || userDoc.data()?['name'] == null) {
            userData['name'] = user.displayName ?? 'No Name';
          }

          if (!userDoc.exists || userDoc.data()?['photoURL'] == null || 
              (userDoc.data()?['photoURL']?.isEmpty ?? true && user.photoURL != null && user.photoURL!.isNotEmpty)) {
            userData['photoURL'] = user.photoURL ?? '';
          }

          // If document doesn't exist, add createdAt
          if (!userDoc.exists) {
            userData['createdAt'] = DateTime.now();
          }

          // Update the document with merge
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(userData, SetOptions(merge: true));

          // Show success message and navigate
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome ${user.displayName ?? user.email}'),
              backgroundColor: Colors.green,
            ),
          );
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          Navigator.pushNamed(context, '/navbar');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign-In failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account exists with different credentials.'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Authentication error: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Sign-In was canceled.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error during sign-in: ${error.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
    print('Error during Google Sign-In: $error');
  }
}
  @override
  Widget build(BuildContext context) {
    final localizations =
        AppLocalizations.of(context)!; // Access localized strings

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
                  // Wrap the logo with GestureDetector to detect taps
                  GestureDetector(
                    child: FadeTransition(
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
                  _buildTextField(localizations.email, false,
                      _emailController), // Bind email controller
                  const SizedBox(height: 15),
                  _buildTextField(localizations.password, true,
                      _passwordController), // Bind password controller
                  const SizedBox(height: 30),
                  _buildLoginButton(context,
                      localizations.loginButton), // Localized login button text
                  const SizedBox(height: 20),
                  _buildGoogleSignInButton(), // Add Google Sign-In Button
                  _buildForgotPasswordButton(
                      context,
                      localizations
                          .forgotPassword), // Localized forgot password text
                  _buildSignupPrompt(context,
                      localizations.createAccount), // Localized sign-up prompt
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, bool obscureText, TextEditingController controller) {
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
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
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
    final localizations =
        AppLocalizations.of(context)!; // Access localized strings

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

  Widget _buildForgotPasswordButton(
      BuildContext context, String forgotPasswordText) {
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
