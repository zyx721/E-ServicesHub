import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> filteredServices = [];
  List<String> likedServiceIds = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterServices);
    _loadServicesFromFirestore();
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
          likedServiceIds = List<String>.from(userDoc.data()?['favorites'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error loading liked services: $e');
    }
  }

  Future<void> _loadServicesFromFirestore() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('isProvider', isEqualTo: true)
          .get();

      final fetchedServices = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        return {
          'uid': doc.id,
          'name': data?['name'] ?? 'Unknown',
          'profession': data?['basicInfo']?['profession'] ?? 'Not specified',
          'photoURL': data?['photoURL'] ?? '',
          'rating': (data?['rating'] is num) ? (data?['rating'] as num).toDouble() : 0.0,
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
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);
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
        const SnackBar(content: Text('Failed to update favorites. Please try again!')),
      );
    }
  }

  void _filterServices() {
    setState(() {
      final searchTerm = _searchController.text.toLowerCase().trim();
      filteredServices = services.where((service) {
        final serviceName = service['profession'].toLowerCase();
        return serviceName.contains(searchTerm) ||
            _calculateLevenshteinDistance(serviceName, searchTerm) <= 2;
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

  Widget _buildStarRating(double rating) {
    int fullStars = rating.floor();
    int halfStars = (rating % 1 >= 0.5) ? 1 : 0;
    int emptyStars = 5 - fullStars - halfStars;

    return Row(
      children: [
        for (int i = 0; i < fullStars; i++) const Icon(Icons.star, color: Colors.amber, size: 20),
        for (int i = 0; i < halfStars; i++) const Icon(Icons.star_half, color: Colors.amber, size: 20),
        for (int i = 0; i < emptyStars; i++) const Icon(Icons.star_border, color: Colors.grey, size: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
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
                  return _buildServiceItem(service, isFavorite);
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

  Widget _buildServiceItem(Map<String, dynamic> service, bool isFavorite) {
    return GestureDetector(
      onTap: () {
        // Replace with your navigation logic
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      service['photoURL'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service['profession'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        service['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                      ),
                      _buildStarRating(service['rating']),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.grey,
                ),
                onPressed: () => toggleFavorite(service),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
