// Firebase authentication service

import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _userKey = "loggedInUserMobile";

  // Login hone par session save karein
  static Future<void> saveUserSession(String mobile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, mobile);
  }

  // Check karein ki kaunsa user login hai
  static Future<String?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userKey);
  }

  // Logout karein
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}
