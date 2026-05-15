import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class CustomersScreen extends StatefulWidget {
  final int futsalId;
  final String futsalName;

  const CustomersScreen({
    super.key,
    required this.futsalId,
    required this.futsalName,
  });

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _frequentPlayers = [];
  Map<String, dynamic> _stats = {};
  
  bool _isLoading = true;
  String? _error;

  final TextEditingController _searchController = TextEditingController();
  String _activeFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchCustomers();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getFutsalCustomers(widget.futsalId);
      
      setState(() {
        _customers = List<Map<String, dynamic>>.from(response['customers'] ?? []);
        _frequentPlayers = List<Map<String, dynamic>>.from(response['frequentPlayers'] ?? []);
        _stats = response['stats'] ?? {};
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load customers: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredCustomers {
    return _customers.where((c) {
      if (_activeFilter == 'Blocked' && c['isBlocked'] != true) return false;
      if (_activeFilter == 'Active' && c['isBlocked'] == true) return false;
      final query = _searchController.text.toLowerCase();
      return query.isEmpty ||
          c['name'].toString().toLowerCase().contains(query) ||
          c['email'].toString().toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.futsalName} - Customers'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Customer List'),
            Tab(text: 'Frequent Players'),
            Tab(text: 'Statistics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCustomerList(),
                    _buildFrequentPlayers(),
                    _buildStatistics(),
                  ],
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 50, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchCustomers,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ----- Customer List Tab -----
  Widget _buildCustomerList() {
    final customers = filteredCustomers;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Active', 'Blocked']
                      .map((label) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(label),
                              selected: _activeFilter == label,
                              onSelected: (val) {
                                setState(() => _activeFilter = label);
                              },
                              selectedColor: Colors.green.shade100,
                              checkmarkColor: Colors.green,
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: customers.isEmpty
              ? const Center(child: Text('No customers found'))
              : ListView.builder(
                  itemCount: customers.length,
                  itemBuilder: (ctx, i) {
                    final c = customers[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: c['isBlocked'] == true 
                              ? Colors.red.shade100 
                              : Colors.green.shade100,
                          child: Text(
                            c['name']?.substring(0, 1).toUpperCase() ?? '?',
                            style: TextStyle(
                              color: c['isBlocked'] == true ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                c['name'] ?? 'Unknown',
                                style: TextStyle(
                                  decoration: c['isBlocked'] == true 
                                      ? TextDecoration.lineThrough 
                                      : null,
                                ),
                              ),
                            ),
                            if (c['isBlocked'] == true)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'BLOCKED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['email'] ?? 'No email'),
                            const SizedBox(height: 2),
                            Text(
                              'Bookings: ${c['totalBookings']} | Spent: ₹${c['totalSpent']}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ----- Frequent Players Tab -----
  Widget _buildFrequentPlayers() {
    if (_frequentPlayers.isEmpty) {
      return const Center(child: Text('No customer data yet'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _frequentPlayers.length,
      itemBuilder: (ctx, i) {
        final c = _frequentPlayers[i];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: i < 3 ? Colors.amber.shade100 : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: i < 3 ? Colors.amber.shade700 : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
            title: Text(
              c['name'] ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${c['totalBookings']} bookings | ₹${c['totalSpent']} spent'),
            trailing: i < 3 
                ? const Icon(Icons.emoji_events, color: Colors.amber)
                : null,
          ),
        );
      },
    );
  }

  // ----- Statistics Tab -----
  Widget _buildStatistics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Customers',
                  value: '${_stats['totalCustomers'] ?? 0}',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Active Customers',
                  value: '${_stats['activeCustomers'] ?? 0}',
                  icon: Icons.person,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Blocked Players',
                  value: '${_stats['blockedCount'] ?? 0}',
                  icon: Icons.block,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Total Revenue',
                  value: '₹${_stats['totalRevenue'] ?? 0}',
                  icon: Icons.currency_rupee,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Top Customers List
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🏆 Top Customers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...(_customers.take(5).map((c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.green.shade100,
                        child: Text(
                          '${c['name']?.substring(0, 1).toUpperCase() ?? '?'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c['name'] ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${c['totalBookings']} bookings',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${c['totalSpent']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}