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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(64.0),
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              appLocalizations.appTitle,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
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
      drawer: _buildDrawer(context, appLocalizations),
      body: _buildBody(context, appLocalizations),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations appLocalizations) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(appLocalizations),
          SizedBox(height: 20),
          Text(
            appLocalizations.availableServices,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              itemCount: 6,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                String providerName = 'Provider ${index + 1}';
                double rating = 4.0 + (index % 3) * 0.5;
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
    );
  }

  Widget _buildServiceItem(
  BuildContext context,
  String serviceName,
  String imagePath,
  String providerName,
  double rating,
  AppLocalizations localizations,
) {
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
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3, // Takes up 60% of the available space
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                    Icons.arrow_forward_ios_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2, // Takes up 40% of the available space
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    serviceName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    '${localizations.provider}: $providerName',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  _buildStarRating(rating),
                ],
              ),
            ),
          ),
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
    String languageCode,
    String languageName,
    String flagPath,
  ) {
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

  Widget _buildStarRating(double rating) {
    int fullStars = rating.floor();
    int halfStars = (rating % 1 >= 0.5) ? 1 : 0;
    int emptyStars = 5 - fullStars - halfStars;

    return Row(
      children: [
        for (int i = 0; i < fullStars; i++)
          Icon(Icons.star, color: Colors.amber, size: 20),
        for (int i = 0; i < halfStars; i++)
          Icon(Icons.star_half, color: Colors.amber, size: 20),
        for (int i = 0; i < emptyStars; i++)
          Icon(Icons.star_border, color: Colors.grey, size: 20),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context, AppLocalizations appLocalizations) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF3949AB)),
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
            onTap: () {
              Navigator.pop(context);
              // Implement logout functionality here (if needed)
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => OnboardingScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}