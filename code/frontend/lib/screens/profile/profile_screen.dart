import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:hanini_frontend/screens/SettingsScreen/SettingsScreen.dart';
import 'package:hanini_frontend/screens/verification/face_verification_screen.dart';
import '../../user_role.dart';
import 'package:hanini_frontend/screens/onboarding/onboarding_screen.dart';

class ProfileScreen extends StatelessWidget {
  final List<CameraDescription> cameras;
  final UserRole userRole;

  ProfileScreen({Key? key, required this.cameras, required this.userRole})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the screen size
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final availableHeight = screenSize.height - padding.top - padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile',
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      // Wrap the main content in a SingleChildScrollView
      body: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: availableHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile section with adaptive spacing
                SizedBox(height: availableHeight * 0.02),
                Center(
                  child: CircleAvatar(
                    radius: screenSize.width * 0.125, // Responsive avatar size
                    backgroundImage: AssetImage('assets/images/profile_picture.png'),
                  ),
                ),
                SizedBox(height: availableHeight * 0.02),
                
                // User information section
                Center(
                  child: Text(
                    'Benmati Ziad',
                    style: GoogleFonts.poppins(
                      fontSize: screenSize.width * 0.06, // Responsive font size
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: availableHeight * 0.01),
                
                Center(
                  child: Text(
                    'Location: Algeria, Algiers',
                    style: GoogleFonts.poppins(
                      fontSize: screenSize.width * 0.04,
                    ),
                  ),
                ),
                SizedBox(height: availableHeight * 0.01),
                
                Center(
                  child: Text(
                    'Role: ${userRole.toString().split('.').last}',
                    style: GoogleFonts.poppins(
                      fontSize: screenSize.width * 0.04,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: availableHeight * 0.02),

                // Contact information with responsive sizing
                _buildModernContactInfo(
                  context,
                  'Email',
                  'benmatiziad5@gmail.com',
                ),
                SizedBox(height: availableHeight * 0.01),
                _buildModernContactInfo(
                  context,
                  'Phone',
                  '(+213) 785945402',
                ),
                SizedBox(height: availableHeight * 0.02),

                // Conditional verification button
                if (userRole == UserRole.serviceProvider) ...[
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RealTimeDetection(cameras: cameras),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenSize.width * 0.1,
                          vertical: screenSize.height * 0.02,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Verify Identity',
                        style: GoogleFonts.poppins(
                          fontSize: screenSize.width * 0.04,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: availableHeight * 0.02),
                ],

                // Option cards
                _buildOptionCard(
                  context,
                  'Service History',
                  Icons.history,
                  () {},
                ),
                SizedBox(height: availableHeight * 0.01),
                _buildOptionCard(
                  context,
                  'Settings',
                  Icons.settings,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsScreen(),
                      ),
                    );
                  },
                ),
                SizedBox(height: availableHeight * 0.01),
                _buildOptionCard(
                  context,
                  'Logout',
                  Icons.logout,
                  () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OnboardingScreen(),
                      ),
                    );
                  },
                  isLogout: true,
                ),
                // Add bottom padding for better scrolling experience
                SizedBox(height: availableHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernContactInfo(BuildContext context, String title, String info) {
    final screenSize = MediaQuery.of(context).size;
    
    return Center(
      child: Container(
        width: screenSize.width * 0.9, // Responsive width
        padding: EdgeInsets.all(screenSize.width * 0.03),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: screenSize.width * 0.04,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              info,
              style: GoogleFonts.poppins(
                fontSize: screenSize.width * 0.04,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isLogout = false,
  }) {
    final screenSize = MediaQuery.of(context).size;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isLogout ? Colors.red : Colors.blueAccent,
          size: screenSize.width * 0.06,
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: screenSize.width * 0.045,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward,
          size: screenSize.width * 0.06,
        ),
        onTap: onTap,
      ),
    );
  }
}