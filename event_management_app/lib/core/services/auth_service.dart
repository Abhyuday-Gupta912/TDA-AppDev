// core/services/auth_service.dart
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'api_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Get current user stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Get user data from Firestore
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        Map<String, dynamic> userData =
            userDoc.data() as Map<String, dynamic>? ?? {};

        // Merge Firebase user data with Firestore user data
        final user = {
          '_id': userCredential.user!.uid,
          'email': userCredential.user!.email ?? email,
          'firstName': userData['firstName'] ?? '',
          'lastName': userData['lastName'] ?? '',
          'phone': userData['phone'] ?? '',
          'profileImage':
              userData['profileImage'] ?? userCredential.user!.photoURL,
          'isAdmin': userData['isAdmin'] ?? false,
          'createdAt':
              userData['createdAt'] ?? DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'registeredEvents': userData['registeredEvents'] ?? [],
          'bookmarkedEvents': userData['bookmarkedEvents'] ?? [],
        };

        // Get ID token
        String? token = await userCredential.user!.getIdToken();

        return {
          'success': true,
          'token': token,
          'user': user,
        };
      } else {
        return {
          'success': false,
          'message': 'Login failed',
        };
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for this email.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'user-disabled':
          message = 'This user account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many login attempts. Please try again later.';
          break;
        default:
          message = e.message ?? 'Login failed';
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please try again.',
      };
    }
  }

  static Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Update display name
        await userCredential.user!.updateDisplayName('$firstName $lastName');

        // Create user document in Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
          'phone': phone,
          'profileImage': null,
          'isAdmin': false,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'registeredEvents': [],
          'bookmarkedEvents': [],
        });

        final user = {
          '_id': userCredential.user!.uid,
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
          'phone': phone,
          'profileImage': null,
          'isAdmin': false,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'registeredEvents': [],
          'bookmarkedEvents': [],
        };

        // Get ID token
        String? token = await userCredential.user!.getIdToken();

        return {
          'success': true,
          'token': token,
          'user': user,
        };
      } else {
        return {
          'success': false,
          'message': 'Signup failed',
        };
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      switch (e.code) {
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          message = 'An account already exists for this email.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are not enabled.';
          break;
        default:
          message = e.message ?? 'Signup failed';
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please try again.',
      };
    }
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Password reset email sent successfully.',
      };
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for this email.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        default:
          message = e.message ?? 'Failed to send reset email';
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please try again.',
      };
    }
  }

  static Future<Map<String, dynamic>?> validateToken(String token) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Get user data from Firestore
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          return {
            '_id': user.uid,
            'email': user.email ?? userData['email'],
            'firstName': userData['firstName'] ?? '',
            'lastName': userData['lastName'] ?? '',
            'phone': userData['phone'] ?? '',
            'profileImage': userData['profileImage'] ?? user.photoURL,
            'isAdmin': userData['isAdmin'] ?? false,
            'createdAt':
                userData['createdAt'] ?? DateTime.now().toIso8601String(),
            'updatedAt':
                userData['updatedAt'] ?? DateTime.now().toIso8601String(),
            'registeredEvents': userData['registeredEvents'] ?? [],
            'bookmarkedEvents': userData['bookmarkedEvents'] ?? [],
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to logout');
    }
  }

  // Additional Firebase-specific methods
  static Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImage,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        Map<String, dynamic> updateData = {
          'updatedAt': DateTime.now().toIso8601String(),
        };

        if (firstName != null) updateData['firstName'] = firstName;
        if (lastName != null) updateData['lastName'] = lastName;
        if (phone != null) updateData['phone'] = phone;
        if (profileImage != null) updateData['profileImage'] = profileImage;

        await _firestore.collection('users').doc(user.uid).update(updateData);

        // Update display name if first or last name changed
        if (firstName != null || lastName != null) {
          DocumentSnapshot userDoc =
              await _firestore.collection('users').doc(user.uid).get();
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          String displayName =
              '${userData['firstName']} ${userData['lastName']}';
          await user.updateDisplayName(displayName);
        }
      }
    } catch (e) {
      throw Exception('Failed to update profile');
    }
  }

  static Future<void> updatePassword(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      }
    } catch (e) {
      throw Exception('Failed to update password');
    }
  }
}
