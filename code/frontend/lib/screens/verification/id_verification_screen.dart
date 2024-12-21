import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:hanini_frontend/screens/verification/manual_verification_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'face_verification_screen.dart';
import 'package:hanini_frontend/localization/app_localization.dart';
import 'package:flutter/services.dart';

class RealTimeDetection extends StatefulWidget {
  final List<CameraDescription> cameras;

  RealTimeDetection({required this.cameras});

  @override
  _RealTimeDetectionState createState() => _RealTimeDetectionState();
}

class _RealTimeDetectionState extends State<RealTimeDetection> with SingleTickerProviderStateMixin {
  late CameraController _cameraController;
  XFile? _capturedImage;
  bool _isUploading = false;
  String? _errorMessage;
  late AnimationController _flashAnimationController;
  late Animation<double> _flashAnimation;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _flashAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _flashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _flashAnimationController,
        curve: Curves.easeInOut,
      ),
    );
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

  Future<void> _takePicture() async {
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

  Future<void> _uploadImage() async {
    if (_capturedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://polite-schools-ask.loca.lt/upload-image/'),
      );

      request.files.add(await http.MultipartFile.fromPath('file', _capturedImage!.path));
      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(responseData.body);
        if (responseBody["stop_capture"]) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FaceCompareScreen()),
          );
        } else {
          _showError(responseBody["message"]);
        }
      } else {
        _showError("Upload failed. Please try again.");
      }
    } catch (e) {
      _showError("Network error. Please check your connection.");
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _flashAnimationController.dispose();
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
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.width * 0.8,
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
                if (_errorMessage != null)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 70,
                    left: 16,
                    right: 16,
                    child: TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 300),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, -20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            )
          : Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
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
              onTap: _takePicture,
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
                  label: appLocalizations.upload,
                  color: Colors.green,
                  onPressed: _uploadImage,
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
            Icon(icon, color: const Color.fromARGB(255, 207, 103, 103)),
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
                        style: TextStyle(fontSize: 16),
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
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Manual Verification',
                        style: TextStyle(fontSize: 16),
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
}
