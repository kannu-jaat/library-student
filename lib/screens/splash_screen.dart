import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/auth_service.dart';
import 'login/login_screen.dart';
import 'home/home_screen.dart';
import 'pending/pending_screen.dart';
import 'update_screen.dart'; // Nayi file import ki

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // App ka current version. Jab bhi naya APK banayenge, isko 1.1, 1.2 kar denge.
  static const double _currentAppVersion = 1.0; 

  @override
  void initState() {
    super.initState();
    _checkAppVersionAndSession();
  }

  Future<void> _checkAppVersionAndSession() async {
    await Future.delayed(const Duration(seconds: 2));

    try {
      // 1. Pehle Firebase se App Version check karo
      final DatabaseReference updateRef = FirebaseDatabase.instance.ref("settings/appUpdate");
      final DataSnapshot updateSnap = await updateRef.get();

      if (updateSnap.exists) {
        Map updateData = updateSnap.value as Map;
        double latestVersion = double.tryParse(updateData['latestVersion'].toString()) ?? 1.0;
        bool forceUpdate = updateData['forceUpdate'] ?? false;
        String updateUrl = updateData['updateUrl'] ?? "";

        // Agar Firebase ka version app ke version se bada hai aur Force Update ON hai
        if (latestVersion > _currentAppVersion && forceUpdate) {
          if (!mounted) return;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => UpdateScreen(updateUrl: updateUrl)));
          return; // Aage ka login check rok do
        }
      }

      // 2. Agar update nahi chahiye, toh normal Login check karo
      String? loggedInMobile = await AuthService.getLoggedInUser();
      if (!mounted) return;

      if (loggedInMobile == null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      } else {
        final DatabaseReference ref = FirebaseDatabase.instance.ref("users/$loggedInMobile");
        final DataSnapshot snapshot = await ref.get();
        
        if (snapshot.exists) {
          Map userData = snapshot.value as Map;
          String status = userData['status'] ?? 'pending';

          if (!mounted) return;
          if (status == 'approved') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PendingScreen()));
          }
        } else {
          await AuthService.logout();
          if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        }
      }
    } catch (e) {
      // Kisi bhi error me login par bhej do
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_library, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text('Krishna Library', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
