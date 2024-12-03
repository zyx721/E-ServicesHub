import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/localization/app_localization.dart';
import 'package:hanini_frontend/screens/navScreens/service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  // Full list of all services
  final List<Map<String, dynamic>> allServices = [
    {
      'id': 'service_001',
      'name': 'Painter',
      'image': 'assets/images/service1.png',
      'provider': 'ziad',
      'rating': 4.5,
    },
    {
      'id': 'service_002',
      'name': 'Plumber',
      'image': 'assets/images/service2.png',
      'provider': 'anas',
      'rating': 4.0,
    },
    {
      'id': 'service_003',
      'name': 'Big House Plumbing',
      'image': 'assets/images/service3.png',
      'provider': 'raouf',
      'rating': 4.5,
    },
    {
      'id': 'service_004',
      'name': 'Electrical Engineer',
      'image': 'assets/images/service4.png',
      'provider': 'fares',
      'rating': 5.0,
    },
    {
      'id': 'service_005',
      'name': 'Floor Cleaning',
      'image': 'assets/images/service5.png',
      'provider': 'Provider 5',
      'rating': 4.2,
    },
    {
      'id': 'service_005',
      'name': 'Floor Cleaning',
      'image': 'assets/images/service5.png',
      'provider': 'Provider 5',
      'rating': 4.2,
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

  // List to store liked service IDs
  List<String> likedServiceIds = [];

  @override
  void initState() {
    super.initState();
    _loadLikedServices();
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

  // Get liked services
  List<Map<String, dynamic>> get likedServices {
    return allServices
        .where((service) => likedServiceIds.contains(service['id']))
        .toList();
  }

  void toggleFavorite(String serviceId) {
    setState(() {
      if (likedServiceIds.contains(serviceId)) {
        likedServiceIds.remove(serviceId);
      } else {
        likedServiceIds.add(serviceId);
      }
      _saveLikedServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: likedServices.isEmpty
                  ? Center(
                      child: Text(
                        'No favorite services yet',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : GridView.builder(
                      itemCount: likedServices.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        childAspectRatio: 0.8,
                      ),
                      itemBuilder: (context, index) {
                        final service = likedServices[index];
                        return _buildServiceItem(
                          context,
                          service['id']!,
                          service['name']!,
                          service['image']!,
                          service['provider']!,
                          service['rating']!,
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

  Widget _buildServiceItem(
    BuildContext context,
    String serviceId,
    String serviceName,
    String imagePath,
    String providerName,
    double rating,
    AppLocalizations localizations,
  ) {
    return GestureDetector(
      onTap: () {
        // Navigate to ServiceProviderFullProfile when service is tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceProviderFullProfile(
              serviceId: serviceId,
            ),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
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
                        const SizedBox(height: 2),
                        Text(
                          '${localizations.provider}: $providerName',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        _buildStarRating(rating),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(
                  Icons.favorite,
                  color: Colors.red,
                ),
                onPressed: () => toggleFavorite(serviceId),
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
          const Icon(Icons.star, color: Colors.amber, size: 20),
        for (int i = 0; i < halfStars; i++)
          const Icon(Icons.star_half, color: Colors.amber, size: 20),
        for (int i = 0; i < emptyStars; i++)
          const Icon(Icons.star_border, color: Colors.grey, size: 20),
      ],
    );
  }
}


