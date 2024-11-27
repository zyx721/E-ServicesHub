import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/localization/app_localization.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences


Widget buildDrawer(BuildContext context, AppLocalizations appLocalizations) {
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
            Navigator.pop(context);
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
            Navigator.pop(context);
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
            Navigator.pop(context);
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
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isLoggedIn', false);
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      ],
    ),
  );
}
