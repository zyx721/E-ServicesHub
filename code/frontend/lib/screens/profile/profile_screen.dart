import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:hanini_frontend/screens/SettingsScreen/SettingsScreen.dart';
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
        title: Text('Profile',
            style:
                GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage(
                    'assets/images/profile_picture.png'), // Change to user's profile picture
              ),
            ),
            SizedBox(height: 16),
            // User Name
            Center(
              child: Text(
                'Benmati Ziad', // Change to user's name
                style: GoogleFonts.poppins(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8),
            // Location
            Center(
              child: Text(
                'Location: Algeria, Algiers', // Change to user's location
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            ),
            SizedBox(height: 8),
            // User Role Display
            Center(
              child: Text(
                'Role: ${userRole.toString().split('.').last}', // Display the user role
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 20),

            // Contact Information - Centered and Modernized
            _buildModernContactInfo(
                'Email', 'benmatiziad5@gmail.com'), // Change to user's email
            SizedBox(height: 8),
            _buildModernContactInfo(
                'Phone', '(+213) 785945402'), // Change to user's phone
            SizedBox(height: 20),

            // Conditional Verification Button
            if (userRole == UserRole.serviceProvider) ...[
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to real-time detection screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RealTimeDetection(cameras: cameras),
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
                    style:
                        GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
            SizedBox(height: 20),

            // Service History and Settings Cards
            _buildOptionCard(context, 'Service History', Icons.history, () {
              // Navigate to service history screen
            }),
            SizedBox(height: 10),
            _buildOptionCard(context, 'Settings', Icons.settings, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SettingsScreen(), // Navigate to settings screen
                ),
              );
            }),

            SizedBox(height: 10),
            _buildOptionCard(context, 'Logout', Icons.logout, () {
              // Navigate to onboarding screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      OnboardingScreen(), // Change to your onboarding screen
                ),
              );
            }, isLogout: true),
          ],
        ),
      ),
    );
  }

  Widget _buildModernContactInfo(String title, String info) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 4), // Adds space between title and info
            Text(info, style: GoogleFonts.poppins(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
      BuildContext context, String title, IconData icon, VoidCallback onTap,
      {bool isLogout = false}) {
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
