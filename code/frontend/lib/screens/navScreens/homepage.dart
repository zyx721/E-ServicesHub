import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hanini_frontend/screens/navScreens/service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PageController _pageController;
  late final ScrollController _scrollController;

  int _currentPage = 0;
  late Timer _adTimer;

  List<Map<String, dynamic>> services = [];
  Set<String> favoriteServices = {};
  String? currentUserId;
  bool _isLoading = true;
  bool _isFetching = false;
  DocumentSnapshot? _lastDocument; // Tracks the last document for pagination
  final int _pageSize = 10; // Number of items to fetch per request

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _scrollController = ScrollController()..addListener(_onScroll);
    _initializeData();

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
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      await _fetchUserData();
      await _fetchServices();
    } catch (e) {
      debugPrint('Error initializing data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint('No user logged in');
        return;
      }

      currentUserId = user.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (userDoc.exists) {
        setState(() {
          favoriteServices = Set<String>.from(
            userDoc.data()?['favorites'] ?? [],
          );
        });
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  Future<void> _fetchServices() async {
  if (_isFetching) return;
  setState(() => _isFetching = true);

  try {
    // Fetch services only for providers, excluding the current user
    Query query = FirebaseFirestore.instance
        .collection('users')
        .where('isProvider', isEqualTo: true)
        .limit(_pageSize);

    // Start after the last document if it exists
    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    final QuerySnapshot snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _lastDocument = snapshot.docs.last;

        services.addAll(
          snapshot.docs
              .map((doc) {
                final service = doc.data() as Map<String, dynamic>;
                final serviceId = doc.id;
                // Exclude the current user from the list of services
                if (serviceId != currentUserId) {
                  return {
                    ...service,
                    'docId': serviceId,
                  };
                } else {
                  return null;
                }
              })
              .whereType<Map<String, dynamic>>(), // Use `whereType` to filter non-null values
        );
      });
    }
  } catch (e) {
    debugPrint('Error fetching services: $e');
  } finally {
    setState(() => _isFetching = false);
  }
}


  Future<void> toggleFavorite(Map<String, dynamic> service) async {
    if (currentUserId == null) {
      // Show a dialog or snackbar to prompt login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to add favorites')),
      );
      return;
    }

    try {
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId);

      final serviceId = service['docId'] ?? service['uid'];

      if (favoriteServices.contains(serviceId)) {
        // Remove from favorites
        await userDoc.update({
          'favorites': FieldValue.arrayRemove([serviceId]),
        });
        setState(() {
          favoriteServices.remove(serviceId);
        });
      } else {
        // Add to favorites
        await userDoc.update({
          'favorites': FieldValue.arrayUnion([serviceId]),
        });
        setState(() {
          favoriteServices.add(serviceId);
        });
      }
    } catch (e) {
      debugPrint('Error updating favorites: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update favorites')),
      );
    }
  }


Widget _buildAdsSlider(List<String> adImages) {
    final List<String> adLinks = [
      'https://www.economic-dz.com',
      'https://www.aegiscare.in',
      'https://yashfine.com/ar/searchinfo/soins_%C3%A0_domicile_mhs/735',
    ];

    return Container(
      height: 220,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: adImages.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => launchUrl(Uri.parse(adLinks[index])),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      adImages[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
              );
            },
          ),
          // Optional: Page indicator dots
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(adImages.length, (index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index ? Colors.blue : Colors.grey,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }


  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isFetching) {
      _fetchServices();
    }
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

  @override
  Widget build(BuildContext context) {
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
    'name': (AppLocalizations(Locale('en')).service(14)),
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
                appLocalizations.topService,
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
                return InkWell(
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
                  child: _buildServiceItem(
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
                  ),
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
                      toggleFavorite(serviceId);
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
                  serviceName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${appLocalizations.provider}: $providerName',
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
