import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminProvider with ChangeNotifier {
  bool isLoading = false;
  String? error;

  // Dashboard statistics
  int totalUsers = 0;
  int totalFutsals = 0;
  int pendingApprovals = 0;
  int todayBookings = 0;
  double totalRevenue = 0;

   double bookingRevenue = 0;
  double registrationRevenue = 0;

  int totalBookings = 0;
  int completedBookings = 0;
  int activeBookings = 0;
  int cancelledBookings = 0;

  // Lists
  List<Map<String, dynamic>> _recentActivities = [];
  List<Map<String, dynamic>> get recentActivities => _recentActivities;

  List<Map<String, dynamic>> _pendingFutsals = [];
  List<Map<String, dynamic>> get pendingFutsals => _pendingFutsals;

  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> get allUsers => _allUsers;

  List<Map<String, dynamic>> _allFutsals = [];
  List<Map<String, dynamic>> get allFutsals => _allFutsals;

  // Bookings
  List<Map<String, dynamic>> _allBookings = [];
  List<Map<String, dynamic>> get allBookings => _allBookings;
  int totalBookingsCount = 0;
  int totalPages = 0;

  /// =========================
  /// Load Dashboard Stats
  /// =========================
  Future<void> loadDashboardStats() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadStats(),
        _loadRecentActivities(),
        _loadPendingFutsals(),
      ]);

      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadStats() async {
  try {
    final response = await ApiService.get('admin/dashboard');
    final data = response['data'];

    totalUsers = data['totalUsers'] ?? 0;
    totalFutsals = data['totalFutsals'] ?? 0;
    pendingApprovals = data['pendingFutsals'] ?? 0;
    todayBookings = data['todayBookings'] ?? 0;
    totalRevenue = (data['totalRevenue'] ?? 0).toDouble();
    
    // ✅ ADD THESE TWO LINES
    bookingRevenue = (data['bookingRevenue'] ?? 0).toDouble();
    registrationRevenue = (data['registrationRevenue'] ?? 0).toDouble();

    totalBookings = data['totalBookings'] ?? 0;
    completedBookings = data['completedBookings'] ?? 0;
    activeBookings = data['activeBookings'] ?? 0;
    cancelledBookings = data['cancelledBookings'] ?? 0;
  } catch (e) {
    totalUsers = 0;
    totalFutsals = 0;
    pendingApprovals = 0;
    todayBookings = 0;
    totalRevenue = 0;
    bookingRevenue = 0;      // ✅ ADD THIS
    registrationRevenue = 0; // ✅ ADD THIS
    totalBookings = 0;
    completedBookings = 0;
    activeBookings = 0;
    cancelledBookings = 0;
  }
}

  Future<void> _loadRecentActivities() async {
    try {
      final response = await ApiService.get('admin/dashboard');
      final data = response['data'];
      if (data['recentActivities'] != null) {
        _recentActivities =
            List<Map<String, dynamic>>.from(data['recentActivities']);
      } else {
        _recentActivities = [];
      }
      notifyListeners();
    } catch (e) {
      _recentActivities = [];
      notifyListeners();
    }
  }

  Future<void> _loadPendingFutsals() async {
    try {
      final response = await ApiService.get('admin/futsals/pending');
      if (response['data'] != null) {
        _pendingFutsals = List<Map<String, dynamic>>.from(response['data']);
        // Update pending approvals count based on actual pending futsals
        pendingApprovals = _pendingFutsals.length;
        notifyListeners();
      } else {
        _pendingFutsals = [];
      }
      notifyListeners();
    } catch (e) {
      _pendingFutsals = [];
      notifyListeners();
    }
  }

  /// =========================
  /// Users Management
  /// =========================
  Future<void> loadAllUsers() async {
    try {
      final response = await ApiService.get('admin/users');
      if (response['data'] != null) {
        _allUsers = List<Map<String, dynamic>>.from(response['data']);
        notifyListeners();
      }
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
      } else {
        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to approve'
        };
      }
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
          'message': isActive ? 'User activated' : 'User blocked',
        };
      } else {
        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to update'
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// =========================
  /// Futsal Management
  /// =========================
  Future<Map<String, dynamic>> approveFutsal(int futsalId) async {
    try {
      final response =
          await ApiService.patch('admin/futsals/$futsalId/approve', {});
      if (response['status'] == 'success') {
        _pendingFutsals.removeWhere((f) => f['id'] == futsalId);
        pendingApprovals = _pendingFutsals.length;
        
        // Also update in allFutsals if present
        final allIndex = _allFutsals.indexWhere((f) => f['id'] == futsalId);
        if (allIndex != -1) {
          _allFutsals[allIndex]['status'] = 'ACTIVE';
          _allFutsals[allIndex]['isApproved'] = true;
        }
        
        await _loadRecentActivities();
        notifyListeners();
        return {'status': 'success', 'message': 'Futsal approved successfully'};
      } else {
        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to approve'
        };
      }
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
        pendingApprovals = _pendingFutsals.length;
        
        // Also remove from allFutsals
        _allFutsals.removeWhere((f) => f['id'] == futsalId);
        
        notifyListeners();
        return {'status': 'success', 'message': 'Futsal rejected and removed'};
      } else {
        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to reject'
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

/// Load all futsals (for admin management)
Future<void> loadAllFutsals() async {
  isLoading = true;
  error = null;
  notifyListeners();
  
  try {
    final response = await ApiService.getAllFutsals();
    print('📊 Admin API Response: ${response['status']}');
    
    if (response['data'] != null) {
      _allFutsals = List<Map<String, dynamic>>.from(response['data']);
      print('✅ Loaded ${_allFutsals.length} futsals total');
      
      // Debug: Print status distribution
      final activeCount = _allFutsals.where((f) => f['status'] == 'ACTIVE').length;
      final deactivatedCount = _allFutsals.where((f) => f['status'] == 'DEACTIVATED').length;
      print('   Active: $activeCount, Deactivated: $deactivatedCount');
    } else {
      _allFutsals = [];
      print('⚠️ No data in response');
    }
    
    isLoading = false;
    notifyListeners();
  } catch (e) {
    print('❌ Load All Futsals Error: $e');
    _allFutsals = [];
    isLoading = false;
    error = e.toString();
    notifyListeners();
  }
}

  /// =========================
  /// Generate Reports
  /// =========================
  Future<Map<String, dynamic>> generateReport(
      String type, DateTime from, DateTime to) async {
    try {
      final response = await ApiService.get(
        'admin/reports?type=$type&from=${from.toIso8601String()}&to=${to.toIso8601String()}',
      );
      return {'status': 'success', 'data': response};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

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

  // Analytics
  Map<String, dynamic> _adminAnalytics = {};
  Map<String, dynamic> get adminAnalytics => _adminAnalytics;

  Future<void> loadAdminAnalytics({int? futsalId}) async {
    try {
      String url = 'admin/analytics';
      if (futsalId != null) {
        url += '?futsalId=$futsalId';
      }
      final response = await ApiService.get(url);
      _adminAnalytics = response;
      notifyListeners();
    } catch (e) {
      debugPrint('Load admin analytics error: $e');
    }
  }

  /// =========================
  /// Helper method to check if futsal is pending payment
  /// =========================
  bool isPaymentPending(Map<String, dynamic> futsal) {
    return futsal['status'] == 'PENDING_PAYMENT' && 
           (futsal['registrationFeePaid'] == false);
  }

  /// =========================
  /// Helper method to get status display text
  /// =========================
  String getStatusDisplayText(Map<String, dynamic> futsal) {
    final status = futsal['status'] ?? 'PENDING';
    final registrationFeePaid = futsal['registrationFeePaid'] ?? false;
    
    if (status == 'ACTIVE') return 'Active';
    if (status == 'PENDING_PAYMENT') return 'Payment Pending';
    if (status == 'PENDING' && registrationFeePaid) return 'Pending Approval';
    if (status == 'PENDING') return 'Pending';
    if (status == 'DEACTIVATED') return 'Deactivated';
    return status;
  }

  /// =========================
  /// Helper method to get status color
  /// =========================
  Color getStatusColor(Map<String, dynamic> futsal) {
    final status = futsal['status'] ?? 'PENDING';
    final registrationFeePaid = futsal['registrationFeePaid'] ?? false;
    
    if (status == 'ACTIVE') return Colors.green;
    if (status == 'PENDING_PAYMENT') return Colors.orange;
    if (status == 'PENDING' && registrationFeePaid) return Colors.orange;
    if (status == 'PENDING') return Colors.orange.shade300;
    if (status == 'DEACTIVATED') return Colors.red;
    return Colors.grey;
  }

  /// =========================
  /// Clear Data
  /// =========================
  void clearData() {
    totalUsers = 0;
    totalFutsals = 0;
    pendingApprovals = 0;
    todayBookings = 0;
    totalRevenue = 0;
    totalBookings = 0;
    completedBookings = 0;
    activeBookings = 0;
    cancelledBookings = 0;
    _recentActivities = [];
    _pendingFutsals = [];
    _allUsers = [];
    _allFutsals = [];
    error = null;
    notifyListeners();
  }

/// Admin deactivates futsal (owner cannot reactivate)
Future<Map<String, dynamic>> adminDeactivateFutsal(int futsalId) async {
  try {
    final response = await ApiService.adminDeactivateFutsal(futsalId);
    if (response['status'] == 'success') {
      return {'status': 'success', 'message': response['message'] ?? 'Futsal deactivated by admin'};
    }
    return {'status': 'error', 'message': response['message'] ?? 'Failed to deactivate'};
  } catch (e) {
    return {'status': 'error', 'message': e.toString()};
  }
}

/// Admin activates futsal
Future<Map<String, dynamic>> adminActivateFutsal(int futsalId) async {
  try {
    final response = await ApiService.adminActivateFutsal(futsalId);
    if (response['status'] == 'success') {
      return {'status': 'success', 'message': response['message'] ?? 'Futsal activated by admin'};
    }
    return {'status': 'error', 'message': response['message'] ?? 'Failed to activate'};
  } catch (e) {
    return {'status': 'error', 'message': e.toString()};
  }
}

/// Admin delete futsal
Future<Map<String, dynamic>> deleteFutsal(int futsalId) async {
  try {
    final response = await ApiService.adminDeleteFutsal(futsalId);
    if (response['status'] == 'success') {
      _allFutsals.removeWhere((f) => f['id'] == futsalId);
      _pendingFutsals.removeWhere((f) => f['id'] == futsalId);
      pendingApprovals = _pendingFutsals.length;
      notifyListeners();
      return {'status': 'success', 'message': response['message'] ?? 'Futsal deleted successfully'};
    }
    return {'status': 'error', 'message': response['message'] ?? 'Failed to delete'};
  } catch (e) {
    return {'status': 'error', 'message': e.toString()};
  }
}

}