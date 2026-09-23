import '../services/api_service.dart';
import 'package:flutter/foundation.dart';

class PaymentService {

  /// Mobile: Create booking + initiate Khalti payment
  static Future<Map<String, dynamic>> initiateKhaltiPayment(
      int slotId, int duration) async {
    try {
      if (kDebugMode) debugPrint('📍 Initiating Khalti payment for slot $slotId');

      final bookingResponse = await ApiService.post('bookings', {
        'slotId': slotId,
        'paymentMethod': 'KHALTI',
        'duration': duration,
      });

      if (bookingResponse['status'] == 'success' &&
          bookingResponse['booking']?['id'] != null) {

        final bookingId = bookingResponse['booking']['id'];

        final paymentResponse = await ApiService.post(
          'bookings/$bookingId/payment/initiate',
          {'paymentMethod': 'KHALTI'},
        );

        return {
          ...paymentResponse,
          'bookingId': bookingId,
        };
      }

      return {
        'status': 'error',
        'message': bookingResponse['message'] ?? 'Failed to create booking',
      };

    } catch (e) {
      debugPrint('❌ Initiate Khalti payment error: $e');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  /// Verify payment using pidx
  static Future<Map<String, dynamic>> verifyPayment(String pidx) async {
    try {
      if (kDebugMode) debugPrint('🔍 Verifying payment for pidx: $pidx');
      
      // FIXED: Added 'bookings/' prefix
      final response = await ApiService.post('bookings/payments/verify', {'pidx': pidx});
      
      if (kDebugMode) debugPrint('📡 Verify payment response: ${response['status']}');

      if (response['status'] == 'success') {
        return {
          'status': 'success',
          'paymentStatus': 'COMPLETED',
        };
      } else {
        return {
          'status': 'failed',
          'paymentStatus': 'FAILED',
          'message': response['message'] ?? 'Payment verification failed',
        };
      }
    } catch (e) {
      debugPrint('❌ Verify payment error: $e');
      return {
        'status': 'failed',
        'paymentStatus': 'ERROR',
        'message': 'Error verifying payment: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getPaymentStatus(int bookingId) async {
    try {
      final response = await ApiService.get('bookings/$bookingId/payment');
      return response;
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }
}