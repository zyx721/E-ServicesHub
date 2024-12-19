import 'package:flutter/material.dart';
import 'package:hanini_frontend/main.dart';
import 'package:hanini_frontend/screens/navScreens/SimpleUserProfile.dart';
import 'package:hanini_frontend/user_role.dart';
import 'package:iconsax/iconsax.dart';
import 'package:hanini_frontend/screens/navScreens/searchpage.dart';
import 'package:hanini_frontend/screens/navScreens/profilepage.dart';
import 'package:hanini_frontend/screens/navScreens/favoritespage.dart';
import 'package:hanini_frontend/screens/navScreens/sidebar.dart';
import 'package:hanini_frontend/screens/navScreens/homepage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/localization/app_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hanini_frontend/screens/navScreens/notificationspage.dart'; // Replace with actual file path



class NavbarPage extends StatefulWidget {


  const NavbarPage({Key? key}) : super(key: key);

  @override
  State<NavbarPage> createState() => _NavbarPageState();
}

class _NavbarPageState extends State<NavbarPage> {
  int selectedIndex = 0;
  List<Widget> screens = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeScreens();
  }

  Future<void> _initializeScreens() async {
    try {
      final isProvider = await _checkIfUserIsProvider();
      setState(() {
        screens = [
          HomePage(),
          SearchPage(),
          FavoritesPage(),
          isProvider ? ServiceProviderProfile2() : SimpleUserProfile(),
        ];
        isLoading = false;
      });
    } catch (e) {
      // Handle error (e.g., show a message or log it)
      print('Error fetching user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Future<bool> _checkIfUserIsProvider() async {
  final User? user = _auth.currentUser;
  
  // Check if the user is logged in
  if (user != null) {
    try {
      final DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

      // Check if the document exists and return the 'isProvider' field
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return data['isProvider'] ?? false;
      } else {
        throw Exception("User not found in Firestore");
      }
    } catch (e) {
      // Log error or handle it
      print("Error while fetching user: $e");
      throw Exception("Failed to fetch user data");
    }
  } else {
    // Handle the case where no user is signed in
    throw Exception("No user is currently signed in");
  }
}


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

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    return isLoading
        ? Center(child: CircularProgressIndicator())
        : PopScope(
          canPop: false,
          child: Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(64.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF3949AB),
                        Color(0xFF1E88E5),
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
                    backgroundColor: Colors.transparent,
                    elevation: 0,
actions: [
  Stack(
    alignment: Alignment.center,
    children: [
      IconButton(
        icon: const Icon(
          Icons.notifications_outlined,
          color: Colors.white,
          size: 28,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NotificationsPage(userId: _auth.currentUser?.uid ?? ''),
            ),
          );
        },
      ),
      Positioned(
        right: 4, // Adjust position to align badge properly
        top: 8,
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(_auth.currentUser?.uid ?? '')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return const SizedBox(); // Show nothing if no data
            }
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final unreadCount = data['newCommentsCount'] ?? 0;

            if (unreadCount == 0) {
              return const SizedBox(); // Show nothing if no unread comments
            }

            return Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ),
    ],
  ),
  _buildLanguageDropdown(),
],


                  ),
                ),
              ),
              drawer: Sidebar(context, appLocalizations),
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
                  NavigationDestination(
                      icon: Icon(Iconsax.search_normal), label: 'Search'),
                  NavigationDestination(
                      icon: Icon(Iconsax.save_2), label: 'Favorites'),
                  NavigationDestination(icon: Icon(Iconsax.user), label: 'Profile'),
                ],
              ),
            ),
        );
  }

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
