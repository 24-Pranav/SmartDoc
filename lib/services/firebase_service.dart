
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reverted to the simpler getToken method. No forced refresh is needed.
  Future<String?> getAuthToken() async {
    final user = _auth.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }

  // ... (existing methods)

  Future<void> registerFaculty({
    required String email,
    required String password,
    required String name,
    required String department,
    required String contactNumber,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        final WriteBatch batch = _firestore.batch();
        final facultyRef = _firestore.collection('faculty').doc(user.uid);
        final userRef = _firestore.collection('users').doc(user.uid);

        batch.set(facultyRef, {
          'uid': user.uid,
          'name': name,
          'email': email,
          'department': department,
          'contactNumber': contactNumber,
          'isVerified': false, 
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending', 
        });

        batch.set(userRef, {
          'email': email,
          'role': 'faculty',
          'name': name,
        });

        await batch.commit();

        await _auth.signOut();

      } else {
        throw Exception('User could not be created.');
      }
    } on FirebaseAuthException catch (e) {
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
    final facultyRef = _firestore.collection('faculty').doc(uid);

    return facultyRef.update({
      'isVerified': true,
      'status': 'approved',
    });
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
    await _firestore.collection('users').doc(userId).delete();
  }

  Future<void> deleteFaculty(String facultyId) async {
    final WriteBatch batch = _firestore.batch();
    final facultyRef = _firestore.collection('faculty').doc(facultyId);
    final userRef = _firestore.collection('users').doc(facultyId);

    batch.delete(facultyRef);
    batch.delete(userRef);

    await batch.commit();
  }

  // ... (rest of the file)
}
