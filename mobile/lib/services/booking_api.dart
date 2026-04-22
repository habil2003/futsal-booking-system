import 'base_api_service.dart';

class BookingApi {
  // Player bookings
  static Future<Map<String, dynamic>> getMyBookings() async {
    try {
      return await BaseApiService.get('bookings/my-bookings');
    } catch (e) {
      return {'bookings': []};
    }
  }

  static Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData) async {
    return await BaseApiService.post('bookings', bookingData);
  }

  static Future<Map<String, dynamic>> cancelUserBooking(int bookingId) async {
    return await BaseApiService.put('bookings/$bookingId/cancel', {});
  }

  // Owner booking actions
  static Future<Map<String, dynamic>> checkInBooking(int bookingId) async {
    return await BaseApiService.put('bookings/owner/$bookingId/checkin', {});
  }

  static Future<Map<String, dynamic>> ownerCancelBooking(int bookingId) async {
    return await BaseApiService.delete('bookings/owner/$bookingId/cancel');
  }

  // Owner dashboard bookings
  static Future<List<dynamic>> getOwnerTodayBookings(int futsalId) async {
    try {
      final response = await BaseApiService.get('bookings/owner/today?futsalId=$futsalId');
      if (response is Map && response.containsKey('bookings')) {
        return response['bookings'] as List;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getOwnerUpcomingBookings(int futsalId) async {
    try {
      final response = await BaseApiService.get('bookings/owner/upcoming?futsalId=$futsalId');
      if (response is Map && response.containsKey('bookings')) {
        return response['bookings'] as List;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getOwnerMonthBookings(int futsalId, int year, int month) async {
    try {
      final response = await BaseApiService.get('bookings/owner/month/$year/$month?futsalId=$futsalId');
      if (response is Map && response.containsKey('bookings')) {
        return response['bookings'] as List;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getOwnerBookings({
    required int futsalId,
    String? status,
    int? courtId,
    String? date,
  }) async {
    try {
      String url = 'bookings/owner/all?futsalId=$futsalId';
      if (status != null) url += '&status=$status';
      if (courtId != null) url += '&courtId=$courtId';
      if (date != null) url += '&date=$date';
      
      final response = await BaseApiService.get(url);
      if (response is Map && response.containsKey('bookings')) {
        return response['bookings'] as List;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}