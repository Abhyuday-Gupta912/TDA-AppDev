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
      final user = _auth.currentUser;
      if (user != null) {
        Map<String, dynamic> updates = {};
        if (firstName != null) updates['firstName'] = firstName;
        if (lastName != null) updates['lastName'] = lastName;
        if (phone != null) updates['phone'] = phone;
        if (profileImage != null) updates['profileImage'] = profileImage;

        updates['updatedAt'] = DateTime.now().toIso8601String();

        await _firestore.collection('users').doc(user.uid).update(updates);

        // Update display name if firstName or lastName changed
        if (firstName != null || lastName != null) {
          final userDoc =
              await _firestore.collection('users').doc(user.uid).get();
          final userData = userDoc.data() as Map<String, dynamic>;
          final displayName =
              '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'
                  .trim();
          await user.updateDisplayName(displayName);
        }
      }
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  /// Admin-specific methods

  /// Create admin user with special admin code
  static Future<Map<String, dynamic>> signupAdmin({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String adminCode,
  }) async {
    try {
      // Verify admin code (you can change this secret code)
      const validAdminCode =
          "ADMIN2024EVENT"; // Change this to your preferred admin code

      if (adminCode != validAdminCode) {
        return {
          'success': false,
          'message': 'Invalid admin code',
        };
      }

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Update display name
        await userCredential.user!.updateDisplayName('$firstName $lastName');

        // Create admin user document in Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
          'phone': phone,
          'profileImage': null,
          'isAdmin': true, // This makes the user an admin
          'adminLevel': 'super', // Optional: different admin levels
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
          'isAdmin': true,
          'adminLevel': 'super',
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
          'message': 'Admin signup failed',
        };
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered.';
          break;
        case 'weak-password':
          message = 'Password is too weak.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        default:
          message = e.message ?? 'Admin signup failed';
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

  /// Promote existing user to admin (only super admins can do this)
  static Future<Map<String, dynamic>> promoteToAdmin(String userEmail) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      // Check if current user is super admin
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final currentUserData =
          currentUserDoc.data() as Map<String, dynamic>? ?? {};

      if (currentUserData['isAdmin'] != true ||
          currentUserData['adminLevel'] != 'super') {
        return {
          'success': false,
          'message': 'Only super admins can promote users',
        };
      }

      // Find user by email
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        return {
          'success': false,
          'message': 'User not found',
        };
      }

      final userDoc = userQuery.docs.first;

      // Update user to admin
      await userDoc.reference.update({
        'isAdmin': true,
        'adminLevel': 'standard',
        'promotedAt': DateTime.now().toIso8601String(),
        'promotedBy': currentUser.uid,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return {
        'success': true,
        'message': 'User promoted to admin successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to promote user: ${e.toString()}',
      };
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
