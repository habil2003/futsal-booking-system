import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class ManageTournamentsScreen extends StatefulWidget {
  const ManageTournamentsScreen({super.key});

  @override
  State<ManageTournamentsScreen> createState() =>
      _ManageTournamentsScreenState();
}

class _ManageTournamentsScreenState extends State<ManageTournamentsScreen> {
  bool _isLoadingTournaments = false;
  List<Map<String, dynamic>> _tournaments = [];

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  Future<void> _loadTournaments() async {
    setState(() => _isLoadingTournaments = true);
    try {
      final response = await ApiService.getList('tournaments');
      setState(() {
        _tournaments = response.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load tournaments: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoadingTournaments = false);
    }
  }

  Future<void> _refreshTournaments() async {
    await _loadTournaments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tournaments'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isLoadingTournaments
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoadingTournaments ? null : _refreshTournaments,
          ),
        ],
      ),
      body: _isLoadingTournaments
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _tournaments.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No tournaments found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshTournaments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tournaments.length,
                    itemBuilder: (context, index) {
                      final t = _tournaments[index];
                      return _buildTournamentCard(t);
                    },
                  ),
                ),
    );
  }

  Widget _buildTournamentCard(Map<String, dynamic> tournament) {
    final bool isPublished = tournament['isPublished'] ?? false;
    final String startDate = _formatShortDate(tournament['startDate']);
    final String? endDate = _formatShortDate(tournament['endDate']);
    final String type = tournament['type'] ?? 'LEAGUE';
    final String status = tournament['status'] ?? 'DRAFT';
    final int maxTeams = tournament['maxTeams'] ?? 0;
    final int? teamCount = tournament['_count']?['teams'];

    Color _getStatusColor(String status) {
      switch (status.toUpperCase()) {
        case 'ONGOING':
          return Colors.green;
        case 'COMPLETED':
          return Colors.blue;
        case 'CANCELLED':
          return Colors.red;
        default:
          return Colors.orange;
      }
    }

    String _getStatusLabel(String status) {
      switch (status.toUpperCase()) {
        case 'ONGOING':
          return 'Ongoing';
        case 'COMPLETED':
          return 'Completed';
        case 'CANCELLED':
          return 'Cancelled';
        default:
          return 'Draft';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row with Status and Publish Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPublished ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPublished ? Icons.visibility : Icons.visibility_off,
                        size: 12,
                        color: isPublished ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPublished ? 'Published' : 'Draft',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isPublished ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  type,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.purple.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tournament Name
            Text(
              tournament['name'] ?? 'Untitled',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),

            // Futsal Name (Owner)
            Row(
              children: [
                const Icon(Icons.sports_soccer, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    tournament['futsal']?['name'] ?? 'Unknown Futsal',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Description
            if (tournament['description'] != null &&
                tournament['description'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  tournament['description'],
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Info Row
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildInfoChip(
                  Icons.calendar_today,
                  '$startDate${endDate != null ? ' - $endDate' : ''}',
                ),
                _buildInfoChip(
                  Icons.people,
                  'Teams: ${teamCount ?? 0}/$maxTeams',
                ),
                if (tournament['entryFee'] != null && tournament['entryFee'] > 0)
                  _buildInfoChip(
                    Icons.currency_rupee,
                    'Entry: रू ${tournament['entryFee']}',
                  ),
                if (tournament['prizePool'] != null && tournament['prizePool'] > 0)
                  _buildInfoChip(
                    Icons.emoji_events,
                    'Prize: रू ${tournament['prizePool']}',
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Owner/Owner Info
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.business, size: 14, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Owner ID: ${tournament['futsal']?['ownerId'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 11, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  String _formatShortDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}