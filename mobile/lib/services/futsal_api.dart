import 'base_api_service.dart';

class FutsalApi {
  static Future<List<dynamic>> getMyFutsals() async {
    try {
      final response = await BaseApiService.get('futsals/my');
      return response['futsals'] ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> createFutsal(Map<String, dynamic> futsalData) async {
    // Return the full response which includes payment info
    return await BaseApiService.post('futsals', futsalData);
  }

  static Future<Map<String, dynamic>> updateFutsal(int id, Map<String, dynamic> futsalData) async {
    return await BaseApiService.put('futsals/$id', futsalData);
  }

  static Future<Map<String, dynamic>> deleteFutsal(int id) async {
    return await BaseApiService.delete('futsals/$id');
  }

  static Future<List<dynamic>> getCourts(int futsalId) async {
    try {
      return await BaseApiService.getList('futsals/$futsalId/courts');
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getDashboardStats(int futsalId) async {
    try {
      return await BaseApiService.get('owner/dashboard/stats?futsalId=$futsalId');
    } catch (e) {
      return {
        'totalCourts': 0,
        'todayBookings': 0,
        'todayRevenue': 0,
        'pendingApprovals': 0,
      };
    }
  }

  static Future<List<dynamic>> getWeeklyRevenue(int futsalId) async {
    try {
      final response = await BaseApiService.get('owner/dashboard/weekly-revenue?futsalId=$futsalId');
      return response['revenue'] ?? [0, 0, 0, 0, 0, 0, 0];
    } catch (e) {
      return [0, 0, 0, 0, 0, 0, 0];
    }
  }

  static Future<Map<String, dynamic>> getPeakHours(int futsalId) async {
    try {
      final response = await BaseApiService.get('owner/dashboard/peak-hours?futsalId=$futsalId');
      return response['peakHours'] ?? {};
    } catch (e) {
      return {};
    }
  }

  // ============================================
  // REGISTRATION FEE PAYMENT METHODS (NEW)
  // ============================================
  
  /// Initiate Khalti payment for futsal registration fee
  static Future<Map<String, dynamic>> initiateRegistrationPayment(int futsalId) async {
    return await BaseApiService.post('futsals/initiate-registration-payment', {
      'futsalId': futsalId,
    });
  }

  /// Verify Khalti payment for futsal registration fee
  static Future<Map<String, dynamic>> verifyRegistrationPayment(String pidx, int futsalId) async {
    return await BaseApiService.post('futsals/verify-registration-payment', {
      'pidx': pidx,
      'futsalId': futsalId,
    });
  }
}