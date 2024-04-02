import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

// Replace with your API URL
const String apiUrl = "http://192.168.189.65:8080/check_image";

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isCapturing = false; // Flag to control capture loop
  bool _initialized = true;
  int currentCamera = 0;
  late CameraController _controller;
  late List<CameraDescription> cameras;
  late Future<void> _initializeControllerFuture;

  String translation = "";

  @override
  void initState() {
    _cameraSetUp();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Set up the camera
  Future<void> _cameraSetUp() async {
    cameras = await availableCameras();
    _controller = CameraController(cameras[0], ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
    setState(() => _initialized = false);
  }

  Future<void> takePicture() async {
    // Wait for the camera to be initialized before proceeding
    await _initializeControllerFuture;
    try {
      final image = await _controller.takePicture();
      // Send captured image to API
      await sendImageToApi(image.path);
    } catch (e) {
      print(e);
    }
  }

  Future<void> sendImageToApi(String imagePath) async {
    print("api called");
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

    // Await the creation of the MultipartFile and then add it to the request
    final imageFile = await http.MultipartFile.fromPath('image', imagePath);
    request.files.add(imageFile);

    var response = await request.send();

    // Handle API response (check status code, parse JSON, etc.)
    if (response.statusCode == 200) {
      print('Image sent successfully!');
    } else {
      print('Error sending image: ${response.reasonPhrase}');
    }
  }

  void startCapture() {
    _isCapturing = true;
    Timer.periodic(Duration(seconds: 1), (_) => takePicture());
  }

  void stopCapture() {
    _isCapturing = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 50),
                child: Text(
                  "Detect your Sign!!",
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    color: Colors.grey.shade50,
                  ),
                ),
              ),
            ),

            // Camera preview
            Center(
              child: Container(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CameraPreview(_controller),
                ),
              ),
            ),

            // Capture controls
            Positioned(
              bottom: 20,
              left: 20,
              child: FloatingActionButton(
                onPressed: _isCapturing ? stopCapture : startCapture,
                child: Icon(
                  _isCapturing ? Icons.pause : Icons.camera_alt,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
