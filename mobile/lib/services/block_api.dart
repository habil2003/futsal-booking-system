import 'base_api_service.dart';

class BlockApi {
  static Future<Map<String, dynamic>> getBlockedPlayers({required int futsalId}) async {
    try {
      return await BaseApiService.get('owner/blocks?futsalId=$futsalId');
    } catch (e) {
      return {'blocks': []};
    }
  }

  static Future<Map<String, dynamic>> blockPlayer({
    required int playerId,
    required int futsalId,
    String? reason,
  }) async {
    return await BaseApiService.post('owner/blocks', {
      'playerId': playerId,
      'futsalId': futsalId,
      'reason': reason,
    });
  }

  static Future<Map<String, dynamic>> unblockPlayer({
    required int playerId,
    required int futsalId,
  }) async {
    return await BaseApiService.delete('owner/blocks/$playerId?futsalId=$futsalId');
  }

  static Future<Map<String, dynamic>> checkIsBlocked({
    required int playerId,
    required int futsalId,
  }) async {
    try {
      return await BaseApiService.get('owner/blocks/check/$playerId?futsalId=$futsalId');
    } catch (e) {
      return {'status': 'error', 'isBlocked': false};
    }
  }
}