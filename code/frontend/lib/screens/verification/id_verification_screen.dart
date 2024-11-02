import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FaceCompareScreen extends StatefulWidget {
  @override
  _FaceCompareScreenState createState() => _FaceCompareScreenState();
}

class _FaceCompareScreenState extends State<FaceCompareScreen> {
  CameraController? _cameraController;
  List<CameraDescription> cameras = [];
  bool _isLoading = false; // Track loading state
  String _comparisonResult = ""; // Track comparison result message
  Color _resultColor = Colors.black; // Track result message color

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
        ResolutionPreset.high, // Set to high resolution for better quality
      );

      await _cameraController?.initialize();
      setState(() {});
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  Future<void> _startFaceDetection() async {
    if (_isLoading) return; // Prevent multiple clicks

    setState(() {
      _isLoading = true; // Start loading
      _comparisonResult = ""; // Clear previous result
    });

    try {
      // Capture image from the camera
      final image = await _cameraController!.takePicture();
      final response = await _submitFaceImage(image.path);

      if (response != null) {
        setState(() {
          _comparisonResult = response['message'];
          // Update the result color based on the comparison
          _resultColor = (_comparisonResult.trim() == "Faces match!")
              ? Colors.green
              : Colors.red;
        });
      }
    } catch (e) {
      print("Error capturing image: $e");
    } finally {
      setState(() {
        _isLoading = false; // End loading
      });
    }
  }

  Future<Map<String, dynamic>?> _submitFaceImage(String imagePath) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.172.216:8000/compare-face/'),
    );

    request.files.add(await http.MultipartFile.fromPath('file', imagePath));

    try {
      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        return json.decode(responseData.body);
      } else {
        print("Failed to submit face image: ${response.statusCode}");
      }
    } catch (e) {
      print("Error submitting face image: $e");
    }

    return null; // Return null in case of error
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Real-Time Face Detection',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.greenAccent, // Modern color for AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_cameraController?.value.isInitialized == true)
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5, // Decreased blur radius
                        offset: Offset(0, 2), // Adjusted vertical offset
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.scale( // Invert left and right
                          scaleX: -1.0,
                          child: CameraPreview(_cameraController!),
                        ),
                        ClipPath(
                          clipper: HeadShapeClipper(),
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(color: Colors.blueAccent, width: 4),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.face,
                                size: 60,
                                color: Colors.blue.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _startFaceDetection,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  backgroundColor: Colors.green, // Button color
                ),
                child: _isLoading
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : Text('Start Face Detection', style: TextStyle(fontSize: 16)),
              ),
              SizedBox(height: 20),
              // Display the comparison result with color
              Text(
                _comparisonResult,
                style: TextStyle(
                    color: _resultColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom clipper to create a head-like shape
class HeadShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(size.width / 2, size.height * 0.2); // Start at the top center
    path.quadraticBezierTo(size.width, size.height * 0.4, size.width / 2,
        size.height); // Right side
    path.quadraticBezierTo(
        0, size.height * 0.4, size.width / 2, size.height * 0.2); // Left side
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
