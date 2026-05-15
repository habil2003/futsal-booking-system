import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

enum ChartRange { week, month, year }

class AdminAnalyticsProvider with ChangeNotifier {
  bool isLoading = false;
  String? error;

  // Revenue chart data (internal)
  final Map<ChartRange, List<FlSpot>> _revenueSpots = {};
  final Map<ChartRange, List<String>> _revenueLabels = {};

  // Bookings chart data (internal)
  final Map<ChartRange, List<FlSpot>> _bookingSpots = {};
  final Map<ChartRange, List<String>> _bookingLabels = {};

  // Aliases for dashboard compatibility
  Map<ChartRange, List<FlSpot>> get revenueByRange => _revenueSpots;
  Map<ChartRange, List<FlSpot>> get bookingsByRange => _bookingSpots;
  Map<ChartRange, List<String>> get revenueLabels => _revenueLabels;
  Map<ChartRange, List<String>> get bookingLabels => _bookingLabels;

  // Booking status breakdown (for pie chart)
  Map<String, int> _bookingStatusBreakdown = {};
  Map<String, int> get bookingStatusBreakdown => _bookingStatusBreakdown;

  // Rankings & extras
  List<Map<String, dynamic>> _groundBookingRank = [];
  List<Map<String, dynamic>> get groundBookingRank => _groundBookingRank;

  List<Map<String, dynamic>> _groundRevenueRank = [];
  List<Map<String, dynamic>> get groundRevenueRank => _groundRevenueRank;

  List<Map<String, dynamic>> _topPlayers = [];
  List<Map<String, dynamic>> get topPlayers => _topPlayers;

  Map<int, int> _peakHoursData = {};
  Map<int, int> get peakHoursData => _peakHoursData;

  List<Map<String, dynamic>> _tournamentRank = [];
  List<Map<String, dynamic>> get tournamentRank => _tournamentRank;

  int _totalUsers = 0;
  int get totalUsers => _totalUsers;

  // ------------------------------------------------------------
  // Load all analytics data
  // ------------------------------------------------------------
  Future<void> loadAllAnalytics() async {
    isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        loadRevenueForRange(ChartRange.week),
        loadBookingsForRange(ChartRange.week),
        loadBookingStatusBreakdown(),
        loadGroundBookingRank(),
        loadGroundRevenueRank(),
        loadTopPlayers(),
        loadPeakHours(),
        loadTournamentRank(),
        loadTotalUsers(),
      ]);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // Revenue chart
  // ------------------------------------------------------------
  Future<void> loadRevenueForRange(ChartRange range) async {
    try {
      final data = await ApiService.getRevenueOverTime(range.name);
      _revenueLabels[range] =
          data.map<String>((e) => e['label'].toString()).toList();
      _revenueSpots[range] = data.asMap().entries.map((e) {
        return FlSpot(e.key.toDouble(), (e.value['value'] as num).toDouble());
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Revenue chart error: $e');
    }
  }

  // ------------------------------------------------------------
  // Bookings chart
  // ------------------------------------------------------------
  Future<void> loadBookingsForRange(ChartRange range) async {
    try {
      final data = await ApiService.getBookingsOverTime(range.name);
      _bookingLabels[range] =
          data.map<String>((e) => e['label'].toString()).toList();
      _bookingSpots[range] = data.asMap().entries.map((e) {
        return FlSpot(e.key.toDouble(), (e.value['value'] as num).toDouble());
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Bookings chart error: $e');
    }
  }

  // ------------------------------------------------------------
  // Booking status breakdown (for pie chart)
  // ------------------------------------------------------------
  Future<void> loadBookingStatusBreakdown() async {
    try {
      final data = await ApiService.getBookingStatusBreakdown();
      _bookingStatusBreakdown =
          data.map((key, value) => MapEntry(key, value as int));
      notifyListeners();
    } catch (e) {
      debugPrint('Status breakdown error: $e');
    }
  }

  // ------------------------------------------------------------
  // Grounds by booking count
  // ------------------------------------------------------------
  Future<void> loadGroundBookingRank() async {
    try {
      final data = await ApiService.getGroundsByBookingCount();
      _groundBookingRank = List<Map<String, dynamic>>.from(data);
      notifyListeners();
    } catch (e) {
      debugPrint('Ground booking rank error: $e');
    }
  }

  // ------------------------------------------------------------
  // Grounds by revenue
  // ------------------------------------------------------------
  Future<void> loadGroundRevenueRank() async {
    try {
      final data = await ApiService.getGroundsByRevenue();
      _groundRevenueRank = List<Map<String, dynamic>>.from(data);
      notifyListeners();
    } catch (e) {
      debugPrint('Ground revenue rank error: $e');
    }
  }

  // ------------------------------------------------------------
  // Top players
  // ------------------------------------------------------------
  Future<void> loadTopPlayers() async {
    try {
      final data = await ApiService.getTopPlayers();
      _topPlayers = List<Map<String, dynamic>>.from(data);
      notifyListeners();
    } catch (e) {
      debugPrint('Top players error: $e');
    }
  }

  // ------------------------------------------------------------
  // Peak hours
  // ------------------------------------------------------------
  Future<void> loadPeakHours() async {
    try {
      final data = await ApiService.getAnalyticsPeakHours();
      _peakHoursData = {
        for (var item in data) (item['hour'] as int): (item['count'] as int)
      };
      notifyListeners();
    } catch (e) {
      debugPrint('Peak hours error: $e');
    }
  }

  // ------------------------------------------------------------
  // Tournament ranking
  // ------------------------------------------------------------
  Future<void> loadTournamentRank() async {
    try {
      final data = await ApiService.getTournamentRanking();
      _tournamentRank = List<Map<String, dynamic>>.from(data);
      notifyListeners();
    } catch (e) {
      debugPrint('Tournament rank error: $e');
    }
  }

  // ------------------------------------------------------------
  // Total users
  // ------------------------------------------------------------
  Future<void> loadTotalUsers() async {
    try {
      final response = await ApiService.get('admin/users');
      final users = response['data'] as List?;
      _totalUsers = users?.length ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Total users error: $e');
    }
  }

  // ------------------------------------------------------------
  // Clear data
  // ------------------------------------------------------------
  void clearData() {
    _revenueSpots.clear();
    _bookingSpots.clear();
    _revenueLabels.clear();
    _bookingLabels.clear();
    _bookingStatusBreakdown.clear();
    _groundBookingRank.clear();
    _groundRevenueRank.clear();
    _topPlayers.clear();
    _peakHoursData.clear();
    _tournamentRank.clear();
    _totalUsers = 0;
    isLoading = false;
    error = null;
    notifyListeners();
  }
}
