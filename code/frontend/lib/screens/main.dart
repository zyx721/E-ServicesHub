import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'face_compare.dart'; // Replace with your actual face comparison screen import
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  MyApp({required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real-Time Detection',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(cameras: cameras),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final List<CameraDescription> cameras;

  HomeScreen({required this.cameras});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // Check and request camera permission
            if (await Permission.camera.request().isGranted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RealTimeDetection(cameras: cameras),
                ),
              );
            } else {
              // Show a message or handle permission denied
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Camera permission is required')),
              );
            }
          },
          child: Text('Start Detection'),
        ),
      ),
    );
  }
}

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
      Uri.parse('http://192.168.138.136:8000/upload-image/'), // Replace with your server's IP address
    );

    request.files.add(await http.MultipartFile.fromPath('file', image.path));

    try {
      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final message = jsonDecode(responseData.body)["message"];
        print("Response: $message");

        if (message == "ID valid. Face extracted.") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FaceCompareScreen()), // Replace with your actual FaceCompareScreen
          );
          _stopDetection();
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
      appBar: AppBar(title: Text('Real-Time Detection')),
      body: _cameraController.value.isInitialized
          ? Stack(
              children: [
                CameraPreview(_cameraController),
                Center(
                  child: Container(
                    width: 300, // Adjusted width for a larger rectangle
                    height: 200, // Adjusted height for a larger rectangle
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color.fromARGB(255, 143, 244, 54),
                          width: 4), // Optional: make the border thicker
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: ElevatedButton(
                    onPressed: _isDetecting ? _stopDetection : _startDetection,
                    child: Text(
                      _isDetecting ? 'Stop Detection' : 'Start Detection',
                    ),
                  ),
                ),
                if (_errorMessage != null)
                  Positioned(
                    bottom: 80,
                    left: 20,
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
              ],
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
