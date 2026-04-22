import 'base_api_service.dart';

class AuthApi {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    return await BaseApiService.post('auth/login', {
      'email': email,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    return await BaseApiService.post('auth/register', userData);
  }

  static Future<Map<String, dynamic>> verifyEmail(String email, String otp) async {
    return await BaseApiService.post('auth/verify-email', {'email': email, 'otp': otp});
  }

  static Future<Map<String, dynamic>> resendOtp(String email) async {
    return await BaseApiService.post('auth/resend-otp', {'email': email});
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    return await BaseApiService.post('auth/forgot-password', {'email': email});
  }

  static Future<Map<String, dynamic>> resetPassword(
      String email, String otp, String newPassword) async {
    return await BaseApiService.post('auth/reset-password', {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    });
  }
}