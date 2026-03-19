import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/tournament_provider.dart';
import '../../../services/api_service.dart';

class RoundRobinLeaderboard extends StatefulWidget {
  final int tournamentId;

  const RoundRobinLeaderboard({super.key, required this.tournamentId});

  @override
  State<RoundRobinLeaderboard> createState() =>
      _RoundRobinLeaderboardState();
}

class _RoundRobinLeaderboardState extends State<RoundRobinLeaderboard> {
  List<Map<String, dynamic>> _standings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStandings();
  }

  Future<void> _loadStandings() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get(
          'tournaments/${widget.tournamentId}/standings');
      setState(() {
        _standings =
            List<Map<String, dynamic>>.from(response['standings'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Standings'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStandings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.green))
          : _standings.isEmpty
              ? const Center(child: Text('No standings yet'))
              : Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      color: Colors.green.shade700,
                      child: const Row(
                        children: [
                          SizedBox(
                              width: 32,
                              child: Text('#',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))),
                          Expanded(
                              child: Text('Team',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))),
                          SizedBox(
                              width: 32,
                              child: Text('P',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))),
                          SizedBox(
                              width: 32,
                              child: Text('W',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))),
                          SizedBox(
                              width: 32,
                              child: Text('D',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))),
                          SizedBox(
                              width: 32,
                              child: Text('L',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))),
                          SizedBox(
                              width: 40,
                              child: Text('GD',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))),
                          SizedBox(
                              width: 40,
                              child: Text('Pts',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),

                    // Standings list
                    Expanded(
                      child: ListView.builder(
                        itemCount: _standings.length,
                        itemBuilder: (_, index) {
                          final standing = _standings[index];
                          final isTop3 = index < 3;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isTop3
                                  ? Colors.green.shade50
                                  : index % 2 == 0
                                      ? Colors.white
                                      : Colors.grey.shade50,
                              border: Border(
                                bottom: BorderSide(
                                    color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 32,
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isTop3
                                          ? Colors.green
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      if (index == 0)
                                        const Text('🥇 '),
                                      if (index == 1)
                                        const Text('🥈 '),
                                      if (index == 2)
                                        const Text('🥉 '),
                                      Expanded(
                                        child: Text(
                                          standing['teamName'] ?? '',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _standingCell(
                                    '${standing['played'] ?? 0}'),
                                _standingCell(
                                    '${standing['wins'] ?? 0}',
                                    color: Colors.green),
                                _standingCell(
                                    '${standing['draws'] ?? 0}',
                                    color: Colors.orange),
                                _standingCell(
                                    '${standing['losses'] ?? 0}',
                                    color: Colors.red),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    '${standing['goalDifference'] ?? 0}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: (standing['goalDifference'] ??
                                                  0) >=
                                              0
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    '${standing['points'] ?? 0}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _standingCell(String value, {Color? color}) {
    return SizedBox(
      width: 32,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(color: color ?? Colors.grey.shade700),
      ),
    );
  }
}