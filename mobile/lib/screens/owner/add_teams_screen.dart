import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import '../../models/tournament.dart';
import '../../models/team.dart';
import '../../services/api_service.dart';
import 'tournament/knockout_bracket.dart';
import 'tournament/round_robin_leaderboard.dart';

class AddTeamsScreen extends StatefulWidget {
  final int tournamentId;
  final int maxTeams;
  final TournamentType tournamentType;
  final TournamentStatus tournamentStatus;

  const AddTeamsScreen({
    super.key,
    required this.tournamentId,
    required this.maxTeams,
    required this.tournamentType,
    required this.tournamentStatus,
  });

  @override
  State<AddTeamsScreen> createState() => _AddTeamsScreenState();
}

class _AddTeamsScreenState extends State<AddTeamsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Team> _pendingTeams = [];
  List<Team> _approvedTeams = [];
  List<Team> _rejectedTeams = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllTeams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllTeams() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        ApiService.getList('tournaments/${widget.tournamentId}/teams/status/PENDING'),
        ApiService.getList('tournaments/${widget.tournamentId}/teams/status/APPROVED'),
        ApiService.getList('tournaments/${widget.tournamentId}/teams/status/REJECTED'),
      ]);

      setState(() {
        _pendingTeams = results[0].map((json) => Team.fromJson(json)).toList();
        _approvedTeams = results[1].map((json) => Team.fromJson(json)).toList();
        _rejectedTeams = results[2].map((json) => Team.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _approveTeam(Team team) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Team'),
        content: Text('Approve team "${team.name}" to join the tournament?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      // FIXED: Correct endpoint with 'tournaments/' prefix
      final response = await ApiService.patch('tournaments/teams/${team.id}/approve', {});

      if (!mounted) return;

      if (response['status'] == 'success') {
        setState(() {
          _pendingTeams.removeWhere((t) => t.id == team.id);
          final approvedTeam = Team(
            id: team.id,
            tournamentId: team.tournamentId,
            name: team.name,
            logo: team.logo,
            captainName: team.captainName,
            captainPhone: team.captainPhone,
            players: team.players,
            jerseyColor: team.jerseyColor,
            registeredAt: team.registeredAt,
            status: 'APPROVED',
            createdAt: team.createdAt,
          );
          _approvedTeams.add(approvedTeam);
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to approve team'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectTeam(Team team) async {
    String rejectReason = '';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Reject Team'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Reject team "${team.name}"?'),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  hintText: 'Why is this team being rejected?',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setDialogState(() => rejectReason = value),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    setState(() => _isLoading = true);

    try {
      // FIXED: Correct endpoint with 'reject' not 'approve'
      final response = await ApiService.patch('tournaments/teams/${team.id}/reject', {'reason': rejectReason});

      if (!mounted) return;

      if (response['status'] == 'success') {
        setState(() {
          _pendingTeams.removeWhere((t) => t.id == team.id);
          final rejectedTeam = Team(
            id: team.id,
            tournamentId: team.tournamentId,
            name: team.name,
            logo: team.logo,
            captainName: team.captainName,
            captainPhone: team.captainPhone,
            players: team.players,
            jerseyColor: team.jerseyColor,
            registeredAt: team.registeredAt,
            status: 'REJECTED',
            createdAt: team.createdAt,
          );
          _rejectedTeams.add(rejectedTeam);
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to reject team'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _generateFixtures() async {
    if (_approvedTeams.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Need at least 2 approved teams to generate fixtures'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generate Fixtures'),
        content: Text(
          'Generate ${widget.tournamentType == TournamentType.knockout ? 'knockout bracket' : 'round robin fixtures'} with ${_approvedTeams.length} approved teams?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;

    setState(() => _isLoading = true);

    final provider = Provider.of<TournamentProvider>(context, listen: false);
    final response = await provider.generateFixtures(widget.tournamentId);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (response['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fixtures generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      await provider.loadTournament(widget.tournamentId);

      if (!mounted) return;

      Navigator.pop(context);

      if (widget.tournamentType == TournamentType.knockout) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => KnockoutBracket(tournamentId: widget.tournamentId),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RoundRobinLeaderboard(tournamentId: widget.tournamentId),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool get _canGenerateFixtures {
    return _approvedTeams.length >= 2 &&
        widget.tournamentStatus != TournamentStatus.cancelled &&
        widget.tournamentStatus != TournamentStatus.completed;
  }

  @override
  Widget build(BuildContext context) {
    final canGenerate = _canGenerateFixtures;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Teams'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Pending (${_pendingTeams.length})'),
            Tab(text: 'Approved (${_approvedTeams.length})'),
            Tab(text: 'Rejected (${_rejectedTeams.length})'),
          ],
        ),
        actions: [
          if (canGenerate)
            TextButton.icon(
              onPressed: _generateFixtures,
              icon: const Icon(Icons.sports_soccer, color: Colors.white),
              label: const Text('Generate Fixtures', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.green.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Approved Teams: ${_approvedTeams.length} / ${widget.maxTeams}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: (_approvedTeams.length < widget.maxTeams) ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                      ),
                      if (_approvedTeams.length < widget.maxTeams)
                        Text(
                          '${widget.maxTeams - _approvedTeams.length} spots remaining',
                          style: TextStyle(fontSize: 12, color: Colors.green.shade600),
                        ),
                    ],
                  ),
                ),
                if (_pendingTeams.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_pendingTeams.length} pending approval',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                    ),
                  ),
              ],
            ),
          ),

          if (widget.tournamentStatus == TournamentStatus.cancelled)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This tournament has been cancelled. No changes can be made.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTeamsList(_pendingTeams, isPending: true),
                      _buildTeamsList(_approvedTeams, isPending: false),
                      _buildTeamsList(_rejectedTeams, isPending: false),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsList(List<Team> teams, {required bool isPending}) {
    if (teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending ? Icons.pending_actions : Icons.group,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isPending
                  ? 'No pending team registrations'
                  : 'No teams in this category',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            if (isPending) const SizedBox(height: 8),
            if (isPending)
              Text(
                'Teams will appear here when players register',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllTeams,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: teams.length,
        itemBuilder: (context, index) {
          final team = teams[index];
          return _buildTeamCard(team, isPending: isPending);
        },
      ),
    );
  }

  Widget _buildTeamCard(Team team, {required bool isPending}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isPending
                        ? Colors.orange.shade100
                        : (team.status == 'APPROVED' ? Colors.green.shade100 : Colors.red.shade100),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    isPending
                        ? Icons.pending
                        : (team.status == 'APPROVED' ? Icons.check_circle : Icons.cancel),
                    color: isPending
                        ? Colors.orange
                        : (team.status == 'APPROVED' ? Colors.green : Colors.red),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Captain: ${team.captainName ?? "Unknown"}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (team.captainPhone != null)
                        Text(
                          'Phone: ${team.captainPhone}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending
                        ? Colors.orange.shade100
                        : (team.status == 'APPROVED' ? Colors.green.shade100 : Colors.red.shade100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPending ? 'PENDING' : team.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isPending
                          ? Colors.orange.shade800
                          : (team.status == 'APPROVED' ? Colors.green.shade800 : Colors.red.shade800),
                    ),
                  ),
                ),
              ],
            ),

            if (team.players != null && team.players!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Players (${team.players!.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: team.players!.map((playerName) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      playerName,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  );
                }).toList(),
              ),
            ],

            if (isPending && widget.tournamentStatus == TournamentStatus.draft) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _rejectTeam(team),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _approveTeam(team),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}