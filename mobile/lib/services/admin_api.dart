import 'base_api_service.dart';

class AdminApi {
  static Future<Map<String, dynamic>> getDashboard() async {
    return await BaseApiService.get('admin/dashboard');
  }

  static Future<Map<String, dynamic>> getAllUsers() async {
    return await BaseApiService.get('admin/users');
  }

  static Future<Map<String, dynamic>> approveOwner(int userId) async {
    return await BaseApiService.patch('admin/users/$userId/approve-owner', {});
  }

  static Future<Map<String, dynamic>> getPendingFutsals() async {
    return await BaseApiService.get('admin/futsals/pending');
  }

  static Future<Map<String, dynamic>> approveFutsal(int futsalId) async {
    return await BaseApiService.patch('admin/futsals/$futsalId/approve', {});
  }

  static Future<Map<String, dynamic>> rejectFutsal(int futsalId) async {
    return await BaseApiService.patch('admin/futsals/$futsalId/reject', {});
  }

  static Future<Map<String, dynamic>> getAllFutsals() async {
    try {
      final response = await BaseApiService.get('admin/futsals');
      return response;
    } catch (e) {
      return {'data': []};
    }
  }

  static Future<Map<String, dynamic>> getAdminBookings({
    String status = 'ALL',
    String? from,
    String? to,
    int page = 1,
  }) async {
    try {
      String endpoint = 'admin/bookings?status=$status&page=$page';
      if (from != null && to != null) {
        endpoint += '&from=$from&to=$to';
      }
      return await BaseApiService.get(endpoint);
    } catch (e) {
      return {'bookings': [], 'total': 0};
    }
  }

  static Future<Map<String, dynamic>> getAdminAnalytics() async {
    try {
      return await BaseApiService.get('admin/analytics');
    } catch (e) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> updateAdminProfile(Map<String, dynamic> data) async {
    return await BaseApiService.put('admin/profile', data);
  }

  static Future<Map<String, dynamic>> getSystemSettings() async {
    try {
      return await BaseApiService.get('admin/settings');
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateSystemSettings(Map<String, dynamic> data) async {
    return await BaseApiService.put('admin/settings', data);
  }

    // ============================================
  // ADMIN FUTSAL MANAGEMENT (Deactivate/Activate/Delete)
  // ============================================

  /// Admin deactivate futsal (owner cannot reactivate)
  static Future<Map<String, dynamic>> adminDeactivateFutsal(int futsalId) async {
    try {
      return await BaseApiService.patch('admin/futsals/$futsalId/admin-deactivate', {});
    } catch (e) {
      print('Admin deactivate futsal error: $e');
      rethrow;
    }
  }

  /// Admin activate futsal
  static Future<Map<String, dynamic>> adminActivateFutsal(int futsalId) async {
    try {
      return await BaseApiService.patch('admin/futsals/$futsalId/admin-activate', {});
    } catch (e) {
      print('Admin activate futsal error: $e');
      rethrow;
    }
  }

  /// Admin delete futsal (permanent)
  static Future<Map<String, dynamic>> adminDeleteFutsal(int futsalId) async {
    try {
      return await BaseApiService.delete('admin/futsals/$futsalId');
    } catch (e) {
      print('Admin delete futsal error: $e');
      rethrow;
    }
  }
}