// Attendance screen

import 'package:flutter/material.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: const Center(
        child: Text('QR Scanner & Auto Selfie will come here'),
      ),
    );
  }
}
