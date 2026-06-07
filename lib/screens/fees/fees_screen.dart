import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/auth_service.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  bool _isLoading = true;
  String _feeStatus = "Loading...";
  String _upiQrBase64 = ""; 
  String _dueDate = "10th of every month"; // Default

  @override
  void initState() {
    super.initState();
    _fetchFeeData();
  }

  Future<void> _fetchFeeData() async {
    try {
      String? mobile = await AuthService.getLoggedInUser();
      if (mobile == null) throw Exception("User not logged in");

      // 1. Student ka current fee status check karein
      final DatabaseReference userRef = FirebaseDatabase.instance.ref("users/$mobile");
      final DataSnapshot userSnap = await userRef.get();

      if (userSnap.exists) {
        Map userData = userSnap.value as Map;
        // Agar database me feeStatus nahi hai, toh default 'Pending' manenge
        _feeStatus = userData['feeStatus'] ?? "Pending"; 
      }

      // 2. Admin ka set kiya hua UPI QR Code aur Due Date fetch karein
      final DatabaseReference settingsRef = FirebaseDatabase.instance.ref("settings");
      final DataSnapshot settingsSnap = await settingsRef.get();

      if (settingsSnap.exists) {
        Map settingsData = settingsSnap.value as Map;
        _upiQrBase64 = settingsData['upiQR'] ?? ""; 
        _dueDate = settingsData['feeDueDate'] ?? "10th of every month";
      }

      if (mounted) {
        setState(() { _isLoading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _feeStatus = "Error";
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isPaid = _feeStatus.toLowerCase() == "paid";

    return Scaffold(
      appBar: AppBar(title: const Text('Fee Status')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Fee Status Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isPaid ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isPaid ? Colors.green : Colors.red,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          isPaid ? Icons.check_circle : Icons.warning_rounded,
                          size: 60,
                          color: isPaid ? Colors.green : Colors.red,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Current Status: ${_feeStatus.toUpperCase()}",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isPaid ? Colors.green : Colors.red,
                          ),
                        ),
                        if (!isPaid)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              "Due Date: $_dueDate",
                              style: const TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // UPI QR Code Section (Sirf tab dikhega jab Fees Pending ho)
                  if (!isPaid) ...[
                    const Text(
                      "Scan to Pay via UPI",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: _upiQrBase64.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Image.memory(
                                  base64Decode(_upiQrBase64),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Center(
                                    child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                  ),
                                ),
                              )
                            : const Center(
                                child: Text(
                                  "QR Code Not Uploaded by Admin",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "Note: After payment, please inform the Admin to mark your status as 'Paid'.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ]
                ],
              ),
            ),
    );
  }
}
