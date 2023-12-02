import 'package:flutter/material.dart';
import 'package:gesture/camera_page.dart';
import 'package:google_fonts/google_fonts.dart';

class GettingStarted extends StatelessWidget {
  const GettingStarted({super.key});

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
                      color: Colors.black),
                ),
              )),
          Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                  child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CameraPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey, // Background color
                  foregroundColor: Colors.black, // Text color
                  padding: EdgeInsets.symmetric(
                      horizontal: 30, vertical: 15), // Button padding
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(10), // Button border radius
                  ),
                  elevation: 3, // Button shadow
                ),
                child: Text(
                  'Detect!',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ), // Text style
                ),
              ))),
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                "assets/images.png",
                fit: BoxFit.cover,
              ))
        ],
      ),
    );
  }
}
