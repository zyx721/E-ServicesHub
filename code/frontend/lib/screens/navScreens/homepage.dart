import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hanini_frontend/screens/navScreens/service.dart';
import 'package:hanini_frontend/models/colors.dart';
import 'package:hanini_frontend/models/servicesWeHave.dart';

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
            snapshot.docs.map((doc) {
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
            }).whereType<
                Map<String,
                    dynamic>>(), // Use `whereType` to filter non-null values
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
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(currentUserId);

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

  // Ads Slider Widget
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

  // Top Services Header Widget
  Widget _buildTopServicesHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 10), // Add padding to the entire Row
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Top Services',
            style: GoogleFonts.poppins(
              color: AppColors.mainColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Icon(Icons.more_horiz, color: AppColors.mainColor),
        ],
      ),
    );
  }

  // Grid of Services Widget
  // Grid of Services Widget
  Widget _buildServicesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 10), // Add padding here
      child: Expanded(
        child: GridView.builder(
          controller: _scrollController,
          itemCount: services.length + (_isFetching ? 1 : 0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, index) {
            if (index >= services.length) {
              return Center(child: CircularProgressIndicator());
            }

            final service = services[index];
            final serviceId = service['docId'] ?? service['uid'];
            final isFavorite = favoriteServices.contains(serviceId);

            return GestureDetector(
              onTap: () {
                // Navigate to FullProfilePage with the selected service's ID
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceProviderFullProfile(
                      providerId: serviceId,
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
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: Image.network(
                              service['photoURL'] ?? '',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(Icons.broken_image,
                                      size: 50, color: Colors.grey),
                                );
                              },
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.tempColor,
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(16),
                            ),
                          ),
                          child: Padding(
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
                                Text(
                                  service['name'] ?? 'Unknown',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.mainColor,
                                  ),
                                  maxLines: 1,
                                ),
                                _buildStarRating(service['rating'].toDouble()),
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
          },
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

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isFetching) {
      _fetchServices();
    }
  }

  // Top Services Header Widget
  Widget _buildTopPopularHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20), // Add padding here
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Popular Services',
            style: GoogleFonts.poppins(
              color: AppColors.mainColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: () {
              _showAllServices(context);
            },
            child: const Icon(Icons.more_horiz, color: AppColors.mainColor),
          ),
        ],
      ),
    );
  }

  void _showAllServices(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.8,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Services',
                    style: GoogleFonts.poppins(
                      color: AppColors.mainColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount:
                          PopularServicesModel.getPopularServices().length,
                      itemBuilder: (context, index) {
                        final service =
                            PopularServicesModel.getPopularServices()[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: service.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                service.iconPath,
                                width: 40,
                                height: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                service.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.mainColor,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${service.availableProviders} Providers',
                                style: const TextStyle(
                                  color: Color(0xff7B6F72),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Column _servicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 140,
          child: ListView.separated(
            // itemCount: categories.length,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
            ),
            itemBuilder: (context, index) {
              final service = PopularServicesModel.getPopularServices()[index];
              return Container(
                width: 150,
                decoration: BoxDecoration(
                  color: PopularServicesModel.getPopularServices()[index]
                      .color
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SvgPicture.asset(
                        service.iconPath,
                        width: 35,
                        height: 35,
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            PopularServicesModel.getPopularServices()[index]
                                .name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.mainColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        height: 35,
                        width: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xff9DCEFF),
                              Color(0xff92A3FD),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Center(
                          child: Text(
                            'Search',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 3,
                      ),
                      Text(
                        '${PopularServicesModel.getPopularServices()[index].availableProviders} Providers',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xff7B6F72),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(
              width: 25,
            ),
            itemCount: PopularServicesModel.getPopularServices().length,
            // scrollDirection: Axis.horizontal,
            // padding: const EdgeInsets.only(left: 20, right: 20), // Add this line
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              // Wrap Column in SingleChildScrollView
              // child: Padding(
              //   padding:
              //       const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Ads slider at the top
                  _buildAdsSlider([
                    'assets/images/ads/first_page.png',
                    'assets/images/ads/second_page.png',
                    'assets/images/ads/third_page.png',
                  ]),
                  const SizedBox(height: 20),
                  _buildTopPopularHeader(context),
                  const SizedBox(height: 20),
                  _servicesSection(),
                  const SizedBox(height: 20),
                  // Top Services Header
                  _buildTopServicesHeader(),
                  const SizedBox(height: 10),
                  // Services Grid (no Expanded here)
                  Container(
                    height:
                        400, // Set a fixed height or adjust according to the content
                    child: _buildServicesGrid(),
                  ),
                ],
              ),
            ),
      // ),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
    );
  }
}
