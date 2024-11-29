import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'face_verification_screen.dart'; // Replace with your actual face comparison screen import

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
      widget.cameras[0],
      ResolutionPreset.medium,
    );

    try {
      await _cameraController.initialize();
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      print("Error initializing camera: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Camera error: $e";
        });
      }
    }
  }

  void _startDetection() {
    if (_cameraController.value.isInitialized) {
      setState(() {
        _isDetecting = true;
      });
      _captureFrames();
    }
  }

  void _stopDetection() {
    if (mounted) {
      setState(() {
        _isDetecting = false;
      });
    }
  }

  Future<void> _captureFrames() async {
    while (_isDetecting && mounted) {
      try {
        final XFile image = await _cameraController.takePicture();
        await _uploadImage(File(image.path));
      } catch (e) {
        print("Error capturing frame: $e");
        if (mounted) {
          setState(() {
            _errorMessage = "Capture error: $e";
          });
        }
        break;
      }
    }
  }

  Future<void> _uploadImage(File image) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
          'http://192.168.172.13:8000/upload-image/'), // Replace with your server's IP address
    );

    request.files.add(await http.MultipartFile.fromPath('file', image.path));

    try {
      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(responseData.body);
        final message = responseBody["message"];
        final stopCapture = responseBody["stop_capture"];
        print("Response: $message");

        if (stopCapture) {
          _stopDetection();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FaceCompareScreen(),
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
      if (mounted) {
        setState(() {
          _errorMessage = "An error occurred during upload.";
        });
      }
    }
  }

  @override
  void dispose() {
    _isDetecting = false;
    _cameraController.dispose();
    super.dispose();
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Support'),
          content: Text(
              'If your card was not detected, please make sure it is aligned correctly and try again.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
              'Real-Time Detection', // Use appropriate title
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
      body: _cameraController.value.isInitialized
          ? Stack(
              children: [
                CameraPreview(_cameraController),
                Center(
                  child: Container(
                    width: 380,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color.fromARGB(255, 0, 0, 0),
                        width: 2.5,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 45, left: 170),
                        child: Text(
                          'XXXXXXXXXXXXXXXXXX : رقم التعريف الوطني ',
                          style: TextStyle(
                            color: const Color.fromARGB(109, 3, 68, 18),
                            fontSize: 8.2,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: const Color.fromARGB(147, 43, 43, 43),
                                offset: Offset(1, 0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: InkWell(
                    onTap: _isDetecting ? _stopDetection : _startDetection,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF3949AB),
                            Color(0xFF1E88E5),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isDetecting ? Icons.stop : Icons.play_arrow,
                            color: Colors.white,
                          ),
                          SizedBox(width: 10),
                          Text(
                            _isDetecting ? 'Stop Detection' : 'Start Detection',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_errorMessage != null)
                  Positioned(
                    bottom: 100,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 280,
                  left: 27,
                  width: 110,
                  height: 150,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color.fromARGB(69, 0, 0, 0),
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.asset(
                      'assets/images/face_shape.png',
                      width: 150,
                      height: 140,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 458,
                  left: 20,
                  right: 20,
                  child: Image.asset(
                    'assets/images/id_things.png',
                    height: 45,
                  ),
                ),
              ],
            )
          : Center(
              child: _errorMessage != null
                  ? Text(_errorMessage!)
                  : CircularProgressIndicator(),
            ),
    );
  }
}
