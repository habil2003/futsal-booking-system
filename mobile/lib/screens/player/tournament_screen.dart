import 'package:flutter/material.dart';
import '../../services/api_service.dart';

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
      _allTournaments = (response as List).map((t) => {
        'id': t['id'],
        'name': t['name'],
        'startDate': t['startDate'],
        'endDate': t['endDate'],
        'status': t['status'] ?? 'OPEN',
        'prize': t['prizePool']?.toString() ?? 'TBA',
        'image': t['imageUrl'] ?? 'https://picsum.photos/id/1005/200/200',
      }).toList().cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error loading tournaments: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Filter by status AND search query
  List<Map<String, dynamic>> _filterByStatus(String status) {
    List<Map<String, dynamic>> filtered = _allTournaments;
    if (status != 'All') {
      filtered = filtered
          .where((t) => (t['status'] as String).toUpperCase() == status.toUpperCase())
          .toList();
    }
    // Apply search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((t) => (t['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()))
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        // ✅ Search bar replaces the title
        title: Container(
          margin: const EdgeInsets.only(top: 8),
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Search tournaments...',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
              prefixIcon: const Icon(Icons.search, color: Colors.green, size: 22),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Open'),
            Tab(text: 'Ongoing'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'No tournaments match your search' : 'No tournaments found.',
              style: TextStyle(color: Colors.grey.shade600),
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

  // Gradient card – same style as home screen tournaments
  Widget _buildCard(Map<String, dynamic> tournament) {
    final start = tournament['startDate'] as String;
    final end = tournament['endDate'] as String?;
    final dateStr = _formatDateRange(start, end);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade400, Colors.purple.shade900],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
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
                Text(
                  tournament['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.emoji_events, size: 14, color: Colors.amber),
                    const SizedBox(width: 6),
                    Text(
                      'Prize: ${tournament['prize']}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                    child: const Text('Register'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}