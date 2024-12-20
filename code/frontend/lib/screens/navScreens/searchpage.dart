import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  void _loadLikedServices() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        setState(() {
          likedServiceIds =
              List<String>.from(userDoc.data()?['favorites'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error loading liked services: $e');
    }
  }

  Future<void> _loadServicesFromFirestore() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('isProvider', isEqualTo: true)
          .get();

      final fetchedServices = snapshot.docs
          .where((doc) => doc.id != currentUserId) // Exclude current user
          .map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        return {
          'uid': doc.id,
          'name': data?['name'] ?? 'Unknown',
          'profession': data?['basicInfo']?['profession'] ?? 'Not specified',
          'photoURL': data?['photoURL'] ?? '',
          'rating': (data?['rating'] is num)
              ? (data?['rating'] as num).toDouble()
              : 0.0,
        };
      }).toList();

      setState(() {
        services = fetchedServices;
        filteredServices = services;
      });
    } catch (e) {
      debugPrint("Error fetching services: $e");
    }
  }

  void toggleFavorite(Map<String, dynamic> service) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add favorites')),
      );
      return;
    }

    try {
      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(userId);
      final serviceId = service['uid'];
      final isCurrentlyFavorite = likedServiceIds.contains(serviceId);

      if (isCurrentlyFavorite) {
        await userDocRef.update({
          'favorites': FieldValue.arrayRemove([serviceId]),
        });
        setState(() {
          likedServiceIds.remove(serviceId);
        });
      } else {
        await userDocRef.update({
          'favorites': FieldValue.arrayUnion([serviceId]),
        });
        setState(() {
          likedServiceIds.add(serviceId);
        });
      }
    } catch (e) {
      debugPrint('Error updating favorites: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to update favorites. Please try again!')),
      );
    }
  }

  void _filterServices() {
    setState(() {
      final searchTerm = _searchController.text.toLowerCase().trim();
      filteredServices = services.where((service) {
        final searchTerm = _searchController.text.toLowerCase().trim();
        final serviceName = service['name'].toLowerCase();

        // Exact match
        if (serviceName.contains(searchTerm)) {
          return true;
        }

        // Fuzzy match using Levenshtein distance
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
        'id': 'service_001',
        'name': (appLocalizations.service(5)),
        'image': 'assets/images/service1.png',
        'provider': 'ziad',
        'rating': 4.0
      },
      {
        'id': 'service_002',
        'name': (appLocalizations.service(1)),
        'image': 'assets/images/service2.png',
        'provider': 'anas',
        'rating': 4.2
      },
      {
        'id': 'service_003',
        'name': (appLocalizations.service(1)),
        'image': 'assets/images/service3.png',
        'provider': 'raouf',
        'rating': 4.5
      },
      {
        'id': 'service_004',
        'name': (appLocalizations.service(2)),
        'image': 'assets/images/service4.png',
        'provider': 'mouh',
        'rating': 4.1
      },
      {
        'id': 'service_005',
        'name': (appLocalizations.service(5)),
        'image': 'assets/images/service5.png',
        'provider': 'fares',
        'rating': 3.9
      },
      {
        'id': 'service_006',
        'name': (appLocalizations.service(3)),
        'image': 'assets/images/service6.png',
        'provider': 'ziad',
        'rating': 4.0
      },
      {
        'id': 'service_007',
        'name': (appLocalizations.service(7)),
        'image': 'assets/images/service7.png',
        'provider': 'anas',
        'rating': 4.5
      },
      {
        'id': 'service_008',
        'name': (appLocalizations.service(8)),
        'image': 'assets/images/service8.png',
        'provider': 'raouf',
        'rating': 4.3
      },
      {
        'id': 'service_009',
        'name': (appLocalizations.service(9)),
        'image': 'assets/images/service9.png',
        'provider': 'mouh',
        'rating': 4.4
      },
      {
        'id': 'service_010',
        'name': (appLocalizations.service(10)),
        'image': 'assets/images/service10.png',
        'provider': 'fares',
        'rating': 4.2
      },
      {
        'id': 'service_011',
        'name': (appLocalizations.service(11)),
        'image': 'assets/images/service11.png',
        'provider': 'ziad',
        'rating': 3.8
      },
      {
        'id': 'service_012',
        'name': (appLocalizations.service(12)),
        'image': 'assets/images/service12.png',
        'provider': 'anas',
        'rating': 4.1
      },
      {
        'id': 'service_013',
        'name': (appLocalizations.service(13)),
        'image': 'assets/images/service13.png',
        'provider': 'raouf',
        'rating': 4.6
      },
      {
        'id': 'service_014',
        'name': (appLocalizations..service(14)),
        'image': 'assets/images/service14.png',
        'provider': 'mouh',
        'rating': 4.5
      },
      // Add more services here
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
            const SizedBox(height: 20),
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
                  final isFavorite = likedServiceIds.contains(service['uid']);
                  return _buildServiceItem(service, isFavorite, service['uid']);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: "Search services...",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
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
    final appLocalizations = AppLocalizations.of(context)!;

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
                serviceId: service['id'],
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
                      service['image'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () {
                        toggleFavorite(service['id']);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        child: Icon(
                          favorite ? Icons.favorite : Icons.favorite_border,
                          color: favorite ? Colors.red : Colors.grey,
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
                    service['name'],
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${appLocalizations.provider}: ${service['provider']}',
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
                        service['rating'].toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
}
