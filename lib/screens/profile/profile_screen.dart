import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/auth_service.dart';
import '../login/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<dynamic, dynamic> _userData = {};
  List<Map<String, dynamic>> _attendanceHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      String? mobile = await AuthService.getLoggedInUser();
      if (mobile == null) return;

      // 1. User Details Fetch Karein
      final DatabaseReference userRef = FirebaseDatabase.instance.ref("users/$mobile");
      final DataSnapshot userSnap = await userRef.get();
      if (userSnap.exists) {
        _userData = userSnap.value as Map<dynamic, dynamic>;
      }

      // 2. Attendance History Fetch Karein
      final DatabaseReference attRef = FirebaseDatabase.instance.ref("attendance");
      final DataSnapshot attSnap = await attRef.get();
      
      List<Map<String, dynamic>> tempHistory = [];
      
      if (attSnap.exists) {
        Map allAttendance = attSnap.value as Map;
        // Date ke hisaab se check karein ki is mobile number ki attendance hai ya nahi
        allAttendance.forEach((date, dailyData) {
          if (dailyData is Map && dailyData.containsKey(mobile)) {
            tempHistory.add({
              "date": date,
              "time": dailyData[mobile]['time'],
              "status": dailyData[mobile]['status'] ?? 'Present',
            });
          }
        });
      }

      // Latest attendance sabse upar
      tempHistory.sort((a, b) => b['date'].compareTo(a['date']));

      if (mounted) {
        setState(() {
          _attendanceHistory = tempHistory;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Profile Header
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _userData['photo'] != null && _userData['photo'].toString().isNotEmpty
                        ? MemoryImage(base64Decode(_userData['photo']))
                        : null,
                    child: _userData['photo'] == null || _userData['photo'].toString().isEmpty
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _userData['name'] ?? 'Student Name',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "+91 ${_userData['mobile'] ?? ''}",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),

                  // Attendance History Section
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Recent Attendance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  
                  _attendanceHistory.isEmpty
                      ? const Text("No attendance records found.", style: TextStyle(color: Colors.grey))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _attendanceHistory.length > 5 ? 5 : _attendanceHistory.length, // Show max 5
                          itemBuilder: (context, index) {
                            var record = _attendanceHistory[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.check_circle, color: Colors.green),
                              title: Text(record['date']),
                              subtitle: const Text("Status: Present"),
                            );
                          },
                        ),
                  
                  const SizedBox(height: 40),

                  // Logout Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () async {
                      await AuthService.logout();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    child: const Text('LOGOUT', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }
}
