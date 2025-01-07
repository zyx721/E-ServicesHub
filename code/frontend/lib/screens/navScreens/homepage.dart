import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/navbar.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hanini_frontend/screens/services/service.dart';
import 'package:hanini_frontend/models/colors.dart';
import 'package:hanini_frontend/models/servicesWeHave.dart';
import 'package:hanini_frontend/localization/app_localization.dart';
import '../../services/data_manager.dart';

// Helper class to structure service data
class ServiceCategory {
  final String id;
  final String localizedName;

  const ServiceCategory(this.id, this.localizedName);
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PageController _pageController;
  late final ScrollController _scrollController;
  final RefreshController _refreshController = RefreshController();

  bool get wantKeepAlive => true; // This ensures the state is preserved

  int _currentPage = 0;
  late Timer _adTimer;

  List<Map<String, dynamic>> services = [];
  Set<String> favoriteServices = {};
  String? currentUserId;
  bool _isLoading = true;
  bool _isFetching = false;
  final int _pageSize = 7;

  bool _hasMoreData = true;
  late Future<List<PopularServicesModel>> _popularServicesFuture;
  int _refreshCount = 0;
  final int _maxRefreshCount = 10;
  bool _isInitializing = true; // Add this flag

  @override
  void initState() {
    super.initState();
    debugPrint('🏠 HomePage initState called');
    _pageController = PageController();
    _scrollController = ScrollController()..addListener(_onScroll);

    _initializeData();
    _popularServicesFuture = PopularServicesModel.getPopularServices(context);

    _adTimer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_pageController.hasClients) {
        setState(() {
          _currentPage = (_currentPage + 1) % 3;
        });
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _initializeData() async {
    setState(() {
      _isInitializing = true;
      _isLoading = true;
    });

    try {
      debugPrint('🔄 Initializing HomePage from cache...');
      final dataManager = DataManager();
      debugPrint('📥 Attempting to retrieve cached data...');
      
      final userData = dataManager.getCurrentUserData();
      if (userData != null) {
        debugPrint('👤 Found cached user data');
        currentUserId = userData['uid'];
        favoriteServices = Set<String>.from(userData['favorites'] ?? []);
        
        final cityUsers = dataManager.getCityUsers();
        if (cityUsers.isEmpty) {
          debugPrint('⚠️ No cached city users found, requesting cache reload');
          await dataManager.reloadCache();
          return;
        }
        
        final providers = cityUsers.where((user) => user['isProvider'] == true).toList();
        
        if (providers.isNotEmpty) {
          debugPrint('📊 Found ${providers.length} service providers in cache');
          setState(() {
            services = providers;
            _hasMoreData = false; // We already have all data
          });
        }
      } else {
        debugPrint('⚠️ No user data in cache, requesting user login');
        // Handle the case when user data is not available
        // Maybe redirect to login or show an error
      }
    } catch (e) {
      debugPrint('❌ Error during initialization: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchUserDataAndRecommendations() async {
    await _fetchUserData();
    await _loadRecommendations();
  }

  // Remove didChangeDependency override as we don't want to reload on navigation

  Future<void> _fetchMoreServices() async {
    if (_isFetching || !_hasMoreData) return;

    setState(() => _isFetching = true);

    try {
      // First get the recommended providers
      if (recommendedProviderIds.isEmpty) {
        await _loadRecommendations();
      }

      if (recommendedProviderIds.isEmpty) {
        setState(() => _hasMoreData = false);
        return;
      }

      // Calculate how many providers we've already loaded
      int startIndex = services.length;
      int endIndex = startIndex + _pageSize;
      if (endIndex > recommendedProviderIds.length) {
        endIndex = recommendedProviderIds.length;
        _hasMoreData = false;
      }

      // Get the next batch of recommended provider IDs
      List<String> nextBatchIds =
          recommendedProviderIds.sublist(startIndex, endIndex);

      // Fetch the actual provider data for these IDs
      List<Map<String, dynamic>> newServices = [];
      for (String providerId in nextBatchIds) {
        final providerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(providerId)
            .get();

        if (providerDoc.exists) {
          final providerData = providerDoc.data()!;
          newServices.add({
            ...providerData,
            'docId': providerId,
          });
        }
      }

      if (mounted) {
        setState(() {
          services.addAll(newServices);
        });
      }
    } catch (e) {
      debugPrint('Error fetching recommended services: $e');
    } finally {
      if (mounted) {
        setState(() => _isFetching = false);
      }
    }
  }

  @override
  void dispose() {
    _adTimer.cancel();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void didChangeDependency() {
    super.didChangeDependencies();
    // Refresh data when returning to this screen
    if (!_isLoading && services.isEmpty) {
      _initializeData();
    }
  }

  Future<void> _onRefresh() async {
    debugPrint('🔄 Refresh triggered. Count: $_refreshCount');
    try {
      if (_refreshCount >= _maxRefreshCount) {
        debugPrint('📥 Max refresh count reached, reloading cache...');
        _refreshCount = 0;
        await DataManager().reloadCache();
        await _initializeData();
      } else {
        debugPrint('🔀 Shuffling existing services for variety');
        setState(() {
          services.shuffle();
          _refreshCount++;
        });
      }

      _refreshController.refreshCompleted();
      debugPrint('✅ Refresh completed successfully');
    } catch (e) {
      debugPrint('❌ Error during refresh: $e');
      _refreshController.refreshFailed();
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
        debugPrint('Fetched current user data.');
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  List<String> recommendedProviderIds = [];

  Future<void> _fetchUsersFromSameCity() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint('No user logged in');
        return;
      }

      // Get the current user's ID
      String currentUserId = user.uid;

      // Fetch the current user's city
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (userDoc.exists) {
        // Retrieve the current user's city
        final userCity = userDoc.data()?['city'];

        // Fetch all users in the same city but exclude the current user
        final usersInSameCity = await FirebaseFirestore.instance
            .collection('users')
            .where('city', isEqualTo: userCity) // Filter users by the same city
            .get();

        if (usersInSameCity.docs.isNotEmpty) {
          // Initialize a list to store the user data in a structured format
          List<Map<String, dynamic>> usersDataList = [];

          // Loop through the users and fetch the necessary data, excluding the current user
          for (var doc in usersInSameCity.docs) {
            if (doc.id == currentUserId) continue; // Skip the current user

            final userData = doc.data();

            // Basic user details
            final userId = doc.id;
            final firstName = userData['firstName'];
            final lastName = userData['lastName'];
            final email = userData['email'];
            final photoURL = userData['photoURL'];
            final city = userData['city'];

            // Interaction-related details
            final clickCount = userData['click_count'] ?? 0;
            final clickCountPerService =
                userData['click_count_per_service'] ?? {};
            final reviewedServiceIds = userData['reviewed_service_ids'] ?? [];
            final isProvider = userData['isProvider'] ?? false;

            // Gender and age
            final gender = userData['gender'] ?? 'Not specified';
            final age = userData['age'] ?? 0;

            // Location (latitude, longitude)
            final locationX = userData['location_x'] ?? 0.0;
            final locationY = userData['location_y'] ?? 0.0;

            // Favorites list
            final favorites = userData['favorites'] ?? [];

            // Provider-specific data (if isProvider)
            final selectedWorkChoice =
                isProvider ? userData['selectedWorkChoice'] ?? [] : [];
            final reviewCount = isProvider ? userData['review_count'] ?? 0 : 0;
            final rating = isProvider ? userData['rating'] ?? 0.0 : 0.0;

            // Organize the data into a map format
            Map<String, dynamic> userMap = {
              'user_id': userId,
              'first_name': firstName,
              'last_name': lastName,
              'email': email,
              'photo_url': photoURL,
              'city': city,
              'click_count': clickCount,
              'click_count_per_service': clickCountPerService,
              'reviewed_service_ids': reviewedServiceIds,
              'is_provider': isProvider,
              'gender': gender,
              'age': age,
              'location_x': locationX,
              'location_y': locationY,
              'favorites': favorites,
              'selected_work_choice': selectedWorkChoice,
              'review_count': reviewCount,
              'rating': rating,
            };

            // Add the user map to the list
            usersDataList.add(userMap);
          }

          debugPrint('Fetched data for users from the same city.');
        }
      }
    } catch (e) {
      debugPrint('Error fetching users from the same city: $e');
    }
  }

  Future<void> _loadRecommendations() async {
    try {
      final recommendationService = RecommendationService();
      final categories = await _getUserInteractionCategories();
      final recommendations = await recommendationService.getRecommendedServices(
        categories: categories,
      );

      recommendedProviderIds =
          recommendations.map((rec) => rec['service_id'] as String).toList();

      // Shuffle the recommendations to ensure they are different each time
      recommendedProviderIds.shuffle();

      // Fetch the actual provider data for these IDs
      List<Map<String, dynamic>> newServices = [];
      for (String providerId in recommendedProviderIds) {
        final providerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(providerId)
            .get();

        if (providerDoc.exists) {
          final providerData = providerDoc.data()!;
          newServices.add({
            ...providerData,
            'docId': providerId,
          });
        }
      }

      if (mounted) {
        setState(() {
          services = newServices;
        });
        debugPrint('Loaded new recommendations.');
      }
    } catch (e) {
      debugPrint('Error loading recommendations: $e');
    }
  }

  Future<List<String>> _getUserInteractionCategories() async {
    final userInteractions = await FirebaseFirestore.instance
        .collection('user_interactions')
        .doc(currentUserId)
        .get();

    final interactionData = userInteractions.data() ?? {};
    final clickedServiceIds = interactionData['clicks']?.keys.toList() ?? [];
    final reviewedServiceIds = interactionData['reviews']?.keys.toList() ?? [];
    final favoriteServiceIds = favoriteServices.toList();

    final allServiceIds = [
      ...clickedServiceIds,
      ...reviewedServiceIds,
      ...favoriteServiceIds,
    ].toSet().toList();

    final categories = <String>{};

    for (final serviceId in allServiceIds) {
      final serviceDoc = await FirebaseFirestore.instance
          .collection('services')
          .doc(serviceId)
          .get();

      if (serviceDoc.exists) {
        final serviceData = serviceDoc.data();
        if (serviceData != null && serviceData['category'] != null) {
          categories.add(serviceData['category']);
        }
      }
    }

    return categories.toList();
  }

  Future<void> toggleFavorite(Map<String, dynamic> service) async {
    if (currentUserId == null) {
      // Show a dialog or snackbar to prompt login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add favorites')),
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
        const SnackBar(content: Text('Failed to update favorites')),
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
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      adImages[index],
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
                  margin: const EdgeInsets.symmetric(horizontal: 4),
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
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 10), // Add padding to the entire Row
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            localizations.topServices,
            style: GoogleFonts.poppins(
              color: AppColors.mainColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: services.length + (_hasMoreData ? 1 : 0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, index) {
        if (index >= services.length) {
          return _isFetching
              ? const Center(child: CircularProgressIndicator())
              : const SizedBox();
        }

        final service = services[index];
        final serviceId = service['docId'] ?? service['uid'];
        final isFavorite = favoriteServices.contains(serviceId);

        return _buildServiceCard(service, isFavorite, serviceId);
      },
    );
  }

  Widget _buildRecommendationBadge(double score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.mainColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.recommend,
            size: 16,
            color: AppColors.mainColor,
          ),
          const SizedBox(width: 4),
          Text(
            '${(score * 100).toInt()}% Match',
            style: const TextStyle(
              color: AppColors.mainColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

Widget _buildServiceCard(
  Map<String, dynamic> service, bool isFavorite, String serviceId) {
  return GestureDetector(
    onTap: () async {
      debugPrint('Navigating to FullProfilePage with providerId: $serviceId');

      try {
        final providerDoc =
            FirebaseFirestore.instance.collection('users').doc(serviceId);
        await providerDoc.update({
          'click_count': FieldValue.increment(1),
        });

        if (currentUserId != null) {
          final userDoc = FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId);
          await userDoc.update({
            'click_count_per_service.$serviceId': FieldValue.increment(1),
          });
        }
      } catch (e) {
        debugPrint('Error incrementing click_count: $e');
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ServiceProviderFullProfile(
            providerId: serviceId,
          ),
        ),
      );
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0), // Adjust spacing here
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded( // Use Expanded to take the remaining space
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      image: DecorationImage(
                        image: NetworkImage(service['photoURL'] ?? ''),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.tempColor,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service['basicInfo']?['profession']?.toString() ?? 'N/A',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          service['name']?.toString() ?? 'Unknown',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.mainColor,
                          ),
                          maxLines: 1,
                        ),
                        _buildStarRating((service['rating'] as num?)?.toDouble() ?? 0.0),
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
        !_isFetching &&
        _hasMoreData) {
      _fetchMoreServices();
    }
  }

  Future<void> _fetchServices() async {
    if (_isFetching) return;

    setState(() {
      _isFetching = true;
    });

    try {
      final dataManager = DataManager();
      final cachedProviders = dataManager.getCachedProviders();
      
      int startIndex = services.length;
      int endIndex = startIndex + _pageSize;
      
      if (endIndex >= cachedProviders.length) {
        endIndex = cachedProviders.length;
        _hasMoreData = false;
      }
      
      if (startIndex < endIndex) {
        final newServices = cachedProviders.sublist(startIndex, endIndex);
        setState(() {
          services.addAll(newServices);
        });
      }
    } catch (e) {
      debugPrint('Error fetching services: $e');
    } finally {
      setState(() {
        _isFetching = false;
      });
    }
  }

  // Top Services Header Widget
  Widget _buildTopPopularHeader(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20), // Add padding here
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            localizations.popularServices,
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

// Update the _servicesSection to use the cached future
  Widget _servicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 180,
          child: FutureBuilder<List<PopularServicesModel>>(
            future: _popularServicesFuture, // Use the cached future
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No services available'));
              }

              final services = snapshot.data!;
              return ListView.separated(
                itemBuilder: (context, index) {
                  final service = services[index];
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 170,
                    decoration: BoxDecoration(
                      color: service.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: service.color.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {
                          final workDomainId =
                              _getWorkDomainIdForService(service.name);
                          final navbarPage = context
                              .findAncestorWidgetOfExactType<NavbarPage>();

                          if (navbarPage != null) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NavbarPage(
                                  initialIndex: 1,
                                  preSelectedWorkDomain: workDomainId,
                                ),
                              ),
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: SvgPicture.asset(
                                  service.iconPath,
                                  width: 40,
                                  height: 40,
                                  color: service.color,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                service.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.mainColor,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 16,
                                      color: service.color,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${service.availableProviders}',
                                      style: TextStyle(
                                        color: service.color,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemCount: services.length,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              );
            },
          ),
        ),
      ],
    );
  }

void _showAllServices(BuildContext context) {
  final localizations = AppLocalizations.of(context);
  if (localizations == null) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localizations.allServices,
                        style: GoogleFonts.poppins(
                          color: AppColors.mainColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.withOpacity(0.1),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<List<PopularServicesModel>>(
                    future: _popularServicesFuture, // Use the cached future
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('No services available'),
                        );
                      }

                      final services = snapshot.data!;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GridView.builder(
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: services.length,
                          itemBuilder: (context, index) {
                            final service = services[index];
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                  // Add your navigation or selection logic here
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: service.color.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: service.color.withOpacity(0.12),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color:
                                              service.color.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: SvgPicture.asset(
                                          service.iconPath,
                                          width: 32,
                                          height: 32,
                                          color: service.color,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        service.name,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          color: Colors.black87,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          padding: const EdgeInsets.only(bottom: 18),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

  // Method to refresh the services data when needed
  void refreshServices() {
    setState(() {
      _popularServicesFuture = PopularServicesModel.getPopularServices(context);
    });
  }

  // Updated helper function to map service names to work domain IDs based on your Firestore data
  String _getWorkDomainIdForService(String serviceName) {
    final local = AppLocalizations.of(context);
    if (local == null) return '';

    // Define service mappings in a more structured way
    final serviceCategories = [
      ServiceCategory('houseCleaning', local.houseCleaning),
      ServiceCategory('electricity', local.electricity),
      ServiceCategory('plumbing', local.plumbing),
      ServiceCategory('gardening', local.gardening),
      ServiceCategory('painting', local.painting),
      ServiceCategory('carpentry', local.carpentry),
      ServiceCategory('pestControl', local.pestControl),
      ServiceCategory('acRepair', local.acRepair),
      ServiceCategory('vehicleRepair', local.vehicleRepair),
      ServiceCategory('applianceInstallation', local.applianceInstallation),
      ServiceCategory('itSupport', local.itSupport),
      ServiceCategory('homeSecurity', local.homeSecurity),
      ServiceCategory('interiorDesign', local.interiorDesign),
      ServiceCategory('windowCleaning', local.windowCleaning),
      ServiceCategory('furnitureAssembly', local.furnitureAssembly),
    ];

    // Create map from the categories
    final serviceToWorkDomain = Map.fromEntries(
      serviceCategories
          .map((category) => MapEntry(category.localizedName, category.id)),
    );

    // Add error logging for debugging
    final workDomainId = serviceToWorkDomain[serviceName];
    if (workDomainId == null) {
      debugPrint('Warning: No work domain ID found for service: $serviceName');
      debugPrint('Available services: ${serviceToWorkDomain.keys.join(', ')}');
    }

    return workDomainId ?? '';
  }

  @override
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: SmartRefresher(
      controller: _refreshController,
      onRefresh: _onRefresh,
      header: const ClassicHeader(
        refreshStyle: RefreshStyle.Behind,
        completeText: 'Refresh complete',
        failedText: 'Refresh failed',
        idleText: 'Pull to refresh',
        refreshingText: 'Refreshing...',
      ),
      child: _isInitializing || _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading recommendations...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : services.isEmpty
              ? const Center(
                  child: Text(
                    'No recommended services found in your area',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                )
              : CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 12),
                          _buildAdsSlider([
                            'assets/images/ads/first_page.png',
                            'assets/images/ads/second_page.png',
                            'assets/images/ads/third_page.png',
                          ]),
                          const SizedBox(height: 10), // Adjusted spacing
                          _buildTopPopularHeader(context),
                          const SizedBox(height: 10), // Adjusted spacing
                          SizedBox(
                            height: 180,
                            child: _servicesSection(),
                          ),
                          const SizedBox(height: 10), // Adjusted spacing
                          _buildTopServicesHeader(),
                          const SizedBox(height: 10), // Adjusted spacing
                        ],
                      ),
                    ),
                    SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 8.0, // Reduced vertical spacing between cards
                        crossAxisSpacing: 8.0, // Reduced horizontal spacing between cards
                        childAspectRatio: 0.9,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= services.length) {
                            return _isFetching
                                ? const Center(child: CircularProgressIndicator())
                                : const SizedBox();
                          }

                          final service = services[index];
                          final serviceId = service['docId'] ?? service['uid'];
                          final isFavorite = favoriteServices.contains(serviceId);

                          return _buildServiceCard(service, isFavorite, serviceId);
                        },
                        childCount: services.length + (_hasMoreData ? 1 : 0),
                      ),
                    ),
                  ],
                ),
    ),
    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
  );
}


}

