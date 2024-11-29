import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/localization/app_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // For Timer
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false); // Reset login state
    Navigator.pushReplacementNamed(context, '/login');
  }

Widget _buildAdsSlider(List<String> adImages) {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // List of URLs corresponding to each ad
  final List<String> adLinks = [
    'https://www.economic-dz.com',
    'https://www.aegiscare.in',
    'https://yashfine.com/ar/searchinfo/soins_%C3%A0_domicile_mhs/735',
  ];

  // Auto-slide logic
  Timer.periodic(Duration(seconds: 3), (Timer timer) {
    if (_pageController.hasClients) {
      _currentPage = (_currentPage + 1) % adImages.length;
      _pageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  });

  return SizedBox(
    height: 200, // Set the height of the slider
    child: PageView.builder(
      controller: _pageController,
      itemCount: adImages.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () async {
            // Open the external link when an ad is clicked
            final url = Uri.parse(adLinks[index]);
            if (await canLaunchUrl(url)) {
              // Opens in the default web browser (e.g., Chrome)
              await launchUrl(url, mode: LaunchMode.externalApplication);
            } else {
              // Handle error if the URL can't be opened
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Could not launch ${adLinks[index]}")),
              );
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              adImages[index],
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    ),
  );
}



  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      drawer: _buildDrawer(context, appLocalizations),
      body: _buildBody(context, appLocalizations),
    );
  }

 Widget _buildBody(BuildContext context, AppLocalizations appLocalizations) {
  // Define the list of services with their respective names and images
  final List<Map<String, String>> services = [
    {'name': 'Painter', 'image': 'assets/images/service1.png'},
    {'name': 'Plumber', 'image': 'assets/images/service2.png'},
    {'name': 'Big House Plumbing', 'image': 'assets/images/service3.png'},
    {'name': 'Electrical Engineer', 'image': 'assets/images/service4.png'},
    {'name': 'Floor Cleaning', 'image': 'assets/images/service5.png'},
    {'name': 'Carpentry', 'image': 'assets/images/service6.png'},
    {'name': 'Makeup Artist', 'image': 'assets/images/service7.png'},
    {'name': 'Private Tutor', 'image': 'assets/images/service8.png'},
    {'name': 'Workout Coach', 'image': 'assets/images/service9.png'},
    {'name': 'Therapy for Mental Help', 'image': 'assets/images/service10.png'},
    {'name': 'Locksmith', 'image': 'assets/images/service11.png'},
    {'name': 'Guardian', 'image': 'assets/images/service12.png'},
    {'name': 'Chef', 'image': 'assets/images/service13.png'},
    {'name': 'Solar Panel Installation', 'image': 'assets/images/service14.png'},
  ];

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Column(
      children: [
        // Ads slider at the top
        _buildAdsSlider([
          'assets/images/ads/first_page.png',
          'assets/images/ads/second_page.png',
          'assets/images/ads/third_page.png',
        ]),
        const SizedBox(height: 20),
        // Modern "Services" title with icon
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              appLocalizations.availableServices,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(Icons.more_horiz, color: Colors.grey),
          ],
        ),
        const SizedBox(height: 10),
        // Services grid with updated styling and list
        Expanded(
          child: GridView.builder(
            itemCount: services.length, // Set the total number of services
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              // Extract service details for each item
              final service = services[index];
              return _buildServiceItem(
                context,
                service['name']!,
                service['image']!,
                'Provider ${index + 1}', // Placeholder provider name
                4.0 + (index % 3) * 0.5, // Dynamic rating
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
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
            flex: 3,
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
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              appLocalizations.appName,
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            title: Text(appLocalizations.home),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            title: Text(appLocalizations.logout),
            onTap: handleLogout,
          ),
        ],
      ),
    );
  }
}
