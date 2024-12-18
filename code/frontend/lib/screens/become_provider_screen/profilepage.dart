import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/navbar.dart';
import 'package:hanini_frontend/user_role.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class ServiceProviderProfile2 extends StatefulWidget {
  const ServiceProviderProfile2({Key? key}) : super(key: key);

  @override
  _ServiceProviderProfileState createState() => _ServiceProviderProfileState();
}

class _ServiceProviderProfileState extends State<ServiceProviderProfile2> {


  final _formKey = GlobalKey<FormState>();

  // Profile basic info
  final TextEditingController _professionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _hourlyRateController = TextEditingController();

  // Dynamic input lists
  List<String> _skills = [];
  List<String> _certifications = [];
  List<Map<String, String>> _workExperience = [];
  List<File> _portfolioImages = [];

  // Controllers for dynamic inputs
  final TextEditingController _skillController = TextEditingController();
  final TextEditingController _certificationController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  // Image picker
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;

  Future<void> _saveProfile() async {
  if (_formKey.currentState!.validate()) {
    // Validate that at least some lists have entries
    if (_skills.isEmpty || _certifications.isEmpty || _workExperience.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add at least one skill, certification, and work experience')),
      );
      return;
    }

    // Get the current authenticated user
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User is not authenticated')),
      );
      return;
    }

    // Reference to Firestore document
    final DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

    // Prepare the profile data
    Map<String, dynamic> profileData = {
      'basicInfo': {
        'profession': _professionController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'hourlyRate': _hourlyRateController.text,
      },
      'skills': _skills,
      'certifications': _certifications,
      'workExperience': _workExperience,
      'portfolioImages': _portfolioImages.map((file) => file.path).toList(),
    };

    // Save profile image path if exists
    if (_profileImage != null) {
      profileData['profileImage'] = _profileImage!.path;
    }

    try {
      // Update the Firestore document with the profile data
      await userDoc.update(profileData);
      await userDoc.update({'rating': 0.0,});
      await userDoc.update({'isProvider': true,});
      await userDoc.update({'aboutMe': _descriptionController.text,});

      // Optional: Navigate to the NavbarPage with provider role
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NavbarPage(userRole: UserRole.provider),
        ),
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      // Handle any errors during Firestore update
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }
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

            _buildPortfolioImagesSection(),
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
      child: GestureDetector(
        onTap: _pickProfileImage,
        child: CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[200],
          backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
          child: _profileImage == null 
            ? Icon(Icons.camera_alt, color: Colors.grey[800], size: 40)
            : null,
        ),
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Widget _buildBasicInfoFields() {
    return Column(
      children: [
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

 Widget _buildPortfolioImagesSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Section title with description
      Text(
        'Portfolio Images',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      Text(
        'Showcase your best work and projects',
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      const SizedBox(height: 15),

      // Add Portfolio Images Button
      Center(
        child: ElevatedButton.icon(
          onPressed: _pickPortfolioImages,
          icon: Icon(Icons.add_photo_alternate),
          label: Text(
            'Add Portfolio Images',
            style: GoogleFonts.poppins(),
          ),
        )),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _portfolioImages.map((image) {
            return Stack(
              alignment: Alignment.topRight,
              children: [
                Image.file(
                  image,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removePortfolioImage(image),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _pickPortfolioImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _portfolioImages.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  void _removePortfolioImage(File image) {
    setState(() {
      _portfolioImages.remove(image);
    });
  }


}

         
