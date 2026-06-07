// Firebase notification service

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permission_handler/permission_handler.dart';
import 'auth_service.dart';

// App background me ya band hone par aane wale messages ko yahan handle kiya jata hai
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Background Notice Received: ${message.notification?.title}");
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // 1. Notifications ki permission maangna (Android 13+ ke liye zaroori)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Background handler register karna
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Foreground (Jab app open ho) me notices receive karna
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("Foreground Notice: ${message.notification?.title}");
        // Yahan par hum local popup notice dikha sakte hain (Aage add karenge)
      });

      // 4. FCM Token generate karke Database me save karna
      String? token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token);
      }

      // Agar token expire/refresh ho jaye toh automatically update kar dena
      _messaging.onTokenRefresh.listen((newToken) {
        _saveTokenToDatabase(newToken);
      });
    }
  }

  // Token ko us student ke Firebase node me save karna
  static Future<void> _saveTokenToDatabase(String token) async {
    String? mobile = await AuthService.getLoggedInUser();
    if (mobile != null) {
      final ref = FirebaseDatabase.instance.ref("users/$mobile/fcmToken");
      await ref.set(token);
    }
  }

  // Battery Optimization ko disable karwana taaki notices delay na hon
  static Future<void> checkAndRequestBatteryOptimization() async {
    var status = await Permission.ignoreBatteryOptimizations.status;
    if (!status.isGranted) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }
}
