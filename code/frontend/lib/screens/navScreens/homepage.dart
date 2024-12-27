import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/navbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hanini_frontend/screens/services/service.dart';
import 'package:hanini_frontend/models/colors.dart';
import 'package:hanini_frontend/models/servicesWeHave.dart';
import 'package:hanini_frontend/localization/app_localization.dart';


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

  int _currentPage = 0;
  late Timer _adTimer;

  List<Map<String, dynamic>> services = [];

  Set<String> favoriteServices = {};
  String? currentUserId;
  bool _isLoading = true;
  bool _isFetching = false;
  DocumentSnapshot? _lastDocument; // Tracks the last document for pagination
  final int _pageSize =7; // Number of items to fetch per 
  
   bool _hasMoreData = true;



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
    if (_isFetching || !_hasMoreData) return;
    setState(() => _isFetching = true);

    try {
      Query query = FirebaseFirestore.instance
          .collection('users')
          .where('isProvider', isEqualTo: true)
          .orderBy('rating', descending: true)  // Sort by rating descending
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        final newServices = snapshot.docs
            .map((doc) {
              final service = doc.data() as Map<String, dynamic>;
              final serviceId = doc.id;
              return serviceId != currentUserId
                  ? {...service, 'docId': serviceId}
                  : null;
            })
            .whereType<Map<String, dynamic>>()
            .toList();

        if (newServices.isEmpty) {
          _hasMoreData = false;
        } else {
          setState(() {
            services.addAll(newServices);
          });
        }
      } else {
        setState(() => _hasMoreData = false);
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
                      adImages[index],                    ),
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

  Widget _buildServiceCard(Map<String, dynamic> service, bool isFavorite, String serviceId) {
    return  GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceProviderFullProfile(
                    providerId: serviceId,
                  ),
                ),
              );
            },
            child:Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  image: DecorationImage(
                    image: NetworkImage(service['photoURL'] ?? ''),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.tempColor,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
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
                      _buildStarRating(service['rating']?.toDouble() ?? 0.0),
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
      _fetchServices();
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
                // Drag handle
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: PopularServicesModel.getPopularServices(context).length,
                      itemBuilder: (context, index) {
                        final service = PopularServicesModel.getPopularServices(context)[index];
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              // Handle service selection
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
                                      color: service.color.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: SvgPicture.asset(
  service.iconPath,
  width: 32,
  height: 32,
  color: service.color, // Set the color directly
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
                    ),
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

Column _servicesSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      Container(
        height: 180, // Increased height for better visibility
        child: ListView.separated(
          itemBuilder: (context, index) {
            final service = PopularServicesModel.getPopularServices(context)[index];
            return AnimatedContainer(
              duration: Duration(milliseconds: 200),
              width: 170, // Slightly wider cards
              decoration: BoxDecoration(
                color: service.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: service.color.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    final workDomainId = _getWorkDomainIdForService(service.name);
                    final navbarPage = context.findAncestorWidgetOfExactType<NavbarPage>();
                    
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
                          padding: EdgeInsets.all(12),
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
                        SizedBox(height: 12),
                        Text(
                          service.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.mainColor,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                              SizedBox(width: 4),
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
          itemCount: PopularServicesModel.getPopularServices(context).length,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    ],
  );
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
    serviceCategories.map((category) => MapEntry(category.localizedName, category.id)),
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                      const SizedBox(height: 20),
                      _buildTopPopularHeader(context),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 180,
                        child: _servicesSection(),
                      ),
                      const SizedBox(height: 20),
                      _buildTopServicesHeader(),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
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
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
    );
  }

  
}
