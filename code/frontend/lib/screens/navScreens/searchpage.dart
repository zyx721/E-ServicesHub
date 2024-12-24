import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hanini_frontend/models/colors.dart';
import 'package:hanini_frontend/screens/services/service.dart';

class SearchPage extends StatefulWidget {
  final String? serviceName;
  const SearchPage({Key? key, this.serviceName}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> filteredServices = [];
  List<String> likedServiceIds = [];
  final TextEditingController _searchController = TextEditingController();
  double _minRating = 0.0;
  bool _isRatingFilterApplied = false;
  RangeValues _priceRange = const RangeValues(0, 19999); // Set default max value to 19999
  bool _isPriceFilterApplied = false;
  List<String> _selectedWorkChoices = [];
  final List<String> _allWorkChoices = [
    'House Cleaning',
    'Electricity',
    'Plumbing',
    'Gardening',
    'Painting',
    'Carpentry',
    'Pest Control',
    'AC Repair',
    'Vehicle Repair',
    'Appliance Installation',
    'IT Support',
    'Home Security',
    'Interior Design',
    'Window Cleaning',
    'Furniture Assembly',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterServices);
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadServicesFromFirestore();
    // await _loadLikedServices();
    
    // This is the key part that makes the search automatic
    // Set initial search text and filter after data is loaded
    if (widget.serviceName != null) {
      _searchController.text = widget.serviceName!;    // Sets the search text
      _filterServices();     // Triggers the search
    }
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
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('isProvider', isEqualTo: true)
          .get();

// <<<<<<< HEAD
    final fetchedServices = snapshot.docs
        .where((doc) => doc.id != currentUserId) // Exclude current user
        .map((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      final basicInfo = data?['basicInfo'] as Map<String, dynamic>?;
      final price = basicInfo?['hourlyRate'] != null
          ? (basicInfo?['hourlyRate'] is num
              ? (basicInfo?['hourlyRate'] as num).toDouble()
              : double.tryParse(basicInfo?['hourlyRate']?.toString() ?? '') ?? 0.0)
          : 0.0;
      debugPrint('Service: ${data?['name']}, Price: $price'); // Debug statement
      return {
        'uid': doc.id,
        'name': data?['name'] ?? 'Unknown',
        'profession': basicInfo?['profession'] ?? 'Not specified',
        'photoURL': data?['photoURL'] ?? '',
        'rating': (data?['rating'] is num) ? (data?['rating'] as num).toDouble() : 0.0,
        'price': price, // Ensure price is fetched correctly
        'selectedWorkChoices': data?['selectedWorkChoices'] ?? [], // Add selectedWorkChoices
      };
    }).toList();
// =======
//       final fetchedServices = snapshot.docs
//           .where((doc) => doc.id != currentUserId)
//           .map((doc) {
//         final data = doc.data() as Map<String, dynamic>?;
//         return {
//           'uid': doc.id,
//           'name': data?['name'] ?? 'Unknown',
//           'profession': data?['basicInfo']?['profession'] ?? 'Not specified',
//           'photoURL': data?['photoURL'] ?? '',
//           'rating': (data?['rating'] is num) ? (data?['rating'] as num).toDouble() : 0.0,
//         };
//       }).toList();
// >>>>>>> Anas_front

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
        final matchesSearchTerm = serviceName.contains(searchTerm) ||
            _calculateLevenshteinDistance(serviceName, searchTerm) <= 2;
        final matchesRating = !_isRatingFilterApplied || service['rating'] >= _minRating;
        final matchesPrice = !_isPriceFilterApplied || (service['price'] >= _priceRange.start && (_priceRange.end == 19999 || service['price'] <= _priceRange.end));

        final matchesWorkChoices = _selectedWorkChoices.isEmpty || _selectedWorkChoices.any((choice) => service['selectedWorkChoices'].contains(choice));
        debugPrint('Service: ${service['name']}, Price: ${service['price']}, Matches Price: $matchesPrice, Matches Work Choices: $matchesWorkChoices'); // Debug statement
        return matchesSearchTerm && matchesRating && matchesPrice && matchesWorkChoices;
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Services'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      children: [
                        const Text('Minimum Rating'),
                        Slider(
                          value: _minRating,
                          min: 0,
                          max: 5,
                          divisions: 10,
                          label: _minRating.toString(),
                          onChanged: (value) {
                            setState(() {
                              _minRating = value;
                            });
                          },
                        ),
                        Text('Minimum Rating: ${_minRating.toStringAsFixed(1)}'),
                        const SizedBox(height: 20),
                        const Text('Price Range (DZD)'),
                        RangeSlider(
                          values: _priceRange,
                          min: 0,
                          max: 19999,
                          divisions: 1000,
                          labels: RangeLabels(
                            _priceRange.start.toStringAsFixed(0),
                            _priceRange.end == 19999 ? '∞' : _priceRange.end.toStringAsFixed(0),
                          ),
                          onChanged: (RangeValues values) {
                            setState(() {
                              _priceRange = values;
                            });
                          },
                        ),
                        Text('Price Range: ${_priceRange.start.toStringAsFixed(0)} - ${_priceRange.end == 19999 ? '∞' : _priceRange.end.toStringAsFixed(0)} DZD'),
                        const SizedBox(height: 20),
                        const Text('Work Domains'),
                        Container(
                          height: 150, // Fixed height for scrollable container
                          child: SingleChildScrollView(
                            child: Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: _allWorkChoices.map((choice) {
                                final isSelected = _selectedWorkChoices.contains(choice);
                                return FilterChip(
                                  label: Text(choice),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedWorkChoices.add(choice);
                                      } else {
                                        _selectedWorkChoices.remove(choice);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _minRating = 0.0;
                  _priceRange = const RangeValues(0, 19999);
                  _selectedWorkChoices.clear();
                  _isRatingFilterApplied = false;
                  _isPriceFilterApplied = false;
                  _filterServices();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Clear Filters'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isRatingFilterApplied = _minRating > 0.0;
                  _isPriceFilterApplied = _priceRange.start > 0 || _priceRange.end < 19999;
                  _filterServices();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Apply Filters'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
       Padding(
        padding: const EdgeInsets.only(left: 20, right: 20),
        child:
         Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildSearchBar(),
            const SizedBox(height: 10),
            _buildAppliedFilters(),
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
    return Container(
      margin: EdgeInsets.only(top: 10, left: 18, right: 18),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0xff1d1617).withOpacity(0.11),
            blurRadius: 40,
            spreadRadius: 0,
          )
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.all(15),
          hintText: 'Search services...',
          hintStyle: TextStyle(
            color: const Color.fromARGB(153, 170, 71, 188),
            fontSize: 14,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SvgPicture.asset('assets/search_icons/Search.svg'), // Replace with your own asset
          ),
          suffixIcon: Container(
            width: 100,
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  VerticalDivider(
                    color: Colors.black,
                    indent: 10,
                    endIndent: 10,
                    thickness: 0.1,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: GestureDetector(
                      onTap: _showFilterDialog, // Trigger filter dialog on press
                      child: SvgPicture.asset(
                        'assets/search_icons/Filter.svg', // Replace with your own asset
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }


  Widget _buildAppliedFilters() {
    List<Widget> filters = [];
    if (_isRatingFilterApplied && _minRating > 0.0) {
      filters.add(_buildFilterChip('Min Rating: ${_minRating.toStringAsFixed(1)}', () {
        setState(() {
          _minRating = 0.0;
          _isRatingFilterApplied = false;
          _filterServices();
        });
      }));
    }
    if (_isPriceFilterApplied && (_priceRange.start > 0 || _priceRange.end < 19999)) {
      filters.add(_buildFilterChip('Price: ${_priceRange.start.toStringAsFixed(0)} - ${_priceRange.end == 19999 ? '∞' : _priceRange.end.toStringAsFixed(0)} DZD', () {
        setState(() {
          _priceRange = const RangeValues(0, 19999);
          _isPriceFilterApplied = false;
          _filterServices();
        });
      }));
    }
    if (_selectedWorkChoices.isNotEmpty) {
      filters.addAll(_selectedWorkChoices.map((choice) => _buildFilterChip(choice, () {
        setState(() {
          _selectedWorkChoices.remove(choice);
          _filterServices();
        });
      })).toList());
    }
    return Wrap(
      spacing: 8.0,
      children: filters,
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDeleted) {
    return Chip(
      label: Text(label),
      onDeleted: onDeleted,
      deleteIcon: const Icon(Icons.close),
      backgroundColor: Colors.blue.shade100,
    );
  }

  Widget _buildServiceItem(Map<String, dynamic> service, bool isFavorite, String serviceId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceProviderFullProfile(providerId: serviceId),
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
                      Text(
                        'Price: \DZD ${service['price'].toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}