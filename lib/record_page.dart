import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class RecordVoice extends StatefulWidget {
  @override
  _RecordVoiceState createState() => _RecordVoiceState();
}

class _RecordVoiceState extends State<RecordVoice> {
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _recognizedText = '';

  @override
  void dispose() {
    _speech.stop(); // Stop listening when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "SignSense",
                style: GoogleFonts.montserrat(
                  fontSize: 30,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: 0,
            bottom: 0,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (!_isListening) {
                        startListening();
                      } else {
                        stopListening();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isListening ? Colors.red : Colors.grey,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.all(20),
                      shape: CircleBorder(),
                      elevation: 3,
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      size: 40,
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Text(
                    _recognizedText,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              "assets/images.png", // Replace with your image asset
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  void startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'listening') {
          setState(() {
            _isListening = true;
          });
        }
      },
      onError: (errorNotification) => print('onError: $errorNotification'),
    );

    if (available) {
      _speech.listen(
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords;
          });
        },
      );
    } else {
      print('The user has denied the use of speech recognition.');
    }
  }

  void stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
    });
  }
}
