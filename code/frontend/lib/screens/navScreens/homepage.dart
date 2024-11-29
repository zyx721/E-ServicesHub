import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/localization/app_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PageController _pageController;
  int _currentPage = 0;
  late Timer _adTimer;

  // List to store liked service IDs
  List<String> likedServiceIds = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadLikedServices();

    // Auto-slide logic
    _adTimer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (_pageController.hasClients) {
        setState(() {
          _currentPage = (_currentPage + 1) % 3;
        });
        _pageController.animateToPage(
          _currentPage,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _adTimer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // Load liked services from SharedPreferences
  Future<void> _loadLikedServices() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      likedServiceIds = prefs.getStringList('likedServiceIds') ?? [];
    });
  }

  // Save liked services to SharedPreferences
  Future<void> _saveLikedServices() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('likedServiceIds', likedServiceIds);
  }

  Future<void> handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    Navigator.pushReplacementNamed(context, '/login');
  }

  Widget _buildAdsSlider(List<String> adImages) {
    // List of URLs corresponding to each ad
    final List<String> adLinks = [
      'https://www.economic-dz.com',
      'https://www.aegiscare.in',
      'https://yashfine.com/ar/searchinfo/soins_%C3%A0_domicile_mhs/735',
    ];

    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: _pageController,
        itemCount: adImages.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () async {
              final url = Uri.parse(adLinks[index]);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
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
    // Define the list of services with their respective names, images, and unique IDs
    final List<Map<String, dynamic>> services = [
      {
        'id': 'service_001',
        'name': 'Painter',
        'image': 'assets/images/service1.png',
        'provider': 'ziad',
        'rating': 4.0
      },
      {
        'id': 'service_002',
        'name': 'Plumber',
        'image': 'assets/images/service2.png',
        'provider': 'anas',
        'rating': 4.2
      },
      {
        'id': 'service_003',
        'name': 'Big House Plumbing',
        'image': 'assets/images/service3.png',
        'provider': 'raouf',
        'rating': 4.5
      },
      {
        'id': 'service_004',
        'name': 'Electrical Engineer',
        'image': 'assets/images/service4.png',
        'provider': 'mouh',
        'rating': 4.1
      },
      {
        'id': 'service_005',
        'name': 'Floor Cleaning',
        'image': 'assets/images/service5.png',
        'provider': 'fares',
        'rating': 3.9
      },
      {
        'id': 'service_006',
        'name': 'Carpentry',
        'image': 'assets/images/service6.png',
        'provider': 'ziad',
        'rating': 4.0
      },
      {
        'id': 'service_007',
        'name': 'Makeup Artist',
        'image': 'assets/images/service7.png',
        'provider': 'anas',
        'rating': 4.5
      },
      {
        'id': 'service_008',
        'name': 'Private Tutor',
        'image': 'assets/images/service8.png',
        'provider': 'raouf',
        'rating': 4.3
      },
      {
        'id': 'service_009',
        'name': 'Workout Coach',
        'image': 'assets/images/service9.png',
        'provider': 'mouh',
        'rating': 4.4
      },
      {
        'id': 'service_010',
        'name': 'Therapy for Mental Help',
        'image': 'assets/images/service10.png',
        'provider': 'fares',
        'rating': 4.2
      },
      {
        'id': 'service_011',
        'name': 'Locksmith',
        'image': 'assets/images/service11.png',
        'provider': 'ziad',
        'rating': 3.8
      },
      {
        'id': 'service_012',
        'name': 'Guardian',
        'image': 'assets/images/service12.png',
        'provider': 'anas',
        'rating': 4.1
      },
      {
        'id': 'service_013',
        'name': 'Chef',
        'image': 'assets/images/service13.png',
        'provider': 'raouf',
        'rating': 4.6
      },
      {
        'id': 'service_014',
        'name': 'Solar Panel Installation',
        'image': 'assets/images/service14.png',
        'provider': 'mouh',
        'rating': 4.5
      },
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
          // Services grid
          Expanded(
            child: GridView.builder(
              itemCount: services.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                final service = services[index];
                return _buildServiceItem(
                  context,
                  service['id']!,
                  service['name']!,
                  service['image']!,
                  service['provider']!,
                  service['rating']!,
                  likedServiceIds.contains(service['id']),
                  (String serviceId) {
                    setState(() {
                      // Toggle liked status
                      if (likedServiceIds.contains(serviceId)) {
                        likedServiceIds.remove(serviceId);
                      } else {
                        likedServiceIds.add(serviceId);
                      }
                      // Save updated liked services
                      _saveLikedServices();
                    });
                  },
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
    String serviceId,
    String serviceName,
    String imagePath,
    String providerName,
    double rating,
    bool favorite,
    Function(String) toggleFavorite,
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
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      favorite ? Icons.favorite : Icons.favorite_border,
                      color: favorite ? Colors.red : Colors.grey,
                    ),
                    onPressed: () {
                      toggleFavorite(serviceId);
                    },
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
                    'Provider: $providerName',
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
        ...List.generate(fullStars,
            (index) => Icon(Icons.star, color: Colors.amber, size: 16)),
        if (halfStars > 0) Icon(Icons.star_half, color: Colors.amber, size: 16),
        ...List.generate(emptyStars,
            (index) => Icon(Icons.star_border, color: Colors.amber, size: 16)),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context, AppLocalizations appLocalizations) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text('Hanini App'),
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
