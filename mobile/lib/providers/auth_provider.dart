import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
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

  Future<void> _loadStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      final userJson = prefs.getString('user');
      if (userJson != null && userJson.isNotEmpty) {
        _user = User.fromJson(jsonDecode(userJson));
      }
    } catch (e) {
      debugPrint('Error loading stored data: $e');
    }
    notifyListeners();
  }

  // ============================================
  // AUTH METHODS
  // ============================================

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.login(email, password);

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
          await prefs.setString('user', json.encode(_user!.toJson()));
          debugPrint('👤 User Logged In: ${_user!.role}');
        }
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
      Navigator.pushReplacementNamed(context, '/admin/dashboard');
    } else if (isOwner) {
      Navigator.pushReplacementNamed(context, '/owner/dashboard');
    } else if (isPlayer) {
      Navigator.pushReplacementNamed(context, '/player/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> logout({BuildContext? context}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    
    _token = null;
    _user = null;
    _adminProfile = {};

    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    
    try {
      final accessToken = await FacebookAuth.instance.accessToken;
      if (accessToken != null) {
        await FacebookAuth.instance.logOut();
      }
    } catch (_) {}
    
    notifyListeners();
    
    if (context != null && context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Future<void> checkAuth() async {
    await _loadStoredData();
    if (_token != null && _user != null) {
      debugPrint('🔄 Restored user session: ${_user?.role}');
    } else {
      debugPrint('⚠️ No session found');
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

  void updateUser(Map<String, dynamic> userData) async {
    if (_user != null) {
      _user = User.fromJson({
        ..._user!.toJson(),
        ...userData,
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', json.encode(_user!.toJson()));
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    try {
      final response = await ApiService.get('auth/me');
      if (response['status'] == 'success') {
        _user = User.fromJson(response['user']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(_user!.toJson()));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing user: $e');
    }
  }

  Future<bool> updateProfileImage(dynamic imageFile) async {
    try {
      final response = await ApiService.uploadProfileImage(imageFile);
      if (response['status'] == 'success' && response['profileImage'] != null && _user != null) {
        await refreshUser();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating profile image: $e');
      return false;
    }
  }

  String get homeRoute {
    if (isAdmin) return '/admin/dashboard';
    if (isOwner) return '/owner/dashboard';
    if (isPlayer) return '/player/home';
    return '/login';
  }

  Future<void> setUserAndToken(String token, Map<String, dynamic> user) async {
    await saveAuthData(token, user);
  }

  Future<void> tryAutoLogin() async {
    await checkAuth();
  }
}