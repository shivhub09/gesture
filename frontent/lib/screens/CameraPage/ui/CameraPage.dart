import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

// Replace with your API URL
const String apiUrl = "http://192.168.189.65:8080/check_image";

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _initialized = false;
  late CameraController _controller;
  late List<CameraDescription> cameras;
  late Future<void> _initializeControllerFuture;

  String predicted = 'Hello';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _cameraSetUp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Set up the camera
  Future<void> _cameraSetUp() async {
    try {
      cameras = await availableCameras();
      _controller = CameraController(cameras[0], ResolutionPreset.medium);
      _initializeControllerFuture = _controller.initialize();
      setState(() => _initialized = true);
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> takePicture() async {
    if (!_controller.value.isInitialized) {
      print('Error: Camera is not initialized');
      return;
    }

    try {
      setState(() {
        _loading = true;
      });
      final image = await _controller.takePicture();
      await sendImageToApi(image.path);
    } catch (e) {
      print('Error taking picture: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> sendImageToApi(String imagePath) async {
    print("API called");
    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      final imageFile = await http.MultipartFile.fromPath('image', imagePath);
      request.files.add(imageFile);
      var response = await request.send();
      if (response.statusCode == 200) {
        var parsedResponse = jsonDecode(await response.stream.bytesToString());
        print(parsedResponse);
        setState(() {
          predicted = parsedResponse['prediction'];
        });
      } else {
        print('Error sending image: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error sending image: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CameraPreview(_controller),
                ),
              ),
            ),
            if (_loading)
              Center(
                child: CircularProgressIndicator(),
              ),
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Center(
                child: Text(
                  predicted,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Center(
                child: FloatingActionButton(
                  backgroundColor: Colors.grey,
                  onPressed: _loading ? null : takePicture,
                  child: Icon(Icons.camera_alt),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
