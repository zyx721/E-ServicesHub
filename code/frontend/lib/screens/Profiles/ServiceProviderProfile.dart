import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hanini_frontend/localization/app_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:ui';

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({Key? key, required this.imageUrl}) : super(key: key);

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
            Positioned(
              top: 16,
              left: 16,
              child: Row(
                children: [
                  const Icon(Icons.image, color: Colors.white, size: 28),
                  const SizedBox(width: 8),
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

class GoogleDriveService {
  static const String _folderID =
      "1b517UTgjLJfsjyH2dByEPYZDg4cgwssQ"; // Your folder ID

  Future<drive.DriveApi> getDriveApi() async {
    try {
      // Load credentials from assets
      final String credentials = await rootBundle
          .loadString('assets/credentials/service_account.json');

      final accountCredentials =
          ServiceAccountCredentials.fromJson(credentials);
      final client = await clientViaServiceAccount(
        accountCredentials,
        [drive.DriveApi.driveScope],
      );

      return drive.DriveApi(client);
    } catch (e) {
      throw Exception('Failed to initialize Drive API: $e');
    }
  }

  Future<String> uploadFile(File file) async {
    try {
      final driveApi = await getDriveApi();
      final fileName = path.basename(file.path);

      // Prepare drive file metadata
      var driveFile = drive.File()
        ..name = fileName
        ..parents = [_folderID];

      // Upload file
      final response = await driveApi.files.create(
        driveFile,
        uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
      );

      final fileId = response.id;
      if (fileId == null) {
        throw Exception('Failed to get file ID after upload');
      }

      // Set file permissions to public
      final permission = drive.Permission()
        ..role = "reader"
        ..type = "anyone";
      await driveApi.permissions.create(permission, fileId);

      // Return the public URL
      return "https://drive.google.com/uc?id=$fileId";
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<void> deleteFile(String fileUrl) async {
    try {
      final driveApi = await getDriveApi();

      // Extract file ID from URL
      final uri = Uri.parse(fileUrl);
      final fileId = uri.queryParameters['id'];

      if (fileId == null) {
        throw Exception('Invalid file URL');
      }

      // Delete the file
      await driveApi.files.delete(fileId);
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }
}

class ServiceProviderProfile extends StatefulWidget {
  const ServiceProviderProfile({Key? key}) : super(key: key);

  @override
  State<ServiceProviderProfile> createState() => _ServiceProviderProfileState();
}

class _ServiceProviderProfileState extends State<ServiceProviderProfile> {
  final _driveService = GoogleDriveService();
  final double profileHeight = 150;
  final FirebaseAuth _auth = FirebaseAuth.instance;
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
  bool isEditMode = false;
  bool isVerified = true;
  bool isLoading = true;
  double rating = 0.0;
  String wilaya = '';
  String commune = '';
  
  String wilayaArabic ="";
  String wilayaLatin = "";
  String communeArabic ="";
  String communeLatin ="";

  final TextEditingController nameController = TextEditingController();
  final TextEditingController hourlyRateController = TextEditingController();
  final TextEditingController aboutMeController = TextEditingController();
  final TextEditingController certificationController = TextEditingController();
  final TextEditingController skillController = TextEditingController();

  Future<void> fetchUserData() async {
  try {
    final User? user = _auth.currentUser;
    if (user != null) {
      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          userName = data['name'] ?? 'Anonymous';
          userEmail = data['email'] ?? 'No email';
          userPhotoUrl = data['photoURL'] ?? '';
          aboutMe = data['aboutMe'] ?? 'Tell us about yourself';
          hourlyRate = data['basicInfo']['hourlyRate'] ?? '';
          profession = data['basicInfo']['profession'] ?? '';

          // Fetch both Arabic and Latin versions of wilaya and commune
          wilayaArabic = data['basicInfo']['wilaya_arabic'] ?? '';
          wilayaLatin = data['basicInfo']['wilaya'] ?? '';
          communeArabic = data['basicInfo']['commune_arabic'] ?? '';
          communeLatin = data['basicInfo']['commune'] ?? '';



          skills = data['skills'];
          certifications = data['certifications'];
          workExperience = data['workExperience'];
          rating = (data['rating'] ?? 0.0).toDouble();
          portfolioImages = List<String>.from(data['portfolioImages'] ?? []);
          nameController.text = userName;
          aboutMeController.text = aboutMe;
          hourlyRateController.text = hourlyRate;
          isLoading = false;
        });
      }
    }
  } catch (e) {
    debugPrint('Error fetching user data: $e');
  }
}

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  @override
  void dispose() {
    nameController.dispose();
    hourlyRateController.dispose();
    aboutMeController.dispose();
    super.dispose();
  }

  Future<void> deletePortfolioImage(String imageUrl) async {
    try {
      // Show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Delete Image'),
            content: const Text('Are you sure you want to delete this image?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;

      // Delete from Google Drive
      await _driveService.deleteFile(imageUrl);

      // Remove from Firestore
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'portfolioImages': FieldValue.arrayRemove([imageUrl]),
        });
      }

      // Update state
      setState(() {
        portfolioImages.remove(imageUrl);
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image deleted successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting portfolio image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete image')),
        );
      }
    }
  }

  Future<void> uploadToGoogleDrive(File file) async {
    try {
      final fileUrl = await _driveService.uploadFile(file);

      // Update Firestore with the new URL
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'portfolioImages': FieldValue.arrayUnion([fileUrl]),
        });
      }

      setState(() {
        portfolioImages.add(fileUrl);
      });

      debugPrint('File uploaded and URL added: $fileUrl');
    } catch (e) {
      debugPrint('Error uploading to Google Drive: $e');
      // Consider showing an error message to the user
    }
  }

  Future<void> pickNewPortfolioImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      await uploadToGoogleDrive(file);
    }
  }

  // Add these to your class state variables
  bool isAddingImage = false;
  Set<String> deletingImages = {};

