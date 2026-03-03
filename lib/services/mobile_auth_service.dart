import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MobileAuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Updated Student Login (Roll No + Contact/Custom Password)
  Future<String?> loginStudent(String rollNo, String password) async {
    try {
      // Fetch the document directly using Roll No as ID
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(rollNo.trim()).get();

      if (!userDoc.exists) {
        return "Student record not found. Please contact the warden.";
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Check for custom password first, then fallback to mobile number
      // Matches 'contact' field from your bulk upload
      String correctPassword = (userData['customPassword'] ?? userData['contact']).toString();

      if (password == correctPassword) {
        // Save session locally to keep the student logged in
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_roll', rollNo.trim());
        await prefs.setBool('is_logged_in', true);

        return "Success";
      } else {
        return "Incorrect password. Use your registered mobile number.";
      }
    } catch (e) {
      return "Login Error: ${e.toString()}";
    }
  }

  // 2. Sign Out logic
  Future<void> signOut() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}