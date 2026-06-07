import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/auth_service.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notices = [];

  @override
  void initState() {
    super.initState();
    _fetchNotices();
  }

  Future<void> _fetchNotices() async {
    try {
      String? mobile = await AuthService.getLoggedInUser();
      List<Map<String, dynamic>> tempNotices = [];

      // 1. Sabhi students wale Global Notices fetch karein
      final DatabaseReference globalRef = FirebaseDatabase.instance.ref("notices/global");
      final DataSnapshot globalSnap = await globalRef.get();
      
      if (globalSnap.exists) {
        Map globalData = globalSnap.value as Map;
        globalData.forEach((key, value) {
          tempNotices.add({
            "title": value['title'] ?? "Notice",
            "message": value['message'] ?? "",
            "date": value['date'] ?? "", // ISO Format YYYY-MM-DD
            "type": "Global Alert",
          });
        });
      }

      // 2. Sirf is student ke Personal Notices fetch karein
      if (mobile != null) {
        final DatabaseReference personalRef = FirebaseDatabase.instance.ref("notices/personal/$mobile");
        final DataSnapshot personalSnap = await personalRef.get();
        
        if (personalSnap.exists) {
          Map personalData = personalSnap.value as Map;
          personalData.forEach((key, value) {
            tempNotices.add({
              "title": value['title'] ?? "Personal Alert",
              "message": value['message'] ?? "",
              "date": value['date'] ?? "",
              "type": "Important Notice",
            });
          });
        }
      }

      // Notices ko Date ke hisaab se sort karein (Naye notices sabse upar)
      tempNotices.sort((a, b) => b['date'].compareTo(a['date']));

      if (mounted) {
        setState(() {
          _notices = tempNotices;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading notices: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notices & Alerts')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notices.isEmpty
              ? const Center(
                  child: Text(
                    "No notices for now!",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: _notices.length,
                  itemBuilder: (context, index) {
                    var notice = _notices[index];
                    bool isPersonal = notice['type'] == "Important Notice";

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isPersonal ? Colors.red.shade300 : Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    notice['title'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isPersonal ? Colors.red : Colors.blue,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPersonal ? Colors.red.shade50 : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _formatDate(notice['date']),
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              notice['message'],
                              style: const TextStyle(fontSize: 15, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  // Date ko padhne layak format me badalna (Jaise 2026-06-10 se 10 Jun 2026)
  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return "";
    try {
      DateTime date = DateTime.parse(isoDate);
      List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return "${date.day} ${months[date.month - 1]} ${date.year}";
    } catch (e) {
      return isoDate; // Agar convert na ho paye toh waise hi dikha do
    }
  }
}
