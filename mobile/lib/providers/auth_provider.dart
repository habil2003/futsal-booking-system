import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  bool get isOwner => _user?.role == 'OWNER';
  bool get isPlayer => _user?.role == 'PLAYER';
  bool get isAdmin => _user?.role == 'ADMIN';
  Map<String, dynamic> _adminProfile = {};
  Map<String, dynamic> get adminProfile => _adminProfile;

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.login(email, password);

      debugPrint('📦 AuthProvider login response: $response');

      if (response['status'] == 'success') {
        if (response.containsKey('user')) {
          _user = User.fromJson(response['user']);
        } else if (response.containsKey('data') &&
            response['data'].containsKey('user')) {
          _user = User.fromJson(response['data']['user']);
        }

        _token = response['token'] ??
            response['data']?['token'] ??
            response['accessToken'];

        if (_token != null && _user != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', _token!);
          await prefs.setString('user', jsonEncode(_user!.toJson()));

          debugPrint('👤 User Logged In: ${_user!.role}');
        }
      } else if (response['requiresVerification'] == true) {
        debugPrint('⚠️ User needs email verification');
      }

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {"status": "error", "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.register(userData);

      debugPrint('📦 AuthProvider register response: $response');

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {"status": "error", "message": "Connection error: $e"};
    }
  }

  Future<void> navigateBasedOnRole(BuildContext context) async {
    if (!isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    if (isAdmin) {
      debugPrint('🚀 Navigating to Admin Dashboard');
      Navigator.pushReplacementNamed(context, '/admin/dashboard');
    } else if (isOwner) {
      debugPrint('🚀 Navigating to Owner Dashboard');
      Navigator.pushReplacementNamed(context, '/owner/dashboard');
    } else if (isPlayer) {
      debugPrint('🚀 Navigating to Player Home');
      Navigator.pushReplacementNamed(context, '/player/home');
    } else {
      debugPrint('⚠️ Unknown role, navigating to login');
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    _token = null;
    _user = null;
    notifyListeners();
  }

  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userString = prefs.getString('user');

    if (token != null && userString != null) {
      _token = token;
      _user = User.fromJson(jsonDecode(userString));
      debugPrint('🔄 Restored user session: ${_user?.role}');
      notifyListeners();
    }
  }

  Future<void> saveAuthData(String token, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', json.encode(userData));
    _user = User.fromJson(userData);
    _token = token;
    notifyListeners();
  }

  Future<void> loadAdminProfile() async {
    if (!isAdmin) return;

    try {
      final response = await ApiService.get('admin/profile');
      if (response['status'] == 'success') {
        _adminProfile = response['data'] ?? {};
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Load admin profile error: $e');
    }
  }

  // Update current user data (call after profile update)
  void updateUser(Map<String, dynamic> userData) {
    if (_user != null) {
      _user = User.fromJson({
        ..._user!.toJson(),
        ...userData,
      });
      notifyListeners();
      _saveUserToStorage();
    }
  }

  // Refresh user data from server (call after profile update)
  Future<void> refreshUser() async {
    try {
      final response = await ApiService.get('users/me');
      if (response['status'] == 'success') {
        _user = User.fromJson(response['user']);
        await _saveUserToStorage();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing user: $e');
    }
  }

  // Helper to save user to storage
  Future<void> _saveUserToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(_user!.toJson()));
  }

  // Helper method to get role-based home route
  String get homeRoute {
    if (isAdmin) return '/admin/dashboard';
    if (isOwner) return '/owner/dashboard';
    if (isPlayer) return '/player/home';
    return '/login';
  }
}