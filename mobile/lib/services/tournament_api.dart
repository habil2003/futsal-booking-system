import 'base_api_service.dart';

class TournamentApi {
  static Future<Map<String, dynamic>> createTournament(Map<String, dynamic> tournamentData) async {
    return await BaseApiService.post('tournaments', tournamentData);
  }

  static Future<List<dynamic>> getAllTournaments() async {
    try {
      final response = await BaseApiService.get('tournaments');
      return response['tournaments'] ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getMyTournaments() async {
    try {
      final response = await BaseApiService.get('tournaments/my-tournaments');
      return response['tournaments'] ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getTournamentById(int tournamentId) async {
    return await BaseApiService.get('tournaments/$tournamentId');
  }

  static Future<Map<String, dynamic>> updateTournament(int tournamentId, Map<String, dynamic> tournamentData) async {
    return await BaseApiService.put('tournaments/$tournamentId', tournamentData);
  }

  static Future<Map<String, dynamic>> deleteTournament(int tournamentId) async {
    return await BaseApiService.delete('tournaments/$tournamentId');
  }

  static Future<Map<String, dynamic>> updateTournamentStatus(int tournamentId, String status) async {
    return await BaseApiService.patch('tournaments/$tournamentId/status', {'status': status});
  }

  // Teams
  static Future<Map<String, dynamic>> addTeam(int tournamentId, Map<String, dynamic> teamData) async {
    return await BaseApiService.post('tournaments/$tournamentId/teams', teamData);
  }

  static Future<List<dynamic>> getTeams(int tournamentId) async {
    try {
      final response = await BaseApiService.get('tournaments/$tournamentId/teams');
      return response['teams'] ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> updateTeam(int teamId, Map<String, dynamic> teamData) async {
    return await BaseApiService.put('teams/$teamId', teamData);
  }

  static Future<Map<String, dynamic>> deleteTeam(int teamId) async {
    return await BaseApiService.delete('teams/$teamId');
  }

  // Matches/Fixtures
  static Future<Map<String, dynamic>> generateFixtures(int tournamentId) async {
    return await BaseApiService.post('tournaments/$tournamentId/generate-fixtures', {});
  }

  static Future<List<dynamic>> getMatches(int tournamentId) async {
    try {
      final response = await BaseApiService.get('tournaments/$tournamentId/matches');
      return response['matches'] ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> updateMatchScore(int matchId, Map<String, dynamic> scoreData) async {
    return await BaseApiService.patch('matches/$matchId/score', scoreData);
  }

  static Future<Map<String, dynamic>> updateMatchStatus(int matchId, String status) async {
    return await BaseApiService.patch('matches/$matchId/status', {'status': status});
  }

  static Future<List<dynamic>> getTournamentStandings(int tournamentId) async {
    try {
      final response = await BaseApiService.get('tournaments/$tournamentId/standings');
      return response['standings'] ?? [];
    } catch (e) {
      return [];
    }
  }
}