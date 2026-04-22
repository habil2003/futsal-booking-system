import 'base_api_service.dart';

class RevenueApi {
  // Admin Revenue Endpoints
  static Future<Map<String, dynamic>> getRevenueOverview({String period = "month"}) async {
    try {
      return await BaseApiService.get('admin/revenue/overview?period=$period');
    } catch (e) {
      return {'data': {'totalRevenue': 0, 'totalBookings': 0}};
    }
  }

  static Future<Map<String, dynamic>> getCommissionBreakdown({int? futsalId, String? from, String? to}) async {
    try {
      String url = 'admin/revenue/commission-breakdown';
      if (futsalId != null) url += '?futsalId=$futsalId';
      if (from != null && to != null) url += '&from=$from&to=$to';
      return await BaseApiService.get(url);
    } catch (e) {
      return {'data': {'breakdown': [], 'totals': {}}};
    }
  }

  static Future<Map<String, dynamic>> getRevenueTrends({String interval = "daily", int days = 30}) async {
    try {
      return await BaseApiService.get('admin/revenue/trends?interval=$interval&days=$days');
    } catch (e) {
      return {'data': []};
    }
  }

  static Future<List<dynamic>> getPayoutRequests({String status = "PENDING"}) async {
    try {
      final response = await BaseApiService.get('admin/revenue/payouts?status=$status');
      return response['data'] ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> processPayout(int payoutId, {String? notes}) async {
    try {
      return await BaseApiService.post('admin/revenue/payouts/$payoutId/process', notes != null ? {'notes': notes} : {});
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateCommissionRate(double rate) async {
    try {
      return await BaseApiService.put('admin/revenue/commission-rate', {'rate': rate});
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<double> getCommissionRate() async {
    try {
      final response = await BaseApiService.get('admin/revenue/commission-rate');
      return response['data']?['rate'] ?? 5.0;
    } catch (e) {
      return 5.0;
    }
  }

  // Owner Earnings Endpoints
  static Future<Map<String, dynamic>> getEarningsOverview({String period = "month"}) async {
    try {
      return await BaseApiService.get('owner/earnings/overview?period=$period');
    } catch (e) {
      return {'data': {'totalEarnings': 0, 'pendingEarnings': 0}};
    }
  }

  static Future<Map<String, dynamic>> getEarningsBreakdown({int? futsalId, String? from, String? to}) async {
    try {
      String url = 'owner/earnings/breakdown';
      if (futsalId != null) url += '?futsalId=$futsalId';
      if (from != null && to != null) url += '&from=$from&to=$to';
      return await BaseApiService.get(url);
    } catch (e) {
      return {'data': {'breakdown': [], 'totals': {}}};
    }
  }

  static Future<Map<String, dynamic>> getEarningsHistory({int page = 1, int limit = 20}) async {
    try {
      return await BaseApiService.get('owner/earnings/history?page=$page&limit=$limit');
    } catch (e) {
      return {'data': {'transactions': [], 'pagination': {}}};
    }
  }

  static Future<Map<String, dynamic>> getEarningsChart({int days = 30}) async {
    try {
      return await BaseApiService.get('owner/earnings/chart?days=$days');
    } catch (e) {
      return {'data': []};
    }
  }

  static Future<Map<String, dynamic>> requestPayout() async {
    try {
      return await BaseApiService.post('owner/earnings/request-payout', {});
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<List<dynamic>> getPayoutHistory() async {
    try {
      final response = await BaseApiService.get('owner/earnings/payouts');
      return response['data'] ?? [];
    } catch (e) {
      return [];
    }
  }
}