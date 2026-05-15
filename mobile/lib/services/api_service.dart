import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:5000/api',
  );

  // ============================================
  // BASE HTTP METHODS
  // ============================================
  
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    debugPrint('📍 GET: $baseUrl/$endpoint');
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('GET failed: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('POST failed: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('PUT failed: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> patch(String endpoint, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.patch(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('PATCH failed: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      if (response.body.isNotEmpty) {
        return json.decode(response.body);
      } else {
        return {'status': 'success', 'message': 'Deleted successfully'};
      }
    } else {
      throw Exception('DELETE failed: ${response.body}');
    }
  }

  // ============================================
  // LIST METHODS
  // ============================================
  
  static Future<List<dynamic>> getList(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final dynamic jsonResponse = json.decode(response.body);
      if (jsonResponse is List) {
        return jsonResponse;
      } else if (jsonResponse is Map && jsonResponse.containsKey('data')) {
        return jsonResponse['data'] as List;
      } else if (jsonResponse is Map && jsonResponse.containsKey('futsals')) {
        return jsonResponse['futsals'] as List;
      } else if (jsonResponse is Map && jsonResponse.containsKey('bookings')) {
        return jsonResponse['bookings'] as List;
      } else if (jsonResponse is Map && jsonResponse.containsKey('courts')) {
        return jsonResponse['courts'] as List;
      }
      return [];
    } else {
      throw Exception('GET LIST failed: ${response.body}');
    }
  }

  // ============================================
  // ADS METHODS
  // ============================================
  
  static Future<List<dynamic>> getActiveAds() async {
    try {
      final response = await getList('ads/active');
      return response;
    } catch (e) {
      debugPrint('Error fetching ads: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> createAd(Map<String, dynamic> adData) async {
    try {
      return await post('ads', adData);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ============================================
  // AUTH METHODS
  // ============================================
  
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    try {
      return json.decode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Invalid response from server'};
    }
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(userData),
    );
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> verifyEmail(String email, String otp) async {
    return await post('auth/verify-email', {'email': email, 'otp': otp});
  }

  static Future<Map<String, dynamic>> resendOtp(String email) async {
    return await post('auth/resend-otp', {'email': email});
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    return await post('auth/forgot-password', {'email': email});
  }

  static Future<Map<String, dynamic>> resetPassword(String email, String otp, String newPassword) async {
    return await post('auth/reset-password', {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    });
  }

  // ============================================
  // FUTSAL METHODS
  // ============================================
  
  static Future<List<dynamic>> getMyFutsals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('No authentication token found');
      final response = await http.get(
        Uri.parse('$baseUrl/futsals/my'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse['futsals'] ?? [];
      } else {
        throw Exception('Failed to load futsals');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> createFutsal(Map<String, dynamic> futsalData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('No authentication token found');
      final response = await http.post(
        Uri.parse('$baseUrl/futsals'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(futsalData),
      );
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonResponse;
      } else {
        throw Exception(jsonResponse['message'] ?? 'Failed to create futsal');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ============================================
  // COURT METHODS
  // ============================================
  
  static Future<List<dynamic>> getCourts(int futsalId) async {
    try {
      return await getList('futsals/$futsalId/courts');
    } catch (e) {
      return [];
    }
  }

  // ============================================
  // SLOT METHODS
  // ============================================
  
  static Future<Map<String, dynamic>> lockSlot(int slotId) async {
    try {
      return await post('slots/$slotId/lock', {});
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> unlockSlot(int slotId) async {
    try {
      return await post('slots/$slotId/unlock', {});
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ============================================
  // PLAYER BOOKING METHODS
  // ============================================
  
  static Future<Map<String, dynamic>> getMyBookings() async {
    try {
      return await get('bookings/my-bookings');
    } catch (e) {
      return {'bookings': []};
    }
  }

  static Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData) async {
    try {
      return await post('bookings', bookingData);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> cancelUserBooking(int bookingId) async {
    return await put('bookings/$bookingId/cancel', {});
  }

  // ============================================
  // OWNER DASHBOARD METHODS
  // ============================================
  
  static Future<Map<String, dynamic>> getDashboardStats(int futsalId) async {
    try {
      return await get('owner/dashboard/stats?futsalId=$futsalId');
    } catch (e) {
      return {'totalCourts': 0, 'todayBookings': 0, 'todayRevenue': 0, 'activeBookings': 0};
    }
  }

  static Future<List<dynamic>> getDashboardTodayBookings(int futsalId) async {
    try {
      final response = await get('owner/dashboard/today-bookings?futsalId=$futsalId');
      return response['bookings'] ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<double>> getWeeklyRevenue(int futsalId) async {
    try {
      final response = await get('owner/dashboard/weekly-revenue?futsalId=$futsalId');
      final revenueList = response['revenue'] ?? [0, 0, 0, 0, 0, 0, 0];
      if (revenueList is List) {
        return revenueList.map((e) {
          if (e is int) return e.toDouble();
          if (e is double) return e;
          if (e is String) return double.tryParse(e) ?? 0.0;
          return 0.0;
        }).toList();
      }
      return [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    } catch (e) {
      return [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    }
  }

  static Future<Map<String, int>> getPeakHours(int futsalId) async {
    try {
      final response = await get('owner/dashboard/peak-hours?futsalId=$futsalId');
      final peakData = response['peakHours'] ?? {};
      if (peakData is Map) {
        Map<String, int> result = {};
        peakData.forEach((key, value) {
          if (value is int) {
            result[key] = value;
          } else if (value is String) {
            result[key] = int.tryParse(value) ?? 0;
          } else {
            result[key] = 0;
          }
        });
        return result;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // ============================================
  // OWNER BOOKINGS METHODS
  // ============================================
  
  static Future<List<dynamic>> getOwnerUpcomingBookings(int futsalId) async {
    try {
      final response = await get('owner/bookings/upcoming?futsalId=$futsalId');
      return response['bookings'] ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getOwnerMonthBookings(int futsalId, int year, int month) async {
    try {
      final response = await get('owner/bookings/month?futsalId=$futsalId&year=$year&month=$month');
      return response['bookings'] ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getOwnerPastBookings(int futsalId) async {
    try {
      final response = await get('owner/bookings/past?futsalId=$futsalId');
      if (response['status'] == 'success') {
        return response['bookings'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ============================================
  // OWNER BOOKING ACTIONS
  // ============================================
  
  static Future<Map<String, dynamic>> checkInBooking(int bookingId) async {
    return await put('owner/bookings/$bookingId/checkin', {});
  }

  static Future<Map<String, dynamic>> confirmCodPayment(int bookingId) async {
    return await put('owner/bookings/$bookingId/cod-confirm', {});
  }

  static Future<Map<String, dynamic>> ownerCancelBooking(int bookingId) async {
    return await put('owner/bookings/$bookingId/cancel', {});
  }

  static Future<Map<String, dynamic>> updatePaymentStatus(int bookingId, String status) async {
    try {
      return await patch('owner/bookings/$bookingId/payment', {'paymentStatus': status});
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ============================================
  // OWNER CUSTOMER METHODS
  // ============================================
  
  static Future<Map<String, dynamic>> getFutsalCustomers(int futsalId) async {
    try {
      final response = await get('owner/customers?futsalId=$futsalId');
      return response['data'] ?? {'customers': [], 'frequentPlayers': [], 'stats': {}};
    } catch (e) {
      return {'customers': [], 'frequentPlayers': [], 'stats': {}};
    }
  }

  // ============================================
  // OWNER ANALYTICS METHODS
  // ============================================
  
  static Future<Map<String, dynamic>> getRevenueSummary(int futsalId) async {
    try {
      return await get('owner/analytics/revenue-summary?futsalId=$futsalId');
    } catch (e) {
      return {'status': 'error', 'data': {}};
    }
  }

  static Future<Map<String, dynamic>> getPerformanceMetrics(int futsalId) async {
    try {
      return await get('owner/analytics/performance-metrics?futsalId=$futsalId');
    } catch (e) {
      return {'status': 'error', 'data': {}};
    }
  }

  static Future<Map<String, dynamic>> getMonthlyRevenue(int futsalId, {int months = 6}) async {
    try {
      return await get('owner/analytics/monthly-revenue?futsalId=$futsalId&months=$months');
    } catch (e) {
      return {'status': 'error', 'data': []};
    }
  }

  static Future<Map<String, dynamic>> getPaymentBreakdown(int futsalId) async {
    try {
      return await get('owner/analytics/payment-breakdown?futsalId=$futsalId');
    } catch (e) {
      return {'status': 'error', 'data': {}};
    }
  }

  // ============================================
  // OWNER BLOCK METHODS
  // ============================================
  
  static Future<Map<String, dynamic>> getBlockedPlayers({required int futsalId}) async {
    try {
      return await get('owner/blocks?futsalId=$futsalId');
    } catch (e) {
      return {'blocks': []};
    }
  }

  static Future<Map<String, dynamic>> blockPlayer({
    required int playerId,
    required int futsalId,
    String? reason,
  }) async {
    try {
      return await post('owner/blocks', {
        'playerId': playerId,
        'futsalId': futsalId,
        'reason': reason,
      });
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> unblockPlayer({
    required int playerId,
    required int futsalId,
  }) async {
    try {
      return await delete('owner/blocks/$playerId?futsalId=$futsalId');
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> checkIsBlocked({
    required int playerId,
    required int futsalId,
  }) async {
    try {
      return await get('owner/blocks/check/$playerId?futsalId=$futsalId');
    } catch (e) {
      return {'status': 'error', 'isBlocked': false};
    }
  }

  // ============================================
  // ADMIN METHODS
  // ============================================
  
  static Future<Map<String, dynamic>> getAdminDashboard() async {
    return await get('admin/dashboard');
  }

  static Future<Map<String, dynamic>> getAllUsers() async {
    return await get('admin/users');
  }

  static Future<Map<String, dynamic>> approveOwner(int userId) async {
    return await patch('admin/users/$userId/approve-owner', {});
  }

  static Future<Map<String, dynamic>> getPendingFutsals() async {
    return await get('admin/futsals/pending');
  }

  static Future<Map<String, dynamic>> approveFutsal(int futsalId) async {
    return await patch('admin/futsals/$futsalId/approve', {});
  }

  static Future<Map<String, dynamic>> rejectFutsal(int futsalId) async {
    return await patch('admin/futsals/$futsalId/reject', {});
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
      return await get(endpoint);
    } catch (e) {
      return {'bookings': [], 'total': 0};
    }
  }

  static Future<Map<String, dynamic>> getAdminAnalytics() async {
    try {
      return await get('admin/analytics');
    } catch (e) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> updateAdminProfile(Map<String, dynamic> data) async {
    return await put('admin/profile', data);
  }

  // ============================================
  // SYSTEM SETTINGS
  // ============================================
  
  static Future<Map<String, dynamic>> getSystemSettings() async {
    try {
      return await get('admin/settings');
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateSystemSettings(Map<String, dynamic> data) async {
    try {
      return await put('admin/settings', data);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ============================================
  // TOURNAMENT METHODS
  // ============================================
  
  static Future<Map<String, dynamic>> createTournament(Map<String, dynamic> tournamentData) async {
    try {
      return await post('tournaments', tournamentData);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<List<dynamic>> getAllTournaments() async {
    try {
      final response = await get('tournaments');
      return response['tournaments'] ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getMyTournaments() async {
    try {
      final response = await get('tournaments/my-tournaments');
      return response['tournaments'] ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getTournamentById(int tournamentId) async {
    try {
      return await get('tournaments/$tournamentId');
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateTournament(int tournamentId, Map<String, dynamic> tournamentData) async {
    try {
      return await put('tournaments/$tournamentId', tournamentData);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteTournament(int tournamentId) async {
    try {
      return await delete('tournaments/$tournamentId');
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateTournamentStatus(int tournamentId, String status) async {
    try {
      return await patch('tournaments/$tournamentId/status', {'status': status});
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ============================================
  // TEAM MANAGEMENT
  // ============================================
  
  static Future<Map<String, dynamic>> addTeam(int tournamentId, Map<String, dynamic> teamData) async {
    try {
      return await post('tournaments/$tournamentId/teams', teamData);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<List<dynamic>> getTeams(int tournamentId) async {
    try {
      final response = await get('tournaments/$tournamentId/teams');
      return response['teams'] ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> updateTeam(int teamId, Map<String, dynamic> teamData) async {
    try {
      return await put('teams/$teamId', teamData);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteTeam(int teamId) async {
    try {
      return await delete('teams/$teamId');
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ============================================
  // FIXTURE MANAGEMENT
  // ============================================
  
  static Future<Map<String, dynamic>> generateFixtures(int tournamentId) async {
    try {
      return await post('tournaments/$tournamentId/generate-fixtures', {});
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<List<dynamic>> getMatches(int tournamentId) async {
    try {
      final response = await get('tournaments/$tournamentId/matches');
      return response['matches'] ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> updateMatchScore(int matchId, Map<String, dynamic> scoreData) async {
    try {
      return await patch('matches/$matchId/score', scoreData);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateMatchStatus(int matchId, String status) async {
    try {
      return await patch('matches/$matchId/status', {'status': status});
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<List<dynamic>> getTournamentStandings(int tournamentId) async {
    try {
      final response = await get('tournaments/$tournamentId/standings');
      return response['standings'] ?? [];
    } catch (e) {
      return [];
    }
  }

  // ============================================
  // ADMIN ANALYTICS (GAURAV'S METHODS)
  // ============================================
  
  static Future<List<dynamic>> getRevenueOverTimeAdmin(String range) async {
    try {
      final response = await get('admin/analytics/revenue-over-time?range=$range');
      return response['data'] ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getBookingsOverTimeAdmin(String range) async {
    try {
      final response = await get('admin/analytics/bookings-over-time?range=$range');
      return response['data'] ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getBookingStatusBreakdownAdmin() async {
    try {
      final response = await get('admin/analytics/booking-status-breakdown');
      return response['data'] ?? {};
    } catch (e) {
      return {};
    }
  }

  static Future<List<dynamic>> getGroundsByBookingCount() async {
    try {
      final response = await get('admin/analytics/grounds/booking-rank');
      return response['data'] ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getGroundsByRevenue() async {
    try {
      final response = await get('admin/analytics/grounds/revenue-rank');
      return response['data'] ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getTopPlayers({int limit = 10}) async {
    try {
      final response = await get('admin/analytics/users/top-players?limit=$limit');
      return response['data'] ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getAnalyticsPeakHours() async {
    try {
      final response = await get('admin/analytics/peak-hours');
      return response['data'] ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getTournamentRanking() async {
    try {
      final response = await get('admin/analytics/tournaments/rank');
      return response['data'] ?? [];
    } catch (e) {
      return [];
    }
  }

  // ============================================
  // IMAGE UPLOAD
  // ============================================
  
  static Future<List<String>> uploadImages(List<XFile> imageFiles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final uri = Uri.parse('$baseUrl/upload/images');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      for (final imageFile in imageFiles) {
        final bytes = await imageFile.readAsBytes();
        final multipartFile = http.MultipartFile.fromBytes(
          'images',
          bytes,
          filename: imageFile.name,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);
      }
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['urls']);
      } else {
        throw Exception('Upload failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Upload images error: $e');
      return [];
    }
  }
}