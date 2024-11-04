import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:hanini_frontend/screens/verification/face_verification_screen.dart';
import '../../user_role.dart'; // Import your UserRole enum
import 'package:hanini_frontend/screens/onboarding/onboarding_screen.dart'; // Update with the correct path

class ProfileScreen extends StatelessWidget {
  final List<CameraDescription> cameras; // List of available cameras
  final UserRole userRole; // User role

  ProfileScreen({Key? key, required this.cameras, required this.userRole})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.poppins()),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage(
                  'assets/images/profile_picture.png'), // Change to user's profile picture
            ),
            SizedBox(height: 16),
            // User Name
            Text(
              'Benmati Ziad', // Change to user's name
              style: GoogleFonts.poppins(
                  fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            // Location
            Text(
              'Location: Algeria,alger', // Change to user's location
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            SizedBox(height: 8),
            // User Role Display
            Text(
              'Role: ${userRole.toString().split('.').last}', // Display the user role
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            // Contact Information
            Text(
              'Email: benmatiziad5@gmail.com', // Change to user's email
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Phone: (+213) 785945402', // Change to user's phone
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            SizedBox(height: 20),
            // Conditional Verification Button
            if (userRole == UserRole.serviceProvider) ...[
              ElevatedButton(
                onPressed: () {
                  // Navigate to real-time detection screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RealTimeDetection(cameras: cameras),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(
                  'Verify Identity',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
            SizedBox(height: 20),
            // Service History
            ListTile(
              title: Text('Service History',
                  style: GoogleFonts.poppins(fontSize: 18)),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                // Navigate to service history screen
              },
            ),
            Divider(),
            // Settings Button
            ListTile(
              title: Text('Settings', style: GoogleFonts.poppins(fontSize: 18)),
              trailing: Icon(Icons.settings),
              onTap: () {
                // Navigate to settings screen
              },
            ),
            Divider(),
            // Logout Button
            ListTile(
              title: Text(
                'Logout',
                style: GoogleFonts.poppins(fontSize: 18, color: Colors.red),
              ),
              trailing: Icon(Icons.logout, color: Colors.red),
              onTap: () {
                // Navigate to onboarding screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        OnboardingScreen(), // Change to your onboarding screen
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
