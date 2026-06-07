import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/auth_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _isLoadingSettings = true;
  bool _isScanningQR = false;
  bool _isCameraReady = false;
  bool _isProcessing = false;
  
  String _expectedQR = "";
  String _expectedSSID = "";
  String _statusText = "Verifying Library Connection...";
  
  CameraController? _cameraController;

  @override
  void initState() {
    super.initState();
    _verifyWiFiAndFetchSettings();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  // 1. Firebase se Settings laana aur WiFi check karna
  Future<void> _verifyWiFiAndFetchSettings() async {
    try {
      // Location permission (Android me WiFi name nikalne ke liye zaroori hai)
      var status = await Permission.locationWhenInUse.request();
      if (!status.isGranted) {
        _showError("Location permission required to verify Library WiFi.");
        return;
      }

      // Firebase se settings fetch karein
      final DatabaseReference ref = FirebaseDatabase.instance.ref("settings");
      final DataSnapshot snapshot = await ref.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> settings = snapshot.value as Map<dynamic, dynamic>;
        _expectedQR = settings['attendanceQR'] ?? "KRISHNA_LIBRARY";
        _expectedSSID = settings['wifiSSID'] ?? "Krishna Library"; // Default fallback
      }

      // Phone ka current WiFi check karein
      final info = NetworkInfo();
      String? currentWiFi = await info.getWifiName();
      
      // Quotes hatane ke liye (Android kabhi kabhi "" me wifi name deta hai)
      currentWiFi = currentWiFi?.replaceAll("\"", "");

      if (currentWiFi != _expectedSSID) {
        _showError("You are not connected to Library WiFi.\nPlease connect to '$_expectedSSID' first.");
        return;
      }

      // WiFi sahi hai, ab Scanner on karein
      if (mounted) {
        setState(() {
          _isLoadingSettings = false;
          _isScanningQR = true;
          _statusText = "WiFi Verified! Scan Library QR";
        });
      }

    } catch (e) {
      _showError("Connection Error: $e");
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() {
        _isLoadingSettings = false;
        _statusText = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
    }
  }

  // 2. QR Code Scanner Logic
  void _onQRScanned(BarcodeCapture capture) async {
    if (!_isScanningQR || _isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue == _expectedQR) {
        setState(() {
          _isScanningQR = false;
          _statusText = "QR Matched! Ready for Selfie...";
        });
        await _initCameraAndTakeSelfie();
        break;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid or Expired QR Code!")),
        );
      }
    }
  }

  // 3. Camera aur Selfie Logic
  Future<void> _initCameraAndTakeSelfie() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere((cam) => cam.lensDirection == CameraLensDirection.front, orElse: () => cameras.first);

      _cameraController = CameraController(frontCamera, ResolutionPreset.medium);
      await _cameraController!.initialize();

      if (!mounted) return;
      setState(() { _isCameraReady = true; });

      // 2 second ka timer
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isProcessing = true;
        _statusText = "Uploading Attendance...";
      });

      final XFile photo = await _cameraController!.takePicture();
      final bytes = await File(photo.path).readAsBytes();
      final String base64Image = base64Encode(bytes);

      await _saveAttendanceToFirebase(base64Image);

    } catch (e) {
      _showError("Camera Error: $e");
    }
  }

  // 4. Database me save karna
  Future<void> _saveAttendanceToFirebase(String base64Photo) async {
    try {
      String? mobile = await AuthService.getLoggedInUser();
      if (mobile == null) throw Exception("User not found");

      String todayDate = DateTime.now().toIso8601String().split('T')[0];
      final DatabaseReference ref = FirebaseDatabase.instance.ref("attendance/$todayDate/$mobile");

      await ref.set({
        "time": DateTime.now().toIso8601String(),
        "photo": base64Photo,
        "status": "Present",
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance Marked Successfully! ✅"), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      _showError("Database Error: $e");
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
                child: _isLoadingSettings
                    ? const Center(child: CircularProgressIndicator())
                    : _isScanningQR
                        ? MobileScanner(onDetect: _onQRScanned)
                        : (_isCameraReady && _cameraController != null)
                            ? CameraPreview(_cameraController!)
                            : const Center(child: Icon(Icons.wifi_off, size: 80, color: Colors.grey)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              _statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: _statusText.contains("Error") || _statusText.contains("not connected") ? Colors.red : Colors.blue
              ),
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
