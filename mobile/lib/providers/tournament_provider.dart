import 'package:flutter/material.dart';
import '../models/tournament.dart';
import '../models/team.dart';
import '../models/match.dart';
import '../services/api_service.dart';

class TournamentProvider with ChangeNotifier {
  // Lists
  List<Tournament> _tournaments = [];
  List<Tournament> _myTournaments = []; // For owners
  List<Team> _teams = [];
  List<Match> _matches = [];
  
  // Single items
  Tournament? _currentTournament;
  Team? _currentTeam;
  Match? _currentMatch;
  
  // Loading states
  bool isLoading = false;
  String? error;
  
  // Getters
  List<Tournament> get tournaments => _tournaments;
  List<Tournament> get myTournaments => _myTournaments;
  List<Team> get teams => _teams;
  List<Match> get matches => _matches;
  Tournament? get currentTournament => _currentTournament;
  Team? get currentTeam => _currentTeam;
  Match? get currentMatch => _currentMatch;

  // ============================================
  // TOURNAMENT METHODS
  // ============================================

  // Load all tournaments (for players)
  Future<void> loadTournaments() async {
    debugPrint('🏆 TournamentProvider: Loading all tournaments');
    
    isLoading = true;
    error = null;
    notifyListeners();
    
    try {
      final response = await ApiService.get('/tournaments');
      
      if (response['tournaments'] != null) {
        _tournaments = (response['tournaments'] as List)
            .map((json) => Tournament.fromJson(json))
            .toList();
      }
      
      debugPrint('🏆 Loaded ${_tournaments.length} tournaments');
      
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      debugPrint('🏆 Error loading tournaments: $e');
    }
  }

  // Load owner's tournaments (for dashboard)
  Future<void> loadMyTournaments() async {
    debugPrint('🏆 TournamentProvider: Loading my tournaments');
    
    isLoading = true;
    error = null;
    notifyListeners();
    
    try {
      final response = await ApiService.get('/tournaments/my');
      
      if (response['tournaments'] != null) {
        _myTournaments = (response['tournaments'] as List)
            .map((json) => Tournament.fromJson(json))
            .toList();
      }
      
      debugPrint('🏆 Loaded ${_myTournaments.length} my tournaments');
      
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      debugPrint('🏆 Error loading my tournaments: $e');
    }
  }

  // Load single tournament
  Future<void> loadTournament(int tournamentId) async {
    debugPrint('🏆 TournamentProvider: Loading tournament $tournamentId');
    
    isLoading = true;
    error = null;
    notifyListeners();
    
    try {
      final response = await ApiService.get('/tournaments/$tournamentId');
      
      if (response['tournament'] != null) {
        _currentTournament = Tournament.fromJson(response['tournament']);
      }
      
      // Also load teams and matches for this tournament
      await Future.wait([
        loadTeams(tournamentId),
        loadMatches(tournamentId),
      ]);
      
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      debugPrint('🏆 Error loading tournament: $e');
    }
  }