class RecommendationConfig {
  final int maxSimilarUsers;
  final int batchSize;
  final Duration cacheDuration;
  final Map<String, double> weightFactors;
  final Map<String, double> recentActivityWeights;

  const RecommendationConfig({
    this.maxSimilarUsers = 10,
    this.batchSize = 20,
    this.cacheDuration = const Duration(minutes: 30),
    this.weightFactors = const {
      'similarity': 0.2,  // Reduced weight for general similarity
      'rating': 0.2,
      'reviewCount': 0.1,
      'clickCount': 0.1,
      'completionRate': 0.1,
      'recentActivity': 0.3,  // New weight for recent activity
    },
    this.recentActivityWeights = const {
      'clicks': 0.4,
      'favorites': 0.4,
      'reviews': 0.2,
    },
  });
}

class _UserSessionActivity {
  final Map<String, int> clicks = {};
  final Set<String> favorites = {};
  final Map<String, double> reviews = {};
  final Set<String> categories = {};
  final DateTime sessionStart = DateTime.now();

  void addClick(String serviceId, String category) {
    clicks[serviceId] = (clicks[serviceId] ?? 0) + 1;
    categories.add(category);
  }

  void addFavorite(String serviceId, String category) {
    favorites.add(serviceId);
    categories.add(category);
  }

