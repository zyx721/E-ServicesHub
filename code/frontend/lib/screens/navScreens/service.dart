import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceProviderFullProfile extends StatefulWidget {
  final String providerId;

  const ServiceProviderFullProfile({Key? key, required this.providerId}) : super(key: key);

  @override
  _ServiceProviderFullProfileState createState() => _ServiceProviderFullProfileState();
}

class _ServiceProviderFullProfileState extends State<ServiceProviderFullProfile> {
  final double profileHeight = 150;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> portfolioImages = [];
  List<dynamic> skills = [];
  List<dynamic> certifications = [];
  List<dynamic> workExperience = [];
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
    _loadPortfolioImages();
  }

  @override
  void dispose() {
    hourlyRateController.dispose();
    aboutMeController.dispose();
    super.dispose();
  }

  // Load saved portfolio images from local storage
  Future<void> _loadPortfolioImages() async {
    final directory = await getApplicationDocumentsDirectory();
    final dirPath =
        directory.path + '/saved_images'; // Change to your desired directory
    final directoryExists = Directory(dirPath).existsSync();

    if (!directoryExists) {
      Directory(dirPath).createSync();
    }

    final List<FileSystemEntity> files = Directory(dirPath).listSync();

    setState(() {
      portfolioImages = files
          .where((file) =>
              file.path.endsWith('.jpg') || file.path.endsWith('.png'))
          .map((file) => file.path)
          .toList();
    });
  }

  // Pick a new portfolio image and save it to local storage
  Future<void> pickNewPortfolioImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = path.basename(pickedFile.path);
      final newDirPath =
          '${directory.path}/saved_images'; // Path for saving images
      final newFile = File('$newDirPath/$fileName');

      // Ensure the directory exists
      Directory(newDirPath).createSync();

      // Copy the image to the app's local directory
      await File(pickedFile.path).copy(newFile.path);

      setState(() {
        portfolioImages.add(newFile.path); // Add new image to the list
      });
    }
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
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                buildTop(),
                buildProfileInfo(),
                const SizedBox(height: 20),
                _buildSectionTitle('Skills'),
                _buildSkillsSection(),
                const SizedBox(height: 20),
                _buildSectionTitle('Work Experience'),
                _buildWorkExperienceSection(),
                const SizedBox(height: 20),
                buildPortfolioSection(),
                const SizedBox(height: 20),
                _buildSectionTitle('Certifications'),
                _buildCertificationsSection(),
                const SizedBox(height: 20),
                const SizedBox(height: 20),
                _buildContactButton(),
              ],
            ),
      floatingActionButton: isEditMode
          ? ElevatedButton(
              onPressed: toggleEditMode,
              child: const Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
            )
          : null, // Hide the button when not in edit mode
    );
  }

  Widget buildTop() {
    return Center(
      child: Column(
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
              if (isEditMode)
                GestureDetector(
                  onTap: () {
                    pickNewProfilePicture();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
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
        ],
      ),
    );
  }

  Widget buildProfileInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildStat('Projects', '0'),
              buildStat('Rating', _buildStarRating(rating)),
              buildStat('Hourly Rate',
                  isEditMode ? buildHourlyRateEditor() : '$hourlyRate DZD'),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: const Text(
              'About Me',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          isEditMode
              ? TextField(
                  controller: aboutMeController,
                  onChanged: (value) => aboutMe = value,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Write about yourself...',
                  ),
                )
              : Text(
                  aboutMe,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  textAlign: TextAlign.justify,
                ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.start,
        children: skills
            .map((skill) => Chip(
                  label: Text(skill, style: GoogleFonts.poppins()),
                  backgroundColor: Colors.blue.shade50,
                ))
            .toList(),
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
              ? GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: portfolioImages.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        // Show image in full screen
                      },
                      child: Image.file(
                        File(portfolioImages[index]),
                        fit: BoxFit.cover,
                      ),
                    );
                  })
              : const Center(child: Text('No portfolio images available')),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: pickNewPortfolioImage,
            child: const Text('Add Portfolio Image'),
          ),
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
        const SizedBox(height: 4),
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
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  // Widget _buildReviewsSection() {
  //   return Column(
  //     children: (_providerData['reviews'] as List<Map<String, dynamic>>)
  //         .map((review) => Card(
  //               margin: const EdgeInsets.symmetric(vertical: 8),
  //               child: Padding(
  //                 padding: const EdgeInsets.all(12.0),
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                       children: [
  //                         Text(
  //                           review['name'],
  //                           style: GoogleFonts.poppins(
  //                             fontWeight: FontWeight.w600,
  //                           ),
  //                         ),
  //                         Row(
  //                           children: List.generate(
  //                             review['rating'].toInt(),
  //                             (index) => const Icon(
  //                               Icons.star,
  //                               color: Colors.amber,
  //                               size: 16,
  //                             ),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                     const SizedBox(height: 8),
  //                     Text(
  //                       review['comment'],
  //                       style: GoogleFonts.poppins(
  //                         color: Colors.grey[700],
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ))
  //         .toList(),
  //   );
  // }

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
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
