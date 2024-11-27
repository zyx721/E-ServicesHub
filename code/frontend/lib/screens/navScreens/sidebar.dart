import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/localization/app_localization.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'package:google_sign_in/google_sign_in.dart';




Widget buildDrawer(BuildContext context, AppLocalizations appLocalizations) {

  final GoogleSignIn _googleSignIn = GoogleSignIn();

   
   Future<void> handleLogout() async {
  final prefs = await SharedPreferences.getInstance();

  try {
    // Sign out from Google
    await _googleSignIn.signOut();

    // Reset login state in SharedPreferences
    await prefs.setBool('isLoggedIn', false);

  
  } catch (e) {
    print('Error during logout: $e');
    // Optionally, show an error message to the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logout failed: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: const BoxDecoration(color: Color(0xFF3949AB)),
          child: Text(
            appLocalizations.menu,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        ListTile(
          leading: Icon(Icons.person, color: Color(0xFF3949AB)),
          title: Text(
            appLocalizations.profile,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
  onTap: () {
  Navigator.pushNamed(context, '/profile');
},

        ),
        ListTile(
          leading: Icon(Icons.settings, color: Color(0xFF3949AB)),
          title: Text(
            appLocalizations.settings,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () {
  Navigator.pushNamed(context, '/settings');
},

        ),
        ListTile(
          leading: Icon(Icons.language, color: Color(0xFF3949AB)),
          title: Text(
            appLocalizations.language,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () {
            // Implement language selection here
          },
        ),
        Divider(
          color: Colors.grey[400],
          thickness: 1,
        ),
ListTile(
  leading: Icon(Icons.logout, color: Color(0xFF3949AB)),
  title: Text(
    appLocalizations.logout,
    style: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
  ),
  onTap: () async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm
              },
              child: Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      handleLogout();
      Navigator.pushReplacementNamed(context, '/login');
    }
  },
),

      ],
    ),
  );
}
