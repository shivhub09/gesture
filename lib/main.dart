import 'dart:typed_data';
import 'dart:ui' as ui; // Renamed 'dart:ui' alias
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as IMG;
import 'package:tflite/tflite.dart';
import 'camera_page.dart'; // Assuming this is your own file

void loadDetectionModel() async {
  Tflite.close();
  try {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",
    );
    print("Loaded model successfully");
    testModel(); // Corrected function name to lowercase
  } on Exception catch (e) {
    print("Failed to load model: $e");
  }
}

Uint8List imageToByteListFloat32(
  IMG.Image img,
  int inputSize,
  double mean,
  double std,
) {
  var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
  var buffer = Float32List.view(convertedBytes.buffer);
  int count = 0;
  int pixelIndex = 0;
  for (var i = 0; i < inputSize; i++) {
    print("running i loop");
    for (var j = 0; j < inputSize; j++) {
      print("running i loop");

      final data = img.getBytes();
      // Ensure the index is within the bounds of the data list
      if (pixelIndex < data.length) {
        var pixel = img.getPixel(j, i);
        count = count + 1;
        buffer[pixelIndex++] = (data[pixelIndex] - mean) / std;
        buffer[pixelIndex++] = (data[pixelIndex] - mean) / std;
        buffer[pixelIndex++] = (data[pixelIndex] - mean) / std;
      } else {
        print('Index out of bounds: $pixelIndex');
        print(count);

        // Handle or debug the out-of-bounds issue here
      }
    }
  }
  print(count);
  return convertedBytes.buffer.asUint8List();
}

Future<IMG.Image> addAndResize(String s) async {
  var img = IMG.decodeImage((await rootBundle.load(s)).buffer.asUint8List());
  return IMG.copyResize(img!, height: 64, width: 64);
}

int getRed(int color) {
  return (color >> 16) & 0xFF;
}

int getGreen(int color) {
  return (color >> 8) & 0xFF;
}

int getBlue(int color) {
  return color & 0xFF;
}

void testModel() async {
  print("testing model");
  IMG.Image resizeImage;
  try {
    String ALPHA = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    int score = 0;
    for (int i = 0; i < 26; i++) {
      String imgSrc = "assets/images/" + ALPHA[i] + "_test.jpg";
      resizeImage = await addAndResize(imgSrc);
      var res = await Tflite.runModelOnBinary(
        binary: imageToByteListFloat32(resizeImage, 64, 0.0, 255.0),
        numResults: 29,
      );
      if (res?[0]['label'] == ALPHA[i]) {
        score++;
      }
    }
    print("Model Score: ${(score / 26) * 100}%");
  } catch (e) {
    print("runModelError: $e");
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  loadDetectionModel();
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key); // Added Key parameter

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: CameraPage(),
    );
  }
}
