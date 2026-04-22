import 'base_api_service.dart';

class SlotApi {
  static Future<Map<String, dynamic>> lockSlot(int slotId) async {
    try {
      return await BaseApiService.post('slots/$slotId/lock', {});
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> unlockSlot(int slotId) async {
    try {
      return await BaseApiService.post('slots/$slotId/unlock', {});
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
}