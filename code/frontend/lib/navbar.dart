import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'screens/navScreens/homepage.dart';
import 'screens/navScreens/searchpage.dart';
import 'screens/navScreens/profilepage.dart';
import 'screens/navScreens/favoritespage.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/localization/app_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavbarPage extends StatefulWidget {
  const NavbarPage({Key? key}) : super(key: key);

  @override
  State<NavbarPage> createState() => _NavbarPageState();
}

class _NavbarPageState extends State<NavbarPage> {
  Future<void> handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false); // Reset login state
    Navigator.pushReplacementNamed(context, '/login'); // Or '/onboarding'
  }

  int selectedIndex = 0;

  final List<Widget> screens = const [
    HomePage(),
    SearchPage(),
    FavoritesPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            appLocalizations.appTitle,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: const Color(0xFF3949AB),
        ),
        drawer: _buildDrawer(context, appLocalizations),
        body: screens[selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              selectedIndex = index; // Update selectedIndex on tap
            });
          },
          destinations: const [
            NavigationDestination(icon: Icon(Iconsax.home), label: 'Home'),
            NavigationDestination(icon: Icon(Iconsax.search_normal), label: 'Search'),
            NavigationDestination(icon: Icon(Iconsax.save_2), label: 'Favorites'),
            NavigationDestination(icon: Icon(Iconsax.user), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AppLocalizations appLocalizations) {
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
            leading: const Icon(Icons.person, color: Color(0xFF3949AB)),
            title: Text(
              appLocalizations.profile,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              setState(() => selectedIndex = 3); // Navigate to Profile
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Color(0xFF3949AB)),
            title: Text(
              appLocalizations.settings,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              // Add Settings page navigation
            },
          ),
          ListTile(
            leading: const Icon(Icons.language, color: Color(0xFF3949AB)),
            title: Text(
              appLocalizations.language,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              // Add language selection logic
            },
          ),
          Divider(
            color: Colors.grey[400],
            thickness: 1,
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFF3949AB)),
            title: Text(
              appLocalizations.logout,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () async {
              await handleLogout();
            },
          ),
        ],
      ),
    );
  }
}
