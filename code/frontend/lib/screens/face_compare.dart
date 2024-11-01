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
    cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front),
      ResolutionPreset.medium,
    );

    await _cameraController?.initialize();
    setState(() {});
  }

  Future<void> _startFaceDetection() async {
    if (_isLoading) return; // Prevent multiple clicks

    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      // Capture image from the camera
      final image = await _cameraController!.takePicture();
      final response = await _submitFaceImage(image.path);

      if (response != null) {
        setState(() {
          _comparisonResult = response['message'];
          // Set result color based on the response message
          _resultColor = response['message'] == "Face matches." ? Colors.green : Colors.red;
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
      Uri.parse('http://192.168.138.136:8000/compare-face/'),
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
        title: Text('Real-Time Face Detection'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_cameraController?.value.isInitialized == true)
              AspectRatio(
                aspectRatio: _cameraController!.value.aspectRatio,
                child: CameraPreview(_cameraController!),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _startFaceDetection,
              child: _isLoading
                  ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : Text('Start Face Detection'),
            ),
            SizedBox(height: 20),
            // Display the comparison result with color
            Text(
              _comparisonResult,
              style: TextStyle(color: _resultColor, fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