  // Create new tournament
  Future<Map<String, dynamic>> createTournament(Map<String, dynamic> tournamentData) async {
    debugPrint('🏆 TournamentProvider: Creating tournament');
    
    isLoading = true;
    error = null;
    notifyListeners();
    
    try {
      final response = await ApiService.post('/tournaments', tournamentData);
      
      if (response['status'] == 'success') {
        // Refresh my tournaments list
        await loadMyTournaments();
        
        isLoading = false;
        notifyListeners();
        
        return {
          'status': 'success',
          'message': response['message'] ?? 'Tournament created successfully',
          'tournamentId': response['tournament']?['id'],
        };
      } else {
        isLoading = false;
        notifyListeners();
        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to create tournament',
        };
      }
    } catch (e) {
      isLoading = false;
      error = e.toString();
      notifyListeners();
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  // Update tournament
  Future<Map<String, dynamic>> updateTournament(int tournamentId, Map<String, dynamic> tournamentData) async {
    debugPrint('🏆 TournamentProvider: Updating tournament $tournamentId');
    
    isLoading = true;
    error = null;
    notifyListeners();
    
    try {
      final response = await ApiService.put('/tournaments/$tournamentId', tournamentData);
      
      if (response['status'] == 'success') {
        // Update current tournament if it's the one being edited
        if (_currentTournament?.id == tournamentId) {
          _currentTournament = Tournament.fromJson({
            ..._currentTournament!.toJson(),
            ...tournamentData,
          });
        }
        
        await loadMyTournaments();
        
        isLoading = false;
        notifyListeners();
        
        return {
          'status': 'success',
          'message': response['message'] ?? 'Tournament updated successfully',
        };
      } else {
        isLoading = false;
        notifyListeners();
        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to update tournament',
        };
      }
    } catch (e) {
      isLoading = false;
      error = e.toString();
      notifyListeners();
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  // Delete tournament
  Future<Map<String, dynamic>> deleteTournament(int tournamentId) async {
    debugPrint('🏆 TournamentProvider: Deleting tournament $tournamentId');
    
    isLoading = true;
    error = null;
    notifyListeners();
    
    try {
      final response = await ApiService.delete('/tournaments/$tournamentId');
      
      if (response['status'] == 'success') {
        // Remove from lists
        _tournaments.removeWhere((t) => t.id == tournamentId);
        _myTournaments.removeWhere((t) => t.id == tournamentId);
        
        if (_currentTournament?.id == tournamentId) {
          _currentTournament = null;
        }
        
        isLoading = false;
        notifyListeners();
        
        return {
          'status': 'success',
          'message': response['message'] ?? 'Tournament deleted successfully',
        };
      } else {
        isLoading = false;
        notifyListeners();
        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to delete tournament',
        };
      }
    } catch (e) {
      isLoading = false;
      error = e.toString();
      notifyListeners();
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  // Update tournament status
  Future<Map<String, dynamic>> updateTournamentStatus(int tournamentId, TournamentStatus status) async {
    debugPrint('🏆 TournamentProvider: Updating tournament $tournamentId status to $status');
    
    try {
      final response = await ApiService.patch('/tournaments/$tournamentId/status', {
        'status': _tournamentStatusToString(status),
      });
      
      if (response['status'] == 'success') {
        // Update local tournament
        if (_currentTournament?.id == tournamentId) {
          _currentTournament = _currentTournament?.copyWith(status: status);
        }
        
        // Update in lists
        _updateTournamentInLists(tournamentId, (t) => t.copyWith(status: status));
        
        notifyListeners();
        
        return {
          'status': 'success',
          'message': 'Tournament status updated',
        };
      } else {
        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to update status',
        };
      }
    } catch (e) {
      debugPrint('🏆 Error updating status: $e');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  // ============================================
  // TEAM METHODS
  // ============================================

  // Load teams for a tournament
  Future<void> loadTeams(int tournamentId) async {
    debugPrint('🏆 TournamentProvider: Loading teams for tournament $tournamentId');
    
    try {
      final response = await ApiService.get('/tournaments/$tournamentId/teams');
      
      if (response['teams'] != null) {
        _teams = (response['teams'] as List)
            .map((json) => Team.fromJson(json))
            .toList();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('🏆 Error loading teams: $e');
    }
  }

  // Add team to tournament
  Future<Map<String, dynamic>> addTeam(int tournamentId, Map<String, dynamic> teamData) async {
    debugPrint('🏆 TournamentProvider: Adding team to tournament $tournamentId');
    
    try {
      final response = await ApiService.post('/tournaments/$tournamentId/teams', teamData);
      
      if (response['status'] == 'success') {
        // Refresh teams
        await loadTeams(tournamentId);
        
        return {
          'status': 'success',
          'message': response['message'] ?? 'Team added successfully',
        };
      } else {
        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to add team',
        };
      }
    } catch (e) {
      debugPrint('🏆 Error adding team: $e');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  // Update team
  Future<Map<String, dynamic>> updateTeam(int teamId, Map<String, dynamic> teamData) async {
    debugPrint('🏆 TournamentProvider: Updating team $teamId');
    
    try {
      final response = await ApiService.put('/teams/$teamId', teamData);
      
      if (response['status'] == 'success') {
        // Update in local list
        final index = _teams.indexWhere((t) => t.id == teamId);
        if (index != -1) {
          _teams[index] = Team.fromJson({
            ..._teams[index].toJson(),
            ...teamData,
          });
          notifyListeners();
        }
        
        return {
          'status': 'success',
          'message': response['message'] ?? 'Team updated successfully',
        };
      } else {
        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to update team',
        };
      }
    } catch (e) {
      debugPrint('🏆 Error updating team: $e');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  // Delete team
  Future<Map<String, dynamic>> deleteTeam(int teamId) async {
    debugPrint('🏆 TournamentProvider: Deleting team $teamId');
    
    try {
      final response = await ApiService.delete('/teams/$teamId');
      
      if (response['status'] == 'success') {
        _teams.removeWhere((t) => t.id == teamId);
        notifyListeners();
        
        return {
          'status': 'success',
          'message': response['message'] ?? 'Team deleted successfully',
        };
      } else {
        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to delete team',
        };
      }
    } catch (e) {
      debugPrint('🏆 Error deleting team: $e');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  // ============================================
  // MATCH METHODS
  // ============================================

  // Load matches for a tournament
  Future<void> loadMatches(int tournamentId) async {
    debugPrint('🏆 TournamentProvider: Loading matches for tournament $tournamentId');
    
    try {
      final response = await ApiService.get('/tournaments/$tournamentId/matches');
      
      if (response['matches'] != null) {
        _matches = (response['matches'] as List)
            .map((json) => Match.fromJson(json))
            .toList();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('🏆 Error loading matches: $e');
    }
  }

  // Generate fixtures (for owner)
  Future<Map<String, dynamic>> generateFixtures(int tournamentId) async {
    debugPrint('🏆 TournamentProvider: Generating fixtures for tournament $tournamentId');
    
    isLoading = true;
    notifyListeners();
    
    try {
      final response = await ApiService.post('/tournaments/$tournamentId/generate-fixtures', {});
      
      if (response['status'] == 'success') {
        // Refresh matches
        await loadMatches(tournamentId);
        
        isLoading = false;
        notifyListeners();
        
        return {
          'status': 'success',
          'message': response['message'] ?? 'Fixtures generated successfully',
        };
      } else {
        isLoading = false;
        notifyListeners();
        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to generate fixtures',
        };
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();
      debugPrint('🏆 Error generating fixtures: $e');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  // Update match score
  Future<Map<String, dynamic>> updateMatchScore(int matchId, int team1Score, int team2Score, {int? team1Penalty, int? team2Penalty}) async {
    debugPrint('🏆 TournamentProvider: Updating score for match $matchId');
    
    try {
      final response = await ApiService.patch('/matches/$matchId/score', {
        'team1Score': team1Score,
        'team2Score': team2Score,
        'team1Penalty': team1Penalty,
        'team2Penalty': team2Penalty,
      });
      
      if (response['status'] == 'success') {
        // Update match in list
        final index = _matches.indexWhere((m) => m.id == matchId);
        if (index != -1) {
          _matches[index] = Match.fromJson({
            ..._matches[index].toJson(),
            'team1Score': team1Score,
            'team2Score': team2Score,
            'team1Penalty': team1Penalty,
            'team2Penalty': team2Penalty,
          });
          notifyListeners();
        }
        
        return {
          'status': 'success',
          'message': response['message'] ?? 'Score updated successfully',
        };
      } else {
        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to update score',
        };
      }
    } catch (e) {
      debugPrint('🏆 Error updating score: $e');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  // Update match status
  Future<Map<String, dynamic>> updateMatchStatus(int matchId, MatchStatus status) async {
    debugPrint('🏆 TournamentProvider: Updating match $matchId status to $status');
    
    try {
      final response = await ApiService.patch('/matches/$matchId/status', {
        'status': _matchStatusToString(status),
      });
      
      if (response['status'] == 'success') {
        // Update match in list
        final index = _matches.indexWhere((m) => m.id == matchId);
        if (index != -1) {
          _matches[index] = Match.fromJson({
            ..._matches[index].toJson(),
            'status': _matchStatusToString(status),
          });
          notifyListeners();
        }
        
        return {
          'status': 'success',
          'message': response['message'] ?? 'Match status updated',
        };
      } else {
        return {
          'status': 'error',
          'message': response['message'] ?? 'Failed to update match status',
        };
      }
    } catch (e) {
      debugPrint('🏆 Error updating match status: $e');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  void _updateTournamentInLists(int tournamentId, Function(Tournament) update) {
    // Update in myTournaments
    final myIndex = _myTournaments.indexWhere((t) => t.id == tournamentId);
    if (myIndex != -1) {
      _myTournaments[myIndex] = update(_myTournaments[myIndex]);
    }
    
    // Update in tournaments list
    final index = _tournaments.indexWhere((t) => t.id == tournamentId);
    if (index != -1) {
      _tournaments[index] = update(_tournaments[index]);
    }
  }

  // Clear all data (for logout)
  void clearData() {
    _tournaments = [];
    _myTournaments = [];
    _teams = [];
    _matches = [];
    _currentTournament = null;
    _currentTeam = null;
    _currentMatch = null;
    error = null;
    notifyListeners();
  }

  // Get tournament statistics
  Map<String, dynamic> getTournamentStats(int tournamentId) {
    final tournament = _tournaments.firstWhere(
      (t) => t.id == tournamentId,
      orElse: () => _myTournaments.firstWhere(
        (t) => t.id == tournamentId,
        orElse: () => Tournament(
          id: 0,
          futsalId: 0,
          futsalName: '',
          name: '',
          type: TournamentType.knockout,
          status: TournamentStatus.draft,
          startDate: DateTime.now(),
          numberOfTeams: 0,
          isPublished: false,
          createdAt: DateTime.now(),
        ),
      ),
    );
    
    final tournamentMatches = _matches.where((m) => m.tournamentId == tournamentId).toList();
    final totalMatches = tournamentMatches.length;
    final completedMatches = tournamentMatches.where((m) => m.isCompleted).length;
    
    // Calculate top scorer (would come from backend in real app)
    
    return {
      'tournament': tournament,
      'totalTeams': _teams.length,
      'totalMatches': totalMatches,
      'completedMatches': completedMatches,
      'progressPercentage': totalMatches > 0 ? completedMatches / totalMatches : 0,
    };
  }
}

// Helper functions (duplicated from models to avoid import issues)
String _tournamentStatusToString(TournamentStatus status) {
  switch (status) {
    case TournamentStatus.draft:
      return 'draft';
    case TournamentStatus.ongoing:
      return 'ongoing';
    case TournamentStatus.completed:
      return 'completed';
    case TournamentStatus.cancelled:
      return 'cancelled';
  }
}

String _matchStatusToString(MatchStatus status) {
  switch (status) {
    case MatchStatus.scheduled:
      return 'scheduled';
    case MatchStatus.ongoing:
      return 'ongoing';
    case MatchStatus.completed:
      return 'completed';
    case MatchStatus.postponed:
      return 'postponed';
    case MatchStatus.cancelled:
      return 'cancelled';
  }
}