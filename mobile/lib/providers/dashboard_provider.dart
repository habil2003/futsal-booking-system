import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/booking.dart';

class DashboardProvider with ChangeNotifier {
  bool isLoading = false;
  String? error;
  
  // Statistics
  int totalCourts = 0;
  int todayBookings = 0;
  double todayRevenue = 0;
  int activeBookings = 0;  // Changed from pendingApprovals
  
  // Today's bookings list
  List<Booking> _todayBookingsList = [];
  List<Booking> get todayBookingsList => _todayBookingsList;
  
  // Weekly revenue data for charts
  List<double> _weeklyRevenue = [];
  List<double> get weeklyRevenue => _weeklyRevenue;
  
  // Peak hours data
  Map<String, int> _peakHours = {};
  Map<String, int> get peakHours => _peakHours;

  // Load dashboard statistics for a specific futsal
  Future<void> loadStatistics(int futsalId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    
    debugPrint('📊 Dashboard: Loading stats for futsal $futsalId');
    
    try {
      // Load all stats in parallel for better performance
      await Future.wait([
        _loadStats(futsalId),
        _loadTodayBookings(futsalId),
        _loadWeeklyRevenue(futsalId),
        _loadPeakHours(futsalId),
      ]);
      
      isLoading = false;
      notifyListeners();
      debugPrint('📊 Dashboard: Stats loaded successfully');
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      debugPrint('📊 Dashboard Error: $e');
    }
  }

  // Load main statistics
  Future<void> _loadStats(int futsalId) async {
    try {
      final response = await ApiService.getDashboardStats(futsalId);
      
      totalCourts = response['totalCourts'] ?? 0;
      todayBookings = response['todayBookings'] ?? 0;
      todayRevenue = (response['todayRevenue'] ?? 0).toDouble();
      activeBookings = response['activeBookings'] ?? 0;  // Changed from pendingApprovals
      
      debugPrint('📊 Stats: Courts=$totalCourts, Bookings=$todayBookings, Revenue=$todayRevenue, Active=$activeBookings');
    } catch (e) {
      debugPrint('📊 Stats Error: $e');
      // Don't rethrow, just use defaults
    }
  }

  // Load today's bookings
  Future<void> _loadTodayBookings(int futsalId) async {
    try {
      final response = await ApiService.getDashboardTodayBookings(futsalId);
      
      _todayBookingsList = response
          .map((json) => Booking.fromJson(json))
          .toList();
          
      debugPrint('📊 Today\'s Bookings: ${_todayBookingsList.length} bookings');
    } catch (e) {
      debugPrint('📊 Today Bookings Error: $e');
      _todayBookingsList = [];
    }
  }

  // Load weekly revenue for chart
  Future<void> _loadWeeklyRevenue(int futsalId) async {
    try {
      final response = await ApiService.getWeeklyRevenue(futsalId);
      
      _weeklyRevenue = response.map((value) {
        if (value is int) return value.toDouble();
        return value;
      }).toList();
          
      debugPrint('📊 Weekly Revenue: $_weeklyRevenue');
    } catch (e) {
      debugPrint('📊 Weekly Revenue Error: $e');
      _weeklyRevenue = [0, 0, 0, 0, 0, 0, 0];
    }
  }

  // Load peak hours data
  Future<void> _loadPeakHours(int futsalId) async {
    try {
      final response = await ApiService.getPeakHours(futsalId);
      
      _peakHours = Map<String, int>.from(response);
          
      debugPrint('📊 Peak Hours: $_peakHours');
    } catch (e) {
      debugPrint('📊 Peak Hours Error: $e');
      _peakHours = {};
    }
  }

  // Check-in a customer (owner action)
  Future<Map<String, dynamic>> checkInCustomer(int bookingId, int futsalId) async {
    try {
      final response = await ApiService.checkInBooking(bookingId);
      
      if (response['status'] == 'success') {
        await _loadTodayBookings(futsalId);
        await _loadStats(futsalId);  // Refresh stats too
        notifyListeners();
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ Check-in error: $e');
      return {
        'status': 'error',
        'message': e.toString()
      };
    }
  }

  // Cancel a booking (owner action)
  Future<Map<String, dynamic>> cancelBooking(int bookingId, int futsalId) async {
    try {
      final response = await ApiService.cancelUserBooking(bookingId);
      
      if (response['status'] == 'success') {
        await _loadTodayBookings(futsalId);
        await _loadStats(futsalId);  // Refresh stats too
        notifyListeners();
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ Cancel booking error: $e');
      return {
        'status': 'error',
        'message': e.toString()
      };
    }
  }

  // Mark as paid (owner action for COD)
  Future<Map<String, dynamic>> markAsPaid(int bookingId, int futsalId) async {
    try {
      final response = await ApiService.updatePaymentStatus(bookingId, 'PAID');
      
      if (response['status'] == 'success') {
        await _loadTodayBookings(futsalId);
        await _loadStats(futsalId);  // Refresh stats too
        notifyListeners();
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ Mark as paid error: $e');
      return {
        'status': 'error',
        'message': e.toString()
      };
    }
  }

  // Clear data (useful for logout)
  void clearData() {
    totalCourts = 0;
    todayBookings = 0;
    todayRevenue = 0;
    activeBookings = 0;  // Changed from pendingApprovals
    _todayBookingsList = [];
    _weeklyRevenue = [];
    _peakHours = {};
    error = null;
    notifyListeners();
  }
}