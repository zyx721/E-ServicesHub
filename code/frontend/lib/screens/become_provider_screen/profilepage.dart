import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/navbar.dart';
import 'package:hanini_frontend/user_role.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class ServiceProviderProfile2 extends StatefulWidget {
  const ServiceProviderProfile2({Key? key}) : super(key: key);

  @override
  _ServiceProviderProfileState createState() => _ServiceProviderProfileState();
}

class _ServiceProviderProfileState extends State<ServiceProviderProfile2> {
  final _formKey = GlobalKey<FormState>();
  
  // Profile basic info
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _professionController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // Hourly rate
  final TextEditingController _hourlyRateController = TextEditingController();

  // Dynamic input lists
  List<String> _skills = [];
  List<String> _certifications = [];
  List<Map<String, String>> _workExperience = [];
  List<File> _portfolioImages = [];

  // Skill, certification, and work experience input controllers
  final TextEditingController _skillController = TextEditingController();
  final TextEditingController _certificationController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  // Image picker
  final ImagePicker _picker = ImagePicker();

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
            // Profile Image
            _buildProfileImageUpload(),
            const SizedBox(height: 20),

            // Basic Info Section
            _buildSectionTitle('Basic Information'),
            _buildBasicInfoFields(),
            const SizedBox(height: 20),

            // Skills Section
            _buildSectionTitle('Skills'),
            _buildSkillsSection(),
            const SizedBox(height: 20),

            // Work Experience Section
            _buildSectionTitle('Work Experience'),
            _buildWorkExperienceSection(),
            const SizedBox(height: 20),

            // Certifications Section
            _buildSectionTitle('Certifications'),
            _buildCertificationsSection(),
            const SizedBox(height: 20),

            // Portfolio Images
            _buildSectionTitle('Portfolio Images'),
            _buildPortfolioImagesSection(),
            const SizedBox(height: 20),

            // Save Profile Button
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

