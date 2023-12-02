import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:image/image.dart' as IMG;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:native_screenshot/native_screenshot.dart';
import 'package:tflite/tflite.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late List<CameraDescription> cameras;
  late CameraController? _controller; // Make the controller nullable
  late int _currentCameraIndex = 0;

  late bool _recording = false;
  late Timer timer;
  String output = "";
  String prevOutput = "";
  String translation = "";
  double confidenceScore = 0.0;
  Color boxColor = Colors.black;
  bool steadyTextDisplay = false;

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
        _recording = true;
      });
    } on CameraException catch (e) {
      print('Error starting video recording: $e');
      setState(() {
        _recording = false;
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
        _recording = false;
      });
    } on CameraException catch (e) {
      print('Error stopping video recording: $e');
    }
  }
// video ended

//////////////////////////////////////////
  _recordVideo() async {
    if (_recording) {
      timer.cancel();

      setState(() => _recording = false);
    } else {
      setState(() => _recording = true);
      translation = "";
      timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        String? path = await NativeScreenshot.takeScreenshot();

        if (path == null || path.isEmpty) {
          print("Screenshot didnt work");
        }

        File imgFile = File(path!);
        // Cropping the image
        Uint8List bytes = imgFile.readAsBytesSync();
        IMG.Image? src = IMG.decodeImage(bytes);

        if (src != null) {
          // IMG.Image destImage = IMG.copyCrop(src, 300, 990, 560, 560);
          IMG.Image destImage =
              IMG.copyCrop(src, x: 300, y: 990, width: 560, height: 560);
          var jpg = IMG.encodeJpg(destImage);
          // var res  = await imageToByteListFloat32(destImage, 560, 0.0, 255.0);

          // path = "../assets/images/IMG_4188.jpg";
          // Uint8List myGesture = File(path).readAsBytesSync();
          // IMG.Image? myImage = IMG.decodeImage(myGesture);
          // IMG.Image resizedImage = IMG.copyResize(myImage!, width:64, height:64);
          IMG.Image resizedImage =
              IMG.copyResize(destImage, width: 64, height: 64);
          var res = await Tflite.runModelOnBinary(
              binary: imageToByteListFloat32(resizedImage, 64, 0.0, 255.0),
              numResults: 29);
          if (res != null) {
            output = res[0]['label'];
            steadyTextDisplay = true;
            confidenceScore = res[0]['confidence'];
            if (confidenceScore > 0.85) {
              // change box colourto green
              boxColor = Colors.green;
              steadyTextDisplay = false;
              if (output != prevOutput && output.length == 1) {
                prevOutput = output;
                translation = translation + output;
              }
            } else if (confidenceScore > 0.6) {
              // change box colour to yellow
              boxColor = Colors.yellow;
            } else {
              // change box colour to red
              boxColor = Colors.red;
            }
            setState(() {});
          }
          // File croppedImage = await File(imgFile.path).writeAsBytes(jpg);
        }
      });
    }
  }

//////////////////////////////////////////

  Uint8List imageToByteListFloat32(
      IMG.Image img, int inputSize, double mean, double std) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        final data = img.getBytes();
        var pixel = img.getPixel(j, i);
        buffer[pixelIndex++] = (data[pixelIndex] - mean) / std;
        buffer[pixelIndex++] = (data[pixelIndex] - mean) / std;
        buffer[pixelIndex++] = (data[pixelIndex] - mean) / std;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  Future<void> switchCamera() async {
    // Dispose the current controller before switching
    await _controller?.dispose();
    _currentCameraIndex = (_currentCameraIndex + 1) % cameras.length;
    _controller =
        CameraController(cameras[_currentCameraIndex], ResolutionPreset.medium);
    await _controller!.initialize();
    if (mounted) {
      setState(() {});
    }
  }

//////////////////////////////////////////

  // (Your imports remain unchanged)

  @override
  Widget build(BuildContext context) {
    if (!_controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return Scaffold(
        backgroundColor: Colors.black12,
        floatingActionButton: FloatingActionButton(onPressed: _toggleCamera),
        body: Stack(
          children: [
            Center(child: CameraPreview(_controller!)),
            Positioned(
              left: 16,
              top: 16,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: steadyTextDisplay ? 1.0 : 0.0,
                child: Text(
                  'Keep steady for accurate results',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: boxColor,
                    width: 5,
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, 0.7),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  translation,
                  key: Key(
                      translation), // Ensure proper animation on text change
                  style: const TextStyle(fontSize: 25),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton(
                  onPressed: _recordVideo,
                  child:
                      Text(_recording ? 'Stop Recording' : 'Start Recording'),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
