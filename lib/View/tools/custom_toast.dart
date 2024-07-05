import 'package:flutter/material.dart';


void showToast(BuildContext context, String message) {
    OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.85, // Atur posisi
        left: 0,
        right: 0,
        child: CustomToast(message: message),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    Future.delayed(Duration(seconds: 2), () {
      overlayEntry.remove();
    });
}

class CustomToast extends StatelessWidget {
  final String message;

  CustomToast({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      color: Colors.black.withOpacity(0.7),
      child: Text(
        message,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16.0,
        ),
      ),
    );
  }
}