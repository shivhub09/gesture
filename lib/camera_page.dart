import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late List<CameraDescription> cameras;
  late CameraController? _controller; // Make the controller nullable
  int _currentCameraIndex = 0;
  late bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    cameras = await availableCameras();
    _controller =
        CameraController(cameras[_currentCameraIndex], ResolutionPreset.medium);
    await _controller!.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose(); // Use safe null-aware operator
    super.dispose();
  }

  Future<void> _toggleCamera() async {
    _currentCameraIndex = (_currentCameraIndex + 1) % cameras.length;
    await _controller!.dispose();
    _controller =
        CameraController(cameras[_currentCameraIndex], ResolutionPreset.medium);
    await _controller!.initialize();
    if (mounted) {
      setState(() {});
    }
  }

// video :
  Future<void> _startRecording() async {
    if (!_controller!.value.isInitialized ||
        _controller!.value.isRecordingVideo) {
      return;
    }

    try {
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    } on CameraException catch (e) {
      print('Error starting video recording: $e');
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    if (!_controller!.value.isRecordingVideo) {
      return null;
    }

    try {
      await _controller?.stopVideoRecording();
      setState(() {
        _isRecording = false;
      });
    } on CameraException catch (e) {
      print('Error stopping video recording: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.white,
          onPressed: _toggleCamera,
          child: Icon(
            Icons.switch_camera,
            color: Colors.black,
          )),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(child: CameraPreview(_controller!)),
          Positioned(
            bottom: 10.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.circle),
                  iconSize: 60.0,
                  color: _isRecording ? Colors.red : Colors.white,
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
