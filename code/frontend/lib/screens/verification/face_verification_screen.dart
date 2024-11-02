import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'id_verification_screen.dart'; // Replace with your actual face comparison screen import

class RealTimeDetection extends StatefulWidget {
  final List<CameraDescription> cameras;

  RealTimeDetection({required this.cameras});

  @override
  _RealTimeDetectionState createState() => _RealTimeDetectionState();
}

class _RealTimeDetectionState extends State<RealTimeDetection> {
  late CameraController _cameraController;
  bool _isDetecting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameraController = CameraController(
      widget.cameras[0], // Use the first available camera
      ResolutionPreset.medium,
    );

    try {
      await _cameraController.initialize();
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      print("Error initializing camera: $e");
      setState(() {
        _errorMessage = "Camera error: $e";
      });
    }
  }

  void _startDetection() {
    if (_cameraController.value.isInitialized) {
      _isDetecting = true;
      _captureFrames();
    }
  }

  void _stopDetection() {
    setState(() {
      _isDetecting = false;
    });
  }

  Future<void> _captureFrames() async {
    while (_isDetecting) {
      try {
        final XFile image = await _cameraController.takePicture();
        await _uploadImage(File(image.path));
      } catch (e) {
        print("Error capturing frame: $e");
        setState(() {
          _errorMessage = "Capture error: $e";
        });
        break;
      }
    }
  }

  Future<void> _uploadImage(File image) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.172.216:8000/upload-image/'), // Replace with your server's IP address
    );

    request.files.add(await http.MultipartFile.fromPath('file', image.path));

    try {
      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(responseData.body);
        final message = responseBody["message"];
        final stopCapture = responseBody["stop_capture"]; // Extract the stop_capture flag
        print("Response: $message");

        if (stopCapture) {
          _stopDetection(); // Call _stopDetection to stop frame capture
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FaceCompareScreen(), // Replace with your actual FaceCompareScreen
            ),
          );
        } else {
          setState(() {
            _errorMessage = "Invalid ID: $message";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Upload failed: ${response.statusCode}";
        });
      }
    } catch (e) {
      print("Error uploading image: $e");
      setState(() {
        _errorMessage = "An error occurred during upload.";
      });
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Real-Time Detection'),
        centerTitle: true,
        backgroundColor: Colors.greenAccent, // Modern color for AppBar
      ),
      body: _cameraController.value.isInitialized
          ? Stack(
              children: [
                CameraPreview(_cameraController),
                Center(
                  child: Container(
                    width: 300, // Adjusted width for a larger rectangle
                    height: 200, // Adjusted height for a larger rectangle
                    decoration: BoxDecoration(
                      border: Border.all(color: Color.fromARGB(255, 143, 244, 54), width: 4),
                      borderRadius: BorderRadius.circular(15), // Rounded corners
                    ),
                    child: Center(
                      child: Text(
                        'Align ID Card Here', // Instructional text
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 10.0,
                              color: Colors.black,
                              offset: Offset(2.0, 2.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: ElevatedButton(
                    onPressed: _isDetecting ? _stopDetection : _startDetection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Button color
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      textStyle: TextStyle(fontSize: 18), // Button text size
                    ),
                    child: Text(
                      _isDetecting ? 'Stop Detection' : 'Start Detection',
                    ),
                  ),
                ),
                if (_errorMessage != null)
                  Positioned(
                    bottom: 80,
                    left: 20,
                    right: 20,
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
