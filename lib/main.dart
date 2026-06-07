import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';

void main() async {
  // Flutter aur Firebase bindings ko initialize karne ke liye
  WidgetsFlutterBinding.ensureInitialized();
  
  // Aapki Firebase Configuration (Bina google-services.json ke direct connect karne ke liye)
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBu0OkmpY7uXZkQIlVxfQj9MCyGBOA9sxI",
      appId: "1:239319034758:web:1c260d221b5f698a63da07",
      messagingSenderId: "239319034758",
      projectId: "whatsapp-web-03",
      databaseURL: "https://whatsapp-web-03-default-rtdb.firebaseio.com",
      storageBucket: "whatsapp-web-03.firebasestorage.app",
    ),
  );

  runApp(const LibraryApp());
}

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Krishna Library',
      debugShowCheckedModeBanner: false, // Upar right corner se 'Debug' banner hatane ke liye
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.blue,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      // App start hote hi sabse pehle Splash Screen khulegi
      home: const SplashScreen(),
    );
  }
}
