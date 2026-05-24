import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class AdminProvider with ChangeNotifier {
  bool isLoading = false;
  String? error;

  // ============================================
  // DASHBOARD STATS
  // ============================================
  int totalUsers = 0;
  int totalFutsals = 0;
  int pendingApprovals = 0;
  int todayBookings = 0;
  double totalRevenue = 0;
  int totalOwners = 0;
  int totalPlayers = 0;
  int totalBookings = 0;
  int _unreadNotificationCount = 0;
int get unreadNotificationCount => _unreadNotificationCount;

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

  // ============================================
  // DASHBOARD
  // ============================================
  Future<void> loadDashboardStats() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('admin/dashboard');

      final data = response['data'] as Map<String, dynamic>? ?? {};

      totalUsers = data['totalUsers'] ?? 0;
      totalFutsals = data['totalFutsals'] ?? 0;
      pendingApprovals = data['pendingApprovals'] ?? 0;
      todayBookings = data['todayBookings'] ?? 0;

      totalRevenue = (data['totalRevenue'] as num?)?.toDouble() ?? 0.0;

      totalOwners = data['totalOwners'] ?? 0;
      totalPlayers = data['totalPlayers'] ?? 0;
      totalBookings = data['totalBookings'] ?? 0;

      final activities = data['recentActivities'] as List? ?? [];

      _recentActivities = activities.cast<Map<String, dynamic>>();

      await checkUnreadNotifications();
      await loadPendingFutsals();
    } catch (e) {
      error = e.toString();
      debugPrint('Dashboard error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkUnreadNotifications() async {
  final lastSeen = await NotificationService.getLastSeen();
  
  if (_recentActivities.isEmpty) {
    _unreadNotificationCount = 0;
    notifyListeners();
    return;
  }
  
  if (lastSeen == null) {
    // Never seen before, all are unread
    _unreadNotificationCount = _recentActivities.length;
    notifyListeners();
    return;
  }
  
  // Count activities newer than last seen
  int count = 0;
  for (var activity in _recentActivities) {
    final createdAt = activity['createdAt'];
    if (createdAt != null) {
      try {
        final activityDate = DateTime.parse(createdAt);
        if (activityDate.isAfter(lastSeen)) {
          count++;
        }
      } catch (e) {
        // Skip invalid dates
      }
    }
  }
  
  _unreadNotificationCount = count;
  notifyListeners();
}

Future<void> markNotificationsAsRead() async {
  await NotificationService.markAsRead();
  _unreadNotificationCount = 0;
  notifyListeners();
}

  // ============================================
  // FUTSALS
  // ============================================
  Future<void> loadPendingFutsals() async {
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

  Future<void> loadAllFutsals() async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('admin/futsals');

      _allFutsals = response['data'] != null
          ? List<Map<String, dynamic>>.from(response['data'])
          : [];
    } catch (e) {
      debugPrint('Load futsals error: $e');
      _allFutsals = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> approveFutsal(int futsalId) async {
    try {
      final response = await ApiService.patch(
        'admin/futsals/$futsalId/approve',
        {},
      );

      if (response['status'] == 'success') {
        _pendingFutsals.removeWhere((f) => f['id'] == futsalId);

        pendingApprovals--;

        notifyListeners();

        return {
          'status': 'success',
          'message': 'Futsal approved successfully',
        };
      }

      return {
        'status': 'error',
        'message': response['message'] ?? 'Approval failed',
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> rejectFutsal(int futsalId, String reason) async {
    try {
      final response = await ApiService.patch(
        'admin/futsals/$futsalId/reject',
        {'reason': reason},
      );

      if (response['status'] == 'success') {
        _pendingFutsals.removeWhere((f) => f['id'] == futsalId);

        pendingApprovals--;

        notifyListeners();

        return {
          'status': 'success',
          'message': 'Futsal rejected',
        };
      }

      return {
        'status': 'error',
        'message': response['message'] ?? 'Reject failed',
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  // ============================================
  // USERS
  // ============================================
  Future<void> loadAllUsers() async {
    try {
      final response = await ApiService.get('admin/users');

      _allUsers = response['data'] != null
          ? List<Map<String, dynamic>>.from(response['data'])
          : [];

      notifyListeners();
    } catch (e) {
      debugPrint('Load users error: $e');

      _allUsers = [];
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> approveOwner(int userId) async {
    try {
      final response = await ApiService.patch(
        'admin/users/$userId/approve-owner',
        {},
      );

      if (response['status'] == 'success') {
        final index = _allUsers.indexWhere((u) => u['id'] == userId);

        if (index != -1) {
          _allUsers[index]['isApproved'] = true;
        }

        notifyListeners();
      }

      return response;
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> toggleUserStatus(
    int userId,
    bool isActive,
  ) async {
    try {
      final response = await ApiService.patch(
        'admin/users/$userId/toggle-status',
        {'isActive': isActive},
      );

      if (response['status'] == 'success') {
        final index = _allUsers.indexWhere((u) => u['id'] == userId);

        if (index != -1) {
          _allUsers[index]['isActive'] = isActive;
        }

        notifyListeners();
      }

      return response;
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> deleteUser(int userId) async {
    try {
      final response = await ApiService.delete('admin/users/$userId');

      if (response['status'] == 'success') {
        _allUsers.removeWhere((u) => u['id'] == userId);

        notifyListeners();
      }

      return response;
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  // ============================================
  // EDIT USER (Update name and phone)
  // ============================================
  Future<Map<String, dynamic>> editUser(
    int userId,
    String fullName,
    String phoneNumber,
  ) async {
    try {
      final response = await ApiService.patch(
        'admin/users/$userId/edit',
        {
          'fullName': fullName,
          'phoneNumber': phoneNumber,
        },
      );

      if (response['status'] == 'success') {
        final index = _allUsers.indexWhere((u) => u['id'] == userId);

        if (index != -1) {
          _allUsers[index]['fullName'] = fullName;
          _allUsers[index]['phoneNumber'] = phoneNumber;
        }

        notifyListeners();
      }

      return response;
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  // ============================================
  // CHANGE USER ROLE
  // ============================================
  Future<Map<String, dynamic>> changeUserRole(
    int userId,
    String newRole,
  ) async {
    try {
      final response = await ApiService.patch(
        'admin/users/$userId/change-role',
        {'role': newRole},
      );

      if (response['status'] == 'success') {
        final index = _allUsers.indexWhere((u) => u['id'] == userId);

        if (index != -1) {
          _allUsers[index]['role'] = newRole;

          // If changing to OWNER, isApproved becomes false
          if (newRole == 'OWNER') {
            _allUsers[index]['isApproved'] = false;
          } else {
            _allUsers[index]['isApproved'] = true;
          }
        }

        notifyListeners();
      }

      return response;
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString(),
      };
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
    final stopwatch = Stopwatch()..start();
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
      debugPrint('Bookings error: $e');

      _allBookings = [];
      notifyListeners();
    }
    stopwatch.stop();
    print('⏱️ API call took: ${stopwatch.elapsedMilliseconds}ms');
    print(
        '📊 Returned: ${_allBookings.length} bookings of $totalBookingsCount total');
  }

  // ============================================
  // CLEAR
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

    totalBookingsCount = 0;
    totalPages = 0;

    error = null;
    isLoading = false;

    notifyListeners();
  }
}
