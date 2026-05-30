import 'package:flutter/material.dart';
import '../../../../models/match.dart';
import '../../../../providers/tournament_provider.dart';

class UpdateScoreDialog {
  static Future<void> show({
    required BuildContext context,
    required Match match,
    required TournamentProvider provider,
    required int tournamentId,
    required VoidCallback onRefresh,
  }) async {
    int team1Score = match.team1Score ?? 0;
    int team2Score = match.team2Score ?? 0;
    int team1Penalty = match.team1Penalty ?? 0;
    int team2Penalty = match.team2Penalty ?? 0;

    // Check if match is knockout (not GROUP_STAGE)
    bool isKnockout = match.round != 'GROUP_STAGE' && match.round != null;

    return showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // Check if current scores create a draw
          final bool isDraw = (team1Score == team2Score && team1Score > 0);

          return AlertDialog(
            title: const Text('Update Score'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${match.team1Name} vs ${match.team2Name}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Regular Score Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Team 1 Score
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              match.team1Name,
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: team1Score > 0
                                      ? () => setDialogState(() => team1Score--)
                                      : null,
                                  color: Colors.green,
                                ),
                                SizedBox(
                                  width: 50,
                                  child: Text(
                                    '$team1Score',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => setDialogState(() => team1Score++),
                                  color: Colors.green,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'vs',
                          style: TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                      ),

                      // Team 2 Score
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              match.team2Name,
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: team2Score > 0
                                      ? () => setDialogState(() => team2Score--)
                                      : null,
                                  color: Colors.green,
                                ),
                                SizedBox(
                                  width: 50,
                                  child: Text(
                                    '$team2Score',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => setDialogState(() => team2Score++),
                                  color: Colors.green,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Penalty Shootout Section (only for knockout matches that are drawn)
                  if (isKnockout && isDraw) ...[
                    const Divider(height: 32),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.sports_soccer,
                                color: Colors.orange.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Penalty Shootout (Match Tied)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Team 1 Penalties
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      match.team1Name,
                                      style: const TextStyle(fontSize: 12),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            size: 20,
                                          ),
                                          onPressed: team1Penalty > 0
                                              ? () => setDialogState(() => team1Penalty--)
                                              : null,
                                          color: Colors.orange,
                                        ),
                                        SizedBox(
                                          width: 50,
                                          child: Text(
                                            '$team1Penalty',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                            size: 20,
                                          ),
                                          onPressed: () =>
                                              setDialogState(() => team1Penalty++),
                                          color: Colors.orange,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'PEN',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                              // Team 2 Penalties
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      match.team2Name,
                                      style: const TextStyle(fontSize: 12),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            size: 20,
                                          ),
                                          onPressed: team2Penalty > 0
                                              ? () => setDialogState(() => team2Penalty--)
                                              : null,
                                          color: Colors.orange,
                                        ),
                                        SizedBox(
                                          width: 50,
                                          child: Text(
                                            '$team2Penalty',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                            size: 20,
                                          ),
                                          onPressed: () =>
                                              setDialogState(() => team2Penalty++),
                                          color: Colors.orange,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Penalty scores will determine winner if match ends in draw',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);

                  // Determine if we need to send penalties
                  final bool sendPenalties = isKnockout && isDraw;

                  final result = await provider.updateMatchScore(
                    match.id,
                    team1Score,
                    team2Score,
                    team1Penalty: sendPenalties ? team1Penalty : null,
                    team2Penalty: sendPenalties ? team2Penalty : null,
                  );

                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(result['message']),
                        backgroundColor: result['status'] == 'success'
                            ? Colors.green
                            : Colors.red,
                      ),
                    );
                    if (result['status'] == 'success') {
                      onRefresh();
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Score'),
              ),
            ],
          );
        },
      ),
    );
  }
}