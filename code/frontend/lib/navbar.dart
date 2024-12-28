import 'package:flutter/material.dart';
import 'package:hanini_frontend/main.dart';
import 'package:hanini_frontend/screens/Profiles/SimpleUserProfile.dart';
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
import 'package:geolocator/geolocator.dart';

class NavbarPage extends StatefulWidget {
  final int initialIndex;
  final String? serviceName;
  final String? preSelectedWorkDomain;

  const NavbarPage({
    Key? key, 
    required this.initialIndex, 
    this.serviceName,
    this.preSelectedWorkDomain,
  }) : super(key: key);

  @override
  State<NavbarPage> createState() => _NavbarPageState();
}

class _NavbarPageState extends State<NavbarPage> {
  late int selectedIndex;
  String? serviceName;
  List<Widget> screens = [];
  bool isLoading = true;
  bool isAdmin = false;
  String currentLanguage = 'en';
  String? _currentPreSelectedWorkDomain;


   final Map<String, Map<String, double>> cityBoundaries = {
    "Algiers": {"lat_min": 36.6, "lat_max": 36.9, "lon_min": 2.9, "lon_max": 3.2},
    "Oran": {"lat_min": 35.6, "lat_max": 35.8, "lon_min": -0.8, "lon_max": -0.5},
    "Constantine": {"lat_min": 36.2, "lat_max": 36.4, "lon_min": 6.5, "lon_max": 6.7},
    "Annaba": {"lat_min": 36.8, "lat_max": 37.1, "lon_min": 7.6, "lon_max": 7.8},
    "Blida": {"lat_min": 36.4, "lat_max": 36.7, "lon_min": 2.5, "lon_max": 3.2},
    "Sétif": {"lat_min": 35.5, "lat_max": 36.6, "lon_min": 5.3, "lon_max": 6.5},
    "Tébessa": {"lat_min": 34.5, "lat_max": 35.8, "lon_min": 7.5, "lon_max": 8.7},
  };


  @override
  void initState() {
    super.initState();
    _loadUserLanguage();
    selectedIndex = widget.initialIndex;
    _currentPreSelectedWorkDomain = widget.preSelectedWorkDomain;
    _initializeScreens();
    _determineAndStoreLocation(); // Add this line
  }


  Future<void> _determineAndStoreLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String city = _getCityFromCoordinates(position.latitude, position.longitude);

      // Store location data in Firebase
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'city': city,
          'location_x': position.latitude,
          'location_y': position.longitude,
          'last_location_update': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  String _getCityFromCoordinates(double lat, double lon) {
    for (var city in cityBoundaries.entries) {
      var bounds = city.value;
      if (lat >= bounds["lat_min"]! &&
          lat <= bounds["lat_max"]! &&
          lon >= bounds["lon_min"]! &&
          lon <= bounds["lon_max"]!) {
        return city.key;
      }
    }
    return "Outside predefined cities";
  }



  Future<void> _initializeScreens() async {
    try {
      final isProvider = await _checkIfUserIsProvider();
      final isAdminUser = await _checkIfUserIsAdmin();
      setState(() {
        isAdmin = isAdminUser;
        screens = isAdminUser
            ? [
                SearchPage(
                  preSelectedWorkDomain: _currentPreSelectedWorkDomain,
                ),
                AdminProfile(),
              ]
            : [
                HomePage(),
                SearchPage(
                  preSelectedWorkDomain: _currentPreSelectedWorkDomain,
                ),
                FavoritesPage(),
                isProvider ? ServiceProviderProfile() : SimpleUserProfile(),
              ];
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onDestinationSelected(int index) {
    if (selectedIndex != index) {
      setState(() {
        selectedIndex = index;
        // Reset preSelectedWorkDomain when switching away from search page
        if (_currentPreSelectedWorkDomain != null) {
          _currentPreSelectedWorkDomain = null;
          _initializeScreens(); // Rebuild screens with null preSelectedWorkDomain
        }
      });
    }
  }    Future<void> _loadUserLanguage() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          final savedLanguage = data['language'] as String?;
          if (savedLanguage != null) {
            setState(() {
              currentLanguage = savedLanguage;
              // Update app's locale
              _updateAppLanguage(savedLanguage);
            });
          }
        }
      }
    } catch (e) {
      print('Error loading user language: $e');
    }
  }

   Future<void> _updateLanguage(String languageCode) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Update in Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'language': languageCode,
        });

        // Update in UI
        _updateAppLanguage(languageCode);

        setState(() {
          currentLanguage = languageCode;
        });
      }
    } catch (e) {
      print('Error updating language: $e');
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
                      if (!isAdmin) _buildNotificationBell(),
                      _buildLanguageDropdown(),
                    ],
                  ),
                ),
              ),
              drawer: Sidebar(context, appLocalizations),
              body: screens[selectedIndex],
              bottomNavigationBar: NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: _onDestinationSelected, // Use new method
                destinations: isAdmin
                    ? [
                        NavigationDestination(
                            icon: Icon(Iconsax.search_normal),
                            label: appLocalizations.search),
                        NavigationDestination(
                            icon: Icon(Iconsax.user),
                            label: appLocalizations.profile),
                      ]
                    : [
                        NavigationDestination(
                            icon:
                                Icon(Iconsax.home, color: AppColors.mainColor),
                            label: appLocalizations.home),
                        NavigationDestination(
                            icon: Icon(Iconsax.search_normal,
                                color: AppColors.mainColor),
                            label: appLocalizations.search),
                        NavigationDestination(
                            icon: Icon(Iconsax.save_2,
                                color: AppColors.mainColor),
                            label: appLocalizations.favorites),
                        NavigationDestination(
                            icon:
                                Icon(Iconsax.user, color: AppColors.mainColor),
                            label: appLocalizations.profile),
                      ],
              ),
            ),
          );
  }

  Widget _buildLanguageDropdown() {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const Padding(
        padding: EdgeInsets.only(right: 20.0),
        child: CircularProgressIndicator(),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 20.0),
      child: PopupMenuButton<String>(
        onSelected: _updateLanguage,
        icon: const Icon(Icons.language, color: Colors.white, size: 28),
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

void _updateAppLanguage(String languageCode) {
    Locale newLocale;
    switch (languageCode) {
      case 'ar':
        newLocale = const Locale('ar', '');
        break;
      case 'fr':
        newLocale = const Locale('fr', '');
        break;
      default:
        newLocale = const Locale('en', '');
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
                builder: (context) =>
                    NotificationsPage(userId: _auth.currentUser?.uid ?? ''),
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
