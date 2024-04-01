import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _recording = false;
  bool _initialized = true;
  int currentCamera = 0;
  late CameraController _controller;
  late List<CameraDescription> cameras;

  late Timer timer;
  String output = "";
  String prevOutput = "";
  String translation = "";
  double confidenceScore = 0.0;
  Color boxColor = Colors.black;
  bool steadyTextDisplay = false;

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
  _cameraSetUp() async {
    cameras = await availableCameras();
    _controller = CameraController(cameras[0], ResolutionPreset.max);
    await _controller.initialize();
    setState(() => _initialized = false);
  }

  // Switch between front and back camera
  void switchCamera() async {
    if (cameras.length > 1) {
      _controller = CameraController(
          currentCamera == 0 ? cameras[1] : cameras[0], ResolutionPreset.max);
      await _controller.initialize();
      setState(() => currentCamera = currentCamera == 0 ? 1 : 0);
    }
  }

  // Start or stop recording
  _recordVideo() async {
    if (_recording) {
      setState(() {
        _recording = false;
      });
    } else {
      setState(() {
        _recording = true;
      });
      translation = "";
    }
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
                      fontSize: 20, color: Colors.grey.shade50),
                ),
              ),
            ),

            // camera
            Center(
                child: Container(
                    padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: CameraPreview(_controller)))),

            // 
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 25.0),
                child: GestureDetector(
                  onTap: () {
                    _recordVideo();
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _recording ? Colors.white : Colors.grey,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      _recording ? Icons.pause_rounded : Icons.circle,
                      color: _recording ? Colors.red : Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}