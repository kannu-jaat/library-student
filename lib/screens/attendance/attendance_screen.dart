import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/auth_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _isScanningQR = true;
  bool _isCameraReady = false;
  bool _isProcessing = false;
  CameraController? _cameraController;
  String _statusText = "Scan Library QR Code";

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  // QR Code scan hone par ye function chalega
  void _onQRScanned(BarcodeCapture capture) async {
    if (!_isScanningQR || _isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue == "KRISHNA_LIBRARY") {
        setState(() {
          _isScanningQR = false;
          _statusText = "QR Verified! Get ready for Selfie...";
        });
        await _initCameraAndTakeSelfie();
        break;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid QR Code! Please scan the library QR.")),
        );
      }
    }
  }

  // Camera start karna aur automatically photo lena
  Future<void> _initCameraAndTakeSelfie() async {
    try {
      final cameras = await availableCameras();
      // Front camera dhoondho
      final frontCamera = cameras.firstWhere((cam) => cam.lensDirection == CameraLensDirection.front, orElse: () => cameras.first);

      _cameraController = CameraController(frontCamera, ResolutionPreset.medium);
      await _cameraController!.initialize();

      if (!mounted) return;
      setState(() { _isCameraReady = true; });

      // 2 second ka wait taaki user pose kar sake
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isProcessing = true;
        _statusText = "Uploading Attendance...";
      });

      // Photo click karein
      final XFile photo = await _cameraController!.takePicture();
      
      // Photo ko Base64 String me convert karein (Firebase Realtime DB ke liye)
      final bytes = await File(photo.path).readAsBytes();
      final String base64Image = base64Encode(bytes);

      await _saveAttendanceToFirebase(base64Image);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Camera Error: $e")));
        Navigator.pop(context);
      }
    }
  }

  // Data ko Firebase me save karna
  Future<void> _saveAttendanceToFirebase(String base64Photo) async {
    try {
      String? mobile = await AuthService.getLoggedInUser();
      if (mobile == null) throw Exception("User not found");

      // Aaj ki date (YYYY-MM-DD)
      String todayDate = DateTime.now().toIso8601String().split('T')[0];
      
      final DatabaseReference ref = FirebaseDatabase.instance.ref("attendance/$todayDate/$mobile");

      // Attendance data save karein
      await ref.set({
        "time": DateTime.now().toIso8601String(),
        "photo": base64Photo,
        "status": "Present",
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance Marked Successfully! ✅"), backgroundColor: Colors.green),
      );
      
      // Wapas Dashboard par bhej dein
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Database Error: $e")));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _isScanningQR
                    ? MobileScanner(
                        onDetect: _onQRScanned,
                      )
                    : (_isCameraReady && _cameraController != null)
                        ? CameraPreview(_cameraController!)
                        : const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              _statusText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.only(bottom: 30),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
