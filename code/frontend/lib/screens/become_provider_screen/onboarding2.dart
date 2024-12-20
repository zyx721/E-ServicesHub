import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:hanini_frontend/localization/app_localization.dart';

class OnboardingScreen2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Lottie Animation
          Lottie.asset(
            'assets/animation/animation4.json', // Update to your correct path
            height: 300,
            repeat: true,
          ),
          SizedBox(height: 30),

          // Title
          Text(
            appLocalizations.verifyYourIdentity,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),

          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              appLocalizations.verifyIdentityDescription,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 40),

          // Gradient Button
          GestureDetector(
            onTap: () {
              // Navigate to the NameEntryScreen first
              Navigator.pushNamed(context, '/name_entry');
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF6A1B9A), // Start color
                    Color(0xFFAB47BC), // End color
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Text(
                appLocalizations.continueButton,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
