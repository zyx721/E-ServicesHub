import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/localization/app_localization.dart';
import 'terms_and_conditions_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false; // To track loading state
  String _message = ''; // To display messages

  Future<void> _signup() async {
    setState(() {
      _isLoading = true;
    });

    final name = _nameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;
    final phone = _phoneController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
      setState(() {
        _message = 'All fields are required';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All fields are required')),
      );
      return;
    }

    final url = Uri.parse('https://hanini-2024-8wdi.onrender.com/signup');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      final responseBody = json.decode(response.body);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signup successful: ${responseBody['message']}'),
            backgroundColor: Colors.green,
          ),
        );

        // Redirect the user to the login page and replace the current screen
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signup failed: ${responseBody['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isChecked = false;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset(0, 0)).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      await _googleSignIn.signIn();
      Navigator.pushNamed(context, '/navbar');
    } catch (error) {
      print("Google Sign-In Error: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1A237E), // Deep indigo
              Color(0xFF42A5F5), // Lighter blue
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Image.asset(
                        'assets/images/onboarding3_b.png',
                        height: 150,
                        width: 150,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SlideTransition(
                      position: _slideAnimation,
                      child: Text(
                        signupTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildTextField(
                        nameLabel, false, _nameController, _slideAnimation),
                    const SizedBox(height: 10),
                    _buildEmailField(emailLabel),
                    const SizedBox(height: 10),
                    _buildPasswordField(passwordLabel),
                    const SizedBox(height: 10),
                    _buildPhoneField(phoneLabel),
                    const SizedBox(height: 20),
                    _buildTermsCheckbox(),
                    const SizedBox(height: 20),
                    _buildGoogleSignInButton(),
                    const SizedBox(height: 10),
                    _buildSignUpButton(context),
                    const SizedBox(height: 10),
                    _buildLoginButton(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get signupTitle =>
      AppLocalizations.of(context)?.signupTitle ?? 'Create Account';

  String get nameLabel => AppLocalizations.of(context)?.nameLabel ?? 'Name';

  String get emailLabel => AppLocalizations.of(context)?.emailLabel ?? 'Email';

  String get passwordLabel =>
      AppLocalizations.of(context)?.passwordLabel ?? 'Password';

  String get phoneLabel => AppLocalizations.of(context)?.phoneLabel ?? 'Phone';

  String get termsAgreement =>
      AppLocalizations.of(context)?.termsAgreement ??
      'I agree to the Terms and Conditions';

  String get signInWithGoogle =>
      AppLocalizations.of(context)?.signInWithGoogle ?? 'Sign in with Google';

  String get signupButton =>
      AppLocalizations.of(context)?.signupButton ?? 'Sign Up';

  String get passwordMinLengthError =>
      AppLocalizations.of(context)?.passwordMinLengthError ??
      'Password must be at least 8 characters long';

  String get emailRequiredError =>
      AppLocalizations.of(context)?.emailRequiredError ??
      'Please enter your email';

  String get emailInvalidError =>
      AppLocalizations.of(context)?.emailInvalidError ??
      'Please enter a valid email';

  String get passwordRequiredError =>
      AppLocalizations.of(context)?.passwordRequiredError ??
      'Please enter your password';

  String get phoneRequiredError =>
      AppLocalizations.of(context)?.phoneRequiredError ??
      'Please enter your phone number';

  String get phoneInvalidError =>
      AppLocalizations.of(context)?.phoneInvalidError ??
      'Please enter a valid phone number';

  Widget _buildTextField(String label, bool obscureText,
      TextEditingController controller, Animation<Offset> slideAnimation) {
    return SlideTransition(
      position: slideAnimation,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.white),
          floatingLabelStyle: GoogleFonts.poppins(color: Colors.blue),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
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
        onChanged: (value) {
          setState(() {}); // Trigger rebuild for real-time validation if needed
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return AppLocalizations.of(context)?.fieldRequiredError ??
                'Please enter your $label';
          } else if (label == passwordLabel && (value.length < 8)) {
            return passwordMinLengthError;
          } else if (label == emailLabel) {
            final emailRegex =
                RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
            if (!emailRegex.hasMatch(value)) {
              return AppLocalizations.of(context)?.emailInvalidError ??
                  'Please enter a valid email';
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _buildEmailField(String label) {
    return SlideTransition(
      position: _slideAnimation,
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.white),
          floatingLabelStyle: GoogleFonts.poppins(
              color: const Color.fromARGB(255, 255, 255, 255)),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
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
        onChanged: (value) {
          setState(() {}); // Trigger rebuild for real-time validation if needed
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return emailRequiredError;
          }
          final emailRegex =
              RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
          if (!emailRegex.hasMatch(value)) {
            return emailInvalidError;
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField(String label) {
    return SlideTransition(
      position: _slideAnimation,
      child: TextFormField(
        controller: _passwordController,
        obscureText: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.white),
          floatingLabelStyle: GoogleFonts.poppins(
              color: const Color.fromARGB(255, 255, 255, 255)),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
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
        onChanged: (value) {
          setState(() {}); // Trigger rebuild for real-time validation if needed
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return passwordRequiredError;
          } else if (value.length < 8) {
            return passwordMinLengthError;
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPhoneField(String label) {
    return SlideTransition(
      position: _slideAnimation,
      child: TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.white),
          floatingLabelStyle: GoogleFonts.poppins(
              color: const Color.fromARGB(255, 255, 255, 255)),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          prefixText: '+213 ',
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
        onChanged: (value) {
          setState(() {}); // Trigger rebuild for real-time validation if needed
        },
        maxLength: 9,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return phoneRequiredError;
          } else if (value.length < 9) {
            return phoneInvalidError;
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return SlideTransition(
      position: _slideAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Checkbox(
            value: _isChecked,
            onChanged: (value) {
              setState(() {
                _isChecked = value ?? false;
              });
            },
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                      text:
                          AppLocalizations.of(context)?.termsAgreementPrefix ??
                              'I agree to the '),
                  TextSpan(
                    text: AppLocalizations.of(context)?.termsAgreementLink ??
                        'Terms and Conditions',
                    style: const TextStyle(
                        color: Color.fromARGB(255, 183, 173, 173)),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => TermsAndConditionsPage()),
                        );
                      },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return SlideTransition(
      position: _slideAnimation,
      child: ElevatedButton(
        onPressed: _handleGoogleSignIn,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/google_logo.png', height: 24),
            const SizedBox(width: 10),
            Text(signInWithGoogle),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpButton(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: ElevatedButton(
        onPressed: _isChecked && !_isLoading
            ? _signup
            : null, // Disable if _isChecked is false or _isLoading is true
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(signupButton),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: TextButton(
        onPressed: () {
          Navigator.pushNamed(context, '/login');
        },
        child: Text(
          AppLocalizations.of(context)?.loginButtonText ??
              'Already have an account? Login',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
