import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

// ============================================
// CHART RANGE ENUM (TOP-LEVEL)
// ============================================
enum ChartRange { week, month, year, all }

class AdminProvider with ChangeNotifier {
  bool isLoading = false;
  String? error;

  // ============================================
  // DASHBOARD STATISTICS
  // ============================================
  int totalUsers = 0;
  int totalFutsals = 0;
  int pendingApprovals = 0;
  int todayBookings = 0;
  double totalRevenue = 0;
  int totalOwners = 0;
  int totalPlayers = 0;
  int totalBookings = 0;

  // ============================================
  // LISTS
  // ============================================
  List<Map<String, dynamic>> _recentActivities = [];
  List<Map<String, dynamic>> get recentActivities => _recentActivities;

  List<Map<String, dynamic>> _pendingFutsals = [];
  List<Map<String, dynamic>> get pendingFutsals => _pendingFutsals;

  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> get allUsers => _allUsers;

  List<Map<String, dynamic>> _allFutsals = [];
  List<Map<String, dynamic>> get allFutsals => _allFutsals;

  List<Map<String, dynamic>> _allBookings = [];
  List<Map<String, dynamic>> get allBookings => _allBookings;
  int totalBookingsCount = 0;
  int totalPages = 0;

  Map<String, dynamic> _adminAnalytics = {};
  Map<String, dynamic> get adminAnalytics => _adminAnalytics;

  // ============================================
  // CHART DATA
  // ============================================
  Map<ChartRange, List<FlSpot>> _revenueByRange = {};
  Map<ChartRange, List<FlSpot>> get revenueByRange => _revenueByRange;

  Map<ChartRange, List<FlSpot>> _bookingsByRange = {};
  Map<ChartRange, List<FlSpot>> get bookingsByRange => _bookingsByRange;

  Map<String, int> _bookingStatusBreakdown = {};
  Map<String, int> get bookingStatusBreakdown => _bookingStatusBreakdown;

  bool _isRangeDataLoading = false;
  bool get isRangeDataLoading => _isRangeDataLoading;

  bool _isChartsLoading = false;
  bool get isChartsLoading => _isChartsLoading;

  // ============================================
  // ANALYTICS SECTIONS (DETAILED)
  // ============================================
  Map<String, dynamic> _bookingAnalytics = {};
  Map<String, dynamic> get bookingAnalytics => _bookingAnalytics;
  Map<String, dynamic> _revenueAnalytics = {};
  Map<String, dynamic> get revenueAnalytics => _revenueAnalytics;
  Map<String, dynamic> _groundPerformance = {};
  Map<String, dynamic> get groundPerformance => _groundPerformance;
  Map<String, dynamic> _userAnalytics = {};
  Map<String, dynamic> get userAnalytics => _userAnalytics;
  Map<String, dynamic> _timeSlotAnalytics = {};
  Map<String, dynamic> get timeSlotAnalytics => _timeSlotAnalytics;
  Map<String, dynamic> _tournamentAnalytics = {};
  Map<String, dynamic> get tournamentAnalytics => _tournamentAnalytics;

  // Loading states for analytics sections
  bool _isBookingAnalyticsLoading = false;
  bool get isBookingAnalyticsLoading => _isBookingAnalyticsLoading;
  bool _isRevenueAnalyticsLoading = false;
  bool get isRevenueAnalyticsLoading => _isRevenueAnalyticsLoading;
  bool _isGroundPerformanceLoading = false;
  bool get isGroundPerformanceLoading => _isGroundPerformanceLoading;
  bool _isUserAnalyticsLoading = false;
  bool get isUserAnalyticsLoading => _isUserAnalyticsLoading;
  bool _isTimeSlotAnalyticsLoading = false;
  bool get isTimeSlotAnalyticsLoading => _isTimeSlotAnalyticsLoading;
  bool _isTournamentAnalyticsLoading = false;
  bool get isTournamentAnalyticsLoading => _isTournamentAnalyticsLoading;

  // ============================================
  // DASHBOARD STATS LOADING
  // ============================================
  Future<void> loadDashboardStats() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('admin/dashboard');
      debugPrint('📊 ===== DASHBOARD RAW RESPONSE =====');
      debugPrint('$response');
      debugPrint('📊 ================================');

      final data = response['data'] as Map<String, dynamic>? ?? {};

