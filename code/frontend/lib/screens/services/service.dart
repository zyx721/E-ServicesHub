import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:hanini_frontend/localization/app_localization.dart';
import 'dart:ui';

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Hero(
                  tag: imageUrl,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 16,
              left: 16,
              child: Row(
                children: [
                  Icon(Icons.image, color: Colors.white, size: 28),
                  SizedBox(width: 8),
                  Text(
                    "Image Viewer",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                iconSize: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Add this class to handle the persistent header
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class PushNotificationService {
  static Future<String> getAccessToken() async {
    // Load the service account JSON
    final serviceAccountJson =
        await rootBundle.loadString('assets/credentials/test.json');

    // Define the required scopes
    List<String> scopes = [
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging"
    ];

    // Create a client using the service account credentials
    final auth.ServiceAccountCredentials credentials =
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson);

    final auth.AuthClient client =
        await auth.clientViaServiceAccount(credentials, scopes);

    // Retrieve the access token
    final String accessToken = client.credentials.accessToken.data;

    // Close the client to avoid resource leaks
    client.close();

    return accessToken;
  }

  static Future<void> sendNotification(String deviceToken, String title,
      String body, Map<String, dynamic> data) async {
    final String serverKey = await getAccessToken();
    String endpointFirebaseCloudMessaging =
        'https://fcm.googleapis.com/v1/projects/hanini-2024/messages:send';

    final Map<String, dynamic> message = {
      'message': {
        'token': deviceToken,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': data,
      }
    };

    final http.Response response = await http.post(
      Uri.parse(endpointFirebaseCloudMessaging),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serverKey',
      },
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print('Notification sent successfully');
    } else {
      print('Failed to send notification');
      print('Response: ${response.body}');
    }
  }
}

class ServiceProviderFullProfile extends StatefulWidget {
  final String providerId;

  const ServiceProviderFullProfile({Key? key, required this.providerId})
      : super(key: key);

  @override
  _ServiceProviderFullProfileState createState() =>
      _ServiceProviderFullProfileState();
}

class _ServiceProviderFullProfileState
    extends State<ServiceProviderFullProfile> {
  final double profileHeight = 100;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  List<String> portfolioImages = [];
  List<dynamic> skills = [];
  List<dynamic> certifications = [];
  List<dynamic> workExperience = [];
  List<dynamic> selectedWorkChoices = [];
  String profession = '';
  String userName = '';
  String userEmail = '';
  String userPhotoUrl = '';
  String aboutMe = '';
  int hourlyRate = 0;
  String phoneNubmber = '';
  bool isVerified = true;
  bool isLoading = true;
  double rating = 0.0;
  String wilaya = '';
  String commune = '';
  String wilayaArabic = "";
  String wilayaLatin = "";
  String communeArabic = "";
  String communeLatin = "";

  // Fetch provider data from Firestore using providerId
  Future<void> fetchProviderData() async {
    try {
      final DocumentSnapshot providerDoc =
          await _firestore.collection('users').doc(widget.providerId).get();

      if (providerDoc.exists) {
        final data = providerDoc.data() as Map<String, dynamic>;
        setState(() {
          userName = data['name'] ?? 'Anonymous';
          userEmail = data['email'] ?? 'No email';
          userPhotoUrl = data['photoURL'] ?? '';
          aboutMe = data['aboutMe'] ?? 'Tell us about yourself';
          hourlyRate = data['basicInfo']['hourlyRate'] ?? '';
          profession = data['basicInfo']['profession'] ?? '';
          phoneNubmber = data['basicInfo']['phone'] ?? '';
          skills = data['skills'];
          certifications = data['certifications'];
          workExperience = data['workExperience'];
          // Fetch both Arabic and Latin versions of wilaya and commune
          wilayaArabic = data['basicInfo']['wilaya_arabic'] ?? '';
          wilayaLatin = data['basicInfo']['wilaya'] ?? '';
          communeArabic = data['basicInfo']['commune_arabic'] ?? '';
          communeLatin = data['basicInfo']['commune'] ?? '';
          portfolioImages = List<String>.from(data['portfolioImages'] ?? []);
          selectedWorkChoices = data['selectedWorkChoices'] ?? [];
          rating = (data['rating'] ?? 0.0).toDouble();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching provider data: $e');
    }
  }

  final TextEditingController hourlyRateController = TextEditingController();
  final TextEditingController aboutMeController = TextEditingController();

// Update initState to properly set the hourlyRateController
  @override
  void initState() {
    super.initState();
    hourlyRateController.text = hourlyRate.toString();
    fetchProviderData();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.purple[25],
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        SizedBox(height: 40,),
                        buildTop(localizations),
                        buildProfileInfo(localizations),
                      ],
                    ),
                  ),
                  SliverPersistentHeader(
                    delegate: _SliverAppBarDelegate(TabBar(
                      labelColor: Colors.purple,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.purple,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ), // Style for the selected tab
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 14,
                      ), // Style for unselected tabs
                      tabs: [
                        Tab(text: localizations.profile),
                        Tab(text: localizations.reviews),
                      ],
                    )),
                    pinned: true,
                  ),
                ],
                body: TabBarView(
                  children: [
                    SingleChildScrollView(
                      child: buildProfileTab(),
                    ),
                    buildReviewsTab(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget buildReviewsTab() {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(widget.providerId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error fetching reviews. Please try again later.',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Text(
              localizations.noReviewsAvailable,
              style: GoogleFonts.poppins(
                  fontSize: 16, fontStyle: FontStyle.italic),
            ),
          );
        }

        final providerData = snapshot.data!.data() as Map<String, dynamic>;
        final reviews = providerData['reviews'] ?? [];

        return Column(
          children: [
            Expanded(
              child: reviews.isEmpty
                  ? Center(
                      child: Text(
                        localizations.noReviewsAvailable,
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontStyle: FontStyle.italic),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: reviews.length,
                      itemBuilder: (context, index) {
                        final review = reviews[index] as Map<String, dynamic>;
                        final comment =
                            review['comment'] ?? 'No comment provided';
                        final commenterId = review['id_commentor'] ?? 'Unknown';
                        final rating = review['rating']?.toDouble() ?? 0.0;
                        final timestamp = review['timestamp'] ?? '';

                        // Parse and format the timestamp
                        final formattedTimestamp = timestamp.isNotEmpty
                            ? DateFormat('MMM d, yyyy • h:mm a').format(
                                DateTime.parse(timestamp),
                              )
                            : 'Unknown time';

                        return FutureBuilder<DocumentSnapshot>(
                          future: _firestore
                              .collection('users')
                              .doc(commenterId)
                              .get(),
                          builder: (context, commenterSnapshot) {
                            if (commenterSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            final commenterData = commenterSnapshot.data?.data()
                                    as Map<String, dynamic>? ??
                                {};
                            final commenterName =
                                commenterData['name'] ?? 'Anonymous';
                            final commenterPhoto =
                                commenterData['photoURL'] ?? '';

                            return Card(
                              margin: const EdgeInsets.all(8.0),
                              elevation: 4,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: commenterPhoto.isNotEmpty
                                          ? NetworkImage(commenterPhoto)
                                          : const AssetImage(
                                                  'assets/images/default_profile.png')
                                              as ImageProvider,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                commenterName,
                                                style: GoogleFonts.poppins(
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                              Text(
                                                formattedTimestamp,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          _buildStarRating(rating),
                                          const SizedBox(height: 8),
                                          Text(
                                            comment,
                                            style: GoogleFonts.poppins(
                                                color: Colors.grey[700]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
            GestureDetector(
              onTap: () {
                _showAddReviewDialog(context, widget.providerId, _firestore);
              },
              child: Container(
                padding: const EdgeInsets.all(
                    10), // Optional padding for touchable area
                decoration: const BoxDecoration(
                  color: Colors.purple, // Button color
                ),
                child: Center(
                  child: Text(
                    localizations.addReview,
                    style: GoogleFonts.poppins(
                      color: Colors.white, // Text color
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddReviewDialog(
      BuildContext context, String providerId, FirebaseFirestore firestore) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;

    final TextEditingController commentController = TextEditingController();
    double newRating = 3.0;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title:
                  Text(localizations.addReview, style: GoogleFonts.poppins()),
              content: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: commentController,
                        enabled: !isSubmitting,
                        decoration: InputDecoration(
                          labelText: localizations.addComment,
                          border: const OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      RatingBar.builder(
                        initialRating: newRating,
                        minRating: 0.5,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        ignoreGestures: isSubmitting,
                        itemPadding:
                            const EdgeInsets.symmetric(horizontal: 2.5),
                        itemBuilder: (context, _) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        onRatingUpdate: (rating) {
                          newRating = rating;
                        },
                      ),
                      if (isSubmitting)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Column(
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 8),
                              Text(
                                localizations.submittingReview,
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child:
                      Text(localizations.cancel, style: GoogleFonts.poppins()),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (commentController.text.trim().isEmpty) return;

                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'You must be logged in to add a review')),
                            );
                            return;
                          }

                          setState(() {
                            isSubmitting = true;
                          });

                          try {
                            final review = {
                              'comment': commentController.text.trim(),
                              'rating': newRating,
                              'id_commentor': user.uid,
                              'timestamp': DateTime.now().toIso8601String(),
                            };

                            final providerRef =
                                firestore.collection('users').doc(providerId);
                            final reviewerRef =
                                firestore.collection('users').doc(user.uid);

                            // Use a batch to update both documents atomically
                            final batch = firestore.batch();

                            // Update provider's reviews and ratings
                            batch.update(providerRef, {
                              'reviews': FieldValue.arrayUnion([review]),
                              'newCommentsCount': FieldValue.increment(1),
                              'review_count': FieldValue.increment(1),
                            });

                            // Update reviewer's reviewed_providers array
                            batch.update(reviewerRef, {
                              'reviewed_service_ids':
                                  FieldValue.arrayUnion([providerId]),
                            });

                            // Commit the batch
                            await batch.commit();

                            // Update the average rating
                            final providerDoc = await providerRef.get();
                            final providerData =
                                providerDoc.data() as Map<String, dynamic>;
                            final reviews =
                                providerData['reviews'] as List<dynamic>;

                            double totalRating = 0.0;
                            for (var rev in reviews) {
                              totalRating += (rev['rating'] as num).toDouble();
                            }
                            final newAverageRating =
                                totalRating / reviews.length;

                            await providerRef.update({
                              'rating': newAverageRating,
                            });

                            final String deviceToken =
                                providerData['deviceToken'];
                            if (deviceToken.isNotEmpty) {
                              await PushNotificationService.sendNotification(
                                deviceToken,
                                localizations.newReviewReceived,
                                localizations.youHaveNewReviewOnYourProfile,
                                {'providerId': providerId},
                              );
                            }

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      localizations.reviewAddedSuccessfully)),
                            );
                          } catch (e) {
                            setState(() {
                              isSubmitting = false;
                            });
                            debugPrint('Error adding review: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text(localizations.failedToAddReview)),
                            );
                          }
                        },
                  child: Text(localizations.submit,
                      style: GoogleFonts.poppins(color: Colors.black)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget buildProfileTab() {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const Column();
    return Column(
      children: [
        const SizedBox(height: 20),
        buildAboutMeSection(localizations),
        const SizedBox(height: 10),
        _buildSkillsSection(localizations),
        const SizedBox(height: 10),
        _buildWorkExperienceSection(localizations),
        const SizedBox(height: 10),
        buildPortfolioSection(context),
        const SizedBox(height: 20),
        _buildCertificationsSection(localizations),
        const SizedBox(height: 40),
        _buildContactButton(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget buildTop(AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.only(
          top: 20,
          bottom: 4,
          left: 16,
          right: 16), // Adds margin around the card
      child: _buildInfoCard(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  height: 90, // Reduced height for the image container
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(userPhotoUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  // ignore: unnecessary_null_comparison
                  child: userPhotoUrl == null
                      ? const Center(
                          child: Icon(Icons.broken_image,
                              size: 50, color: Colors.grey),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              userName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color:
                        Colors.blue.withOpacity(0.1), // Light blue background
                    shape: BoxShape
                        .rectangle, // Circular shape for the icon's background
                  ),
                  child: Icon(Icons.business_center,
                      size: 20, color: Colors.blue.shade700),
                ),
                const SizedBox(width: 8),
                Text(
                  profession,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color:
                        Colors.green.withOpacity(0.1), // Light green background
                    shape: BoxShape
                        .rectangle, // Circular shape for the icon's background
                  ),
                  child:
                      Icon(Icons.email, size: 20, color: Colors.green.shade700),
                ),
                const SizedBox(width: 8),
                Text(
                  userEmail,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProfileInfo(AppLocalizations localizations) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    final displayWilaya = currentLocale == 'ar' ? wilayaArabic : wilayaLatin;
    final displayCommune = currentLocale == 'ar' ? communeArabic : communeLatin;

    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.location_on,
                                color: Colors.blue.shade700),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayCommune,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  displayWilaya,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.star, color: Colors.amber.shade700),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStarRating(rating),
                            Text(
                              localizations.rating,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.monetization_on,
                            color: Colors.green.shade700),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$hourlyRate DZD',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              localizations.hourlyRate,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10, top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 8,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget buildAboutMeSection(AppLocalizations localizations) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(Icons.person, size: 24, color: Colors.blue.shade700),
                ),
                const SizedBox(width: 8),
                Text(
                  localizations.aboutMeLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              aboutMe,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsSection(AppLocalizations localizations) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with Icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.psychology,
                      size: 24, color: Colors.blue.shade700),
                ),
                const SizedBox(width: 8),
                Text(
                  localizations.skills,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Skill Chips or Placeholder
            if (skills.isNotEmpty)
              Wrap(
                spacing: 12.0,
                runSpacing: 12.0,
                children:
                    skills.map((skill) => _buildSkillChip(skill)).toList(),
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lightbulb_outline,
                          size: 48,
                          color: Colors.orange.shade400,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localizations.noSkillsAvailable,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillChip(String skill) {
    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade300, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade100,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                skill,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkExperienceSection(AppLocalizations localizations) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.work,
                            size: 24, color: Colors.purple),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        localizations.workExperience,
                        style: GoogleFonts.poppins(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  if (workExperience.isNotEmpty)
                    SizedBox(
                      height: 150,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: workExperience.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final exp = workExperience[index];
                          return Container(
                            width: 250,
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.grey.withOpacity(0.1)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          exp['company'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    exp['position'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    exp['duration'],
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          localizations.noWorkExperienceAvailable,
                          style: GoogleFonts.poppins(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPortfolioSection(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_album,
                      size: 24, color: Colors.blue[600]),
                ),
                const SizedBox(width: 8),
                Text(
                  localizations.portfolio,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            portfolioImages.isNotEmpty
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: portfolioImages.map((imageUrl) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              Hero(
                                tag: imageUrl,
                                child: Material(
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FullScreenImage(
                                            imageUrl: imageUrl,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          imageUrl,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Container(
                                              width: 120,
                                              height: 120,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  value: loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                      : null,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            localizations.noPortfolioImagesAvailable,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificationsSection(AppLocalizations localizations) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Section with Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.workspace_premium,
                      color: Colors.green.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    localizations.certifications,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add Certification Input
                  if (certifications.isNotEmpty)
                    ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: certifications.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final cert = certifications[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.shade200,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.verified,
                                  color: Colors.green.shade600,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  cert,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.card_membership,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              localizations.noCertificationsAvailable,
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStat(String title, dynamic value) {
    return Column(
      children: [
        if (value is String)
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        if (value is Widget) value,
        Text(
          title,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildStarRating(double rating) {
    int fullStars = rating.floor();
    int halfStars = (rating - fullStars) >= 0.5 ? 1 : 0;

    return Row(
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return const Icon(Icons.star, color: Colors.yellow, size: 16);
        } else if (index < fullStars + halfStars) {
          return const Icon(Icons.star_half, color: Colors.yellow, size: 16);
        } else {
          return const Icon(Icons.star_border, color: Colors.yellow, size: 16);
        }
      }),
    );
  }

  Widget _buildSectionTitle(String title) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Align(
        alignment: localizations.locale.languageCode == 'ar'
            ? Alignment.centerRight
            : Alignment.centerLeft, // Align title based on language
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildContactButton() {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();

    return Center(
      child: Hero(
        tag: 'contactButton',
        child: FilledButton.icon(
          onPressed: () {
            HapticFeedback.mediumImpact();
            _showContactBottomSheet();
          },
          icon: const Icon(Icons.contact_mail),
          label: Text(
            localizations.contactProvider,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.purple,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  void _showContactBottomSheet() {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                localizations.contactInformation,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.phone, color: Colors.purple),
                      title: Text(
                        phoneNubmber,
                        style: GoogleFonts.poppins(),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.content_copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: phoneNubmber));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(localizations.copiedToClipboard)),
                          );
                        },
                      ),
                    ),
                    Divider(
                        height: 1,
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.2)),
                    ListTile(
                      leading: const Icon(Icons.email, color: Colors.purple),
                      title: Text(
                        userEmail,
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.content_copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: userEmail));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(localizations.copiedToClipboard)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        localizations.close,
                        style: GoogleFonts.poppins(color: Colors.purple),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showContactDialog(
                            widget.providerId, currentUserId, _firestore);
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.purple,
                      ),
                      child: Text(
                        localizations.sendDirectListing,
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactDialog(
      String recipientUid, String senderUid, FirebaseFirestore firestore) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;

    final _formKey = GlobalKey<FormState>();
    String mainTitle = '';
    String description = '';
    String pay = '';
    String location = '';
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.sendDirectJobListing,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        enabled: !isSubmitting,
                        decoration: InputDecoration(
                          labelText: localizations.mainTitle,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.title),
                        ),
                        validator: (value) => value!.isEmpty
                            ? localizations.pleaseEnterTitle
                            : null,
                        onSaved: (value) => mainTitle = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        enabled: !isSubmitting,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: localizations.description,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.description),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) => value!.isEmpty
                            ? localizations.pleaseEnterDescription
                            : null,
                        onSaved: (value) => description = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        enabled: !isSubmitting,
                        decoration: InputDecoration(
                          labelText: localizations.pay,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (value) => value!.isEmpty
                            ? localizations.pleaseEnterPay
                            : null,
                        onSaved: (value) => pay = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        enabled: !isSubmitting,
                        decoration: InputDecoration(
                          labelText: localizations.location,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.location_on),
                        ),
                        validator: (value) => value!.isEmpty
                            ? localizations.locationRequiredError
                            : null,
                        onSaved: (value) => location = value!,
                      ),
                    ],
                  ),
                ),
                if (isSubmitting) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          localizations.sendingListing,
                          style: GoogleFonts.poppins(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            isSubmitting ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          localizations.close,
                          style: GoogleFonts.poppins(color: Colors.purple),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() {
                                    isSubmitting = true;
                                  });

                                  try {
                                    _formKey.currentState!.save();
                                    final uniqueId = const Uuid().v4();

                                    final jobData = {
                                      'id': uniqueId,
                                      'mainTitle': mainTitle,
                                      'description': description,
                                      'pay': pay,
                                      'location': location,
                                      'status': 'pending',
                                      'timestamp':
                                          DateTime.now().toIso8601String(),
                                      'receiverUid': recipientUid,
                                      'senderUid': senderUid,
                                    };

                                    await Future.wait([
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(senderUid)
                                          .update({
                                        'Listing_(sent)':
                                            FieldValue.arrayUnion([jobData]),
                                      }),
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(recipientUid)
                                          .update({
                                        'Listing_(received)':
                                            FieldValue.arrayUnion([jobData]),
                                      }),
                                    ]);

                                    final providerDoc = await firestore
                                        .collection('users')
                                        .doc(recipientUid)
                                        .get();

                                    final providerData = providerDoc.data()
                                        as Map<String, dynamic>;
                                    final String deviceToken =
                                        providerData['deviceToken'];

                                    if (deviceToken.isNotEmpty) {
                                      await PushNotificationService
                                          .sendNotification(
                                        deviceToken,
                                        'New Job Listing',
                                        'You have received a new job listing: $mainTitle',
                                        jobData,
                                      );
                                    }

                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(localizations
                                            .jobListingSentSuccessfully),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } catch (e) {
                                    setState(() {
                                      isSubmitting = false;
                                    });
                                    debugPrint('Error sending listing: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            localizations.failedToSendListing),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor:
                                            Theme.of(context).colorScheme.error,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          localizations.sendListing,
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkDomainsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Align(
        alignment: Alignment.topLeft,
        child: Column(
          children: [
            if (selectedWorkChoices.isNotEmpty)
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: selectedWorkChoices
                    .map(
                      (choice) => Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(choice, style: GoogleFonts.poppins()),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              )
            else
              const Center(child: Text('No work domains available')),
          ],
        ),
      ),
    );
  }
}