Widget buildPortfolioSection(BuildContext context) {
  final localizations = AppLocalizations.of(context);
  if (localizations == null) return const SizedBox.shrink();

  return Container(
    padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 5,
          blurRadius: 15,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    margin: const EdgeInsets.all(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                child: Icon(Icons.photo_album, size: 24, color: Colors.blue[600]),
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
                      final isDeleting = deletingImages.contains(imageUrl);
    
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
                                          color: Colors.black.withOpacity(0.1),
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
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            width: 120,
                                            height: 120,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                        loadingProgress.expectedTotalBytes!
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
                            if (isEditMode && isDeleting)
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            if (isEditMode && !isDeleting)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.white),
                                    iconSize: 20,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    onPressed: () async {
                                      setState(() {
                                        deletingImages.add(imageUrl);
                                      });
                                      await deletePortfolioImage(imageUrl);
                                      setState(() {
                                        deletingImages.remove(imageUrl);
                                      });
                                    },
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
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
          const SizedBox(height: 16),
          if (isEditMode)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
onPressed: isAddingImage
    ? null
    : () async {
        setState(() {
          isAddingImage = true;
        });
        try {
          await pickNewPortfolioImage();
        } finally {
          setState(() {
            isAddingImage = false;
          });
        }
      },
icon: isAddingImage
    ? const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white, // Set spinner color to white
        ),
      )
    : const Icon(
        Icons.add_photo_alternate,
        color: Colors.white, // Icon color set to white
      ),
label: Text(
  localizations.addPortfolioImage,
  style: const TextStyle(color: Colors.white), // Text color set to white
),
style: ElevatedButton.styleFrom(
  backgroundColor: Colors.blue, // Button background color set to blue
  foregroundColor: Colors.white, // Ensures all content inside is styled white
  padding: const EdgeInsets.symmetric(vertical: 12),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  ),
),
             ),
            ),
        ],
      ),
    ),
  );
}


  Future<void> saveUserData() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        // Update Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'name': userName,
          'aboutMe': aboutMe,
          'basicInfo.hourlyRate': hourlyRate,
          'skills': skills,
          'certifications': certifications,
          'workExperience': workExperience,
        });

        // Update FirebaseAuth user profile
        await user.updateDisplayName(userName);
        await user.reload(); // Refresh the current user
        debugPrint('User data updated successfully');
      }
    } catch (e) {
      debugPrint('Error saving user data: $e');
    }
  }

  // Toggle edit mode and save changes
  void toggleEditMode() {
    setState(() {
      if (isEditMode) {
        // Save changes (you can save your form values here if needed)
        userName = nameController.text;
        hourlyRate = hourlyRateController.text;
        aboutMe = aboutMeController.text;
        saveUserData();
      }
      isEditMode = !isEditMode;
    });
// After saving changes, stay on the same page
    if (!isEditMode) {
      // Do not navigate away
    }
  }

  void navigateBack() {
    Navigator.pop(context); // Navigate back to the previous screen or navbar
  }

  @override
  Widget build(BuildContext context) {
    final localizations =
        AppLocalizations.of(context); // Get localization instance

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    buildTop(localizations!),
                    buildProfileInfo(localizations),
                    const SizedBox(height: 20),
                    _buildSkillsSection(localizations),
                    const SizedBox(height: 20),
                    _buildWorkExperienceSection(localizations),
                    const SizedBox(height: 20),
                    buildPortfolioSection(context),
                    const SizedBox(height: 20),
                    _buildCertificationsSection(localizations),
                    const SizedBox(
                      height: 20,
                    )
                  ],
                ),
                Positioned(
                  bottom: 40, // Adjust this value to fine-tune the position
                  right: 16, // Adjust this value to fine-tune the position
                  child: FloatingActionButton(
                    onPressed: toggleEditMode,
                    child: Icon(isEditMode ? Icons.check : Icons.edit),
                    tooltip: isEditMode
                        ? localizations.save
                        : localizations.editProfile,
                    backgroundColor: const Color.fromARGB(255, 43, 133, 207),
                  ),
                ),
              ],
            ),
      resizeToAvoidBottomInset: false,
    );
  }

