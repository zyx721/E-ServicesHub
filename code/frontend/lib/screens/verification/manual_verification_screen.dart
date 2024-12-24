import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as path;
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

class ManualVerificationScreen extends StatefulWidget {
  @override
  _ManualVerificationScreenState createState() => _ManualVerificationScreenState();
}

class _ManualVerificationScreenState extends State<ManualVerificationScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _idImage;
  XFile? _faceImage;
  bool _isUploading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleDriveService _driveService = GoogleDriveService();

  Future<void> _pickImage(ImageSource source, bool isIdImage) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    setState(() {
      if (isIdImage) {
        _idImage = pickedFile;
      } else {
        _faceImage = pickedFile;
      }
    });
  }

  Future<void> _uploadImages() async {
    if (_idImage == null || _faceImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both ID and face images')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to upload images')),
        );
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Upload both images to Google Drive
      final idImageUrl = await _uploadImageToDrive(_idImage!, 'id_${user.uid}${path.extension(_idImage!.path)}');
      final faceImageUrl = await _uploadImageToDrive(_faceImage!, 'face_${user.uid}${path.extension(_faceImage!.path)}');

      // Store the verification request in Firestore
      await FirebaseFirestore.instance.collection('verification_requests').doc(user.uid).set({
        'userId': user.uid,
        'name': user.displayName ?? 'Anonymous',
        'email': user.email ?? 'No email',
        'idImageURL': idImageUrl,
        'faceImageURL': faceImageUrl,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Update user profile
      Map<String, dynamic> profileData = {'isWaiting': true};
      await _firestore.collection('users').doc(user.uid).update(profileData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification request sent successfully')),
      );

      setState(() {
        _idImage = null;
        _faceImage = null;
        _isUploading = false;
      });

      Navigator.of(context).pushNamedAndRemoveUntil(
      '/navbar', // Your navbar route
      (Route<dynamic> route) => false, // This removes all previous routes
    );
    
    } catch (e) {
      debugPrint('Error uploading images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send verification request. Please try again. Error: $e')),
      );
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<String> _uploadImageToDrive(XFile image, String fileName) async {
    try {
      final file = File(image.path);
      return await _driveService.uploadFile(file);
    } catch (e) {
      debugPrint('Error uploading image to Google Drive: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFF6B46C1),
        title: Text(
          'Verify Your Identity',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFF6B46C1),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: EdgeInsets.all(20),
              child: Text(
                'Please provide clear photos of your ID and face for verification',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildImageUploadCard(
                    'ID Document',
                    'Upload a clear photo of your government-issued ID',
                    _idImage,
                    true,
                    Icons.credit_card,
                  ),
                  SizedBox(height: 20),
                  _buildImageUploadCard(
                    'Selfie Photo',
                    'Take a clear photo of your face',
                    _faceImage,
                    false,
                    Icons.face,
                  ),
                  SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _uploadImages,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6B46C1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 2,
                      ),
                      child: _isUploading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Submit for Verification',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
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

  Widget _buildImageUploadCard(
    String title,
    String description,
    XFile? image,
    bool isIdImage,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Color(0xFF6B46C1), size: 24),
              SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Color(0xFF718096),
            ),
          ),
          SizedBox(height: 20),
          if (image != null)
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: FileImage(File(image.path)),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Color(0xFFF7FAFC),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Color(0xFFE2E8F0),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 40,
                    color: Color(0xFF6B46C1),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No image selected',
                    style: GoogleFonts.poppins(
                      color: Color(0xFF718096),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera, isIdImage),
                  icon: Icon(Icons.camera_alt, size: 20),
                  label: Text('Camera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF9F7AEA),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery, isIdImage),
                  icon: Icon(Icons.photo_library, size: 20),
                  label: Text('Gallery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFB794F4),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }}

