
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart' as auth;


class PushNotificationService {
  static Future<String> getAccessToken() async {
    // Load the service account JSON
    final serviceAccountJson =await rootBundle.loadString(
        'assets/credentials/test.json'
      );

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

  static Future<void> sendNotification(
      String deviceToken, String title, String body, Map<String, dynamic> data) async {
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

  const ServiceProviderFullProfile({Key? key, required this.providerId}) : super(key: key);

  @override
  _ServiceProviderFullProfileState createState() => _ServiceProviderFullProfileState();
}

class _ServiceProviderFullProfileState extends State<ServiceProviderFullProfile> {
  final double profileHeight = 150;
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
  String hourlyRate = '';
  String phoneNubmber ='';
  bool isEditMode = false;
  bool isVerified = true;
  bool isLoading = true;
  double rating =0.0;

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

  @override
  void initState() {
    super.initState();
    fetchProviderData();

  }

  @override
  void dispose() {
    hourlyRateController.dispose();
    aboutMeController.dispose();
    super.dispose();
  }




  // Toggle edit mode and save changes
  void toggleEditMode() {
    setState(() {
      if (isEditMode) {
        // Save changes (you can save your form values here if needed)
        hourlyRate = hourlyRateController.text;
        aboutMe = aboutMeController.text;
      }
      isEditMode = !isEditMode;
    });

    // After saving changes, navigate to '/navbar'
    if (!isEditMode) {
      Navigator.pushReplacementNamed(context, '/navbar');
    }
  }

  void navigateBack() {
    Navigator.pop(context); // Navigate back to the previous screen or navbar
  }

@override
Widget build(BuildContext context) {
  return DefaultTabController(
    length: 2, // Number of tabs
    child: Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                buildTopProfileInfo(),
                const SizedBox(height: 20),
                TabBar(
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue,
                  tabs: const [
                    Tab(text: 'Profile'),
                    Tab(text: 'Reviews'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            buildProfileTab(), // Profile content
                          ],
                        ),
                      ),
                      buildReviewsTab(), // Reviews content
                    ],
                  ),
                ),
              ],
            ),
    ),
  );
}

