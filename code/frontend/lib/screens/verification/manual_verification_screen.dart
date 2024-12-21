import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class ManualVerificationScreen extends StatefulWidget {
  @override
  _ManualVerificationScreenState createState() => _ManualVerificationScreenState();
}

class _ManualVerificationScreenState extends State<ManualVerificationScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _idImage;
  XFile? _faceImage;
  bool _isUploading = false;

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

      final idImageUrl = await _uploadImageToStorage(_idImage!, 'id_images/${user.uid}.jpg');
      final faceImageUrl = await _uploadImageToStorage(_faceImage!, 'face_images/${user.uid}.jpg');

      await FirebaseFirestore.instance.collection('verification_requests').doc(user.uid).set({
        'userId': user.uid,
        'name': user.displayName ?? 'Anonymous',
        'email': user.email ?? 'No email',
        'idImageURL': idImageUrl,
        'faceImageURL': faceImageUrl,
        'timestamp': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification request sent successfully')),
      );

      setState(() {
        _idImage = null;
        _faceImage = null;
        _isUploading = false;
      });
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

  Future<String> _uploadImageToStorage(XFile image, String path) async {
    try {
      final Reference storageRef = FirebaseStorage.instance.ref().child(path);
      final UploadTask uploadTask = storageRef.putFile(File(image.path));
      final TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image to storage: $e');
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
              child: Text('Take Picture', style: GoogleFonts.poppins()),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.gallery, isIdImage),
              child: Text('Choose from Gallery', style: GoogleFonts.poppins()),
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
