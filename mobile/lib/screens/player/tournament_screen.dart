import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'register_team_screen.dart';
import 'my_team_screen.dart';
import 'player_tournament_details_screen.dart';

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _allTournaments = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchTournaments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTournaments() async {
    try {
      final response = await ApiService.getList('tournaments/published');
      _allTournaments = (response as List)
          .map((t) => {
                'id': t['id'],
                'name': t['name'],
                'startDate': t['startDate'],
                'endDate': t['endDate'],
                'status': t['status'] ?? 'OPEN',
                'prize': t['prizePool']?.toString() ?? 'TBA',
                'type': t['type'] ?? 'KNOCKOUT',
                'maxTeams': t['maxTeams'] ?? 0,
                'currentTeams': t['_count']?['teams'] ?? 0,
                'image': t['imageUrl'] ?? 'https://picsum.photos/id/1005/200/200',
              })
          .toList()
          .cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error loading tournaments: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _filterByStatus(String status) {
    List<Map<String, dynamic>> filtered = _allTournaments;
    if (status != 'All') {
      filtered = filtered
          .where((t) => (t['status'] as String).toUpperCase() == status.toUpperCase())
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((t) => (t['name'] as String)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return filtered;
  }

  String _monthAbbr(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String _formatDateRange(String start, String? end) {
    final s = DateTime.parse(start);
    final e = end != null ? DateTime.parse(end) : null;
    if (e != null) {
      return '${_monthAbbr(s.month)} ${s.day} - ${_monthAbbr(e.month)} ${e.day}';
    }
    return '${_monthAbbr(s.month)} ${s.day}';
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return AppColors.primary;
      case 'ONGOING':
        return AppColors.accentAmber;
      case 'COMPLETED':
        return AppColors.secondaryText;
      default:
        return AppColors.primary;
    }
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return 'Open';
      case 'ONGOING':
        return 'Ongoing';
      case 'COMPLETED':
        return 'Completed';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        foregroundColor: AppColors.onBackground,
        elevation: 0.5,
        title: Container(
          margin: const EdgeInsets.only(top: 8),
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
            style: const TextStyle(fontSize: 16, color: AppColors.onBackground),
            decoration: InputDecoration(
              hintText: 'Search tournaments...',
              hintStyle: TextStyle(color: AppColors.secondaryText, fontSize: 15),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.secondaryText, size: 20),
                      onPressed: () {
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.grey.shade100,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.secondaryText,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Open'),
                Tab(text: 'Ongoing'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList('All'),
                _buildList('OPEN'),
                _buildList('ONGOING'),
                _buildList('COMPLETED'),
              ],
            ),
    );
  }

  Widget _buildList(String status) {
    final list = _filterByStatus(status);
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.secondaryText),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No tournaments match your search'
                  : 'No tournaments found.',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final t = list[index];
        return _buildCard(t);
      },
    );
  }

  Widget _buildCard(Map<String, dynamic> tournament) {
    final start = tournament['startDate'] as String;
    final end = tournament['endDate'] as String?;
    final dateStr = _formatDateRange(start, end);
    final status = (tournament['status'] as String).toUpperCase();
    final statusColor = _statusColor(status);
    final statusLabel = _statusLabel(status);
    final currentTeams = tournament['currentTeams'] ?? 0;
    final maxTeams = tournament['maxTeams'] ?? 0;
    final isFull = currentTeams >= maxTeams;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accentPurple, const Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPurple.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.emoji_events,
              size: 100,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.6)),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tournament['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded, size: 14, color: Colors.amber),
                    const SizedBox(width: 6),
                    Text(
                      'Prize: ${tournament['prize']}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Capacity indicator
                Row(
                  children: [
                    const Icon(Icons.people, size: 14, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      'Teams: $currentTeams/$maxTeams',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Show FULL badge or Register button
                    if (isFull)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'FULL',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () async {
                          // Get auth state
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          
                          // Check if logged in
                          if (!authProvider.isAuthenticated) {
                            final loggedIn = await Navigator.pushNamed(context, '/login');
                            if (loggedIn == true) {
                              _fetchTournaments();
                            }
                            return;
                          }
                          
                          // Show loading indicator
                          setState(() => _isLoading = true);
                          
                          try {
                            // First, check if tournament has capacity (double-check)
                            final tournamentData = await ApiService.get('tournaments/${tournament['id']}');
                            final tData = tournamentData['tournament'];
                            final currentTeamsCount = tData['teams']?.length ?? 0;
                            final maxTeamsCount = tData['maxTeams'] ?? 0;
                            
                            setState(() => _isLoading = false);
                            
                            if (currentTeamsCount >= maxTeamsCount) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🏆 Tournament is full! No more teams can register.'),
                                  backgroundColor: Colors.orange,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                              return;
                            }
                            
                            // Check if player already has a team
                            final response = await ApiService.get(
                                'tournaments/${tournament['id']}/my-team');

                            if (response['status'] == 'success' && response['hasTeam'] == true) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MyTeamScreen(
                                    tournamentId: tournament['id'],
                                    tournamentName: tournament['name'],
                                  ),
                                ),
                              );
                            } else {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegisterTeamScreen(
                                    tournamentId: tournament['id'],
                                    tournamentName: tournament['name'],
                                  ),
                                ),
                              );
                              if (result == true) {
                                _fetchTournaments();
                              }
                            }
                          } catch (e) {
                            setState(() => _isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.accentPurple,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        child: const Text('Register', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    
                    if (tournament['status'] == 'ONGOING' || tournament['status'] == 'COMPLETED')
                      const SizedBox(width: 8),
                    
                    if (tournament['status'] == 'ONGOING' || tournament['status'] == 'COMPLETED')
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlayerTournamentDetailsScreen(
                                tournamentId: tournament['id'],
                                tournamentName: tournament['name'],
                                tournamentType: tournament['type'] ?? 'KNOCKOUT',
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        child: const Text('View Details'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}