  void addReview(String serviceId, double rating, String category) {
    reviews[serviceId] = rating;
    categories.add(category);
  }
}

class RecommendationService {
  static final RecommendationService _instance =
      RecommendationService._internal();
  factory RecommendationService() => _instance;
  RecommendationService._internal();

  final _config = const RecommendationConfig();
  final _cache = _RecommendationCache();
  final _firestore = FirebaseFirestore.instance;



  final Map<String, _UserSessionActivity> _sessionActivity = {};

  

  // Add this new method
  Future<void> trackServiceClick(String serviceId, String category) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _sessionActivity.putIfAbsent(currentUser.uid, () => _UserSessionActivity())
      .addClick(serviceId, category);

    _cache.remove(currentUser.uid);

    await _firestore.collection('user_interactions').doc(currentUser.uid)
      .set({
        'clicks': {
          serviceId: FieldValue.increment(1),
        },
        'last_clicked': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
  }



 Future<List<Map<String, dynamic>>> getRecommendedServices({
    int limit = 20,
    List<String>? categories,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return [];

      final userData = await _getUserData(currentUser.uid);
      if (userData == null) return [];

      // Add this block
      final sessionData = _sessionActivity[currentUser.uid];
      if (sessionData != null) {
        userData['current_session'] = {
          'clicks': sessionData.clicks,
          'favorites': sessionData.favorites.toList(),
          'reviews': sessionData.reviews,
          'categories': sessionData.categories.toList(),
          'session_start': sessionData.sessionStart.toIso8601String(),
        };
      }

      final similarUsers = await _getSimilarUsers(userData);

      final recommendations = await _generateRecommendations(
        userData: userData,
        similarUsers: similarUsers,
        categories: categories ?? userData['current_session']?['categories'],  // Modified
        limit: limit,
      );

      return recommendations;
    } catch (e) {
      debugPrint('Error in getRecommendedServices: $e');
      return [];
    }
  }








static double _calculateBaseScores(
  Map<String, dynamic> provider,
  List<dynamic> similarUsers,
  Map<String, double> weightFactors,
) {
  double score = 0.0;
  final providerId = provider['id'];

  final similarityScore = _calculateSimilarityScore(providerId, similarUsers);
  score += similarityScore * weightFactors['similarity']!;

  final rating = provider['rating'] ?? 0.0;
  score += (rating / 5.0) * weightFactors['rating']!;

  final reviewCount = (provider['review_count'] ?? 0) as num;
  score += (min(reviewCount, 100) / 100) * weightFactors['reviewCount']!;

  final clickCount = (provider['click_count'] ?? 0) as num;
  score += (min(clickCount, 1000) / 1000) * weightFactors['clickCount']!;

  final completedJobs = provider['completed_jobs'] ?? 0;
  final totalJobs = provider['total_jobs'] ?? 0;
  if (totalJobs > 0) {
    score += (completedJobs / totalJobs) * weightFactors['completionRate']!;
  }

  return score;
}

static double _calculateRecentActivityScore(
  String providerId,
  Map<String, dynamic> provider,
  Map<String, dynamic> currentSession,
) {
  double score = 0.0;
  final config = const RecommendationConfig();

  final clickedCategories = Set<String>.from(currentSession['categories'] ?? []);
  final providerCategories = Set<String>.from(provider['categories'] ?? []);
  final categoryOverlap = clickedCategories.intersection(providerCategories).length;
  if (categoryOverlap > 0) {
    score += (categoryOverlap / clickedCategories.length) * config.recentActivityWeights['clicks']!;
  }

  final recentFavorites = Set<String>.from(currentSession['favorites'] ?? []);
  if (recentFavorites.contains(providerId)) {
    score += config.recentActivityWeights['favorites']!;
  }

  final recentReviews = Map<String, double>.from(currentSession['reviews'] ?? {});
  if (recentReviews.containsKey(providerId)) {
    score += (recentReviews[providerId]! / 5.0) * config.recentActivityWeights['reviews']!;
  }

  return score;
}










  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data()!;
      final userInteractions = await _getUserInteractions(userId);

      return {
        ...userData,
        'interactions': userInteractions,
      };
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _getUserInteractions(String userId) async {
    final interactions =
        await _firestore.collection('user_interactions').doc(userId).get();

    return interactions.data() ?? {};
  }

  Future<List<Map<String, dynamic>>> _getSimilarUsers(
    Map<String, dynamic> userData,
  ) async {
    try {
      // Get users from same city with batch processing
      final cityUsers = await _firestore
          .collection('users')
          .where('city', isEqualTo: userData['city'])
          .where('isProvider', isEqualTo: false)
          .where(FieldPath.documentId, isNotEqualTo: userData['uid'])
          .limit(50)
          .get();

      final similarUsers = await compute(
        _calculateSimilarUsers,
        {
          'currentUser': userData,
          'potentialUsers': cityUsers.docs.map((doc) => doc.data()).toList(),
        },
      );

      return similarUsers.take(_config.maxSimilarUsers).toList();
    } catch (e) {
      debugPrint('Error getting similar users: $e');
      return [];
    }
  }

  static List<Map<String, dynamic>> _calculateSimilarUsers(
      Map<String, dynamic> data) {
    final currentUser = data['currentUser'];
    final potentialUsers = data['potentialUsers'] as List;
    final similarities = <Map<String, dynamic>>[];

    for (var user in potentialUsers) {
      final similarity = _calculateUserSimilarity(currentUser, user);
      if (similarity > 0) {
        similarities.add({
          ...user,
          'similarity_score': similarity,
        });
      }
    }

    similarities.sort((a, b) => (b['similarity_score'] as double)
        .compareTo(a['similarity_score'] as double));

    return similarities;
  }

  static double _calculateUserSimilarity(
    Map<String, dynamic> user1,
    Map<String, dynamic> user2,
  ) {
    double score = 0.0;

    // Calculate favorite services similarity
    final favorites1 = Set<String>.from(user1['favorites'] ?? []);
    final favorites2 = Set<String>.from(user2['favorites'] ?? []);
    if (favorites1.isNotEmpty && favorites2.isNotEmpty) {
      final intersection = favorites1.intersection(favorites2);
      final union = favorites1.union(favorites2);
      score += intersection.length / union.length * 0.4;
    }

    // Calculate service category preference similarity
    final categories1 = Set<String>.from(user1['preferred_categories'] ?? []);
    final categories2 = Set<String>.from(user2['preferred_categories'] ?? []);
    if (categories1.isNotEmpty && categories2.isNotEmpty) {
      final intersection = categories1.intersection(categories2);
      final union = categories1.union(categories2);
      score += intersection.length / union.length * 0.3;
    }

    // Calculate interaction pattern similarity
    final interactions1 = user1['interactions'] ?? {};
    final interactions2 = user2['interactions'] ?? {};
    if (interactions1.isNotEmpty && interactions2.isNotEmpty) {
      score +=
          _calculateInteractionSimilarity(interactions1, interactions2) * 0.3;
    }

    return score;
  }

  static double _calculateInteractionSimilarity(
    Map<String, dynamic> interactions1,
    Map<String, dynamic> interactions2,
  ) {
    final services1 = Set<String>.from(interactions1.keys);
    final services2 = Set<String>.from(interactions2.keys);
    final commonServices = services1.intersection(services2);

    if (commonServices.isEmpty) return 0.0;

    double totalDiff = 0.0;
    for (final service in commonServices) {
      final count1 = interactions1[service] ?? 0;
      final count2 = interactions2[service] ?? 0;
      totalDiff += (count1 - count2).abs() / (count1 + count2);
    }

    return 1 - (totalDiff / commonServices.length);
  }

  Future<List<Map<String, dynamic>>> _generateRecommendations({
    required Map<String, dynamic> userData,
    required List<Map<String, dynamic>> similarUsers,
    List<String>? categories,
    required int limit,
}) async {
    try {
      // Get potential service providers
      final providerQuery = _firestore
          .collection('users')
          .where('isProvider', isEqualTo: true)
          .where('city', isEqualTo: userData['city']);

      final providers = await providerQuery.get();
      final userFavorites = Set<String>.from(userData['favorites'] ?? []);

      // Updated compute call to match new method structure
      final recommendations = await compute(
        _calculateProviderScoresForBatch,  // New method name
        {
          'providers': providers.docs
              .map((doc) => {
                    ...doc.data(),
                    'id': doc.id,
                  })
              .toList(),
          'similarUsers': similarUsers,
          'userFavorites': userFavorites.toList(),
          'weightFactors': _config.weightFactors,
          'currentSession': userData['current_session'],  // Add current session data
        },
      );

      // Filter by categories if specified
      if (categories != null && categories.isNotEmpty) {
        recommendations.removeWhere((rec) {
          final providerCategories = List<String>.from(
            rec['service_data']['categories'] ?? [],
          );
          return !providerCategories.any(categories.contains);
        });
      }

      return recommendations.take(limit).toList();
    } catch (e) {
      debugPrint('Error generating recommendations: $e');
      return [];
    }
}

// Add this new static method for compute
static List<Map<String, dynamic>> _calculateProviderScoresForBatch(
    Map<String, dynamic> data) {
  final providers = data['providers'] as List;
  final similarUsers = data['similarUsers'] as List;
  final weightFactors = data['weightFactors'] as Map<String, double>;
  final currentSession = data['currentSession'];
  
  final recommendations = <Map<String, dynamic>>[];

  for (var provider in providers) {
    final score = _calculateProviderScore(
      provider,
      similarUsers,
      weightFactors,
    );

    if (score > 0) {
      recommendations.add({
        'service_id': provider['id'],
        'service_data': provider,
        'recommendation_score': score,
      });
    }
  }

  recommendations.sort((a, b) => (b['recommendation_score'] as double)
      .compareTo(a['recommendation_score'] as double));

  return recommendations;
}

static double _calculateProviderScore(
    Map<String, dynamic> provider,
    List<dynamic> similarUsers,
    Map<String, double> weightFactors,
  ) {
    double score = 0.0;
    final providerId = provider['id'];

    // Base scores
    score += _calculateBaseScores(provider, similarUsers, weightFactors);

    // Recent activity score
    final currentSession = provider['current_session'];
    if (currentSession != null) {
      final recentActivityScore = _calculateRecentActivityScore(
        providerId,
        provider,
        currentSession,
      );
      score += recentActivityScore * weightFactors['recentActivity']!;
    }

    return score;
  }
  

  
  static double _calculateSimilarityScore(
      String providerId, List<dynamic> similarUsers) {
    double totalScore = 0.0;
    int count = 0;

    for (var user in similarUsers) {
      final favorites = List<String>.from(user['favorites'] ?? []);
      if (favorites.contains(providerId)) {
        final userScore = user['similarity_score'] as double;
        totalScore += userScore;
        count++;
      }
    }

    return count > 0 ? totalScore / count : 0.0;
  }
}

class _RecommendationCache {
  final Map<String, _CacheEntry> _cache = {};

  Future<List<Map<String, dynamic>>?> get(String userId) async {
    final entry = _cache[userId];
    if (entry == null || entry.isExpired) {
      _cache.remove(userId); // Invalidate expired cache
      return null;
    }
    return entry.data;
  }

  Future<void> set(String userId, List<Map<String, dynamic>> data, {Duration? duration}) async {
    _cache[userId] = _CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      duration: duration ?? const Duration(minutes: 5), // Shorter cache duration
    );
  }

  void remove(String userId) {
    _cache.remove(userId);
  }
}

class _CacheEntry {
  final List<Map<String, dynamic>> data;
  final DateTime timestamp;
  final Duration validity = const Duration(minutes: 30);

  _CacheEntry({
    required this.data,
    required this.timestamp, required Duration duration,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > validity;
}
