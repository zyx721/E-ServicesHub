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
  bool _isLoading = false;
  String _comparisonResult = "";
  Color _resultColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      _cameraController = CameraController(
        cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front),
        ResolutionPreset.high,
      );

      await _cameraController?.initialize();
      setState(() {});
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  Future<void> _takeAndSendPicture() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _comparisonResult = "";
    });

    try {
      final image = await _cameraController!.takePicture();
      final response = await _submitFaceImage(image.path);

      if (response != null) {
        setState(() {
          _comparisonResult = response['message'];
          _resultColor = (_comparisonResult.trim() == "Faces match!") ? Colors.green : Colors.red;
        });
      } else {
        setState(() {
          _comparisonResult = "Failed to compare faces.";
          _resultColor = Colors.red;
        });
      }
    } catch (e) {
      print("Error capturing image: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _submitFaceImage(String imagePath) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.113.34:8000/compare-face/'),
    );

    try {
      request.files.add(await http.MultipartFile.fromPath('file', imagePath));
      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        return json.decode(responseData.body);
      } else {
        print("Failed to submit face image: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error submitting face image: $e");
      return null;
    }
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
        title: Text('Face Comparison', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.greenAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 63.0, vertical: 10.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_cameraController?.value.isInitialized == true)
                _buildCameraPreview(),
              SizedBox(height: 20),
              _buildTakePictureButton(),
              SizedBox(height: 20),
              _buildComparisonResultText(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
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
    );
  }

  Widget _buildTakePictureButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _takeAndSendPicture,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        backgroundColor: Colors.green,
      ),
      child: _isLoading
          ? CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
          : Text('Take and Send Picture', style: TextStyle(fontSize: 16)),
    );
  }

  Widget _buildComparisonResultText() {
    return Text(
      _comparisonResult,
      style: TextStyle(color: _resultColor, fontSize: 24, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );
  }
}

class HeadShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(size.width / 2, size.height * 0.2);
    path.quadraticBezierTo(size.width, size.height * 0.4, size.width / 2, size.height);
    path.quadraticBezierTo(0, size.height * 0.4, size.width / 2, size.height * 0.2);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
