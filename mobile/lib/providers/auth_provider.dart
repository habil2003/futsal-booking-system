import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../services/api_service.dart';
import '../models/user.dart';

// Conditionally import dart:html only for web
import 'dart:html' as html show window;

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

  // ============================================
  // TOKEN STORAGE HELPERS (Works on Mobile + Web)
  // ============================================

  Future<void> _saveToken(String token) async {
    debugPrint('💾 Saving token...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      debugPrint('✅ Token saved to SharedPreferences');
    } catch (e) {
      debugPrint('SharedPreferences save error: $e');
    }
    
    if (kIsWeb) {
      try {
        html.window.localStorage['token'] = token;
        debugPrint('✅ Token saved to localStorage');
      } catch (e) {
        debugPrint('localStorage save error: $e');
      }
    }
  }

  Future<void> _saveUser(Map<String, dynamic> userData) async {
    debugPrint('💾 Saving user data...');
    final userJson = jsonEncode(userData);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', userJson);
      debugPrint('✅ User saved to SharedPreferences');
    } catch (e) {
      debugPrint('SharedPreferences save error: $e');
    }
    
    if (kIsWeb) {
      try {
        html.window.localStorage['user'] = userJson;
        debugPrint('✅ User saved to localStorage');
      } catch (e) {
        debugPrint('localStorage save error: $e');
      }
    }
  }

  Future<String?> _getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null && token.isNotEmpty) {
        debugPrint('🔑 Token found in SharedPreferences');
        return token;
      }
    } catch (e) {
      debugPrint('SharedPreferences read error: $e');
    }
    
    if (kIsWeb) {
      try {
        final token = html.window.localStorage['token'];
        if (token != null && token.isNotEmpty && token != 'null') {
          debugPrint('🔑 Token found in localStorage');
          return token;
        }
      } catch (e) {
        debugPrint('localStorage read error: $e');
      }
    }
    
    debugPrint('⚠️ No token found');
    return null;
  }

  Future<Map<String, dynamic>?> _getStoredUser() async {
    String? userJson;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      userJson = prefs.getString('user');
    } catch (e) {
      debugPrint('SharedPreferences read error: $e');
    }
    
    if (userJson == null && kIsWeb) {
      try {
        userJson = html.window.localStorage['user'];
      } catch (e) {
        debugPrint('localStorage read error: $e');
      }
    }
    
    if (userJson != null && userJson.isNotEmpty) {
      try {
        return jsonDecode(userJson) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('User JSON parse error: $e');
      }
    }
    
    return null;
  }

  Future<void> _clearStoredData() async {
    debugPrint('🗑️ Clearing stored auth data...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');
      debugPrint('✅ Cleared from SharedPreferences');
    } catch (e) {
      debugPrint('SharedPreferences clear error: $e');
    }
    
    if (kIsWeb) {
      try {
        html.window.localStorage.remove('token');
        html.window.localStorage.remove('user');
        debugPrint('✅ Cleared from localStorage');
      } catch (e) {
        debugPrint('localStorage clear error: $e');
      }
    }
  }

  // ============================================
  // AUTH METHODS
  // ============================================

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
        } else if (response.containsKey('userData')) {
          _user = User.fromJson(response['userData']);
        }

        _token = response['token'] ??
            response['data']?['token'] ??
            response['accessToken'] ??
            response['access_token'];

        if (_token != null && _user != null) {
          await _saveToken(_token!);
          await _saveUser(_user!.toJson());
          
          if (kIsWeb) {
            try {
              await ApiService.saveToken(_token!);
            } catch (e) {
              debugPrint('ApiService saveToken error: $e');
            }
          }

          debugPrint('👤 User Logged In: ${_user!.role}');
          debugPrint('🔑 Token saved successfully');
        } else {
          debugPrint('⚠️ Missing token or user in response');
          debugPrint('Response keys: ${response.keys}');
        }
      } else if (response['requiresVerification'] == true) {
        debugPrint('⚠️ User needs email verification');
      }

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('❌ Login error: $e');
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

  Future<void> logout({BuildContext? context}) async {
    debugPrint('🚪 Logging out...');
    
    await _clearStoredData();
    
    try {
      await ApiService.clearToken();
    } catch (e) {
      debugPrint('ApiService clearToken error: $e');
    }
    
    _token = null;
    _user = null;
    _adminProfile = {};

    // Google Sign Out (only if signed in)
    try {
      final googleUser = await GoogleSignIn().currentUser;
      if (googleUser != null) {
        await GoogleSignIn().signOut();
      }
    } catch (_) {}
    
    // Facebook Sign Out (only if signed in)
    try {
      final accessToken = await FacebookAuth.instance.accessToken;
      if (accessToken != null) {
        await FacebookAuth.instance.logOut();
      }
    } catch (_) {}
    
    notifyListeners();
    debugPrint('✅ Logout complete');
    
    if (context != null && context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Future<void> checkAuth() async {
    debugPrint('🔍 Checking auth...');
    
    final token = await _getStoredToken();
    final userData = await _getStoredUser();

    if (token != null && userData != null) {
      _token = token;
      _user = User.fromJson(userData);
      debugPrint('🔄 Restored user session: ${_user?.role}');
      notifyListeners();
      
      if (kIsWeb && token.isNotEmpty) {
        try {
          await ApiService.saveToken(token);
        } catch (e) {
          debugPrint('ApiService saveToken during checkAuth error: $e');
        }
      }
    } else {
      debugPrint('⚠️ No session found');
    }
  }

  Future<void> saveAuthData(String token, Map<String, dynamic> userData) async {
    debugPrint('💾 Saving auth data...');
    await _saveToken(token);
    await _saveUser(userData);
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

  void updateUser(Map<String, dynamic> userData) {
    if (_user != null) {
      _user = User.fromJson({
        ..._user!.toJson(),
        ...userData,
      });
      notifyListeners();
      _saveUser(_user!.toJson());
    }
  }

  Future<void> refreshUser() async {
    try {
      final response = await ApiService.get('users/me');
      if (response['status'] == 'success') {
        _user = User.fromJson(response['user']);
        await _saveUser(_user!.toJson());
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing user: $e');
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