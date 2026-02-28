import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> loginUser(String email, String password) async {
    try {
      // 1. Authenticate user
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password.trim()
      );

      User? user = result.user;

      if (user != null) {
        // 2. Fetch user document using the UID
        DocumentSnapshot doc = await _db.collection('users').doc(user.uid).get();

        if (doc.exists) {
          // Fetch raw role (lowercase in DB) and normalize for UI logic
          String rawRole = doc.get('role') ?? "warden";
          String normalizedRole = rawRole.toString().toLowerCase();

          // 3. Check logging toggle
          // Note: Using the exact field 'isLoggingEnabled' from your DB
          DocumentSnapshot logConfig = await _db.collection('system_settings').doc('logging_config').get();
          bool canLog = logConfig.exists ? (logConfig.get('isLoggingEnabled') ?? false) : false;

          if (canLog) {
            await _db.collection('activity_logs').add({
              'email': email.trim(),
              'event': 'User Login',
              'role': normalizedRole,
              'timestamp': FieldValue.serverTimestamp(),
            });
          }

          // Return UPPERCASE to match your UI's if-statements
          return rawRole.toString().toUpperCase();
        } else {
          return "User document missing in Firestore.";
        }
      }
      return "Authentication failed.";
    } on FirebaseAuthException catch (e) {
      // Returns specific Firebase error messages like 'wrong-password'
      return e.message;
    } catch (e) {
      return "Access Denied: Role '${e.toString()}' unauthorized";
    }
  }
}