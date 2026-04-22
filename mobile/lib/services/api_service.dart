// lib/services/api_service.dart
// This file maintains backward compatibility with existing code
// All methods delegate to the new modular API classes

// Import all the new modular APIs
import 'base_api_service.dart';
import 'auth_api.dart';
import 'futsal_api.dart';
import 'slot_api.dart';
import 'booking_api.dart';
import 'payment_api.dart';
import 'block_api.dart';
import 'admin_api.dart';
import 'revenue_api.dart';
import 'tournament_api.dart';
import 'upload_api.dart';

import 'package:image_picker/image_picker.dart';  // ✅ ADD THIS IMPORT


// Legacy ApiService class that delegates to the new modular APIs
class ApiService {
  // ============================================
  // BASE URL (kept for compatibility)
  // ============================================
  static const String baseUrl = BaseApiService.baseUrl;

  // ============================================
  // BASE HTTP METHODS (delegated)
  // ============================================
  static Future<Map<String, dynamic>> get(String endpoint) async {
    return await BaseApiService.get(endpoint);
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    return await BaseApiService.post(endpoint, data);
  }

  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    return await BaseApiService.put(endpoint, data);
  }

  static Future<Map<String, dynamic>> patch(String endpoint, Map<String, dynamic> data) async {
    return await BaseApiService.patch(endpoint, data);
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    return await BaseApiService.delete(endpoint);
  }

  static Future<List<dynamic>> getList(String endpoint) async {
    return await BaseApiService.getList(endpoint);
  }

  // ============================================
  // AUTHENTICATION METHODS
  // ============================================
  static Future<Map<String, dynamic>> login(String email, String password) async {
    return await AuthApi.login(email, password);
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    return await AuthApi.register(userData);
  }

  static Future<Map<String, dynamic>> verifyEmail(String email, String otp) async {
    return await AuthApi.verifyEmail(email, otp);
  }

  static Future<Map<String, dynamic>> resendOtp(String email) async {
    return await AuthApi.resendOtp(email);
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    return await AuthApi.forgotPassword(email);
  }

  static Future<Map<String, dynamic>> resetPassword(
      String email, String otp, String newPassword) async {
    return await AuthApi.resetPassword(email, otp, newPassword);
  }

  // ============================================
  // SLOT METHODS
  // ============================================
  static Future<Map<String, dynamic>> lockSlot(int slotId) async {
    return await SlotApi.lockSlot(slotId);
  }

  static Future<Map<String, dynamic>> unlockSlot(int slotId) async {
    return await SlotApi.unlockSlot(slotId);
  }

  // ============================================
  // FUTSAL METHODS
  // ============================================
  static Future<List<dynamic>> getMyFutsals() async {
    return await FutsalApi.getMyFutsals();
  }

  static Future<Map<String, dynamic>> createFutsal(Map<String, dynamic> futsalData) async {
    return await FutsalApi.createFutsal(futsalData);
  }

  static Future<Map<String, dynamic>> updateFutsal(int id, Map<String, dynamic> futsalData) async {
    return await FutsalApi.updateFutsal(id, futsalData);
  }

  static Future<Map<String, dynamic>> deleteFutsal(int id) async {
    return await FutsalApi.deleteFutsal(id);
  }

  static Future<List<dynamic>> getCourts(int futsalId) async {
    return await FutsalApi.getCourts(futsalId);
  }

  static Future<Map<String, dynamic>> getDashboardStats(int futsalId) async {
    return await FutsalApi.getDashboardStats(futsalId);
  }

  static Future<List<dynamic>> getWeeklyRevenue(int futsalId) async {
    return await FutsalApi.getWeeklyRevenue(futsalId);
  }

  static Future<Map<String, dynamic>> getPeakHours(int futsalId) async {
    return await FutsalApi.getPeakHours(futsalId);
  }

  // ============================================
  // PLAYER BOOKING METHODS
  // ============================================
  static Future<Map<String, dynamic>> getMyBookings() async {
    return await BookingApi.getMyBookings();
  }

  static Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData) async {
    return await BookingApi.createBooking(bookingData);
  }

  static Future<Map<String, dynamic>> cancelUserBooking(int bookingId) async {
    return await BookingApi.cancelUserBooking(bookingId);
  }

  // ============================================
  // PAYMENT METHODS
  // ============================================
  static Future<Map<String, dynamic>> confirmCodPayment(int bookingId) async {
    return await PaymentApi.confirmCodPayment(bookingId);
  }

  static Future<Map<String, dynamic>> initiateKhaltiPayment(int bookingId) async {
    return await PaymentApi.initiateKhaltiPayment(bookingId);
  }

  static Future<Map<String, dynamic>> verifyKhaltiPayment(String pidx) async {
    return await PaymentApi.verifyKhaltiPayment(pidx);
  }

  // ============================================
  // OWNER BOOKING ACTIONS
  // ============================================
  static Future<Map<String, dynamic>> checkInBooking(int bookingId) async {
    return await BookingApi.checkInBooking(bookingId);
  }

  static Future<Map<String, dynamic>> ownerCancelBooking(int bookingId) async {
    return await BookingApi.ownerCancelBooking(bookingId);
  }

  // ============================================
  // OWNER DASHBOARD BOOKINGS
  // ============================================
  static Future<List<dynamic>> getOwnerTodayBookings(int futsalId) async {
    return await BookingApi.getOwnerTodayBookings(futsalId);
  }

  static Future<List<dynamic>> getOwnerUpcomingBookings(int futsalId) async {
    return await BookingApi.getOwnerUpcomingBookings(futsalId);
  }

  static Future<List<dynamic>> getOwnerMonthBookings(int futsalId, int year, int month) async {
    return await BookingApi.getOwnerMonthBookings(futsalId, year, month);
  }

  static Future<List<dynamic>> getOwnerBookings({
    required int futsalId,
    String? status,
    int? courtId,
    String? date,
  }) async {
    return await BookingApi.getOwnerBookings(
      futsalId: futsalId,
      status: status,
      courtId: courtId,
      date: date,
    );
  }

  // ============================================
  // BLOCK PLAYER METHODS
  // ============================================
  static Future<Map<String, dynamic>> getBlockedPlayers({required int futsalId}) async {
    return await BlockApi.getBlockedPlayers(futsalId: futsalId);
  }

  static Future<Map<String, dynamic>> blockPlayer({
    required int playerId,
    required int futsalId,
    String? reason,
  }) async {
    return await BlockApi.blockPlayer(playerId: playerId, futsalId: futsalId, reason: reason);
  }

  static Future<Map<String, dynamic>> unblockPlayer({
    required int playerId,
    required int futsalId,
  }) async {
    return await BlockApi.unblockPlayer(playerId: playerId, futsalId: futsalId);
  }

  static Future<Map<String, dynamic>> checkIsBlocked({
    required int playerId,
    required int futsalId,
  }) async {
    return await BlockApi.checkIsBlocked(playerId: playerId, futsalId: futsalId);
  }

  // ============================================
  // ADMIN METHODS
  // ============================================
  static Future<Map<String, dynamic>> getAdminDashboard() async {
    return await AdminApi.getDashboard();
  }

  static Future<Map<String, dynamic>> getAllUsers() async {
    return await AdminApi.getAllUsers();
  }

  static Future<Map<String, dynamic>> approveOwner(int userId) async {
    return await AdminApi.approveOwner(userId);
  }

  static Future<Map<String, dynamic>> getPendingFutsals() async {
    return await AdminApi.getPendingFutsals();
  }

  static Future<Map<String, dynamic>> approveFutsal(int futsalId) async {
    return await AdminApi.approveFutsal(futsalId);
  }

  static Future<Map<String, dynamic>> rejectFutsal(int futsalId) async {
    return await AdminApi.rejectFutsal(futsalId);
  }

  static Future<Map<String, dynamic>> getAllFutsals() async {
    return await AdminApi.getAllFutsals();
  }

  static Future<Map<String, dynamic>> getAdminBookings({
    String status = 'ALL',
    String? from,
    String? to,
    int page = 1,
  }) async {
    return await AdminApi.getAdminBookings(status: status, from: from, to: to, page: page);
  }

  static Future<Map<String, dynamic>> getAdminAnalytics() async {
    return await AdminApi.getAdminAnalytics();
  }

  static Future<Map<String, dynamic>> updateAdminProfile(Map<String, dynamic> data) async {
    return await AdminApi.updateAdminProfile(data);
  }

  static Future<Map<String, dynamic>> getSystemSettings() async {
    return await AdminApi.getSystemSettings();
  }

  static Future<Map<String, dynamic>> updateSystemSettings(Map<String, dynamic> data) async {
    return await AdminApi.updateSystemSettings(data);
  }

  // ============================================
  // REVENUE & EARNINGS METHODS
  // ============================================
  static Future<Map<String, dynamic>> getRevenueOverview({String period = "month"}) async {
    return await RevenueApi.getRevenueOverview(period: period);
  }

  static Future<Map<String, dynamic>> getCommissionBreakdown({int? futsalId, String? from, String? to}) async {
    return await RevenueApi.getCommissionBreakdown(futsalId: futsalId, from: from, to: to);
  }

  static Future<Map<String, dynamic>> getRevenueTrends({String interval = "daily", int days = 30}) async {
    return await RevenueApi.getRevenueTrends(interval: interval, days: days);
  }

  static Future<List<dynamic>> getPayoutRequests({String status = "PENDING"}) async {
    return await RevenueApi.getPayoutRequests(status: status);
  }

  static Future<Map<String, dynamic>> processPayout(int payoutId, {String? notes}) async {
    return await RevenueApi.processPayout(payoutId, notes: notes);
  }

  static Future<Map<String, dynamic>> updateCommissionRate(double rate) async {
    return await RevenueApi.updateCommissionRate(rate);
  }

  static Future<double> getCommissionRate() async {
    return await RevenueApi.getCommissionRate();
  }

  static Future<Map<String, dynamic>> getEarningsOverview({String period = "month"}) async {
    return await RevenueApi.getEarningsOverview(period: period);
  }

  static Future<Map<String, dynamic>> getEarningsBreakdown({int? futsalId, String? from, String? to}) async {
    return await RevenueApi.getEarningsBreakdown(futsalId: futsalId, from: from, to: to);
  }

  static Future<Map<String, dynamic>> getEarningsHistory({int page = 1, int limit = 20}) async {
    return await RevenueApi.getEarningsHistory(page: page, limit: limit);
  }

  static Future<Map<String, dynamic>> getEarningsChart({int days = 30}) async {
    return await RevenueApi.getEarningsChart(days: days);
  }

  static Future<Map<String, dynamic>> requestPayout() async {
    return await RevenueApi.requestPayout();
  }

  static Future<List<dynamic>> getPayoutHistory() async {
    return await RevenueApi.getPayoutHistory();
  }

  // ============================================
  // TOURNAMENT METHODS
  // ============================================
  static Future<Map<String, dynamic>> createTournament(Map<String, dynamic> tournamentData) async {
    return await TournamentApi.createTournament(tournamentData);
  }

  static Future<List<dynamic>> getAllTournaments() async {
    return await TournamentApi.getAllTournaments();
  }

  static Future<List<dynamic>> getMyTournaments() async {
    return await TournamentApi.getMyTournaments();
  }

  static Future<Map<String, dynamic>> getTournamentById(int tournamentId) async {
    return await TournamentApi.getTournamentById(tournamentId);
  }

  static Future<Map<String, dynamic>> updateTournament(int tournamentId, Map<String, dynamic> tournamentData) async {
    return await TournamentApi.updateTournament(tournamentId, tournamentData);
  }

  static Future<Map<String, dynamic>> deleteTournament(int tournamentId) async {
    return await TournamentApi.deleteTournament(tournamentId);
  }

  static Future<Map<String, dynamic>> updateTournamentStatus(int tournamentId, String status) async {
    return await TournamentApi.updateTournamentStatus(tournamentId, status);
  }

  static Future<Map<String, dynamic>> addTeam(int tournamentId, Map<String, dynamic> teamData) async {
    return await TournamentApi.addTeam(tournamentId, teamData);
  }

  static Future<List<dynamic>> getTeams(int tournamentId) async {
    return await TournamentApi.getTeams(tournamentId);
  }

  static Future<Map<String, dynamic>> updateTeam(int teamId, Map<String, dynamic> teamData) async {
    return await TournamentApi.updateTeam(teamId, teamData);
  }

  static Future<Map<String, dynamic>> deleteTeam(int teamId) async {
    return await TournamentApi.deleteTeam(teamId);
  }

  static Future<Map<String, dynamic>> generateFixtures(int tournamentId) async {
    return await TournamentApi.generateFixtures(tournamentId);
  }

  static Future<List<dynamic>> getMatches(int tournamentId) async {
    return await TournamentApi.getMatches(tournamentId);
  }

  static Future<Map<String, dynamic>> updateMatchScore(int matchId, Map<String, dynamic> scoreData) async {
    return await TournamentApi.updateMatchScore(matchId, scoreData);
  }

  static Future<Map<String, dynamic>> updateMatchStatus(int matchId, String status) async {
    return await TournamentApi.updateMatchStatus(matchId, status);
  }

  static Future<List<dynamic>> getTournamentStandings(int tournamentId) async {
    return await TournamentApi.getTournamentStandings(tournamentId);
  }

  // ============================================
  // IMAGE UPLOAD
  // ============================================
  static Future<List<String>> uploadImages(List<XFile> imageFiles) async {
    return await UploadApi.uploadImages(imageFiles);
  }
    // ============================================
  // REGISTRATION FEE PAYMENT METHODS
  // ============================================
  
  /// Initiate Khalti payment for futsal registration fee
  static Future<Map<String, dynamic>> initiateRegistrationPayment(int futsalId) async {
    try {
      final response = await BaseApiService.post('futsals/initiate-registration-payment', {
        'futsalId': futsalId,
      });
      return response;
    } catch (e) {
      print('Initiate registration payment error: $e');
      rethrow;
    }
  }

  /// Verify Khalti payment for futsal registration fee
  static Future<Map<String, dynamic>> verifyRegistrationPayment(String pidx, int futsalId) async {
    try {
      final response = await BaseApiService.post('futsals/verify-registration-payment', {
        'pidx': pidx,
        'futsalId': futsalId,
      });
      return response;
    } catch (e) {
      print('Verify registration payment error: $e');
      rethrow;
    }
  }

  /// Get registration fee settings (admin only)
  static Future<Map<String, dynamic>> getRegistrationFeeSettings() async {
    try {
      return await BaseApiService.get('admin/settings/registration-fee');
    } catch (e) {
      print('Get registration fee settings error: $e');
      rethrow;
    }
  }

  /// Update registration fee settings (admin only)
  static Future<Map<String, dynamic>> updateRegistrationFeeSettings({
    required double amount,
    required bool enabled,
  }) async {
    try {
      return await BaseApiService.put('admin/settings/registration-fee', {
        'amount': amount,
        'enabled': enabled,
      });
    } catch (e) {
      print('Update registration fee settings error: $e');
      rethrow;
    }
  }

    // ============================================
  // ADMIN FUTSAL MANAGEMENT (Deactivate/Activate/Delete)
  // ============================================
  static Future<Map<String, dynamic>> adminDeactivateFutsal(int futsalId) async {
    return await AdminApi.adminDeactivateFutsal(futsalId);
  }

  static Future<Map<String, dynamic>> adminActivateFutsal(int futsalId) async {
    return await AdminApi.adminActivateFutsal(futsalId);
  }

  static Future<Map<String, dynamic>> adminDeleteFutsal(int futsalId) async {
    return await AdminApi.adminDeleteFutsal(futsalId);
  }
}
