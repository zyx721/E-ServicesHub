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
import 'package:hanini_frontend/localization/algeria_cites.dart';
import 'package:hanini_frontend/localization/app_localization.dart';

// algeria_location_model.dart
class AlgeriaLocation {
  final int id;
  final String communeNameAscii;
  final String communeName;
  final String dairaNameAscii;
  final String dairaName;
  final String wilayaCode;
  final String wilayaNameAscii;
  final String wilayaName;

  const AlgeriaLocation({
    required this.id,
    required this.communeNameAscii,
    required this.communeName,
    required this.dairaNameAscii,
    required this.dairaName,
    required this.wilayaCode,
    required this.wilayaNameAscii,
    required this.wilayaName,
  });

  factory AlgeriaLocation.fromJson(Map<String, dynamic> json) {
    return AlgeriaLocation(
      id: json['id'] as int,
      communeNameAscii: json['commune_name_ascii'] as String,
      communeName: json['commune_name'] as String,
      dairaNameAscii: json['daira_name_ascii'] as String,
      dairaName: json['daira_name'] as String,
      wilayaCode: json['wilaya_code'] as String,
      wilayaNameAscii: json['wilaya_name_ascii'] as String,
      wilayaName: json['wilaya_name'] as String,
    );
  }
}

// Convert the const data to AlgeriaLocation objects
final List<AlgeriaLocation> algeriaLocations =
    algeria_cites.map((json) => AlgeriaLocation.fromJson(json)).toList();

class LocationSelectionFields extends StatefulWidget {
  final void Function(AlgeriaLocation?) onLocationSelected;
  final String? initialWilayaCode;
  final int? initialCommuneId;

  const LocationSelectionFields({
    Key? key,
    required this.onLocationSelected,
    this.initialWilayaCode,
    this.initialCommuneId,
  }) : super(key: key);

  @override
  State<LocationSelectionFields> createState() =>
      _LocationSelectionFieldsState();
}

class _LocationSelectionFieldsState extends State<LocationSelectionFields> {
  String? selectedWilayaCode;
  int? selectedCommuneId;

  // Computed properties with proper uniqueness handling
  Map<String, List<AlgeriaLocation>> get locationsByWilaya {
    final map = <String, List<AlgeriaLocation>>{};
    for (var location in algeriaLocations) {
      if (!map.containsKey(location.wilayaCode)) {
        map[location.wilayaCode] = [];
      }
      map[location.wilayaCode]!.add(location);
    }
    return map;
  }

  // Get unique wilayas with their names
  List<MapEntry<String, String>> get uniqueWilayas {
    final wilayaMap = <String, String>{};
    for (var location in algeriaLocations) {
      // if language is Arabic, use Arabic names
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      wilayaMap.putIfAbsent(location.wilayaCode,
          () => isArabic ? location.wilayaName : location.wilayaNameAscii);
    }
    final wilayas = wilayaMap.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return wilayas;
  }

  List<AlgeriaLocation> get communes {
    return selectedWilayaCode != null
        ? locationsByWilaya[selectedWilayaCode] ?? []
        : [];
  }

  @override
  void initState() {
    super.initState();
    selectedWilayaCode = widget.initialWilayaCode;
    selectedCommuneId = widget.initialCommuneId;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Wilaya Dropdown
   DropdownButtonFormField<String>(
  value: selectedWilayaCode,
  decoration: InputDecoration(
    labelText: localizations.wilaya,
    border: const OutlineInputBorder(),
    labelStyle: GoogleFonts.poppins(),
  ),
  items: uniqueWilayas.map((wilaya) {
    return DropdownMenuItem<String>(
      value: wilaya.key, // wilayaCode
      child: Text(
        wilaya.value, // The name of the wilaya based on the locale
        style: GoogleFonts.poppins(),
      ),
    );
  }).toList(),
  onChanged: (String? newValue) {
    setState(() {
      selectedWilayaCode = newValue;
      selectedCommuneId = null; // Reset commune selection
      widget.onLocationSelected(null);
    });
  },
  validator: (value) => 
      value == null ? localizations.wilayaRequiredError : null,
),

        const SizedBox(height: 10),
        // Commune Dropdown
      DropdownButtonFormField<int>(
  value: selectedCommuneId,
  decoration: InputDecoration(
    labelText: localizations.commune,
    border: const OutlineInputBorder(),
    labelStyle: GoogleFonts.poppins(),
  ),
  items: communes.map((commune) {
    return DropdownMenuItem<int>(
      value: commune.id,
      child: Text(
        // Display based on current locale
        Localizations.localeOf(context).languageCode == 'ar'
            ? commune.communeName
            : commune.communeNameAscii,
        style: GoogleFonts.poppins(),
      ),
    );
  }).toList(),
  onChanged: selectedWilayaCode == null
      ? null
      : (int? newValue) {
          setState(() {
            selectedCommuneId = newValue;
            final selectedLocation = communes.firstWhere(
              (location) => location.id == newValue,
            );

            // Pass both Arabic and Latin names to the parent
            widget.onLocationSelected(selectedLocation);
          });
        },
  validator: (value) =>
      value == null ? localizations.communeRequiredError : null,
),

      ],
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

class SetProviderProfile extends StatefulWidget {
  const SetProviderProfile({Key? key}) : super(key: key);

