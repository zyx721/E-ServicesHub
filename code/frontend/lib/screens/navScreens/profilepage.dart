import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:flutter/services.dart' show rootBundle;


class GoogleDriveService {
  static const String _folderID = "1b517UTgjLJfsjyH2dByEPYZDg4cgwssQ"; // Your folder ID

  Future<drive.DriveApi> getDriveApi() async {
    try {
      // Load credentials from assets
      final String credentials = await rootBundle.loadString(
        'assets/credentials/service_account.json'
      );
      
      final accountCredentials = ServiceAccountCredentials.fromJson(credentials);
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

class ServiceProviderProfile2 extends StatefulWidget {
  const ServiceProviderProfile2({Key? key}) : super(key: key);

  @override
  State<ServiceProviderProfile2> createState() =>
      _ServiceProviderProfileState();
}

class _ServiceProviderProfileState extends State<ServiceProviderProfile2> {
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
  double rating =0.0;

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



   Future<drive.DriveApi> getDriveApi() async {
    final serviceAccountFile = File('assets/credentials/sunny-passage-444710-n0-401a2eef3d8b.json');
    final credentials = serviceAccountFile.readAsStringSync();
    final accountCredentials = ServiceAccountCredentials.fromJson(credentials);
    final client = await clientViaServiceAccount(
      accountCredentials,
      [drive.DriveApi.driveScope],
    );
    return drive.DriveApi(client);
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
                    final isDeleting = deletingImages.contains(imageUrl);
                    
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
                              width: 100,
                              height: 100,
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
                          if (isEditMode && isDeleting)
                            Container(
                              width: 100,
                              height: 100,
                              color: Colors.black.withOpacity(0.5),
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
            : const Center(child: Text('No portfolio images available')),
        const SizedBox(height: 16),
        if (isEditMode)
          ElevatedButton(
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
            child: isAddingImage
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Text('Add Portfolio Image'),
          ),
      ],
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
        'workExperience':workExperience,
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
        : Stack(
            children: [
              ListView(
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
                ],
              ),
              Positioned(
                top: 40, // Adjust this value to fine-tune the position
                right: 16, // Adjust this value to fine-tune the position
                child: FloatingActionButton(
                  onPressed: toggleEditMode,
                  child: Icon(isEditMode ? Icons.check : Icons.edit),
                  tooltip: isEditMode ? 'Save Changes' : 'Edit Profile',
                  backgroundColor: const Color.fromARGB(255, 43, 133, 207),
                ),
              ),
            ],
          ),
    resizeToAvoidBottomInset: false,
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
            isEditMode
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Name',
                  ),
                ),
              )
            :Text(
            userName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            profession,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            userEmail,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
void removeSkill(int index ) {
  setState(() {
    skills.removeAt(index); // Remove the first occurrence of the skill
  });
}

Widget _buildSkillsSection() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // If in edit mode, show the input field for new skills
        if (isEditMode)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: skillController,
                  decoration: const InputDecoration(
                    labelText: 'Add Skill',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.blue),
                onPressed: () {
                  String skill = skillController.text.trim(); // Get skill from input
                  if (skill.isNotEmpty) {
                    addSkill(skill); // Add skill to list
                    skillController.clear(); // Clear the input field
                  }
                },
              ),
            ],
          ),
        
        // Display list of skills
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
                          if (isEditMode)
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
                              onPressed: () {
                                removeSkill(skills.indexOf(skill)); // Remove skill
                              },
                            ),
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
  );
}

Widget _buildWorkExperienceSection() {
  final TextEditingController companyController = TextEditingController();
  final TextEditingController positionController = TextEditingController();
  final TextEditingController durationController = TextEditingController();

  void addWorkExperience() {
    String company = companyController.text.trim();
    String position = positionController.text.trim();
    String duration = durationController.text.trim();

    if (company.isNotEmpty && position.isNotEmpty && duration.isNotEmpty) {
      setState(() {
        workExperience.add({
          'company': company,
          'position': position,
          'duration': duration,
        });
      });
      // Clear input fields after adding
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

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isEditMode)
          Column(
            children: [
              TextField(
                controller: companyController,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: positionController,
                decoration: const InputDecoration(
                  labelText: 'Position',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (e.g., Jan 2020 - Dec 2022)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: addWorkExperience,
                child: const Text('Add Work Experience'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        if (workExperience.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: workExperience.length,
            itemBuilder: (context, index) {
              final exp = workExperience[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  exp['company'],
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${exp['position']} | ${exp['duration']}',
                  style: GoogleFonts.poppins(),
                ),
                trailing: isEditMode
                    ? IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => removeWorkExperience(index),
                      )
                    : null,
              );
            },
          )
        else
          const Center(
            child: Text('No work experience available'),
          ),
      ],
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


Widget _buildCertificationsSection() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        if (isEditMode)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: certificationController,
                  decoration: const InputDecoration(
                    labelText: 'Add Certification',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.blue),
                onPressed: () {
                  String certification = certificationController.text.trim();
                  if (certification.isNotEmpty) {
                    addCertification(certification);
                    certificationController.clear();
                  }
                },
              ),
            ],
          ),
        
        // Display list of certifications
        if (certifications.isNotEmpty)
          Column(
            children: certifications
                .map(
                  (cert) => Padding(
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
                        if (isEditMode)
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () {
                              removeCertification(certifications.indexOf(cert));
                            },
                          ),
                      ],
                    ),
                  ),
                )
                .toList(),
          )
        else
          const Center(child: Text('No certifications available')),
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
        return const Icon(Icons.star, color: Colors.yellow, size: 16);
      } else if (hasHalfStar && index == fullStars) {
        // Half star
        return const Icon(Icons.star_half, color: Colors.yellow, size: 16);
      } else {
        // Empty star
        return const Icon(Icons.star_border, color: Colors.yellow, size: 16);
      }
    }),
  );
}

  
Future<void> pickNewProfilePicture() async {
  try {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
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
