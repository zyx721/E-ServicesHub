import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/localization/app_localization.dart';
import 'package:hanini_frontend/models/colors.dart';


class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return Container();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.mainGradient, // Apply gradient here
          ),
          child: AppBar(
            title: Text(
              localizations.settings,
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent, // Make the background transparent to show the gradient
            elevation: 0, // Remove shadow for clean look
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Change Password Option
            _buildOptionCard(context, localizations.changePassword, Icons.lock,
                () {
              // Navigate to change password screen
            },),
            SizedBox(height: 10),
            // Notification Settings Option
            _buildOptionCard(context, localizations.notificationSettings,
                Icons.notifications, () {
              // Navigate to notification settings screen
            },),
            SizedBox(height: 10),
            // Privacy Settings Option
            _buildOptionCard(
                context, localizations.privacySettings, Icons.privacy_tip, () {
              // Navigate to privacy settings screen
            },),
            SizedBox(height: 10),

            // About App Option
            _buildOptionCard(context, localizations.aboutApp, Icons.info, () {

              // Show app info or navigate to an about screen
            },), // Pass black color for the icon
          ],
        ),
      ),
    );
  }


  Widget _buildOptionCard(BuildContext context, String title, IconData icon, VoidCallback onTap, {Color? iconColor}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor = AppColors.secondaryColor,
        ),
        title: Text(title, style: GoogleFonts.poppins(fontSize: 18)),
        trailing: Icon(Icons.arrow_forward, color: AppColors.secondaryColor,),
        onTap: onTap,
      ),
    );
  }
}