Widget buildReviewsTab() {
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
            'No reviews available.',
            style: GoogleFonts.poppins(fontSize: 16, fontStyle: FontStyle.italic),
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
                      'No reviews available.',
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontStyle: FontStyle.italic),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final review = reviews[index] as Map<String, dynamic>;
                      final comment = review['comment'] ?? 'No comment provided';
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
                        future: _firestore.collection('users').doc(commenterId).get(),
                        builder: (context, commenterSnapshot) {
                          if (commenterSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final commenterData =
                              commenterSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                          final commenterName = commenterData['name'] ?? 'Anonymous';
                          final commenterPhoto =
                              commenterData['photoURL'] ?? '';

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              commenterName,
                                              style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600),
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
    padding: const EdgeInsets.all(10), // Optional padding for touchable area
    decoration: BoxDecoration(
      color: Colors.blue, // Button color
    ),
    child: Center(
      child: Text(
        'Add Review',
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





void _showAddReviewDialog(BuildContext context, String providerId, FirebaseFirestore firestore) {
  final TextEditingController commentController = TextEditingController();
  double newRating = 3.0;
  bool isSubmitting = false; // Add loading state variable

  showDialog(
    context: context,
    barrierDismissible: !isSubmitting, // Prevent dismissal while submitting
    builder: (BuildContext dialogContext) {
      return StatefulBuilder( // Use StatefulBuilder to manage dialog state
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Add a Review', style: GoogleFonts.poppins()),
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
                      decoration: const InputDecoration(
                        labelText: 'Comment',
                        border: OutlineInputBorder(),
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
                      itemPadding: const EdgeInsets.symmetric(horizontal: 2.5),
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
                              'Submitting review...',
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
                child: Text('Cancel', style: GoogleFonts.poppins()),
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
                                content: Text('You must be logged in to add a review')),
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

                          final providerRef = firestore.collection('users').doc(providerId);

                          await providerRef.update({
                            'reviews': FieldValue.arrayUnion([review]),
                            'newCommentsCount': FieldValue.increment(1),
                          });

                          final providerDoc = await providerRef.get();
                          final providerData = providerDoc.data() as Map<String, dynamic>;
                          final reviews = providerData['reviews'] as List<dynamic> ?? [];

                          double totalRating = 0.0;
                          for (var rev in reviews) {
                            totalRating += (rev['rating'] as num).toDouble();
                          }
                          final newAverageRating = totalRating / reviews.length;

                          await providerRef.update({
                            'rating': newAverageRating,
                          });

                          final String deviceToken = providerData['deviceToken'];
                          if (deviceToken.isNotEmpty) {
                            await PushNotificationService.sendNotification(
                              deviceToken,
                              'New Review Received',
                              'You have a new review on your profile',
                              {'providerId': providerId},
                            );
                          }

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Review added successfully!')),
                          );
                        } catch (e) {
                          setState(() {
                            isSubmitting = false;
                          });
                          debugPrint('Error adding review: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Failed to add review. Please try again.')),
                          );
                        }
                      },
                child: Text('Submit', style: GoogleFonts.poppins()),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget buildProfileTab() {
  return  // Make sure everything is scrollable
    Column(
      children: [
         const SizedBox(height: 20),
        buildAboutMeSection(),
        const SizedBox(height: 20),
        _buildSectionTitle('Skills'),
        _buildSkillsSection(),
        const SizedBox(height: 20),
        _buildSectionTitle('Work Experience'),
        _buildWorkExperienceSection(),
        const SizedBox(height: 20),
        _buildSectionTitle('Work Domains'),
        _buildWorkDomainsSection(),
        const SizedBox(height: 20),
        buildPortfolioSection(),
        const SizedBox(height: 20),
        _buildSectionTitle('Certifications'),
        _buildCertificationsSection(),
        const SizedBox(height: 20),
        const SizedBox(height: 20),
        _buildContactButton(),
      ],
    );
}



Widget buildTopProfileInfo() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      const SizedBox(height: 40),
      Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: profileHeight / 2,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: userPhotoUrl.isNotEmpty
                ? NetworkImage(userPhotoUrl) as ImageProvider
                : const AssetImage('assets/images/default_profile.png'),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Text(
        userName,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      Text(
        profession,
        style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
      ),
      const SizedBox(height: 20),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround, // Center items evenly
          children: [
            buildStat('Projects', '0'),
            buildStat('Rating', _buildStarRating(rating)),
            buildStat('Hourly Rate', isEditMode ? buildHourlyRateEditor() : '$hourlyRate DZD',
            ),
          ],
        ),
      ),
    ],
  );
}




  Column buildAboutMeSection() {
    return Column(
          children: [
            _buildSectionTitle('About Me'),
            const SizedBox(height: 8),
             Text(
                    aboutMe,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    textAlign: TextAlign.justify,
                  ),
          ],
        );
  }

  Widget _buildSkillsSection() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Align(
      alignment: Alignment.topLeft,
      child: Column( 
        children: [
          if (skills.isNotEmpty)
            Wrap(  
              spacing: 8.0,
              runSpacing: 4.0,
              children: skills
                  .map(
                    (skill) => Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(skill, style: GoogleFonts.poppins()),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            )
          else
            const Center(child: Text('No skills available')),
        ],
      ),
    ),
  );
}

  Widget _buildWorkExperienceSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: workExperience
            .map((exp) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    exp['company'],
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${exp['position']} | ${exp['duration']}',
                    style: GoogleFonts.poppins(),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget buildPortfolioSection() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Portfolio',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        portfolioImages.isNotEmpty
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: portfolioImages.map((imageUrl) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              // Show image in full screen
                            },
                            child: Image.network(
                              imageUrl,
                              width: 100, // Fixed width for consistency
                              height: 100, // Fixed height for consistency
                              fit: BoxFit.cover,
                              loadingBuilder: (BuildContext context, Widget child,
                                  ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                }
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              )
            : const Center(child: Text('No portfolio images available')),
      ],
    ),
  );
}

  Widget _buildCertificationsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: certifications
            .map((cert) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(Icons.verified, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cert,
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget buildHourlyRateEditor() {
    return SizedBox(
      width: 100,
      child: TextField(
        controller: hourlyRateController,
        onChanged: (value) => hourlyRate = value,
        decoration:
            const InputDecoration(border: OutlineInputBorder(), isDense: true),
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

  Future<void> pickNewProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        userPhotoUrl = pickedFile.path; // You can upload it to Firebase here
      });
    }
  }

    Widget _buildSectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    child: Align(
      alignment: Alignment.centerLeft,  // Align title to the start
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
    return Center(
      child: ElevatedButton.icon(
        onPressed: _showContactBottomSheet,
        icon: const Icon(Icons.contact_mail),
        label: Text(
          'Contact Provider',
          style: GoogleFonts.poppins(),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  void _showContactBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Contact Information',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.blue),
              title: Text(
                phoneNubmber,
                style: GoogleFonts.poppins(),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: Text(
                userEmail,
                style: GoogleFonts.poppins(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(),
                  ),
                ),

 ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
  onPressed: () {
    _showContactDialog(widget.providerId, currentUserId, _firestore); // Call your dialog function here
  },
  child: Text(
    'Send Direct Listing',
    style: GoogleFonts.poppins(),
  ),
),

              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showContactDialog(String recipientUid, String senderUid, FirebaseFirestore firestore) {
  final _formKey = GlobalKey<FormState>();
  String mainTitle = '';
  String description = '';
  String pay = '';
  String location = '';
  bool isSubmitting = false; // Add loading state variable

  showDialog(
    context: context,
    barrierDismissible: !isSubmitting, // Prevent dismissal while submitting
    builder: (BuildContext dialogContext) {
      return StatefulBuilder( // Use StatefulBuilder to manage dialog state
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Send Direct Job Listing',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(labelText: 'Main Title'),
                          validator: (value) =>
                              value!.isEmpty ? 'Please enter a title' : null,
                          onSaved: (value) => mainTitle = value!,
                        ),
                        TextFormField(
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(labelText: 'Description'),
                          validator: (value) =>
                              value!.isEmpty ? 'Please enter a description' : null,
                          onSaved: (value) => description = value!,
                        ),
                        TextFormField(
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(labelText: 'Pay'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) =>
                              value!.isEmpty ? 'Please enter the pay' : null,
                          onSaved: (value) => pay = value!,
                        ),
                        TextFormField(
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(labelText: 'Location'),
                          validator: (value) =>
                              value!.isEmpty ? 'Please enter a location' : null,
                          onSaved: (value) => location = value!,
                        ),
                      ],
                    ),
                  ),
                  if (isSubmitting)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 8),
                          Text(
                            'Sending listing...',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: isSubmitting ? null : () => Navigator.pop(context),
                        child: Text(
                          'Close',
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() {
                                    isSubmitting = true;
                                  });

                                  try {
                                    _formKey.currentState!.save();
                                    final uniqueId = Uuid().v4();

                                    final jobData = {
                                      'id': uniqueId,
                                      'mainTitle': mainTitle,
                                      'description': description,
                                      'pay': pay,
                                      'location': location,
                                      'status': 'pending',
                                      'timestamp': DateTime.now().toIso8601String(),
                                      'receiverUid': recipientUid,
                                      'senderUid': senderUid,
                                    };

                                    // Save to sender's listings
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(senderUid)
                                        .update({
                                      'Listing_(sent)': FieldValue.arrayUnion([jobData]),
                                    });

                                    // Save to recipient's listings
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(recipientUid)
                                        .update({
                                      'Listing_(received)':
                                          FieldValue.arrayUnion([jobData]),
                                    });

                                    final providerRef =
                                        firestore.collection('users').doc(recipientUid);
                                    final providerDoc = await providerRef.get();
                                    final providerData =
                                        providerDoc.data() as Map<String, dynamic>;

                                    final String deviceToken = providerData['deviceToken'];
                                    if (deviceToken.isNotEmpty) {
                                      await PushNotificationService.sendNotification(
                                        deviceToken,
                                        'New Job Listing',
                                        'You have received a new job listing: $mainTitle',
                                        jobData,
                                      );
                                    }

                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Job listing sent successfully!'),
                                      ),
                                    );
                                  } catch (e) {
                                    setState(() {
                                      isSubmitting = false;
                                    });
                                    debugPrint('Error sending listing: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Failed to send listing. Please try again.'),
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 52, 141, 237),
                        ),
                        child: Text(
                          'Send Listing',
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
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
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
