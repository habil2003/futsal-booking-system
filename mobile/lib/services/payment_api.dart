import 'base_api_service.dart';

class PaymentApi {
  static Future<Map<String, dynamic>> confirmCodPayment(int bookingId) async {
    try {
      return await BaseApiService.put('owner/bookings/$bookingId/cod-confirm', {});
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> initiateKhaltiPayment(int bookingId) async {
    try {
      return await BaseApiService.post('bookings/payment/initiate', {
        'bookingId': bookingId,
        'paymentMethod': 'KHALTI',
      });
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> verifyKhaltiPayment(String pidx) async {
    return await BaseApiService.post('bookings/payment/verify', {'pidx': pidx});
  }
}