Widget buildTop(AppLocalizations localizations) {
  return Container(
    margin: const EdgeInsets.all(16), // Adds margin around the card
    child: _buildInfoCard(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: profileHeight / 2,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: userPhotoUrl.isNotEmpty
                      ? NetworkImage(userPhotoUrl) as ImageProvider
                      : const AssetImage('assets/images/default_profile.png'),
                ),
              ),
              if (isEditMode)
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: pickNewProfilePicture,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (isEditMode)
            TextField(
              controller: nameController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                labelText: localizations.name,
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            )
          else
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
        color: Colors.blue.withOpacity(0.1), // Light blue background
        shape: BoxShape.rectangle, // Circular shape for the icon's background
      ),
      child: Icon(Icons.business_center, size: 20, color: Colors.blue.shade700),
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
        color: Colors.green.withOpacity(0.1), // Light green background
        shape: BoxShape.rectangle, // Circular shape for the icon's background
      ),
      child: Icon(Icons.email, size: 20, color: Colors.green.shade700),
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
    padding: const EdgeInsets.all(16),
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
                          child: Icon(Icons.location_on, color: Colors.blue.shade700),
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
                      child: Icon(Icons.monetization_on, color: Colors.green.shade700),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          isEditMode
                              ? buildHourlyRateEditor()
                              : Text(
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
        const SizedBox(height: 24),
        _buildInfoCard(
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
                child: Icon(Icons.person, size: 24, color: Colors.blue.shade700),
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
              isEditMode
                  ? TextField(
                      controller: aboutMeController,
                      onChanged: (value) => aboutMe = value,
                      maxLines: 4,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: localizations.aboutMeLabel,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    )
                  : Text(
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
      ],
    ),
  );
}

