// Main entry point

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';

void main() async {
  // Flutter aur Firebase ko start karne ke liye zaroori
  WidgetsFlutterBinding.ensureInitialized();
  
  // Aapki Firebase Configuration
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBu0OkmpY7uXZkQIlVxfQj9MCyGBOA9sxI",
      appId: "1:239319034758:web:1c260d221b5f698a63da07",
      messagingSenderId: "239319034758",
      projectId: "whatsapp-web-03",
      databaseURL: "https://whatsapp-web-03-default-rtdb.firebaseio.com",
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.blue,
          centerTitle: true,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
