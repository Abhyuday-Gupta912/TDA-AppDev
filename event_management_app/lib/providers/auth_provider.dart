import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user_model.dart';
import '../core/services/auth_service.dart';
import '../core/services/storage_service.dart' as storage;

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _setLoading(true);
    try {
      // Listen to Firebase auth state changes
      AuthService.authStateChanges
          .listen((firebase_auth.User? firebaseUser) async {
        if (firebaseUser != null) {
          // User is signed in, get user data from Firestore
          try {
            final token = await firebaseUser.getIdToken();
            if (token != null) {
              final userData = await AuthService.validateToken(token);
              if (userData != null) {
                _user = User.fromJson(userData);
                await storage.StorageService.setToken(token);
                await storage.StorageService.setUser(_user!);
              }
            }
          } catch (e) {
            _setError('Failed to load user data');
          }
        } else {
          // User is signed out
          _user = null;
          await storage.StorageService.clearAll();
        }
        _isInitialized = true;
        notifyListeners();
      });

      // Check if user is already authenticated
      final token = await storage.StorageService.getToken();
      if (token != null) {
        final userData = await AuthService.validateToken(token);
        if (userData != null) {
          _user = User.fromJson(userData);
        }
      }
    } catch (e) {
      _setError('Failed to initialize authentication');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await AuthService.login(email, password);

      if (response['success']) {
        _user = User.fromJson(response['user']);
        await storage.StorageService.setToken(response['token']);
        await storage.StorageService.setUser(_user!);
        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'Login failed');
        return false;
      }
    } catch (e) {
      _setError('Network error. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await AuthService.signup(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );

      if (response['success']) {
        _user = User.fromJson(response['user']);
        await storage.StorageService.setToken(response['token']);
        await storage.StorageService.setUser(_user!);
        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'Signup failed');
        return false;
      }
    } catch (e) {
      _setError('Network error. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);

    try {
      await AuthService.logout();
      await storage.StorageService.clearAll();
      _user = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to logout');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await AuthService.forgotPassword(email);

      if (response['success']) {
        return true;
      } else {
        _setError(response['message'] ?? 'Failed to send reset email');
        return false;
      }
    } catch (e) {
      _setError('Network error. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImage,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      await AuthService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        profileImage: profileImage,
      );

      // Update local user data
      if (_user != null) {
        _user = _user!.copyWith(
          firstName: firstName ?? _user!.firstName,
          lastName: lastName ?? _user!.lastName,
          phone: phone ?? _user!.phone,
          profileImage: profileImage ?? _user!.profileImage,
          updatedAt: DateTime.now(),
        );
        await storage.StorageService.setUser(_user!);
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to update profile');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    _setLoading(true);
    _setError(null);

    try {
      await AuthService.updatePassword(newPassword);
      return true;
    } catch (e) {
      _setError('Failed to update password');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
