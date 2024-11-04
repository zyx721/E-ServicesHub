import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogoWithAnimation(),
                SizedBox(height: 30),
                _buildWelcomeText(),
                SizedBox(height: 20),
                _buildTextField('Email', false),
                SizedBox(height: 10),
                _buildTextField('Password', true),
                SizedBox(height: 20),
                _buildLoginButton(context),
                SizedBox(height: 10),
                _buildSignUpButton(context),
                SizedBox(height: 10),
                _buildForgotPasswordButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoWithAnimation() {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: Duration(seconds: 2),
      child: Image.asset(
        'assets/images/onboarding3.png',
        height: 100,
        width: 100,
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Text(
      'Welcome Back!',
      style: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.teal,
      ),
    );
  }

  Widget _buildTextField(String label, bool obscureText) {
    return TextField(
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.teal),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.teal, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pushNamed(context, '/home');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      ),
      child: Text(
        'Login',
        style: GoogleFonts.poppins(
          fontSize: 18,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSignUpButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.pushNamed(context, '/signup');
      },
      child: Text(
        'Don’t have an account? Sign up',
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: Colors.teal,
        ),
      ),
    );
  }

  Widget _buildForgotPasswordButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.pushNamed(context, '/forgot_password');
      },
      child: Text(
        'Forgot Password?',
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: Colors.teal,
        ),
      ),
    );
  }
}