  File? _profileImage;
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
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
            labelStyle: GoogleFonts.poppins(),
          ),
          validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
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
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
            labelStyle: GoogleFonts.poppins(),
          ),
          validator: (value) => value!.isEmpty || !value.contains('@') 
            ? 'Please enter a valid email' 
            : null,
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
        // Company input
        TextField(
          controller: _companyController,
          decoration: InputDecoration(
            labelText: 'Company Name',
            border: OutlineInputBorder(),
            labelStyle: GoogleFonts.poppins(),
          ),
        ),
        const SizedBox(height: 10),
        // Position input
        TextField(
          controller: _positionController,
          decoration: InputDecoration(
            labelText: 'Position',
            border: OutlineInputBorder(),
            labelStyle: GoogleFonts.poppins(),
          ),
        ),
        const SizedBox(height: 10),
        // Duration input
        TextField(
          controller: _durationController,
          decoration: InputDecoration(
            labelText: 'Duration (e.g., 2015 - Present)',
            border: OutlineInputBorder(),
            labelStyle: GoogleFonts.poppins(),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _addWorkExperience,
          icon: Icon(Icons.add),
          label: Text('Add Work Experience', style: GoogleFonts.poppins()),
        ),
        const SizedBox(height: 10),
        // Display added work experiences
        ..._workExperience.map((exp) => ListTile(
          title: Text(exp['company'] ?? ''),
          subtitle: Text('${exp['position'] ?? ''} | ${exp['duration'] ?? ''}'),
          trailing: IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () => _removeWorkExperience(exp),
          ),
        )).toList(),
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
        // Clear controllers
        _companyController.clear();
        _positionController.clear();
        _durationController.clear();
      });
    }
  }

  void _removeWorkExperience(Map<String, String> exp) {
    setState(() {
      _workExperience.remove(exp);
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
          children: _certifications.map((cert) => Chip(
            label: Text(cert, style: GoogleFonts.poppins()),
            deleteIcon: Icon(Icons.close),
            onDeleted: () => _removeCertification(cert),
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

  void _removeCertification(String cert) {
    setState(() {
      _certifications.remove(cert);
    });
  }

  Widget _buildPortfolioImagesSection() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _pickPortfolioImages,
          icon: Icon(Icons.add_photo_alternate),
          label: Text('Add Portfolio Images', style: GoogleFonts.poppins()),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _portfolioImages.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _portfolioImages[index],
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.red.withOpacity(0.7),
                      child: IconButton(
                        icon: Icon(Icons.close, size: 15, color: Colors.white),
                        onPressed: () => _removePortfolioImage(index),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _pickPortfolioImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    setState(() {
      _portfolioImages.addAll(
        pickedFiles.map((file) => File(file.path)).toList()
      );
    });
  }

  void _removePortfolioImage(int index) {
    setState(() {
      _portfolioImages.removeAt(index);
    });
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // Validate that at least some lists have entries
      if (_skills.isEmpty || _certifications.isEmpty || _workExperience.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please add at least one skill, certification, and work experience')),
        );
        return;
      }

      // Prepare profile data
      Map<String, dynamic> profileData = {
        'basicInfo': {
          'name': _nameController.text,
          'profession': _professionController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
          'hourlyRate': _hourlyRateController.text,
          'description': _descriptionController.text,
        },
        'skills': _skills,
        'certifications': _certifications,
        'workExperience': _workExperience,
        'portfolioImages': _portfolioImages.map((file) => file.path).toList(),
      };

      // Save profile image path
      if (_profileImage != null) {
        profileData['profileImage'] = _profileImage!.path;
      }

      try {
        // Get the application documents directory
        final directory = await getApplicationDocumentsDirectory();
        
        // Create a file for storing the profile data
        final file = File('${directory.path}/service_provider_profile.json');
        
        // Write the profile data to the JSON file
        await file.writeAsString(json.encode(profileData));

        // Navigate to NavbarPage with provider role
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NavbarPage(userRole: UserRole.provider)
          )
        );

        // Optional: Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile saved successfully!')),
        );
      } catch (e) {
        // Handle any errors during file saving
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    }
  }

  // Optional: Method to load saved profile data
  Future<Map<String, dynamic>?> _loadSavedProfile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/service_provider_profile.json');
      
      if (await file.exists()) {
        String contents = await file.readAsString();
        return json.decode(contents);
      }
    } catch (e) {
      print('Error loading profile: $e');
    }
    return null;
  }

  // You might want to add this method to pre-fill the form if a profile exists
  @override
  void initState() {
    super.initState();
    _loadSavedProfile().then((savedProfile) {
      if (savedProfile != null) {
        // Pre-fill form fields
        _nameController.text = savedProfile['basicInfo']['name'] ?? '';
        _professionController.text = savedProfile['basicInfo']['profession'] ?? '';
        _emailController.text = savedProfile['basicInfo']['email'] ?? '';
        _phoneController.text = savedProfile['basicInfo']['phone'] ?? '';
        _addressController.text = savedProfile['basicInfo']['address'] ?? '';
        _hourlyRateController.text = savedProfile['basicInfo']['hourlyRate'] ?? '';
        _descriptionController.text = savedProfile['basicInfo']['description'] ?? '';

        // Restore skills
        setState(() {
          _skills = List<String>.from(savedProfile['skills'] ?? []);
        });

        // Restore certifications
        setState(() {
          _certifications = List<String>.from(savedProfile['certifications'] ?? []);
        });

        // Restore work experience
        setState(() {
          _workExperience = List<Map<String, String>>.from(
            (savedProfile['workExperience'] ?? []).map<Map<String, String>>(
              (exp) => Map<String, String>.from(exp)
            )
          );
        });

        // Restore profile image
        if (savedProfile['profileImage'] != null) {
          setState(() {
            _profileImage = File(savedProfile['profileImage']);
          });
        }

        // Restore portfolio images
        if (savedProfile['portfolioImages'] != null) {
          setState(() {
            _portfolioImages = (savedProfile['portfolioImages'] as List)
              .map((path) => File(path))
              .toList();
          });
        }
      }
    });
  }
}