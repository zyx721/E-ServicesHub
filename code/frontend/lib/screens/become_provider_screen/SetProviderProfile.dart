import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/navbar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as path;
import 'package:googleapis_auth/auth_io.dart';

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


class SetProviderProfile extends StatefulWidget {
  const SetProviderProfile({Key? key}) : super(key: key);

  @override
  _ServiceProviderProfileState createState() => _ServiceProviderProfileState();
}

class _ServiceProviderProfileState extends State<SetProviderProfile> {
  final _driveService = GoogleDriveService();
  final _formKey = GlobalKey<FormState>();

    // Track temporary uploads that haven't been saved to profile yet
  List<String> _temporaryUploads = [];
  List<String> portfolioImages = [];

  // Profile basic info
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _professionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _hourlyRateController = TextEditingController();

  // Dynamic input lists
  List<String> _skills = [];
  List<String> _certifications = [];
  List<Map<String, String>> _workExperience = [];
  // Controllers for dynamic inputs
  final TextEditingController _skillController = TextEditingController();
  final TextEditingController _certificationController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();



  String userPhotoUrl = '';
  String _originalFirstName = "";
  String _originalLastName = "";

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }
  
  Future<void> fetchUserData() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            userPhotoUrl = data['photoURL'] ?? '';
            _originalFirstName = data['firstName'] ?? '';
            _originalLastName = data['lastName'] ?? '';
            _firstNameController.text = _originalFirstName;
            _lastNameController.text = _originalLastName;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  

 @override
  void dispose() {
    // Cleanup temporary uploads when widget is disposed
    _cleanupTemporaryUploads();
    super.dispose();
  }


  Future<void> _cleanupTemporaryUploads() async {
    for (String fileUrl in _temporaryUploads) {
      try {
        await _driveService.deleteFile(fileUrl);
      } catch (e) {
        debugPrint('Error cleaning up temporary upload: $e');
      }
    }
  }

  Future<void> uploadToGoogleDrive(File file) async {
    try {
      final fileUrl = await _driveService.uploadFile(file);
      
      setState(() {
        _temporaryUploads.add(fileUrl); // Track as temporary upload
        portfolioImages.add(fileUrl);
      });

      debugPrint('File uploaded temporarily: $fileUrl');
    } catch (e) {
      debugPrint('Error uploading to Google Drive: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload image')),
      );
    }
  }

  Future<void> deletePortfolioImage(String imageUrl) async {
    try {
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

      await _driveService.deleteFile(imageUrl);

      setState(() {
        portfolioImages.remove(imageUrl);
        _temporaryUploads.remove(imageUrl); // Remove from temporary tracking
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image deleted successfully')),
      );
    } catch (e) {
      debugPrint('Error deleting portfolio image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete image')),
      );
    }
  }

  Future<void> _saveProfile() async {
    final String firstName = _firstNameController.text.trim();
    final String lastName = _lastNameController.text.trim();

    if (_calculateDifference(_originalFirstName, firstName) > 2 || _calculateDifference(_originalLastName, lastName) > 2) {
      _showErrorDialog("You can only change up to 2 characters in your names.");
      return;
    }

    if (_formKey.currentState!.validate()) {
      if (_skills.isEmpty || _certifications.isEmpty || _workExperience.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one skill, certification, and work experience')),
        );
        return;
      }

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User is not authenticated')),
        );
        return;
      }

      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(child: CircularProgressIndicator());
          },
        );

        final DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

        // Prepare the profile data
        Map<String, dynamic> profileData = {
          'firstName': firstName,
          'lastName': lastName,
          'basicInfo': {
            'profession': _professionController.text,
            'phone': _phoneController.text,
            'address': _addressController.text,
            'hourlyRate': _hourlyRateController.text,
          },
          'skills': _skills,
          'certifications': _certifications,
          'workExperience': _workExperience,
          'portfolioImages': portfolioImages, // Save all current portfolio images
          'rating': 0.0,
          'isProvider': true,
          'aboutMe': _descriptionController.text,
        };

        // Update the Firestore document
        await userDoc.update(profileData);
        
        // Clear temporary uploads list since they're now saved
        _temporaryUploads.clear();

        // Close loading indicator
        Navigator.of(context).pop();

        // Navigate to the NavbarPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NavbarPage(),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      } catch (e) {
        // Close loading indicator
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  int _calculateDifference(String original, String updated) {
    int difference = 0;
    for (int i = 0; i < original.length && i < updated.length; i++) {
      if (original[i] != updated[i]) {
        difference++;
      }
    }
    difference += (original.length - updated.length).abs();
    return difference;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Setup Your Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildProfileImageUpload(),
            const SizedBox(height: 20),

            _buildSectionTitle('Basic Information'),
            _buildBasicInfoFields(),
            const SizedBox(height: 20),

            _buildSectionTitle('Skills'),
            _buildSkillsSection(),
            const SizedBox(height: 20),

            _buildSectionTitle('Work Experience'),
            _buildWorkExperienceSection(),
            const SizedBox(height: 20),

            _buildSectionTitle('Certifications'),
            _buildCertificationsSection(),
            const SizedBox(height: 20),

            buildPortfolioSection(),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(
                'Save Profile',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildProfileImageUpload() {
    return Center(
      child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: userPhotoUrl.isNotEmpty
                      ? NetworkImage(userPhotoUrl) as ImageProvider
                      : const AssetImage('assets/images/default_profile.png'),
                ),
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


  Widget _buildBasicInfoFields() {
    return Column(
      children: [
        TextFormField(
          controller: _firstNameController,
          decoration: InputDecoration(
            labelText: 'First Name',
            border: OutlineInputBorder(),
            labelStyle: GoogleFonts.poppins(),
          ),
          validator: (value) => value!.isEmpty ? 'Please enter your first name' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _lastNameController,
          decoration: InputDecoration(
            labelText: 'Last Name',
            border: OutlineInputBorder(),
            labelStyle: GoogleFonts.poppins(),
          ),
          validator: (value) => value!.isEmpty ? 'Please enter your last name' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _professionController,
          decoration: InputDecoration(
            labelText: 'Profession',
            border: OutlineInputBorder(),
            labelStyle: GoogleFonts.poppins(),
          ),
          validator: (value) => value!.isEmpty ? 'Please enter your profession' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
            labelStyle: GoogleFonts.poppins(),
          ),
          validator: (value) => value!.isEmpty 
            ? 'Please enter your phone number' 
            : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: 'Address',
            border: OutlineInputBorder(),
            labelStyle: GoogleFonts.poppins(),
          ),
          validator: (value) => value!.isEmpty 
            ? 'Please enter your address' 
            : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _hourlyRateController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Hourly Rate (DZD)',
            border: OutlineInputBorder(),
            labelStyle: GoogleFonts.poppins(),
          ),
          validator: (value) => value!.isEmpty 
            ? 'Please enter your hourly rate' 
            : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'About Me',
            border: OutlineInputBorder(),
            labelStyle: GoogleFonts.poppins(),
          ),
          validator: (value) => value!.isEmpty 
            ? 'Please provide a brief description' 
            : null,
        ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _skillController,
                decoration: InputDecoration(
                  labelText: 'Add Skill',
                  border: OutlineInputBorder(),
                  labelStyle: GoogleFonts.poppins(),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle, color: Colors.blue),
              onPressed: _addSkill,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _skills.map((skill) => Chip(
            label: Text(skill, style: GoogleFonts.poppins()),
            deleteIcon: Icon(Icons.close),
            onDeleted: () => _removeSkill(skill),
          )).toList(),
        ),
      ],
    );
  }

  void _addSkill() {
    if (_skillController.text.isNotEmpty) {
      setState(() {
        _skills.add(_skillController.text);
        _skillController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  Widget _buildWorkExperienceSection() {
    return Column(
      children: [
        TextField(
          controller: _companyController,
          decoration: InputDecoration(
            labelText: 'Company Name',
            border: OutlineInputBorder(),
            labelStyle: GoogleFonts.poppins(),
          ),
        ),
        const SizedBox(height: 10),
                TextField(
          controller: _positionController,
          decoration: InputDecoration(
            labelText: 'Position',
            border: OutlineInputBorder(),
            labelStyle: GoogleFonts.poppins(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _durationController,
          decoration: InputDecoration(
            labelText: 'Duration',
            border: OutlineInputBorder(),
            labelStyle: GoogleFonts.poppins(),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _addWorkExperience,
          child: Text(
            'Add Experience',
            style: GoogleFonts.poppins(),
          ),
        ),
        const SizedBox(height: 10),
        Column(
          children: _workExperience.map((experience) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 5),
              child: ListTile(
                title: Text(
                  experience['company'] ?? '',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Position: ${experience['position'] ?? ''}', style: GoogleFonts.poppins()),
                    Text('Duration: ${experience['duration'] ?? ''}', style: GoogleFonts.poppins()),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeWorkExperience(experience),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _addWorkExperience() {
    if (_companyController.text.isNotEmpty &&
        _positionController.text.isNotEmpty &&
        _durationController.text.isNotEmpty) {
      setState(() {
        _workExperience.add({
          'company': _companyController.text,
          'position': _positionController.text,
          'duration': _durationController.text,
        });
        _companyController.clear();
        _positionController.clear();
        _durationController.clear();
      });
    }
  }

  void _removeWorkExperience(Map<String, String> experience) {
    setState(() {
      _workExperience.remove(experience);
    });
  }

  Widget _buildCertificationsSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _certificationController,
                decoration: InputDecoration(
                  labelText: 'Add Certification',
                  border: OutlineInputBorder(),
                  labelStyle: GoogleFonts.poppins(),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle, color: Colors.blue),
              onPressed: _addCertification,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _certifications.map((certification) => Chip(
            label: Text(certification, style: GoogleFonts.poppins()),
            deleteIcon: Icon(Icons.close),
            onDeleted: () => _removeCertification(certification),
          )).toList(),
        ),
      ],
    );
  }

  void _addCertification() {
    if (_certificationController.text.isNotEmpty) {
      setState(() {
        _certifications.add(_certificationController.text);
        _certificationController.clear();
      });
    }
  }

  void _removeCertification(String certification) {
    setState(() {
      _certifications.remove(certification);
    });
  }



  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;



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
                          if (isDeleting)
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
                          if (!isDeleting)
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




}


