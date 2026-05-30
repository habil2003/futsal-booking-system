import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';

class PlayerTournamentDetailsScreen extends StatefulWidget {
  final int tournamentId;
  final String tournamentName;
  final String tournamentType; // KNOCKOUT or ROUND_ROBIN

  const PlayerTournamentDetailsScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    required this.tournamentType,
  });

  @override
  State<PlayerTournamentDetailsScreen> createState() =>
      _PlayerTournamentDetailsScreenState();
}

class _PlayerTournamentDetailsScreenState
    extends State<PlayerTournamentDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> _matches = [];
  List<dynamic> _standings = [];
  List<dynamic> _teams = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTournamentData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTournamentData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch matches, standings, and teams in parallel
      final matchesResponse = await ApiService.getList(
          'tournaments/${widget.tournamentId}/matches');
      final standingsResponse =
          await ApiService.get('tournaments/${widget.tournamentId}/standings');
      final teamsResponse =
          await ApiService.getList('tournaments/${widget.tournamentId}/teams');

      setState(() {
        _matches = matchesResponse;
        _standings = standingsResponse['standings'] ?? [];
        _teams = teamsResponse;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tournamentName),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Matches', icon: Icon(Icons.sports_soccer)),
            Tab(text: 'Standings', icon: Icon(Icons.leaderboard)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTournamentData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMatchesTab(),
                    _buildStandingsTab(),
                  ],
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Failed to load tournament data',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchTournamentData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesTab() {
    if (_matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No matches scheduled yet',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Fixtures will appear once the tournament starts',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    // Group matches by round
    final Map<String, List<dynamic>> groupedMatches = {};
    for (final match in _matches) {
      String round = match['round'] ?? 'GROUP_STAGE';
      groupedMatches.putIfAbsent(round, () => []).add(match);
    }

    // Define round order for display
    final List<String> roundOrder = [];
    if (groupedMatches.containsKey('ROUND_OF_32'))
      roundOrder.add('ROUND_OF_32');
    if (groupedMatches.containsKey('ROUND_OF_16'))
      roundOrder.add('ROUND_OF_16');
    if (groupedMatches.containsKey('QUARTER_FINAL'))
      roundOrder.add('QUARTER_FINAL');
    if (groupedMatches.containsKey('SEMI_FINAL')) roundOrder.add('SEMI_FINAL');
    if (groupedMatches.containsKey('FINAL')) roundOrder.add('FINAL');
    if (groupedMatches.containsKey('GROUP_STAGE'))
      roundOrder.add('GROUP_STAGE');

    // Add any remaining rounds not in order
    for (final round in groupedMatches.keys) {
      if (!roundOrder.contains(round)) {
        roundOrder.add(round);
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: roundOrder.expand((round) {
        final matches = groupedMatches[round]!;
        return [
          _buildRoundHeader(round, matches.length),
          const SizedBox(height: 8),
          ...matches.map((match) => _buildMatchCard(match)),
          const SizedBox(height: 16),
        ];
      }).toList(),
    );
  }

  Widget _buildRoundHeader(String round, int matchCount) {
    String displayName = round;
    switch (round) {
      case 'ROUND_OF_32':
        displayName = 'Round of 32';
        break;
      case 'ROUND_OF_16':
        displayName = 'Round of 16';
        break;
      case 'QUARTER_FINAL':
        displayName = 'Quarter Finals';
        break;
      case 'SEMI_FINAL':
        displayName = 'Semi Finals';
        break;
      case 'FINAL':
        displayName = 'Final';
        break;
      case 'GROUP_STAGE':
        displayName = 'Group Stage';
        break;
    }

    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          displayName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$matchCount matches',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchCard(dynamic match) {
    final isCompleted = match['status'] == 'COMPLETED';
    final homeTeam = match['homeTeam']?['name'] ?? 'TBD';
    final awayTeam = match['awayTeam']?['name'] ?? 'TBD';
    final homeScore = match['homeScore'];
    final awayScore = match['awayScore'];
    final matchDate =
        match['matchDate'] != null ? DateTime.parse(match['matchDate']) : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Date
            if (matchDate != null)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _formatDate(matchDate),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            const SizedBox(height: 8),

            // Match
            Row(
              children: [
                Expanded(
                  child: Text(
                    homeTeam,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  width: 60,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        isCompleted ? AppColors.primary : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: isCompleted
                        ? Text(
                            '$homeScore - $awayScore',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'vs',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                Expanded(
                  child: Text(
                    awayTeam,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),

            if (!isCompleted && matchDate != null) ...[
              const SizedBox(height: 8),
              Text(
                _formatTime(matchDate),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStandingsTab() {
    if (widget.tournamentType == 'KNOCKOUT') {
      return _buildBracketView();
    }

    // Round Robin - Show standings table
    if (_standings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No standings available yet',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Standings will appear once matches start',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 16,
            headingRowColor: WidgetStateProperty.all(AppColors.primary),
            headingTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            columns: const [
              DataColumn(label: Text('#')),
              DataColumn(label: Text('Team')),
              DataColumn(label: Text('P')),
              DataColumn(label: Text('W')),
              DataColumn(label: Text('D')),
              DataColumn(label: Text('L')),
              DataColumn(label: Text('GF')),
              DataColumn(label: Text('GA')),
              DataColumn(label: Text('GD')),
              DataColumn(label: Text('PTS')),
            ],
            rows: _standings.asMap().entries.map((entry) {
              final index = entry.key;
              final team = entry.value;
              return DataRow(
                cells: [
                  DataCell(Text('${index + 1}')),
                  DataCell(Text(team['teamName'] ?? 'Unknown')),
                  DataCell(Text('${team['played'] ?? 0}')),
                  DataCell(Text('${team['wins'] ?? 0}')),
                  DataCell(Text('${team['draws'] ?? 0}')),
                  DataCell(Text('${team['losses'] ?? 0}')),
                  DataCell(Text('${team['goalsFor'] ?? 0}')),
                  DataCell(Text('${team['goalsAgainst'] ?? 0}')),
                  DataCell(Text('${team['goalDifference'] ?? 0}')),
                  DataCell(
                    Text(
                      '${team['points'] ?? 0}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildBracketView() {
    if (_matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_tree, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No bracket available yet',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Bracket will appear once the tournament starts',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    // Simple bracket view for players
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Quarter Finals
        if (_matches.any((m) => m['round'] == 'QUARTER_FINAL'))
          _buildBracketRound('Quarter Finals',
              _matches.where((m) => m['round'] == 'QUARTER_FINAL').toList()),

        // Semi Finals
        if (_matches.any((m) => m['round'] == 'SEMI_FINAL'))
          _buildBracketRound('Semi Finals',
              _matches.where((m) => m['round'] == 'SEMI_FINAL').toList()),

        // Final
        if (_matches.any((m) => m['round'] == 'FINAL'))
          _buildBracketRound(
              'Final', _matches.where((m) => m['round'] == 'FINAL').toList()),
      ],
    );
  }

  Widget _buildBracketRound(String title, List<dynamic> matches) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        ...matches.map((match) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMatchCard(match),
            )),
        const SizedBox(height: 16),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
