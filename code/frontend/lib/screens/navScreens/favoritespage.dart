import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/localization/app_localization.dart';
import 'package:hanini_frontend/screens/navScreens/service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<String> favoriteIds = [];
  List<Map<String, dynamic>> favoriteServices = [];

  @override
  void initState() {
    super.initState();
    _loadFavoritesFromFirebase();
  }

  Future<void> _loadFavoritesFromFirebase() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      // Fetch favorite IDs from the Firebase collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        final ids = List<String>.from(data?['favorites'] ?? []);

        setState(() {
          favoriteIds = ids;
        });

        // Load service details for each favorite ID
        await _loadServiceDetails();
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<void> _loadServiceDetails() async {
    try {
      final serviceSnapshots = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: favoriteIds)
          .get();

      setState(() {
        favoriteServices = serviceSnapshots.docs
            .map(
                (doc) => {'uid': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading service details: $e');
    }
  }

  void toggleFavorite(Map<String, dynamic> service) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to add favorites')),
      );
      return;
    }

    try {
      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(userId);
      final serviceId = service['uid']; // Ensure you use the correct 'id'

      final isCurrentlyFavorite = favoriteIds.contains(serviceId);

      if (isCurrentlyFavorite) {
        // Remove from favorites
        await userDocRef.update({
          'favorites': FieldValue.arrayRemove([serviceId]),
        });

        setState(() {
          favoriteIds.remove(serviceId);
          favoriteServices.removeWhere((s) => s['uid'] == serviceId);
        });
      } else {
        // Add to favorites
        await userDocRef.update({
          'favorites': FieldValue.arrayUnion([serviceId]),
        });

        setState(() {
          favoriteIds.add(serviceId);
          favoriteServices.add(service);
        });
      }
    } catch (e) {
      debugPrint('Error updating favorites: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to update favorites. Please try again!')),
      );
    }
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
              child: favoriteServices.isEmpty
                  ? Center(
                      child: Text(
                        appLocalizations.noFavoriteServicesYet,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : GridView.builder(
                      itemCount: favoriteServices.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        childAspectRatio: 0.8,
                      ),
                      itemBuilder: (context, index) {
                        final service = favoriteServices[index];
                        return _buildServiceCard(context, service);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, Map<String, dynamic> service) {
    final isFavorite = favoriteIds.contains(service['uid']); // Use 'uid'

    return GestureDetector(
      onTap: () {
        // Navigate to FullProfilePage with the selected service's ID
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceProviderFullProfile(
              providerId: service['uid'], // Use 'uid' from the service map
            ),
          ),
        );
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
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.network(
                      service['photoURL'] ?? '',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.broken_image,
                              size: 50, color: Colors.grey),
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
                        service['basicInfo']['profession'] ?? 'N/A',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        service['name'] ?? 'Unknown',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      _buildStarRating(service['rating'].toDouble()),
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
