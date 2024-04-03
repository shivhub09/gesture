import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

// Replace with your API URL
const String apiUrl = "http://192.168.185.65:8080/check_image";

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
  bool _isTimerActive = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _cameraSetUp();
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
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

  void startStopTimer() {
    setState(() {
      _isTimerActive = !_isTimerActive;
    });

    if (_isTimerActive) {
      _timer = Timer.periodic(Duration(seconds: 5), (timer) {
        if (_isTimerActive) {
          takePicture();
        }
      });
    } else {
      _timer.cancel();
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
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Center(
            child: Text(
              "Sign To Text",
              style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 30),
            ),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0.0,
          title: Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: Center(
              child: Text(
                "Sign To Text",
                style: GoogleFonts.montserrat(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 25),
              ),
            ),
          ),
        ),
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned(
              bottom: 175,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CameraPreview(_controller),
                  ),
                ),
              ),
            ),
            if (_loading)
              Center(
                child: CircularProgressIndicator(),
              ),
            Positioned(
              bottom: 150,
              left: 20,
              right: 20,
              child: Center(
                child: Text(
                  predicted,
                  style: GoogleFonts.montserrat(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 50,
              left: 20,
              right: 20,
              child: Center(
                child: FloatingActionButton(
                  backgroundColor: _isTimerActive ? Colors.red : Colors.grey,
                  onPressed: _loading ? null : startStopTimer,
                  child: Icon(_isTimerActive ? Icons.stop : Icons.camera_alt),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
