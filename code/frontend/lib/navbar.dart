import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'screens/navScreens/homepage.dart';
import 'screens/navScreens/searchpage.dart';
import 'screens/navScreens/profilepage.dart';
import 'screens/navScreens/favoritespage.dart';
import 'package:hanini_frontend/screens/navScreens/sidebar.dart';
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

  final List<Widget> screens = const [
    HomePage(),
    SearchPage(),
    FavoritesPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      child :MaterialApp(
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
        drawer: buildDrawer(context, appLocalizations), // Use the imported function
        body: screens[selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              selectedIndex = index;
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
    ),
  );

  }
}
