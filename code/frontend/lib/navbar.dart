import 'package:flutter/material.dart';
import 'package:hanini_frontend/main.dart';
import 'package:hanini_frontend/screens/Profiles/SimpleUserProfile.dart';
import 'package:hanini_frontend/screens/become_provider_screen/profilepage.dart';
import 'package:iconsax/iconsax.dart';
import 'package:hanini_frontend/screens/navScreens/searchpage.dart';
import 'package:hanini_frontend/screens/Profiles/ServiceProviderProfile.dart';
import 'package:hanini_frontend/screens/navScreens/favoritespage.dart';
import 'package:hanini_frontend/screens/navScreens/sidebar.dart';
import 'package:hanini_frontend/screens/navScreens/homepage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/localization/app_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hanini_frontend/screens/navScreens/notificationspage.dart'; // Replace with actual file path
import 'package:hanini_frontend/screens/Profiles/AdminProfile.dart'; // Import AdminProfile
import 'models/colors.dart';

class NavbarPage extends StatefulWidget {
  final int initialIndex;
  final String? serviceName;
  const NavbarPage({Key? key, required this.initialIndex, this.serviceName}) : super(key: key);

  @override
  State<NavbarPage> createState() => _NavbarPageState();
}

class _NavbarPageState extends State<NavbarPage> {
  late int selectedIndex;
  String? serviceName;
  List<Widget> screens = [];
  bool isLoading = true;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
    _initializeScreens();
  }


  // Future<void> _initializeScreens() async {
    // try {
  //     final isProvider = await _checkIfUserIsProvider();
  //     setState(() {
  //       screens = [
  //         HomePage(),
  //         // SearchPage(),
  //         SearchPage(serviceName: widget.serviceName), // Pass serviceName here
  //         FavoritesPage(),
  //         isProvider ? ServiceProviderProfile2() : SimpleUserProfile(),
  //       ];
  //       isLoading = false;
  //     });
  //   } catch (e) {
  //     // Handle error (e.g., show a message or log it)
  //     print('Error fetching user data: $e');
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

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

  

Future<bool> _checkIfUserIsAdmin() async {
  final User? user = _auth.currentUser;
  if (user != null) {
    try {
      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return data['isAdmin'] ?? false;
      } else {
        throw Exception("User not found in Firestore");
      }
    } catch (e) {
      print("Error while fetching user: $e");
      throw Exception("Failed to fetch user data");
    }
  } else {
    throw Exception("No user is currently signed in");
  }
}

  Future<void> _initializeScreens() async {
    try {
      final isProvider = await _checkIfUserIsProvider();
      final isAdminUser = await _checkIfUserIsAdmin();
      setState(() {
        isAdmin = isAdminUser;
        screens = isAdminUser 
          ? [
              SearchPage(),
              AdminProfile(),
            ]
          : [
              HomePage(),
              SearchPage(),
              FavoritesPage(),
              isProvider ? ServiceProviderProfile() : SimpleUserProfile(),
            ];
        // Reset selected index if it's out of bounds for admin
        if (isAdminUser && selectedIndex > 1) {
          selectedIndex = 0;
        }
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        isLoading = false;
      });
    }
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
                        gradient: AppColors.mainGradient,
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
// <<<<<<< HEAD
                      // Only show notification bell for non-admin users
                      if (!isAdmin) _buildNotificationBell(),
// =======
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
                                  builder: (context) => NotificationsPage(
                                      userId: _auth.currentUser?.uid ?? ''),
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
                                if (!snapshot.hasData ||
                                    snapshot.data == null) {
                                  return const SizedBox(); // Show nothing if no data
                                }
                                final data = snapshot.data!.data()
                                    as Map<String, dynamic>;
                                final unreadCount =
                                    data['newCommentsCount'] ?? 0;

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
// >>>>>>> Anas_front
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
                destinations: isAdmin 
                  ? const [
                      NavigationDestination(
                          icon: Icon(Iconsax.search_normal), label: 'Search'),
                      NavigationDestination(
                          icon: Icon(Iconsax.user), label: 'Profile'),
                    ]
                  : const [
                  NavigationDestination(
                      icon: Icon(Iconsax.home,   color: AppColors.mainColor,), label: 'Home',),
                  NavigationDestination(
                      icon: Icon(Iconsax.search_normal,  color: AppColors.mainColor,), label: 'Search'),
                  NavigationDestination(
                      icon: Icon(Iconsax.save_2,   color: AppColors.mainColor,), label: 'Favorites'),
                  NavigationDestination(
                      icon: Icon(Iconsax.user,   color: AppColors.mainColor,), label: 'Profile'),
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

  Widget _buildNotificationBell() {
    return Stack(
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
                builder: (context) => NotificationsPage(
                    userId: _auth.currentUser?.uid ?? ''),
              ),
            );
          },
        ),
        Positioned(
          right: 4,
          top: 8,
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(_auth.currentUser?.uid ?? '')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == null) {
                return const SizedBox();
              }
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final unreadCount = data['newCommentsCount'] ?? 0;

              if (unreadCount == 0) {
                return const SizedBox();
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
    );
  }
}