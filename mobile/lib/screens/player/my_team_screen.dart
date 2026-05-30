import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import 'register_team_screen.dart';

class MyTeamScreen extends StatefulWidget {
  final int tournamentId;
  final String tournamentName;

  const MyTeamScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<MyTeamScreen> createState() => _MyTeamScreenState();
}

class _MyTeamScreenState extends State<MyTeamScreen> {
  bool _isLoading = true;
  bool _hasTeam = false;
  Map<String, dynamic>? _team;
  List<dynamic> _players = [];

  @override
  void initState() {
    super.initState();
    _fetchMyTeam();
  }

  Future<void> _fetchMyTeam() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.get(
          'tournaments/${widget.tournamentId}/my-team');

      if (response['status'] == 'success') {
        setState(() {
          _hasTeam = response['hasTeam'] ?? false;
          _team = response['team'];
          _players = _team?['players'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error fetching my team: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Team - ${widget.tournamentName}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_hasTeam)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchMyTeam,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _hasTeam && _team != null
              ? _buildTeamDetails()
              : _buildNoTeamView(),
    );
  }

  Widget _buildTeamDetails() {
    // Find captain from players list
    final captain = _players.firstWhere(
      (p) => p['role'] == 'CAPTAIN',
      orElse: () => null,
    );

    final regularPlayers = _players.where((p) => p['role'] == 'PLAYER').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Team Name Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Team',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _team!['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Captain Section
          if (captain != null)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.star,
                            color: Colors.amber.shade700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Team Captain',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 20, color: Colors.grey),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                captain['playerName'] ?? 'N/A',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (captain['playerPhone'] != null)
                                Text(
                                  captain['playerPhone'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (captain['jerseyColor'] != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.style, size: 20, color: Colors.grey),
                          const SizedBox(width: 12),
                          Text('Jersey Color: ${captain['jerseyColor']}'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Players Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.people,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Players (${regularPlayers.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: regularPlayers.length,
                    itemBuilder: (context, index) {
                      final player = regularPlayers[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                player['playerName'] ?? 'Unknown',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Status Info Note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_team?['status'] == 'APPROVED') 
                  ? Colors.green.shade50 
                  : (_team?['status'] == 'REJECTED')
                      ? Colors.red.shade50
                      : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (_team?['status'] == 'APPROVED') 
                    ? Colors.green.shade200 
                    : (_team?['status'] == 'REJECTED')
                        ? Colors.red.shade200
                        : Colors.orange.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  (_team?['status'] == 'APPROVED') 
                      ? Icons.check_circle
                      : (_team?['status'] == 'REJECTED')
                          ? Icons.cancel
                          : Icons.pending,
                  color: (_team?['status'] == 'APPROVED') 
                      ? Colors.green.shade700
                      : (_team?['status'] == 'REJECTED')
                          ? Colors.red.shade700
                          : Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _team?['status'] == 'APPROVED'
                        ? '✅ Your team has been approved! You can now participate in the tournament.'
                        : (_team?['status'] == 'REJECTED')
                            ? '❌ Your team registration was rejected. Please contact the tournament organizer.'
                            : '⏳ Your team registration is pending approval from the tournament organizer.',
                    style: TextStyle(
                      fontSize: 12,
                      color: (_team?['status'] == 'APPROVED') 
                          ? Colors.green.shade700
                          : (_team?['status'] == 'REJECTED')
                              ? Colors.red.shade700
                              : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoTeamView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_soccer,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'You haven\'t registered a team yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Register your team for this tournament',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => RegisterTeamScreen(
                    tournamentId: widget.tournamentId,
                    tournamentName: widget.tournamentName,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Register Team'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}