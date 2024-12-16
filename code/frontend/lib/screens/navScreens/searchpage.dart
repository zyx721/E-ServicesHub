import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/localization/app_localization.dart';
import 'package:hanini_frontend/screens/navScreens/service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
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
        final serviceName = service['name']!.toLowerCase();
        
        // Exact match
        if (serviceName.contains(searchTerm)) {
          return true;
        }
        
        // Fuzzy match using Levenshtein distance
        return _calculateLevenshteinDistance(serviceName, searchTerm) <= 2;
      }).toList();
    });
  }

  // Levenshtein distance algorithm to calculate string similarity
  int _calculateLevenshteinDistance(String s1, String s2) {
    // Create a matrix of zeros with length of both input strings
    List<List<int>> distances = List.generate(
      s1.length + 1, 
      (i) => List.generate(s2.length + 1, (j) => 0)
    );
    
    // Initialize first row and column
    for (int i = 0; i <= s1.length; i++) {
      distances[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      distances[0][j] = j;
    }
    
    // Calculate Levenshtein distance
    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        int cost = (s1[i - 1] == s2[j - 1]) ? 0 : 1;
        
        distances[i][j] = min(
          min(
            distances[i - 1][j] + 1,     // Deletion
            distances[i][j - 1] + 1      // Insertion
          ),
          distances[i - 1][j - 1] + cost // Substitution
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

    // Update filtered services if not yet initialized
    if (filteredServices.isEmpty) {
      filteredServices = services;
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(appLocalizations),
            SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                itemCount: filteredServices.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.8,
                ),
                itemBuilder: (context, index) {
                  final service = filteredServices[index];
                  return _buildServiceItem(
                    context,
                    service,
                    likedServiceIds.contains(service['id']),
                    (String serviceId) {
                      toggleFavorite(serviceId);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations appLocalizations) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: appLocalizations.searchHint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        prefixIcon: const Icon(Icons.search, color: Colors.blue),
      ),
    );
  }

  Widget _buildServiceItem(
    BuildContext context,
    Map<String, dynamic> service,
    bool favorite,
    Function(String) toggleFavorite,
  ) {
    return GestureDetector(
      onTap: () {
        // Navigate to ServiceProviderFullProfile when service is tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceProviderFullProfile(
              serviceId: service['id'],
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
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.asset(
                      service['image']!,
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
                        toggleFavorite(service['id']);
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
                      service['name']!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${service['provider']}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _buildStarRating(service['rating']),
                  ],
                ),
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