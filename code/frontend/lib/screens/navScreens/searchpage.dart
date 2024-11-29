import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/localization/app_localization.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
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

  List<Map<String, String>> filteredServices = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredServices = services;

    _searchController.addListener(() {
      _filterServices();
    });
  }

  void _filterServices() {
    setState(() {
      filteredServices = services
          .where((service) =>
              service['name']!
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
                    service['name']!,
                    service['image']!,
                    'Provider ${index + 1}',
                    4.0 + (index % 3) * 0.5,
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