  @override
  _ServiceProviderProfileState createState() => _ServiceProviderProfileState();
}

class _ServiceProviderProfileState extends State<SetProviderProfile> {
  final _driveService = GoogleDriveService();
  final _formKey = GlobalKey<FormState>();
  // Add these new variables to track selected location
  String? selectedWilaya;
  String? selectedCommune;

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
  final TextEditingController _certificationController =
      TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  var userPhotoUrl = '';
  String _originalFirstName = "";
  String _originalLastName = "";


  String selectedWilayaAscii ="";
  String selectedWilayaArabic="";
  String selectedCommuneAscii ="";
  String selectedCommuneArabic="";

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
  // Add these variables to track temporary images
  List<File> _temporaryImageFiles = [];
  bool _isUploading = false;

  // Modify the pickNewPortfolioImage function to store files temporarily
  Future<void> pickNewPortfolioImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _temporaryImageFiles.add(File(pickedFile.path));
      });
    }
  }

  // Add function to upload all images at once
  Future<List<String>> _uploadAllImages() async {
    List<String> uploadedUrls = [];
    setState(() {
      _isUploading = true;
    });

    try {
      for (File file in _temporaryImageFiles) {
        final fileUrl = await _driveService.uploadFile(file);
        uploadedUrls.add(fileUrl);
      }
    } catch (e) {
      // If there's an error, cleanup any successful uploads
      for (String url in uploadedUrls) {
        try {
          await _driveService.deleteFile(url);
        } catch (e) {
          debugPrint('Error cleaning up after failed upload: $e');
        }
      }
      throw e;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }

    return uploadedUrls;
  }

  // Modify the _saveProfile function to include image uploads
  Future<void> _saveProfile() async {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;

    final String firstName = _firstNameController.text.trim();
    final String lastName = _lastNameController.text.trim();

    if (_calculateDifference(_originalFirstName, firstName) > 2 ||
        _calculateDifference(_originalLastName, lastName) > 2) {
      _showErrorDialog(localizations.nameChangeLimit);
      return;
    }

    if (_formKey.currentState!.validate()) {
      if (_skills.isEmpty ||
          _certifications.isEmpty ||
          _workExperience.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Please add at least one skill, certification, and work experience')),
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


        // Upload all images first
        List<String> uploadedImages = [];
        if (_temporaryImageFiles.isNotEmpty) {
          uploadedImages = await _uploadAllImages();
        }

        final DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);


        // Prepare the profile data with uploaded image URLs
        Map<String, dynamic> profileData = {
          'firstName': firstName,
          'lastName': lastName,
          'basicInfo': {
            'profession': _professionController.text,
            'phone': _phoneController.text,
            'wilaya': selectedWilayaAscii, // Latin name
            'wilaya_arabic': selectedWilayaArabic, // Arabic name
            'commune': selectedCommuneAscii, // Latin name
            'commune_arabic': selectedCommuneArabic, // Arabic name
            'hourlyRate': _hourlyRateController.text,
          },
          'skills': _skills,
          'certifications': _certifications,
          'workExperience': _workExperience,
          'portfolioImages': uploadedImages,
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
            builder: (context) => NavbarPage(
              initialIndex: 3,
            ),
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
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.error),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.okay),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return Padding(
        padding: const EdgeInsets.only(right: 20.0),
        child: CircularProgressIndicator(),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.setupYourProfile,
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
            _buildSectionTitle(localizations.BaicInfo),
            _buildBasicInfoFields(),
            const SizedBox(height: 20),
            _buildSectionTitle(localizations.skills),
            _buildSkillsSection(),
            const SizedBox(height: 20),
            _buildSectionTitle(localizations.workExperience),
            _buildWorkExperienceSection(),
            const SizedBox(height: 20),
            _buildSectionTitle(localizations.certifications),
            _buildCertificationsSection(),
            const SizedBox(height: 20),
            _buildSectionTitle(localizations.portfolio),
            buildPortfolioSection(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(
                localizations.saveProfile,
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

bool isAddingImage = false;
Set<String> deletingImages = {};

// Modify the portfolio section UI to show temporary images
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
          _temporaryImageFiles.isNotEmpty
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _temporaryImageFiles.map((file) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            Image.file(
                              file,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
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
                                  onPressed: () {
                                    setState(() {
                                      _temporaryImageFiles.remove(file);
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
              : const Center(child: Text('No portfolio images selected')),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isUploading 
              ? null 
              : pickNewPortfolioImage,
            child: _isUploading
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




  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;




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
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();

    return Column(
      children: [
        TextFormField(
          controller: _firstNameController,
          decoration: InputDecoration(
            labelText: localizations.firstName,
            border: OutlineInputBorder(),
            labelStyle: GoogleFonts.poppins(),
          ),
          validator: (value) =>
              value!.isEmpty ? localizations.firstNameRequired : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _lastNameController,
          decoration: InputDecoration(
            labelText: localizations.lastName,
            border: OutlineInputBorder(),
            labelStyle: GoogleFonts.poppins(),
          ),
          validator: (value) =>
              value!.isEmpty ? localizations.LastNameRequired : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _professionController,
          decoration: InputDecoration(
            labelText: localizations.profession,
            border: OutlineInputBorder(),
            labelStyle: GoogleFonts.poppins(),
          ),
          validator: (value) =>
              value!.isEmpty ? localizations.professionRequiredError : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: localizations.phone,
            border: OutlineInputBorder(),
            labelStyle: GoogleFonts.poppins(),
          ),
          validator: (value) =>
              value!.isEmpty ? localizations.phoneRequiredError : null,
        ),
        const SizedBox(height: 10),
        const SizedBox(height: 10),
LocationSelectionFields(
  onLocationSelected: (location) {
    if (location != null) {
      setState(() {
        selectedWilayaAscii = location.wilayaNameAscii; // Latin
        selectedWilayaArabic = location.wilayaName;    // Arabic
        selectedCommuneAscii = location.communeNameAscii; // Latin
        selectedCommuneArabic = location.communeName;     // Arabic
      });
    }
  },
),

        const SizedBox(height: 10),
        const SizedBox(height: 10),
        TextFormField(
          controller: _hourlyRateController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: localizations.hourlyRate,
            border: OutlineInputBorder(),
            labelStyle: GoogleFonts.poppins(),
          ),
          validator: (value) =>
              value!.isEmpty ? localizations.hourlyRateRequiredError : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: localizations.aboutMe,
            border: OutlineInputBorder(),
            labelStyle: GoogleFonts.poppins(),
          ),
          validator: (value) =>
              value!.isEmpty ? localizations.fieldRequiredError : null,
        ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _skillController,
                decoration: InputDecoration(
                  labelText: localizations.addSkill,
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
          children: _skills
              .map((skill) => Chip(
                    label: Text(skill, style: GoogleFonts.poppins()),
                    deleteIcon: Icon(Icons.close),
                    onDeleted: () => _removeSkill(skill),
                  ))
              .toList(),
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
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();

    return Column(
      children: [
        TextField(
          controller: _companyController,
          decoration: InputDecoration(
            labelText: localizations.companyName,
            border: OutlineInputBorder(),
            labelStyle: GoogleFonts.poppins(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _positionController,
          decoration: InputDecoration(
            labelText: localizations.position,
            border: OutlineInputBorder(),
            labelStyle: GoogleFonts.poppins(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _durationController,
          decoration: InputDecoration(
            labelText: localizations.duration,
            border: OutlineInputBorder(),
            labelStyle: GoogleFonts.poppins(),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _addWorkExperience,
          child: Text(
            localizations.addWorkExperience,
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
                    Text('Position: ${experience['position'] ?? ''}',
                        style: GoogleFonts.poppins()),
                    Text('Duration: ${experience['duration'] ?? ''}',
                        style: GoogleFonts.poppins()),
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
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _certificationController,
                decoration: InputDecoration(
                  labelText: localizations.skills,
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
          children: _certifications
              .map((certification) => Chip(
                    label: Text(certification, style: GoogleFonts.poppins()),
                    deleteIcon: Icon(Icons.close),
                    onDeleted: () => _removeCertification(certification),
                  ))
              .toList(),
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


}


 

  