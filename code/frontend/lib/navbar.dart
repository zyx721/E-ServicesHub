import 'package:flutter/material.dart';
import 'package:hanini_frontend/main.dart';
import 'package:hanini_frontend/screens/navScreens/SimpleUserProfile.dart';
import 'package:iconsax/iconsax.dart';
import 'package:hanini_frontend/screens/navScreens/searchpage.dart';
import 'package:hanini_frontend/screens/navScreens/profilepage.dart';
import 'package:hanini_frontend/screens/navScreens/favoritespage.dart';
import 'package:hanini_frontend/screens/navScreens/sidebar.dart';
import 'package:hanini_frontend/screens/navScreens/homepage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/localization/app_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
class NavbarPage extends StatefulWidget {
  const NavbarPage({Key? key}) : super(key: key);

  @override
  State<NavbarPage> createState() => _NavbarPageState();
}

class _NavbarPageState extends State<NavbarPage> {
  int selectedIndex = 0;

  final List<Widget> screens = [
    HomePage(),
    SearchPage(),
    FavoritesPage(),
    SimpleUserProfile(),
  ];

  // Language change logic
  void _changeLanguage(String languageCode) {
    Locale newLocale;
    switch (languageCode) {
      case 'ar':
        newLocale = Locale('ar', '');
        break;
      case 'fr':
        newLocale = Locale('fr', '');
        break;
      default:
        newLocale = Locale('en', '');
    }
    MyApp.of(context)?.changeLanguage(newLocale);
  }

  // Handle logout functionality
  Future<void> handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false); // Reset login state
    Navigator.pushReplacementNamed(context, '/login'); // Or '/onboarding'
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(64.0), // Set height for the AppBar
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF3949AB), // Indigo 600
                Color(0xFF1E88E5), // Blue 600
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: AppBar(
            title: Text(
              appLocalizations.appTitle,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.transparent, // Transparent to show gradient
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  // Handle notifications
                },
              ),
              _buildLanguageDropdown(),
            ],
          ),
        ),
      ),
      drawer: Sidebar(context, appLocalizations),
      body: screens[selectedIndex], // Switch between screens based on the selected index
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
    );
  }

  // Language Dropdown for switching languages
  Widget _buildLanguageDropdown() {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return Padding(
        padding: const EdgeInsets.only(right: 20.0),
        child: CircularProgressIndicator(),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 20.0),
      child: PopupMenuButton<String>(
        onSelected: _changeLanguage,
        icon: Icon(Icons.language, color: Colors.white, size: 28),
        itemBuilder: (BuildContext context) {
          return [
            _buildLanguageMenuItem('en', localizations.englishLanguageName,
                'assets/images/sen.png'),
            _buildLanguageMenuItem('ar', localizations.arabicLanguageName,
                'assets/images/sarab.png'),
            _buildLanguageMenuItem('fr', localizations.frenchLanguageName,
                'assets/images/sfr.png'),
          ];
        },
      ),
    );
  }

  // Helper function to build the language selection menu
  PopupMenuItem<String> _buildLanguageMenuItem(
      String languageCode, String languageName, String flagPath) {
    return PopupMenuItem<String>(
      value: languageCode,
      child: Row(
        children: [
          Image.asset(flagPath, width: 22),
          SizedBox(width: 10),
          Text(languageName),
        ],
      ),
    );
  }
}
