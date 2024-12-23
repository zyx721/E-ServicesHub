import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:hanini_frontend/screens/become_provider_screen/SetProviderProfile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lottie/lottie.dart'; // Import the Lottie package
import 'package:hanini_frontend/localization/app_localization.dart';
import 'package:image/image.dart' as img; // Import the image package for image processing
import 'package:path_provider/path_provider.dart'; // Import the path_provider package for file storage
import 'dart:io'; // Import the dart:io package for file operations
import 'package:flutter/services.dart'; // Import the services package for rootBundle

class FaceCompareScreen extends StatefulWidget {
  @override
  _FaceCompareScreenState createState() => _FaceCompareScreenState();
}

class _FaceCompareScreenState extends State<FaceCompareScreen> {
  CameraController? _cameraController;
  List<CameraDescription> cameras = [];
  bool _isLoading = false;
  String _comparisonResult = "";
  Color _resultColor = Colors.black;
  bool _showAnimation = false; // Flag to trigger animation
  XFile? _firstImage;
  XFile? _secondImage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      _cameraController = CameraController(
        cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front),
        ResolutionPreset.high,
      );

      await _cameraController?.initialize();
      setState(() {});
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  Future<void> _captureImage(bool isFirstImage) async {
    try {
      final image = await _cameraController!.takePicture();
      setState(() {
        if (isFirstImage) {
          _firstImage = image;
        } else {
          _secondImage = image;
        }
      });
    } catch (e) {
      print("Error capturing image: $e");
    }
  }

  Future<void> _submitFaceImages() async {
    if (_firstImage == null || _secondImage == null) {
      setState(() {
        _comparisonResult = "Please capture both images.";
        _resultColor = Colors.redAccent;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _comparisonResult = "";
      _showAnimation = false; // Reset animation on new picture
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://polite-schools-ask.loca.lt/compare-face/'), // Ensure this URL is correct
      );

      request.files.add(await http.MultipartFile.fromPath('file1', _firstImage!.path));
      request.files.add(await http.MultipartFile.fromPath('file2', _secondImage!.path));
      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final responseBody = json.decode(responseData.body);
        setState(() {
          _comparisonResult = responseBody['message'];
          _resultColor = (_comparisonResult.trim() == "Faces match!")
              ? Colors.greenAccent
              : Colors.redAccent;

          // Show animation only when faces match
          if (_comparisonResult.trim() == "Faces match!") {
            _showAnimation = true;
            // Delay transition to next screen to allow the animation to play
            Future.delayed(Duration(seconds: 1), () {
              _navigateToNextScreen();
            });
          }
        });
      } else {
        setState(() {
          _comparisonResult = "Failed to compare faces.";
          _resultColor = Colors.redAccent;
        });
      }
    } catch (e) {
      print("Error submitting face images: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to navigate to the next screen with a smooth transition
  void _navigateToNextScreen() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          SetProviderProfile(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(
            1.0, 0.0); // Start from the right, but less aggressive than before
        const end = Offset.zero; // End at the center
        const curve = Curves.easeInOut;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
    ));
  }

  void _showSupportDialog() {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(appLocalizations.support),
          content: Text(appLocalizations.faceVerificationSupportMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(appLocalizations.ok),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(64.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF3949AB), // Indigo 600
                Color(0xFF1E88E5), // Blue 600
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              appLocalizations.faceVerification,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.help_outline,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: _showSupportDialog,
              ),
            ],
          ),
        ),
      ),
      body: _cameraController?.value.isInitialized == true
          ? Stack(
              children: [
                Transform.scale(
                  scaleX: -1.0,
                  child: CameraPreview(_cameraController!),
                ),
                Center(
                  child: CustomPaint(
                    size: Size(280, 350),
                    painter: FaceGuidelinePainter(),
                  ),
                ),
                if (_comparisonResult.isNotEmpty)
                  Positioned(
                    bottom: 100,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _resultColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _comparisonResult,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                if (_showAnimation)
                  Positioned.fill(
                    child: Center(
                      child: Lottie.asset(
                        'assets/animation/animation3.json', // Path to your animation file
                        width: 150,
                        height: 150,
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: Column(
                    children: [
                      if (_firstImage == null)
                        ElevatedButton(
                          onPressed: _isLoading ? null : () => _captureImage(true),
                          child: Text(
                            "Capture With Mouth Closed",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      if (_firstImage != null && _secondImage == null)
                        ElevatedButton(
                          onPressed: _isLoading ? null : () => _captureImage(false),
                          child: Text(
                            "Capture With Mouth Open",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      if (_firstImage != null)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.file(
                            File(_firstImage!.path),
                            width: 100,
                            height: 100,
                          ),
                        ),
                      if (_secondImage != null)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.file(
                            File(_secondImage!.path),
                            width: 100,
                            height: 100,
                          ),
                        ),
                      if (_firstImage != null && _secondImage != null)
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submitFaceImages,
                          child: Text(
                            "Submit Images",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      if (_firstImage != null || _secondImage != null)
                        ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _firstImage = null;
                                    _secondImage = null;
                                    _comparisonResult = "";
                                  });
                                },
                          child: Text(
                            "Retake Images",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            )
          : Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3949AB)),
              ),
            ),
    );
  }
}

class FaceGuidelinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color.fromARGB(255, 75, 0, 31)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Paint dashedPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    // Draw outer face oval - modified to be slightly V-shaped
    final Path facePath = Path();
    final double ovalWidth = size.width * 0.85;
    final double ovalHeight = size.height * 0.8;

    // Create natural V shape using cubic bezier curves
    facePath.moveTo(centerX, centerY - ovalHeight / 2);

    // Top right curve (naturally rounded)
    facePath.cubicTo(
        centerX + ovalWidth * 0.4,
        centerY - ovalHeight / 2,
        centerX + ovalWidth / 2,
        centerY - ovalHeight * 0.3,
        centerX + ovalWidth / 2,
        centerY - ovalHeight * 0.1);

    // Bottom right curve (gentle V-shape)
    facePath.cubicTo(
        centerX + ovalWidth / 2,
        centerY + ovalHeight * 0.25,
        centerX + ovalWidth * 0.25,
        centerY + ovalHeight * 0.4,
        centerX,
        centerY + ovalHeight / 2 // More natural bottom point
        );

    // Bottom left curve (gentle V-shape)
    facePath.cubicTo(
        centerX - ovalWidth * 0.25,
        centerY + ovalHeight * 0.4,
        centerX - ovalWidth / 2,
        centerY + ovalHeight * 0.25,
        centerX - ovalWidth / 2,
        centerY - ovalHeight * 0.1);

    // Top left curve (naturally rounded)
    facePath.cubicTo(
        centerX - ovalWidth / 2,
        centerY - ovalHeight * 0.3,
        centerX - ovalWidth * 0.4,
        centerY - ovalHeight / 2,
        centerX,
        centerY - ovalHeight / 2);

    canvas.drawPath(facePath, paint);

    // Draw inner guidelines with dashed lines
    // Horizontal center line
    drawDashedLine(
      canvas,
      Offset(centerX - ovalWidth * 0.35, centerY),
      Offset(centerX + ovalWidth * 0.35, centerY),
      dashedPaint,
    );

    // Vertical center line
    drawDashedLine(
      canvas,
      Offset(centerX, centerY - ovalHeight * 0.3),
      Offset(centerX, centerY + ovalHeight * 0.3),
      dashedPaint,
    );

    // Draw eye level guideline
    final double eyeLevel = centerY - ovalHeight * 0.15;
    drawDashedLine(
      canvas,
      Offset(centerX - ovalWidth * 0.3, eyeLevel),
      Offset(centerX + ovalWidth * 0.3, eyeLevel),
      dashedPaint,
    );

    // Add corner markers
    final double markerSize = 15.0;
    paint.strokeWidth = 3.0;

    // Top left corner markers
    canvas.drawLine(
      Offset(centerX - ovalWidth * 0.4, centerY - ovalHeight * 0.35),
      Offset(
          centerX - ovalWidth * 0.4 + markerSize, centerY - ovalHeight * 0.35),
      paint,
    );
    canvas.drawLine(
      Offset(centerX - ovalWidth * 0.4, centerY - ovalHeight * 0.35),
      Offset(
          centerX - ovalWidth * 0.4, centerY - ovalHeight * 0.35 + markerSize),
      paint,
    );

    // Top right corner markers
    canvas.drawLine(
      Offset(centerX + ovalWidth * 0.4, centerY - ovalHeight * 0.35),
      Offset(
          centerX + ovalWidth * 0.4 - markerSize, centerY - ovalHeight * 0.35),
      paint,
    );
    canvas.drawLine(
      Offset(centerX + ovalWidth * 0.4, centerY - ovalHeight * 0.35),
      Offset(
          centerX + ovalWidth * 0.4, centerY - ovalHeight * 0.35 + markerSize),
      paint,
    );

    // Bottom left corner markers
    canvas.drawLine(
      Offset(centerX - ovalWidth * 0.4, centerY + ovalHeight * 0.35),
      Offset(
          centerX - ovalWidth * 0.4 + markerSize, centerY + ovalHeight * 0.35),
      paint,
    );
    canvas.drawLine(
      Offset(centerX - ovalWidth * 0.4, centerY + ovalHeight * 0.35),
      Offset(
          centerX - ovalWidth * 0.4, centerY + ovalHeight * 0.35 - markerSize),
      paint,
    );

    // Bottom right corner markers
    canvas.drawLine(
      Offset(centerX + ovalWidth * 0.4, centerY + ovalHeight * 0.35),
      Offset(
          centerX + ovalWidth * 0.4 - markerSize, centerY + ovalHeight * 0.35),
      paint,
    );
    canvas.drawLine(
      Offset(centerX + ovalWidth * 0.4, centerY + ovalHeight * 0.35),
      Offset(
          centerX + ovalWidth * 0.4, centerY + ovalHeight * 0.35 - markerSize),
      paint,
    );
  }

  void drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final Path path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);

    final Path dashPath = Path();
    const double dashWidth = 10.0;
    const double dashSpace = 5.0;
    double distance = 0.0;

    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth;
        distance += dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
