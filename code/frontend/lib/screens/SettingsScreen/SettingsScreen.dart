import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/screens/onboarding/onboarding_screen.dart'; // Update with the correct path

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Change Password Option
            _buildOptionCard(context, 'Change Password', Icons.lock, () {
              // Navigate to change password screen
            }),
            SizedBox(height: 10),
            // Notification Settings Option
            _buildOptionCard(context, 'Notification Settings', Icons.notifications, () {
              // Navigate to notification settings screen
            }),
            SizedBox(height: 10),
            // Privacy Settings Option
            _buildOptionCard(context, 'Privacy Settings', Icons.privacy_tip, () {
              // Navigate to privacy settings screen
            }),
            SizedBox(height: 10),
            // About App Option
            _buildOptionCard(context, 'About App', Icons.info, () {
              // Show app info or navigate to an about screen
            }),
            SizedBox(height: 10),
            // Logout Option
            _buildOptionCard(context, 'Logout', Icons.logout, () {
              // Navigate to onboarding screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => OnboardingScreen(), // Change to your onboarding screen
                ),
              );
            }, isLogout: true),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, String title, IconData icon, VoidCallback onTap, {bool isLogout = false}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: isLogout ? Colors.red : Colors.blueAccent),
        title: Text(title, style: GoogleFonts.poppins(fontSize: 18)),
        trailing: Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }
}
