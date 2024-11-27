import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/localization/app_localization.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  // Function to handle password recovery
  Future<void> _recoverPassword(String email) async {
    setState(() {
      _isLoading = true;
    });

    final String backendUrl = 'http://192.168.113.70:3000/forget-password'; // Replace with your backend URL

    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: '{"email": "$email"}',
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        // Success
        final snackBar = SnackBar(
          content: Text(
            AppLocalizations.of(context)!.passwordResetEmailSent, // Localized text
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      } else {
        // Handle error response
        final snackBar = SnackBar(
          content: Text(
            AppLocalizations.of(context)!.emailNotFound, // Localized text
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Handle network or unexpected errors
      final snackBar = SnackBar(
        content: Text(
          AppLocalizations.of(context)!.networkError, // Localized text
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!; // Access localization instance

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
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Image
                  Image.asset(
                    'assets/images/onboarding3_b.png',
                    height: 150,
                    width: 150,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    localization.forgotPassword, // Localized text
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(localization.email, false),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            final email = _emailController.text.trim();
                            if (email.isNotEmpty) {
                              _recoverPassword(email);
                            } else {
                              final snackBar = SnackBar(
                                content: Text(
                                  localization.enterValidEmail, // Localized text
                                  style: GoogleFonts.poppins(color: Colors.white),
                                ),
                                backgroundColor: Colors.red,
                              );
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(snackBar);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.teal)
                        : Text(
                            localization.getStarted, // Localized button text
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.teal,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, bool obscureText) {
    return TextField(
      controller: _emailController,
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
    );
  }
}
