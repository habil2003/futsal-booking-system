import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AnalyticsProvider with ChangeNotifier {
  bool isLoading = false;
  String? error;

  // Revenue Summary
  double todayRevenue = 0;
  double thisWeekRevenue = 0;
  double thisMonthRevenue = 0;
  double thisYearRevenue = 0;
  double allTimeRevenue = 0;

  // Performance Metrics
  double completionRate = 0;
  double cancellationRate = 0;
  double averageBookingValue = 0;
  int totalBookings = 0;
  int completedBookings = 0;
  int cancelledBookings = 0;
  int pendingBookings = 0;
  int confirmedBookings = 0;

  // Monthly Revenue (for chart)
  List<Map<String, dynamic>> monthlyRevenue = [];

  // Payment Breakdown
  Map<String, dynamic> paymentBreakdown = {
    'COD': {'revenue': 0, 'count': 0, 'percentage': 0},
    'KHALTI': {'revenue': 0, 'count': 0, 'percentage': 0},
  };
  double totalPaymentRevenue = 0;

  // Weekly Revenue
  List<double> weeklyRevenue = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

  // Peak Hours
  Map<String, int> peakHours = {};

  Future<void> loadAllAnalytics(int futsalId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await Future.wait([
        loadRevenueSummary(futsalId),
        loadPerformanceMetrics(futsalId),
        loadMonthlyRevenue(futsalId),
        loadPaymentBreakdown(futsalId),
        loadWeeklyRevenue(futsalId),
        loadPeakHours(futsalId),
      ]);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRevenueSummary(int futsalId) async {
    try {
      final response = await ApiService.getRevenueSummary(futsalId);
      if (response['status'] == 'success') {
        final data = response['data'];

        double parseValue(dynamic value) {
          if (value == null) return 0.0;
          if (value is int) return value.toDouble();
          if (value is double) return value;
          if (value is String) return double.tryParse(value) ?? 0.0;
          return 0.0;
        }

        todayRevenue = parseValue(data['today']);
        thisWeekRevenue = parseValue(data['thisWeek']);
        thisMonthRevenue = parseValue(data['thisMonth']);
        thisYearRevenue = parseValue(data['thisYear']);
        allTimeRevenue = parseValue(data['allTime']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading revenue summary: $e');
    }
  }

  Future<void> loadPerformanceMetrics(int futsalId) async {
    try {
      final response = await ApiService.getPerformanceMetrics(futsalId);
      if (response['status'] == 'success') {
        final data = response['data'];

        double parseDouble(dynamic value) {
          if (value == null) return 0.0;
          if (value is int) return value.toDouble();
          if (value is double) return value;
          if (value is String) return double.tryParse(value) ?? 0.0;
          return 0.0;
        }

        int parseInt(dynamic value) {
          if (value == null) return 0;
          if (value is int) return value;
          if (value is double) return value.toInt();
          if (value is String) return int.tryParse(value) ?? 0;
          return 0;
        }

        completionRate = parseDouble(data['completionRate']);
        cancellationRate = parseDouble(data['cancellationRate']);
        averageBookingValue = parseDouble(data['averageBookingValue']);
        totalBookings = parseInt(data['totalBookings']);
        completedBookings = parseInt(data['completedBookings']);
        cancelledBookings = parseInt(data['cancelledBookings']);
        pendingBookings = parseInt(data['pendingBookings']);
        confirmedBookings = parseInt(data['confirmedBookings']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading performance metrics: $e');
    }
  }

  Future<void> loadMonthlyRevenue(int futsalId) async {
    try {
      final response = await ApiService.getMonthlyRevenue(futsalId);
      final data = response['data'] ?? [];

      monthlyRevenue = data.map<Map<String, dynamic>>((item) {
        double revenueValue = 0.0;
        if (item['revenue'] is int) {
          revenueValue = (item['revenue'] as int).toDouble();
        } else if (item['revenue'] is double) {
          revenueValue = item['revenue'];
        } else if (item['revenue'] is String) {
          revenueValue = double.tryParse(item['revenue']) ?? 0.0;
        }

        int bookingsValue = 0;
        if (item['bookings'] is int) {
          bookingsValue = item['bookings'];
        } else if (item['bookings'] is String) {
          bookingsValue = int.tryParse(item['bookings']) ?? 0;
        }

        return {
          'month': item['month'] ?? '',
          'year': item['year'] ?? 0,
          'revenue': revenueValue,
          'bookings': bookingsValue,
        };
      }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading monthly revenue: $e');
      monthlyRevenue = [];
    }
  }

  Future<void> loadPaymentBreakdown(int futsalId) async {
    try {
      final response = await ApiService.getPaymentBreakdown(futsalId);
      if (response['status'] == 'success') {
        final data = response['data'];

        double parseDouble(dynamic value) {
          if (value == null) return 0.0;
          if (value is int) return value.toDouble();
          if (value is double) return value;
          if (value is String) return double.tryParse(value) ?? 0.0;
          return 0.0;
        }

        int parseInt(dynamic value) {
          if (value == null) return 0;
          if (value is int) return value;
          if (value is String) return int.tryParse(value) ?? 0;
          return 0;
        }

        paymentBreakdown = {
          'COD': {
            'revenue': parseDouble(data['breakdown']['COD']['revenue']),
            'count': parseInt(data['breakdown']['COD']['count']),
            'percentage': parseDouble(data['breakdown']['COD']['percentage']),
          },
          'KHALTI': {
            'revenue': parseDouble(data['breakdown']['KHALTI']['revenue']),
            'count': parseInt(data['breakdown']['KHALTI']['count']),
            'percentage': parseDouble(data['breakdown']['KHALTI']['percentage']),
          },
        };
        totalPaymentRevenue = parseDouble(data['totalRevenue']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading payment breakdown: $e');
    }
  }

  Future<void> loadWeeklyRevenue(int futsalId) async {
    try {
      final revenueList = await ApiService.getWeeklyRevenue(futsalId);
      
      if (revenueList is List<double>) {
        weeklyRevenue = revenueList;
      } else if (revenueList is List) {
        weeklyRevenue = revenueList.map((e) {
          if (e is int) return e.toDouble();
          if (e is double) return e;
          return 0.0;
        }).toList();
      } else {
        weeklyRevenue = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
      }
      
      if (weeklyRevenue.length != 7) {
        weeklyRevenue = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading weekly revenue: $e');
      weeklyRevenue = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
      notifyListeners();
    }
  }

  Future<void> loadPeakHours(int futsalId) async {
    try {
      final peakData = await ApiService.getPeakHours(futsalId);
      
      if (peakData is Map<String, int>) {
        peakHours = peakData;
      } else if (peakData is Map) {
        Map<String, int> temp = {};
        peakData.forEach((key, value) {
          if (value is int) {
            temp[key] = value;
          } else if (value is double) {
            temp[key] = value.toInt();
          } else {
            temp[key] = 0;
          }
        });
        peakHours = temp;
      } else {
        peakHours = {};
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading peak hours: $e');
      peakHours = {};
      notifyListeners();
    }
  }
}