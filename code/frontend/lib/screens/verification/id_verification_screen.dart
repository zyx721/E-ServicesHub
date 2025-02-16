import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:hanini_frontend/screens/become_provider_screen/SetProviderProfile.dart';
import 'package:hanini_frontend/screens/verification/manual_verification_screen.dart'; // Import ManualVerificationScreen
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'face_verification_screen.dart'; // Replace with your actual face comparison screen import
import 'package:hanini_frontend/localization/app_localization.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart'; // Import Lottie package
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image/image.dart' as img; // Import the image package for image processing

class RealTimeDetection extends StatefulWidget {
  final List<CameraDescription> cameras;
  RealTimeDetection({required this.cameras});

  @override
  _RealTimeDetectionState createState() => _RealTimeDetectionState();
}

class _RealTimeDetectionState extends State<RealTimeDetection> with TickerProviderStateMixin {
  late CameraController _cameraController;
  XFile? _capturedImage;
  bool _isUploading = false;
  String? _errorMessage;
  late AnimationController _flashAnimationController;
  late Animation<double> _flashAnimation;
  bool _isCapturing = false;
  bool _isBackIdCaptured = false; // Flag to check if back of ID is captured
  bool _showFrontIdMessage = false; // Flag to show front ID message
  bool _showBackIdMessage = false; // Flag to show back ID message
  bool _showFrontIdAnimation = false; // Flag to show front ID animation
  bool _showBackIdAnimation = false; // Flag to show back ID animation
  late AnimationController _flipAnimationController;
  bool _showFlipAnimation = false;
  double _frozenProgress = 0.3; // Start at 30% for initial frame
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    
    // Initialize animation controllers with longer duration
    _flashAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _flipAnimationController = AnimationController(
      duration: const Duration(seconds: 2), // Longer duration for smoother animation
      vsync: this,
    );

