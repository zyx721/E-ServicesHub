import 'dart:math';

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
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> filteredServices = [];
  List<String> likedServiceIds = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _filterServices();
    });
    _loadLikedServices();
  }

  Future<void> _loadLikedServices() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      likedServiceIds = prefs.getStringList('likedServiceIds') ?? [];
    });
  }

  Future<void> _saveLikedServices() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('likedServiceIds', likedServiceIds);
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

  void _filterServices() {
    setState(() {
      filteredServices = services.where((service) {
        final searchTerm = _searchController.text.toLowerCase().trim();
        final serviceName = service['name'].toLowerCase();

        if (serviceName.contains(searchTerm)) {
          return true;
        }

        return _calculateLevenshteinDistance(serviceName, searchTerm) <= 2;
      }).toList();
    });
  }

  int _calculateLevenshteinDistance(String s1, String s2) {
    List<List<int>> distances = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s1.length; i++) distances[i][0] = i;
    for (int j = 0; j <= s2.length; j++) distances[0][j] = j;

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        int cost = (s1[i - 1] == s2[j - 1]) ? 0 : 1;
        distances[i][j] = min(
          min(distances[i - 1][j] + 1, distances[i][j - 1] + 1),
          distances[i - 1][j - 1] + cost,
        );
      }
    }

    return distances[s1.length][s2.length];
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    // Initialize services dynamically within build()
    services = [
      {
        'id': 'service_001',
        'name': appLocalizations.service(5),
        'image': 'assets/images/service1.png',
        'provider': 'ziad',
        'rating': 4.0
      },
      {
        'id': 'service_002',
        'name': appLocalizations.service(1),
        'image': 'assets/images/service2.png',
        'provider': 'anas',
        'rating': 4.2
      },
      {
        'id': 'service_003',
        'name': appLocalizations.service(1),
        'image': 'assets/images/service3.png',
        'provider': 'raouf',
        'rating': 4.5
      },
      {
        'id': 'service_004',
        'name': appLocalizations.service(2),
        'image': 'assets/images/service4.png',
        'provider': 'mouh',
        'rating': 4.1
      },
      {
        'id': 'service_005',
        'name': appLocalizations.service(5),
        'image': 'assets/images/service5.png',
        'provider': 'fares',
        'rating': 3.9
      },
      {
        'id': 'service_006',
        'name': appLocalizations.service(3),
        'image': 'assets/images/service6.png',
        'provider': 'ziad',
        'rating': 4.0
      },
      {
        'id': 'service_007',
        'name': appLocalizations.service(7),
        'image': 'assets/images/service7.png',
        'provider': 'anas',
        'rating': 4.5
      },
      {
        'id': 'service_008',
        'name': appLocalizations.service(8),
        'image': 'assets/images/service8.png',
        'provider': 'raouf',
        'rating': 4.3
      },
      {
        'id': 'service_009',
        'name': appLocalizations.service(9),
        'image': 'assets/images/service9.png',
        'provider': 'mouh',
        'rating': 4.4
      },
      {
        'id': 'service_010',
        'name': appLocalizations.service(10),
        'image': 'assets/images/service10.png',
        'provider': 'fares',
        'rating': 4.2
      },
      {
        'id': 'service_011',
        'name': appLocalizations.service(11),
        'image': 'assets/images/service11.png',
        'provider': 'ziad',
        'rating': 3.8
      },
      {
        'id': 'service_012',
        'name': appLocalizations.service(12),
        'image': 'assets/images/service12.png',
        'provider': 'anas',
        'rating': 4.1
      },
      {
        'id': 'service_013',
        'name': appLocalizations.service(13),
        'image': 'assets/images/service13.png',
        'provider': 'raouf',
        'rating': 4.6
      },
      {
        'id': 'service_014',
        'name': appLocalizations.service(14),
        'image': 'assets/images/service14.png',
        'provider': 'mouh',
        'rating': 4.5
      },
    ];

    // Filtered list based on favorites
    List<Map<String, dynamic>> likedServices = services
        .where((service) => likedServiceIds.contains(service['id']))
        .toList();

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
                          service['id'],
                          service['name'],
                          service['image'],
                          service['provider'],
                          service['rating'],
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
  return Card(
    elevation: 6,
    shadowColor: Colors.blue.withOpacity(0.3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceProviderFullProfile(
              serviceId: serviceId,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () {
                      // Add toggle favorite functionality if needed
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(
                  '${localizations.provider}: $providerName',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                ),
                Row(
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
          const Icon(Icons.star, color: Colors.amber, size: 20),
        for (int i = 0; i < halfStars; i++)
          const Icon(Icons.star_half, color: Colors.amber, size: 20),
        for (int i = 0; i < emptyStars; i++)
          const Icon(Icons.star_border, color: Colors.grey, size: 20),
      ],
    );
  }
}


