import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/screens/auth/signup_screen.dart'; // Make sure this import matches your structure

class TermsAndConditionsPage extends StatefulWidget {
  @override
  _TermsAndConditionsPageState createState() => _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState extends State<TermsAndConditionsPage> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Terms and Conditions',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Text(
                          'Terms and Conditions',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '1. Introduction\n'
                          'These terms and conditions outline the rules and regulations for the use of the HANINI app.\n\n'
                          '2. Acceptance of Terms\n'
                          'By accessing this app, we assume you accept these terms and conditions.\n\n'
                          '3. Privacy Policy\n'
                          'Your privacy is important to us, and we are committed to protecting your personal data.\n\n'
                          '4. Changes to Terms\n'
                          'We may update the terms and conditions periodically. Please review them regularly.\n\n'
                          '5. Limitation of Liability\n'
                          'In no event shall we be liable for any damages or losses.\n\n'
                          '6. Governing Law\n'
                          'These terms shall be governed by the laws of [Your Country].\n\n'
                          'Please read all terms carefully before proceeding to the app.',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: _isChecked,
                  activeColor: Colors.teal,
                  onChanged: (value) {
                    setState(() {
                      _isChecked = value!;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    'I accept the Terms and Conditions',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _isChecked
                    ? () {
                        // Pop the Terms and Conditions page and return to the previous page
                        Navigator.pop(context, true); // Pass back the acceptance status
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  backgroundColor: _isChecked ? Colors.teal : Colors.grey,
                ),
                child: Text(
                  'Continue',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
