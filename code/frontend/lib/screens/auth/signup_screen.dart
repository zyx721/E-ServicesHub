import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'terms_and_conditions_page.dart'; // Import the Terms and Conditions page

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  bool _isChecked = false;
  final TextEditingController _phoneController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.teal],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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
                      'Create Account',
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildTextField('Name', false),
                  const SizedBox(height: 10),
                  _buildTextField('Email', false),
                  const SizedBox(height: 10),
                  _buildTextField('Password', true),
                  const SizedBox(height: 10),
                  _buildPhoneField(),
                  const SizedBox(height: 20),
                  _buildTermsCheckbox(),
                  const SizedBox(height: 20),
                  _buildSignUpButton(context),
                  const SizedBox(height: 10),
                  _buildLoginButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, bool obscureText) {
    return SlideTransition(
      position: _slideAnimation,
      child: TextField(
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white, width: 2),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return SlideTransition(
      position: _slideAnimation,
      child: TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          labelText: 'Phone Number',
          labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
          prefixText: '+213 ',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white, width: 2),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        ),
        maxLength: 9,
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _isChecked,
          activeColor: Colors.white,
          checkColor: Colors.teal,
          onChanged: (value) {
            setState(() {
              _isChecked = value!;
            });
          },
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TermsAndConditionsPage()),
            );
          },
          child: Text(
            'I accept the Terms and Conditions',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton(BuildContext context) {
    return ElevatedButton(
      onPressed: _isChecked
          ? () {
              String phoneNumber = '+213' + _phoneController.text;
              print('Phone Number: $phoneNumber');
              Navigator.pushNamed(context, '/home');
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      ),
      child: Text(
        'Sign Up',
        style: GoogleFonts.poppins(
          fontSize: 18,
          color: Colors.teal,
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.pushNamed(context, '/login');
      },
      child: Text(
        'Already have an account? Login',
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}
