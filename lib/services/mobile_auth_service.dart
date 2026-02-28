import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MobileAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Student Registration
  Future<String?> registerStudent({
    required String name,
    required String rollNo,
    required String password,
    required String contact,
    required String branch,
  }) async {
    try {
      // Map Roll Number to a fake email for Firebase
      String email = "${rollNo.trim()}@gpcs.com";

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save Student Details to the 'users' collection
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': name,
        'rollNo': rollNo,
        'contact': contact,
        'branch': branch,
        'status': 'Pending', // New students start as pending
        'role': 'student',
      });
      return "Success";
    } catch (e) {
      return e.toString();
    }
  }

  // Student Login
  Future<String?> loginStudent(String rollNo, String password) async {
    try {
      String email = "${rollNo.trim()}@gpcs.com";
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return "Success";
    } catch (e) {
      return e.toString();
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}