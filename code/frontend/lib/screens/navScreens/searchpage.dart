import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/localization/app_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final List<Map<String, dynamic>> services = [
    {'id': 'service_001', 'name': 'Painter', 'image': 'assets/images/service1.png', 'provider': 'Provider 1', 'rating': 4.0},
    {'id': 'service_002', 'name': 'Plumber', 'image': 'assets/images/service2.png', 'provider': 'Provider 2', 'rating': 4.2},
    {'id': 'service_003', 'name': 'Big House Plumbing', 'image': 'assets/images/service3.png', 'provider': 'Provider 3', 'rating': 4.5},
    {'id': 'service_004', 'name': 'Electrical Engineer', 'image': 'assets/images/service4.png', 'provider': 'Provider 4', 'rating': 4.1},
    {'id': 'service_005', 'name': 'Floor Cleaning', 'image': 'assets/images/service5.png', 'provider': 'Provider 5', 'rating': 3.9},
    {'id': 'service_006', 'name': 'Carpentry', 'image': 'assets/images/service6.png', 'provider': 'Provider 6', 'rating': 4.0},
    {'id': 'service_007', 'name': 'Makeup Artist', 'image': 'assets/images/service7.png', 'provider': 'Provider 7', 'rating': 4.5},
    // Add other services here similarly
  ];

  List<Map<String, dynamic>> filteredServices = [];
  List<String> likedServiceIds = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredServices = services;

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
      filteredServices = services
          .where((service) => service['name']!
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
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
                    service['id']!,
                    service['name']!,
                    service['image']!,
                    service['provider']!,
                    service['rating']!,
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
                  borderRadius: const BorderRadius.vertical(
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
                  const SizedBox(height: 2),
                  Text(
                    '$providerName',
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