    // Add scale animation
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _flipAnimationController,
        curve: Curves.easeInOutBack, // Smoother curve
      ),
    );

    _flashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _flashAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Show and freeze initial animation
    setState(() {
      _showFlipAnimation = true;
      _frozenProgress = 0.1;
      _flipAnimationController.value = _frozenProgress;
    });
  }

  Future<void> _initializeCamera() async {
    _cameraController = CameraController(
      widget.cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController.initialize();
      await _cameraController.setFlashMode(FlashMode.auto);
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      _showError("Camera initialization failed");
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
      });
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
        }
      });
    }
  }

  Future<void> _captureImage() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      // Haptic feedback
      HapticFeedback.mediumImpact();
      
      // Flash animation
      _flashAnimationController.forward().then((_) {
        _flashAnimationController.reverse();
      });

      final XFile image = await _cameraController.takePicture();
      setState(() {
        _capturedImage = image;
      });
    } catch (e) {
      _showError("Failed to capture image");
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  Future<void> _uploadCapturedImage() async {
    if (_capturedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(_isBackIdCaptured
            ? 'https://polite-schools-ask.loca.lt/upload-back-id/'
            : 'https://polite-schools-ask.loca.lt/upload-image/'),
      );

      request.files.add(await http.MultipartFile.fromPath('file', _capturedImage!.path));
      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(responseData.body);
        if (_isBackIdCaptured) {
          if (responseBody["stop_capture"]) {
            setState(() {
              _showBackIdAnimation = true;
              _showFlipAnimation = false; // Hide flip animation
            });
            await Future.delayed(Duration(seconds: 2));
            await _saveProviderInfo(responseBody["first_name"], responseBody["last_name"]);
            
            // Add null check and error handling for compare_id
            final compareId = responseBody["compare_id"];
            if (compareId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FaceCompareScreen(compareId: compareId),
                ),
              );
            } else {
              _showError("Error: Missing compare ID");
            }
          } else {
            _showError(responseBody["message"]);
          }
        } else {
          if (responseBody["stop_capture"]) {
            setState(() {
              _isBackIdCaptured = true;
              _capturedImage = null;
              _showFrontIdMessage = false;
              _showBackIdMessage = true;
              _showFrontIdAnimation = true;
              // Show and freeze flip animation at final frame
              _handleFlipAnimation(freeze: true, freezeProgress: 1.0);
            });
            await Future.delayed(Duration(seconds: 2));
            setState(() {
              _showFrontIdAnimation = false;
            });
          } else {
            _showError(responseBody["message"]);
          }
        }
      } else {
        _showError("Upload failed. Please try again.");
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      _showError("Network error. Please check your connection. Error: $e"); // Add error details
    }
  }

  Future<void> _saveProviderInfo(String firstName, String lastName) async {
    try {
      // Get the current user's UID
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError("User not authenticated.");
        return;
      }

      // Reference Firestore document
      final DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Update Firestore with the new information
      await userDoc.update({
        'firstName': firstName,
        'lastName': lastName,
        'isSTEP_1': true,
      });
    } catch (e) {
      _showError("Failed to save data: $e");
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _flashAnimationController.dispose();
    _flipAnimationController.dispose();
    super.dispose();
  }

  Widget _buildCameraOverlay() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.width * 0.6,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _cameraController.value.isInitialized
          ? Stack(
              children: [
                Transform.scale(
                  scale: 1.1,
                  child: _capturedImage == null
                      ? CameraPreview(_cameraController)
                      : Image.file(
                          File(_capturedImage!.path),
                          fit: BoxFit.cover,
                        ),
                ),
                if (_capturedImage == null) _buildCameraOverlay(),
                // Show flip animation above camera preview
                if (_showFlipAnimation)
                  _buildLottieAnimation('assets/animation/flip.json', size: 300),
                AnimatedBuilder(
                  animation: _flashAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _flashAnimation.value,
                      child: Container(
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                SafeArea(
                  child: Column(
                    children: [
                      _buildAppBar(appLocalizations),
                      Spacer(),
                      _buildBottomControls(appLocalizations),
                      SizedBox(height: 32),
                    ],
                  ),
                ),
                if (_isUploading)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Uploading...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_showFrontIdMessage)
                  _buildMessageOverlay("Please capture the back of the ID."),
                if (_showBackIdMessage)
                  _buildMessageOverlay("Back ID captured. Proceeding..."),
                if (_errorMessage != null)
                  _buildMessageOverlay(_errorMessage!),
                if (_showFrontIdAnimation)
                  _buildLottieAnimation('assets/animation/flip.json', size: 300),
                if (_showBackIdAnimation)
                  _buildLottieAnimation('assets/animation/id_aproved.json', size: 200),
              ],
            )
          : Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
    );
  }

  Widget _buildMessageOverlay(String message) {
    return Positioned(
      bottom: 150,
      left: 16,
      right: 16,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message,
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildLottieAnimation(String assetPath, {double size = 200}) {
    if (assetPath.contains('flip.json') && _showFlipAnimation) {
      return Positioned(
        top: MediaQuery.of(context).size.height * 0.08, // Higher position (8% from top)
        left: 0,
        right: 0,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Center(
                child: Lottie.asset(
                  assetPath,
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                  controller: _flipAnimationController,
                  onLoaded: (composition) {
                    _flipAnimationController.value = _frozenProgress;
                  },
                  frameRate: FrameRate.max, // Smoother frame rate
                ),
              ),
            );
          },
        ),
      );
    }
    return Center(
      child: Lottie.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.fill,
        frameRate: FrameRate.max,
      ),
    );
  }

  Widget _buildAppBar(AppLocalizations appLocalizations) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            appLocalizations.realTimeDetection,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: Icon(Icons.help_outline, color: Colors.white),
            onPressed: () => _showSupportDialog(appLocalizations),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(AppLocalizations appLocalizations) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: _capturedImage == null
          ? GestureDetector(
              onTap: _captureImage,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.refresh,
                  label: appLocalizations.retake,
                  color: Colors.orange,
                  onPressed: () {
                    setState(() {
                      _capturedImage = null;
                    });
                  },
                ),
                _buildActionButton(
                  icon: Icons.check,
                  label: _isBackIdCaptured
                      ? appLocalizations.uploadLabel
                      : "Upload Front ID",
                  color: Colors.green,
                  onPressed: _uploadCapturedImage,
                ),
              ],
            ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSupportDialog(AppLocalizations appLocalizations) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  appLocalizations.support,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  appLocalizations.supportMessage,
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        appLocalizations.ok,
                        style: TextStyle(fontSize: 13.5),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ManualVerificationScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        appLocalizations.manualVerification ,
                        style: TextStyle(fontSize: 11,color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Add this method to control flip animation
  void _handleFlipAnimation({bool freeze = false, double? freezeProgress}) {
    setState(() {
      _showFlipAnimation = true;
      if (freeze && freezeProgress != null) {
        _frozenProgress = freezeProgress;
        _flipAnimationController.animateTo(
          _frozenProgress,
          duration: Duration(seconds: 1),
          curve: Curves.easeInOutCubic, // Smooth curve for transition
        );
      } else {
        _flipAnimationController.forward();
      }
    });
  }
}