import 'package:flutter/material.dart';

void showMessageBox(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
          textAlign: TextAlign.center,
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16.0),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white, fontSize: 16.0),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      );
    },
  );
}