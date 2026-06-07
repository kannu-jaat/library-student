// Notices screen

import 'package:flutter/material.dart';

class NoticesScreen extends StatelessWidget {
  const NoticesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notices & Alerts')),
      body: const Center(
        child: Text('Admin Notices will be displayed here'),
      ),
    );
  }
}
