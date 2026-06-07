import 'package:flutter/material.dart';

class UpdateScreen extends StatelessWidget {
  final String updateUrl;
  
  const UpdateScreen({super.key, required this.updateUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.system_update, size: 100, color: Colors.orange),
              const SizedBox(height: 30),
              const Text(
                'Update Required!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'A new version of Krishna Library app is available. Please update to continue using the app.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () {
                  // Yahan hum baad me update link open karne ka logic lagayenge
                  print("Update Link: $updateUrl");
                },
                child: const Text('DOWNLOAD LATEST APP', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