      totalUsers = data['totalUsers'] ?? 0;
      totalFutsals = data['totalFutsals'] ?? 0;
      pendingApprovals = data['pendingApprovals'] ?? 0;
      todayBookings = data['todayBookings'] ?? 0;
      totalRevenue = (data['totalRevenue'] as num?)?.toDouble() ?? 0.0;
      totalOwners = data['totalOwners'] ?? 0;
      totalPlayers = data['totalPlayers'] ?? 0;
      totalBookings = data['totalBookings'] ?? 0;

      debugPrint(
          '✅ Parsed: users=$totalUsers, futsals=$totalFutsals, owners=$totalOwners, players=$totalPlayers, bookings=$totalBookings, revenue=$totalRevenue');

      // 🆕 Recent activities now contain full details: name, email, phone, category, status, createdAt
      final activities = data['recentActivities'] as List? ?? [];
      _recentActivities = activities.cast<Map<String, dynamic>>();

      await _loadPendingFutsals();
      await refreshAllChartData();
    } catch (e) {
      error = e.toString();
      debugPrint('❌ Dashboard error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadPendingFutsals() async {
    try {
      final response = await ApiService.get('admin/futsals/pending');
      _pendingFutsals = response['data'] != null
          ? List<Map<String, dynamic>>.from(response['data'])
          : [];
      notifyListeners();
    } catch (e) {
      _pendingFutsals = [];
      notifyListeners();
    }
  }

  // ============================================
  // CHART DATA LOADING (RANGE‑BASED)
  // ============================================
  Future<void> refreshAllChartData() async {
    _revenueByRange.clear();
    _bookingsByRange.clear();
    await loadChartData();
  }

  Future<void> loadChartData() async {
    _isChartsLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        loadRevenueForRange(ChartRange.week),
        loadBookingsForRange(ChartRange.week),
        _loadBookingStatusBreakdown(),
      ]);
    } catch (e) {
      debugPrint('❌ Chart loading error: $e');
    } finally {
      _isChartsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRevenueForRange(ChartRange range) async {
    _isRangeDataLoading = true;
    notifyListeners();

    try {
      final endpoint = 'admin/analytics/revenue-over-time?range=${range.name}';
      final response = await ApiService.get(endpoint);
      debugPrint('📈 Revenue response ($range): $response');

      if (response['status'] == 'success' && response['data'] != null) {
        final data = response['data'] as List;
        _revenueByRange[range] = data.asMap().entries.map((e) {
          return FlSpot(
              e.key.toDouble(), (e.value['revenue'] as num).toDouble());
        }).toList();
      } else {
        _revenueByRange[range] = [];
      }
    } catch (e) {
      debugPrint('Error loading revenue for $range: $e');
      _revenueByRange[range] = [];
    } finally {
      _isRangeDataLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBookingsForRange(ChartRange range) async {
    _isRangeDataLoading = true;
    notifyListeners();

    try {
      final endpoint = 'admin/analytics/bookings-over-time?range=${range.name}';
      final response = await ApiService.get(endpoint);
      debugPrint('📊 Bookings response ($range): $response');

      if (response['status'] == 'success' && response['data'] != null) {
        final data = response['data'] as List;
        _bookingsByRange[range] = data.asMap().entries.map((e) {
          return FlSpot(e.key.toDouble(), (e.value['count'] as num).toDouble());
        }).toList();
      } else {
        _bookingsByRange[range] = [];
      }
    } catch (e) {
      debugPrint('Error loading bookings for $range: $e');
      _bookingsByRange[range] = [];
    } finally {
      _isRangeDataLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadBookingStatusBreakdown() async {
    try {
      final response =
          await ApiService.get('admin/analytics/booking-status-breakdown');
      debugPrint('Status breakdown: $response');
      if (response['status'] == 'success' && response['data'] != null) {
        _bookingStatusBreakdown = Map<String, int>.from(response['data']);
      } else {
        _bookingStatusBreakdown = {};
      }
    } catch (e) {
      debugPrint('Status breakdown error: $e');
      _bookingStatusBreakdown = {};
    }
  }

  // ============================================
  // USER MANAGEMENT
  // ============================================
  Future<void> loadAllUsers() async {
    try {
      final response = await ApiService.get('admin/users');
      _allUsers = response['data'] != null
          ? List<Map<String, dynamic>>.from(response['data'])
          : [];
      notifyListeners();
    } catch (e) {
      debugPrint('Load Users Error: $e');
      _allUsers = [];
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> approveOwner(int userId) async {
    try {
      final response =
          await ApiService.patch('admin/users/$userId/approve-owner', {});
      if (response['status'] == 'success') {
        final index = _allUsers.indexWhere((u) => u['id'] == userId);
        if (index != -1) {
          _allUsers[index]['isApproved'] = true;
          notifyListeners();
        }
        return {
          'status': 'success',
          'message': response['message'] ?? 'Owner approved'
        };
      }
      return {
        'status': 'error',
        'message': response['message'] ?? 'Failed to approve'
      };
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> toggleUserStatus(
      int userId, bool isActive) async {
    try {
      final response = await ApiService.patch(
          'admin/users/$userId/toggle-status', {'isActive': isActive});
      if (response['status'] == 'success') {
        final index = _allUsers.indexWhere((u) => u['id'] == userId);
        if (index != -1) {
          _allUsers[index]['isActive'] = isActive;
          notifyListeners();
        }
        return {
          'status': 'success',
          'message': isActive ? 'User activated' : 'User blocked'
        };
      }
      return {
        'status': 'error',
        'message': response['message'] ?? 'Failed to update'
      };
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteUser(int userId) async {
  try {
    final response = await ApiService.delete('admin/users/$userId');
    if (response['status'] == 'success') {
      _allUsers.removeWhere((u) => u['id'] == userId);
      notifyListeners();
      return {'status': 'success', 'message': 'User deleted permanently'};
    }
    return {'status': 'error', 'message': response['message'] ?? 'Delete failed'};
  } catch (e) {
    return {'status': 'error', 'message': e.toString()};
  }
}

  // ============================================
  // FUTSAL MANAGEMENT
  // ============================================
  Future<Map<String, dynamic>> approveFutsal(int futsalId) async {
    try {
      final response =
          await ApiService.patch('admin/futsals/$futsalId/approve', {});
      if (response['status'] == 'success') {
        _pendingFutsals.removeWhere((f) => f['id'] == futsalId);
        pendingApprovals--;
        notifyListeners();
        return {'status': 'success', 'message': 'Futsal approved successfully'};
      }
      return {
        'status': 'error',
        'message': response['message'] ?? 'Failed to approve'
      };
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> rejectFutsal(int futsalId, String reason) async {
    try {
      final response = await ApiService.patch(
          'admin/futsals/$futsalId/reject', {'reason': reason});
      if (response['status'] == 'success') {
        _pendingFutsals.removeWhere((f) => f['id'] == futsalId);
        pendingApprovals--;
        notifyListeners();
        return {'status': 'success', 'message': 'Futsal rejected'};
      }
      return {
        'status': 'error',
        'message': response['message'] ?? 'Failed to reject'
      };
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<void> loadAllFutsals() async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.get('admin/futsals');
      _allFutsals = response['data'] != null
          ? List<Map<String, dynamic>>.from(response['data'])
          : [];
    } catch (e) {
      debugPrint('Load All Futsals Error: $e');
      _allFutsals = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ============================================
  // BOOKINGS
  // ============================================
  Future<void> loadAllBookings({
    String status = 'ALL',
    String? from,
    String? to,
    int page = 1,
  }) async {
    try {
      final response = await ApiService.getAdminBookings(
        status: status,
        from: from,
        to: to,
        page: page,
      );
      _allBookings =
          List<Map<String, dynamic>>.from(response['bookings'] ?? []);
      totalBookingsCount = response['total'] ?? 0;
      totalPages = response['totalPages'] ?? 1;
      notifyListeners();
    } catch (e) {
      debugPrint('Load bookings error: $e');
      _allBookings = [];
      notifyListeners();
    }
  }

  // ============================================
  // DETAILED ANALYTICS SECTIONS
  // ============================================
  Future<void> loadAllAnalytics() async {
    await Future.wait([
      loadBookingAnalytics(),
      loadRevenueAnalytics(),
      loadGroundPerformance(),
      loadUserAnalytics(),
      loadTimeSlotAnalytics(),
      loadTournamentAnalytics(),
    ]);
  }

  Future<void> loadBookingAnalytics() async {
    _isBookingAnalyticsLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.get('admin/analytics/bookings');
      if (response['status'] == 'success') {
        _bookingAnalytics = response['data'] ?? {};
      }
    } catch (e) {
      debugPrint('Booking analytics error: $e');
    } finally {
      _isBookingAnalyticsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRevenueAnalytics() async {
    _isRevenueAnalyticsLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.get('admin/analytics/revenue');
      if (response['status'] == 'success') {
        _revenueAnalytics = response['data'] ?? {};
      }
    } catch (e) {
      debugPrint('Revenue analytics error: $e');
    } finally {
      _isRevenueAnalyticsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadGroundPerformance() async {
    _isGroundPerformanceLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.get('admin/analytics/grounds');
      if (response['status'] == 'success') {
        _groundPerformance = response['data'] ?? {};
      }
    } catch (e) {
      debugPrint('Ground performance error: $e');
    } finally {
      _isGroundPerformanceLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserAnalytics() async {
    _isUserAnalyticsLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.get('admin/analytics/users');
      debugPrint('📊 User Analytics Response: $response');
      if (response['status'] == 'success') {
        var data = response['data'] ?? response;
        if (data.containsKey('analytics')) data = data['analytics'];
        _userAnalytics = {
          'newUsers': data['newUsers'] ?? 0,
          'activeVsInactive': {
            'active': data['activeUsers'] ?? 0,
            'inactive': (data['totalUsers'] ?? 0) - (data['activeUsers'] ?? 0),
          },
          'topPlayers':
              List<Map<String, dynamic>>.from(data['topPlayers'] ?? []),
        };
      } else {
        _userAnalytics = {
          'newUsers': response['newUsers'] ?? 0,
          'activeVsInactive': {
            'active': response['activeUsers'] ?? 0,
            'inactive':
                (response['totalUsers'] ?? 0) - (response['activeUsers'] ?? 0),
          },
          'topPlayers':
              List<Map<String, dynamic>>.from(response['topPlayers'] ?? []),
        };
      }
    } catch (e) {
      debugPrint('❌ User analytics error: $e');
      _userAnalytics = {
        'newUsers': 0,
        'activeVsInactive': {'active': 0, 'inactive': 0},
        'topPlayers': [],
      };
    } finally {
      _isUserAnalyticsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTimeSlotAnalytics() async {
    _isTimeSlotAnalyticsLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.get('admin/analytics/timeslots');
      if (response['status'] == 'success') {
        _timeSlotAnalytics = response['data'] ?? {};
      }
    } catch (e) {
      debugPrint('Time slot analytics error: $e');
    } finally {
      _isTimeSlotAnalyticsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTournamentAnalytics() async {
    _isTournamentAnalyticsLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.get('admin/analytics/tournaments');
      if (response['status'] == 'success') {
        _tournamentAnalytics = response['data'] ?? {};
      } else {
        _tournamentAnalytics = {
          'count': 0,
          'participationRate': 0,
          'revenue': 0
        };
      }
    } catch (e) {
      debugPrint('Tournament analytics error: $e');
      _tournamentAnalytics = {'count': 0, 'participationRate': 0, 'revenue': 0};
    } finally {
      _isTournamentAnalyticsLoading = false;
      notifyListeners();
    }
  }

  // ============================================
  // LEGACY ANALYTICS
  // ============================================
  Future<void> loadAdminAnalytics() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final response = await ApiService.getAdminAnalytics();
      if (response.isNotEmpty) {
        _adminAnalytics = response;
      } else {
        error = 'No analytics data received';
      }
    } catch (e) {
      error = 'Failed to load analytics: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ============================================
  // CLEAR DATA
  // ============================================
  void clearData() {
    totalUsers = 0;
    totalFutsals = 0;
    pendingApprovals = 0;
    todayBookings = 0;
    totalRevenue = 0;
    totalOwners = 0;
    totalPlayers = 0;
    totalBookings = 0;
    _recentActivities = [];
    _pendingFutsals = [];
    _allUsers = [];
    _allFutsals = [];
    _allBookings = [];
    _adminAnalytics = {};
    _bookingAnalytics = {};
    _revenueAnalytics = {};
    _groundPerformance = {};
    _userAnalytics = {};
    _timeSlotAnalytics = {};
    _tournamentAnalytics = {};
    _revenueByRange = {};
    _bookingsByRange = {};
    _bookingStatusBreakdown = {};
    error = null;
    isLoading = false;
    _isChartsLoading = false;
    _isRangeDataLoading = false;
    notifyListeners();
  }
}