import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RevenueProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;

  double _bookingRevenue = 0;
double _registrationRevenue = 0;

double get bookingRevenue => _bookingRevenue;
double get registrationRevenue => _registrationRevenue;

  // Admin Revenue Data
  Map<String, dynamic> _revenueOverview = {};
  Map<String, dynamic> get revenueOverview => _revenueOverview;

  List<dynamic> _commissionBreakdown = [];
  List<dynamic> get commissionBreakdown => _commissionBreakdown;

  Map<String, dynamic> _commissionTotals = {};
  Map<String, dynamic> get commissionTotals => _commissionTotals;

  List<dynamic> _revenueTrends = [];
  List<dynamic> get revenueTrends => _revenueTrends;

  List<dynamic> _payoutRequests = [];
  List<dynamic> get payoutRequests => _payoutRequests;

  // Owner Earnings Data
  Map<String, dynamic> _earningsOverview = {};
  Map<String, dynamic> get earningsOverview => _earningsOverview;

  List<dynamic> _earningsBreakdown = [];
  List<dynamic> get earningsBreakdown => _earningsBreakdown;

  Map<String, dynamic> _earningsTotals = {};
  Map<String, dynamic> get earningsTotals => _earningsTotals;

  List<dynamic> _earningsHistory = [];
  List<dynamic> get earningsHistory => _earningsHistory;

  Map<String, dynamic> _earningsPagination = {};
  Map<String, dynamic> get earningsPagination => _earningsPagination;

  List<dynamic> _earningsChart = [];
  List<dynamic> get earningsChart => _earningsChart;

  List<dynamic> _payoutHistory = [];
  List<dynamic> get payoutHistory => _payoutHistory;

  double _commissionRate = 5.0;
  double get commissionRate => _commissionRate;

  // ============================================
  // ADMIN REVENUE METHODS
  // ============================================

Future<void> loadRevenueOverview({String period = "month"}) async {
  isLoading = true;
  error = null;
  notifyListeners();

  try {
    final response = await ApiService.getRevenueOverview(period: period);
    final data = response['data'] ?? {};
    
    _revenueOverview = data;
    
    // ✅ ADD THESE LINES - Parse booking and registration revenue
    _bookingRevenue = (data['bookingRevenue'] ?? 0).toDouble();
    _registrationRevenue = (data['registrationRevenue'] ?? 0).toDouble();
    
    print('📊 Revenue loaded - Booking: $_bookingRevenue, Registration: $_registrationRevenue, Total: ${data['totalRevenue']}');
    
    isLoading = false;
    notifyListeners();
  } catch (e) {
    error = e.toString();
    isLoading = false;
    notifyListeners();
  }
}

  Future<void> loadCommissionBreakdown({int? futsalId, String? from, String? to}) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.getCommissionBreakdown(futsalId: futsalId, from: from, to: to);
      _commissionBreakdown = response['data']?['breakdown'] ?? [];
      _commissionTotals = response['data']?['totals'] ?? {};
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRevenueTrends({String interval = "daily", int days = 30}) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.getRevenueTrends(interval: interval, days: days);
      _revenueTrends = response['data'] ?? [];
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPayoutRequests({String status = "PENDING"}) async {
    isLoading = true;
    notifyListeners();

    try {
      _payoutRequests = await ApiService.getPayoutRequests(status: status);
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> processPayout(int payoutId, {String? notes}) async {
    try {
      final response = await ApiService.processPayout(payoutId, notes: notes);
      if (response['status'] == 'success') {
        await loadPayoutRequests();
      }
      return response;
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<void> loadCommissionRate() async {
    try {
      _commissionRate = await ApiService.getCommissionRate();
      notifyListeners();
    } catch (e) {
      debugPrint('Load commission rate error: $e');
    }
  }

  Future<Map<String, dynamic>> updateCommissionRate(double rate) async {
    try {
      final response = await ApiService.updateCommissionRate(rate);
      if (response['status'] == 'success') {
        _commissionRate = rate;
        notifyListeners();
      }
      return response;
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ============================================
  // OWNER EARNINGS METHODS
  // ============================================

Future<void> loadEarningsOverview({String period = "month"}) async {
  isLoading = true;
  error = null;
  notifyListeners();

  try {
    final response = await ApiService.getEarningsOverview(period: period);
    _earningsOverview = response['data'] ?? {};
    print('🔵 Earnings overview: $_earningsOverview'); // Debug print
    isLoading = false;
    notifyListeners();
  } catch (e) {
    error = e.toString();
    isLoading = false;
    notifyListeners();
  }
}

  Future<void> loadEarningsBreakdown({int? futsalId, String? from, String? to}) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.getEarningsBreakdown(futsalId: futsalId, from: from, to: to);
      _earningsBreakdown = response['data']?['breakdown'] ?? [];
      _earningsTotals = response['data']?['totals'] ?? {};
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadEarningsHistory({int page = 1, int limit = 20}) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.getEarningsHistory(page: page, limit: limit);
      _earningsHistory = response['data']?['transactions'] ?? [];
      _earningsPagination = response['data']?['pagination'] ?? {};
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadEarningsChart({int days = 30}) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.getEarningsChart(days: days);
      _earningsChart = response['data'] ?? [];
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> requestPayout() async {
    try {
      final response = await ApiService.requestPayout();
      if (response['status'] == 'success') {
        await loadEarningsOverview();
        await loadPayoutHistory();
      }
      return response;
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<void> loadPayoutHistory() async {
    isLoading = true;
    notifyListeners();

    try {
      _payoutHistory = await ApiService.getPayoutHistory();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  void clearData() {
    _revenueOverview = {};
    _commissionBreakdown = [];
    _commissionTotals = {};
    _revenueTrends = [];
    _payoutRequests = [];
    _earningsOverview = {};
    _earningsBreakdown = [];
    _earningsTotals = {};
    _earningsHistory = [];
    _earningsChart = [];
    _payoutHistory = [];
    error = null;
    notifyListeners();
  }
}