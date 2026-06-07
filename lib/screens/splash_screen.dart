import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/auth_service.dart';
import 'login/login_screen.dart';
import 'home/home_screen.dart';
import 'pending/pending_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserSession();
  }

  Future<void> _checkUserSession() async {
    // 2 second ka splash animation
    await Future.delayed(const Duration(seconds: 2));

    String? loggedInMobile = await AuthService.getLoggedInUser();

    if (!mounted) return;

    if (loggedInMobile == null) {
      // Koi session nahi mila -> Login Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      // User ka current status Firebase se check karo
      try {
        final DatabaseReference ref = FirebaseDatabase.instance.ref("users/$loggedInMobile");
        final DataSnapshot snapshot = await ref.get();
        
        if (snapshot.exists) {
          Map<dynamic, dynamic> userData = snapshot.value as Map<dynamic, dynamic>;
          String status = userData['status'] ?? 'pending';

          if (!mounted) return;

          if (status == 'approved') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PendingScreen()));
          }
        } else {
          // Account delete ho gaya ho toh logout kar do
          await AuthService.logout();
          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
          }
        }
      } catch (e) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
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
            Text(
              'Krishna Library',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
