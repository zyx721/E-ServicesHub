import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/localization/app_localization.dart';
import 'package:hanini_frontend/main.dart';
import 'package:hanini_frontend/screens/onboarding/onboarding_screen.dart';
import 'package:hanini_frontend/screens/services/ServiceDetailScreen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.appTitle,
            style: GoogleFonts.poppins(fontSize: 20)),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // Handle notifications
            },
          ),
          _buildLanguageDropdown(), // Add language dropdown
        ],
      ),
      
      drawer: _buildDrawer(context, appLocalizations),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(appLocalizations),
            SizedBox(height: 20),
            Text(
              appLocalizations.availableServices,
              style: GoogleFonts.poppins(
                  fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            // Wrap the GridView in Expanded to fill available space without overflow
            Expanded(
              child: GridView.builder(
                itemCount: 6, // Adjust based on the number of services
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.8,
                ),
                itemBuilder: (context, index) {
                  String providerName = 'Provider ${index + 1}';
                  double rating = 4.0 + (index % 3) * 0.5; // Example ratings
                  return _buildServiceItem(
                    context,
                    appLocalizations.service(index + 1),
                    'assets/images/service${index + 1}.png',
                    providerName,
                    rating,
                    appLocalizations,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build the language selection dropdown with icons
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

  // Helper method to build individual language menu items with flags
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

  Widget _buildSearchBar(AppLocalizations appLocalizations) {
    return TextField(
      decoration: InputDecoration(
        hintText: appLocalizations.searchHint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.blue),
        ),
        prefixIcon: Icon(Icons.search, color: Colors.blue),
      ),
    );
  }

  Widget _buildServiceItem(
      BuildContext context,
      String serviceName,
      String imagePath,
      String providerName,
      double rating,
      AppLocalizations localizations) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailScreen(
              serviceName: serviceName,
              imagePath: imagePath,
              providerName: providerName,
              rating: rating,
              description: '',
            ),
          ),
        );
      },
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.asset(
                imagePath,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '${localizations.provider}: $providerName',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 5),
                  _buildStarRating(rating), // Add the star rating widget
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    int fullStars = rating.floor();
    int halfStars = (rating % 1 >= 0.5) ? 1 : 0;
    int emptyStars = 5 - fullStars - halfStars;

    return Row(
      children: [
        for (int i = 0; i < fullStars; i++)
          Icon(Icons.star, color: Colors.amber, size: 20), // Increased size
        for (int i = 0; i < halfStars; i++)
          Icon(Icons.star_half,
              color: Colors.amber, size: 20), // Increased size
        for (int i = 0; i < emptyStars; i++)
          Icon(Icons.star_border,
              color: Colors.grey, size: 20), // Changed empty star color
      ],
    );
  }

  Widget _buildDrawer(BuildContext context, AppLocalizations appLocalizations) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              appLocalizations.menu,
              style: GoogleFonts.poppins(fontSize: 24, color: Colors.white),
            ),
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text(appLocalizations.profile, style: GoogleFonts.poppins()),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title:
                Text(appLocalizations.settings, style: GoogleFonts.poppins()),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: Icon(Icons.language),
            title:
                Text(appLocalizations.language, style: GoogleFonts.poppins()),
            onTap: () {
              Navigator.pop(context);
              // Implement language selection here
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text(appLocalizations.logout, style: GoogleFonts.poppins()),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              // Implement logout functionality here (if needed)

              // Navigate to the OnboardingScreen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      OnboardingScreen(), // Navigate to OnboardingScreen
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