Widget _buildInfoCard({required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(16),
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

// Add a new skill
  void addSkill(String skill) {
    if (skill.isNotEmpty) {
      setState(() {
        // Trim the skill and add it if it's not already in the list
        skill = skill.trim();
        if (!skills.contains(skill)) {
          skills.add(skill);
        }
      });
    }
  }

// Replace the existing methods with these:

// Remove a skill
  void removeSkill(int index) {
    setState(() {
      skills.removeAt(index); // Remove the first occurrence of the skill
    });
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
                child: Icon(Icons.psychology, size: 24, color: Colors.blue.shade700),
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
          // Add Skill Section
          if (isEditMode)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: skillController,
                      decoration: InputDecoration(
                        labelText: localizations.addSkill,
                        labelStyle: TextStyle(color: Colors.blue.shade700),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.blue.shade50,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.blue.shade400,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        final skill = skillController.text.trim();
                        if (skill.isNotEmpty) {
                          addSkill(skill);
                          skillController.clear();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Skill Chips or Placeholder
          if (skills.isNotEmpty)
            Wrap(
              spacing: 12.0,
              runSpacing: 12.0,
              children: skills.map((skill) => _buildSkillChip(skill)).toList(),
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
            if (isEditMode) ...[
              const SizedBox(width: 4),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => removeSkill(skills.indexOf(skill)),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
 Widget _buildWorkExperienceSection(AppLocalizations localizations) {
  final companyController = TextEditingController();
  final positionController = TextEditingController();
  final durationController = TextEditingController();

  void addWorkExperience() {
    final company = companyController.text.trim();
    final position = positionController.text.trim();
    final duration = durationController.text.trim();

    if (company.isNotEmpty && position.isNotEmpty && duration.isNotEmpty) {
      setState(() {
        workExperience.add({
          'company': company,
          'position': position,
          'duration': duration,
        });
      });
      companyController.clear();
      positionController.clear();
      durationController.clear();
    }
  }

  void removeWorkExperience(int index) {
    setState(() {
      workExperience.removeAt(index);
    });
  }

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 5,
          blurRadius: 15,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    margin: const EdgeInsets.all(16),
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
                child: Icon(Icons.work, size: 24, color: Colors.purple),
              ),
              const SizedBox(width: 16),
              Text(
                localizations.workExperience,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
              const SizedBox(height: 24),
              if (isEditMode) ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: companyController,
                        decoration: InputDecoration(
                          labelText: localizations.companyName,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          prefixIcon: const Icon(Icons.business),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: positionController,
                        decoration: InputDecoration(
                          labelText: localizations.position,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          prefixIcon: const Icon(Icons.work),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: durationController,
                        decoration: InputDecoration(
                          labelText: localizations.duration,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          prefixIcon: const Icon(Icons.calendar_today),
                          hintText: 'e.g., Jan 2020 - Present',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => addWorkExperience(),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(

                        onPressed: addWorkExperience,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:Colors.purple,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              localizations.addWorkExperience,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
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
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    if (isEditMode)
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red[400]),
                        onPressed: () => removeWorkExperience(index),
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
  );
}
  void addCertification(String certification) {
    if (certification.isNotEmpty) {
      setState(() {
        // Trim the certification to remove any leading/trailing whitespace
        certification = certification.trim();

        // Check if the certification is not already in the list
        if (!certifications.contains(certification)) {
          certifications.add(certification);
        }
      });
    }
  }

// Remove a certification from the list
  void removeCertification(int index) {
    setState(() {
      certifications.removeAt(index);
    });
  }

Widget _buildCertificationsSection(AppLocalizations localizations) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 15,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Section with Icon
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
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
              if (isEditMode)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: certificationController,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                          decoration: InputDecoration(
                            labelText: localizations.addCertification,
                            labelStyle: GoogleFonts.poppins(color: Colors.black54),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () {
                            String certification = certificationController.text.trim();
                            if (certification.isNotEmpty) {
                              addCertification(certification);
                              certificationController.clear();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.add_circle,
                              color: Colors.green.shade600,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Certifications List
              if (certifications.isNotEmpty)
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: certifications.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
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
                          if (isEditMode)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: () => removeCertification(index),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.remove_circle,
                                    color: Colors.red.shade400,
                                    size: 24,
                                  ),
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

  
  Widget _buildStarRating(double? rating) {
    if (rating == null || rating < 0.0) {
      rating = 0.0; // Default value for invalid or missing rating
    }

    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min, // To prevent expanding
      children: List.generate(5, (index) {
        if (index < fullStars) {
          // Full star
          return const Icon(Icons.star, color: Colors.yellow, size: 14.5);
        } else if (hasHalfStar && index == fullStars) {
          // Half star
          return const Icon(Icons.star_half, color: Colors.yellow, size: 14.5);
        } else {
          // Empty star
          return const Icon(Icons.star_border, color: Colors.yellow, size: 14.5);
        }
      }),
    );
  }

  Future<void> pickNewProfilePicture() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return;

      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(child: CircularProgressIndicator());
          },
        );
      }

      // Upload new image to Drive
      final file = File(pickedFile.path);
      final fileUrl = await _driveService.uploadFile(file);

      // Get current user
      final User? user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Delete old photo from Drive if it exists
      if (userPhotoUrl.startsWith('https://drive.google.com')) {
        try {
          await _driveService.deleteFile(userPhotoUrl);
        } catch (e) {
          debugPrint('Error deleting old profile picture: $e');
        }
      }

      // Update Firestore and local state
      await _firestore.collection('users').doc(user.uid).update({
        'photoURL': fileUrl,
      });

      setState(() {
        userPhotoUrl = fileUrl;
      });

      // Close loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error updating profile picture: $e');
      if (mounted) {
        Navigator.of(context).pop(); // Close loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile picture')),
        );
      }
    }
  }
}
