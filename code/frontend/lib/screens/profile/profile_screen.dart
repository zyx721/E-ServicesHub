import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/screens/verification/face_verification_screen.dart'; // Adjust this import as needed

class ProfileScreen extends StatelessWidget {
  final List<CameraDescription> cameras; // Add this to pass camera descriptions

  ProfileScreen({Key? key, required this.cameras}) : super(key: key);

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
              'John Doe', // Change to user's name
              style: GoogleFonts.poppins(
                  fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            // Location
            Text(
              'Location: New York, NY', // Change to user's location
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            SizedBox(height: 16),
            // Contact Information
            Text(
              'Email: john.doe@example.com', // Change to user's email
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Phone: (123) 456-7890', // Change to user's phone
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            SizedBox(height: 20),
            // Verification Button
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
            SizedBox(height: 20),
            // Service History
            ListTile(
              title: Text('Service History',
                  style: GoogleFonts.poppins(fontSize: 18)),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                // Navigate to service history screen
                // Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceHistoryScreen()));
              },
            ),
            Divider(),
            // Settings Button
            ListTile(
              title: Text('Settings', style: GoogleFonts.poppins(fontSize: 18)),
              trailing: Icon(Icons.settings),
              onTap: () {
                // Navigate to settings screen
                // Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen()));
              },
            ),
            Divider(),
            // Logout Button
            ListTile(
              title: Text('Logout',
                  style: GoogleFonts.poppins(fontSize: 18, color: Colors.red)),
              trailing: Icon(Icons.logout, color: Colors.red),
              onTap: () {
                // Logout functionality
              },
            ),
          ],
        ),
      ),
    );
  }
}
