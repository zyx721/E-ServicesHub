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
      appBar: AppBar(
        title: Text(
          'Manual Verification',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload your ID and face pictures for manual verification.',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            const SizedBox(height: 20),
            _buildImagePicker('ID Image', _idImage, true),
            const SizedBox(height: 20),
            _buildImagePicker('Face Image', _faceImage, false),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadImages,
                child: _isUploading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Send Verification Request', style: GoogleFonts.poppins()),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(String label, XFile? image, bool isIdImage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.camera, isIdImage),
              child: Text('Take Picture', style:TextStyle(fontSize: 13)),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.gallery, isIdImage),
              child: Text('Choose from Gallery', style:TextStyle(fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (image != null)
          Image.file(
            File(image.path),
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
      ],
    );
  }
}

