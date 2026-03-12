import 'package:flutter/material.dart';

class TournamentDetailsScreen extends StatelessWidget {
  final int tournamentId;
  
  const TournamentDetailsScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament Details'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text('Tournament Details Screen\nID: $tournamentId'),
      ),
    );
  }
}