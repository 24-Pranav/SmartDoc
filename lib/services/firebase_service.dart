import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ... (existing methods)

  Future<void> registerFaculty({
    required String email,
    required String password,
    required String name,
    required String department,
    required String contactNumber,
  }) async {
    // Note: This method should ideally be called from a secure admin environment.
    // For this example, we'll assume it's called from the faculty registration screen.
    
    // First, create the user in Firebase Auth
    // We won't sign them in, just create the user.
    // A more robust solution would use a server-side function to create the user.
    
    // Create a temporary user to get a UID
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        // Now, store the faculty details in Firestore with the UID
        await _firestore.collection('faculty').doc(user.uid).set({
          'uid': user.uid, // Storing uid for easy lookup
          'name': name,
          'email': email,
          'department': department,
          'contactNumber': contactNumber,
          'isVerified': false, // Admin needs to approve
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Optionally, sign the user out immediately after registration
        await _auth.signOut();
        
      } else {
        throw Exception('User could not be created.');
      }
    } on FirebaseAuthException catch (e) {
      // Provide more specific error messages
      if (e.code == 'weak-password') {
        throw Exception('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('An account already exists for that email.');
      } else {
        throw Exception(e.message);
      }
    } catch (e) {
      throw Exception('An unknown error occurred: $e');
    }
  }

  Stream<QuerySnapshot> getUnverifiedFaculty() {
    return _firestore
        .collection('faculty')
        .where('isVerified', isEqualTo: false)
        .snapshots();
  }

  Future<void> verifyFaculty(String uid) {
    return _firestore.collection('faculty').doc(uid).update({'isVerified': true});
  }

  Stream<QuerySnapshot> getUsersByRole(String role) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: role)
        .snapshots();
  }

  Stream<QuerySnapshot> getFaculty() {
    return _firestore.collection('faculty').snapshots();
  }

  Future<void> deleteUser(String userId) async {
    // This is a simplified deletion. In a real app, you would want to handle this
    // with a cloud function to ensure atomicity and handle related data.
    await _firestore.collection('users').doc(userId).delete();
    // Note: Deleting from Firebase Auth is a privileged operation and should
    // be handled by a backend service for security reasons.
  }

  Future<void> deleteFaculty(String facultyId) async {
    await _firestore.collection('faculty').doc(facultyId).delete();
    // Note: Deleting from Firebase Auth should be handled by a backend service.
  }

  // ... (rest of the file)
}
