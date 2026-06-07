import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import '../pending/pending_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String _base64Photo = ""; // Photo ko save karne ke liye

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Gallery ya Camera se photo lene ka function
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 50, // Size kam rakhne ke liye
    );

    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      setState(() {
        _base64Photo = base64Encode(bytes);
      });
    }
  }

  Future<void> _submitRegistration() async {
    if (_nameController.text.isEmpty || _mobileController.text.isEmpty || 
        _passwordController.text.isEmpty || _base64Photo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and upload a photo!')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final DatabaseReference ref = FirebaseDatabase.instance.ref("users");
      String userId = _mobileController.text.trim();

      Map<String, dynamic> studentData = {
        "name": _nameController.text.trim(),
        "mobile": userId,
        "address": _addressController.text.trim(),
        "password": _passwordController.text.trim(),
        "status": "pending", 
        "photo": _base64Photo, // Base64 Photo yahan save hogi
        "registeredAt": DateTime.now().toIso8601String(),
      };

      await ref.child(userId).set(studentData);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PendingScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Registration')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Upload UI
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 2),
                          image: _base64Photo.isNotEmpty 
                            ? DecorationImage(image: MemoryImage(base64Decode(_base64Photo)), fit: BoxFit.cover)
                            : null,
                        ),
                        child: _base64Photo.isEmpty ? const Icon(Icons.person, size: 80, color: Colors.grey) : null,
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Center(child: Text("Tap to upload photo", style: TextStyle(color: Colors.grey))),
              const SizedBox(height: 30),

              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.badge))),
              const SizedBox(height: 20),
              TextField(controller: _mobileController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Number', prefixIcon: Icon(Icons.phone))),
              const SizedBox(height: 20),
              TextField(controller: _addressController, maxLines: 2, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on))),
              const SizedBox(height: 20),
              TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Create Password', prefixIcon: Icon(Icons.lock))),
              const SizedBox(height: 40),
              
              _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitRegistration,
                    child: const Text('SUBMIT REGISTRATION', style: TextStyle(fontSize: 16)),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
