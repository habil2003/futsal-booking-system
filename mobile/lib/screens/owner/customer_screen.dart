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
  final List<String> _tabs = [
    'Customer List',
    'Frequent Players',
    'Customer Profiles',
  ];

  List<Map<String, dynamic>> _allCustomers = [];
  bool _isLoading = true;
  String? _error;

  final TextEditingController _searchController = TextEditingController();
  String _activeFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
      // Fetch upcoming and last month bookings to gather customer data
      final now = DateTime.now();
      final upcoming =
          await ApiService.getOwnerUpcomingBookings(widget.futsalId);

      int year = now.month == 1 ? now.year - 1 : now.year;
      int month = now.month == 1 ? 12 : now.month - 1;
      final lastMonth =
          await ApiService.getOwnerMonthBookings(widget.futsalId, year, month);

      final allBookings = [...upcoming, ...lastMonth];

      // Aggregate unique customers from bookings
      final Map<String, Map<String, dynamic>> customerMap = {};
      for (var booking in allBookings) {
        final user = booking['user'];
        if (user == null) continue;

        final userId = user['id']?.toString() ?? '';
        if (!customerMap.containsKey(userId)) {
          customerMap[userId] = {
            'id': userId,
            'name': user['name'] ?? 'Unknown',
            'email': user['email'] ?? '',
            'phone': user['phone'] ?? '',
            'totalBookings': 0,
            'totalSpent': 0.0,
            'lastBooking': '',
            'status': 'Active', // you can enhance this from backend later
          };
        }

        final data = customerMap[userId]!;
        data['totalBookings'] = (data['totalBookings'] as int) + 1;
        data['totalSpent'] = (data['totalSpent'] as double) +
            (double.tryParse('${booking['totalAmount'] ?? 0}') ?? 0);

        final bookingDate = booking['date'] ?? '';
        if (bookingDate.toString().isNotEmpty &&
            bookingDate.toString().compareTo(data['lastBooking'].toString()) > 0) {
          data['lastBooking'] = bookingDate.toString();
        }
      }

      _allCustomers = customerMap.values.toList();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Failed to load customers: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredCustomers {
    return _allCustomers.where((c) {
      if (_activeFilter != 'All' && c['status'] != _activeFilter) return false;
      final query = _searchController.text.toLowerCase();
      return query.isEmpty ||
          '${c['name']}'.toLowerCase().contains(query) ||
          '${c['email']}'.toLowerCase().contains(query);
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
          isScrollable: true,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
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
                    _buildCustomerProfiles(),
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
                  children: ['All', 'Active', 'VIP', 'Banned']
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
                          child: Text(c['name']?[0] ?? '?')),
                        title: Text(c['name']),
                        subtitle: Text(
                          '${c['email']}\nBookings: ${c['totalBookings']} | Spent: Rs. ${c['totalSpent']}',
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
    final sorted = List<Map<String, dynamic>>.from(_allCustomers)
      ..sort((a, b) =>
          (b['totalBookings'] as int).compareTo(a['totalBookings'] as int));
    final top10 = sorted.take(10).toList();

    return top10.isEmpty
        ? const Center(child: Text('No data'))
        : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: top10.length,
            itemBuilder: (ctx, i) {
              final c = top10[i];
              return ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(c['name']),
                subtitle: Text(
                    '${c['totalBookings']} bookings | Rs. ${c['totalSpent']}'),
                trailing: const Icon(Icons.star, color: Colors.amber),
              );
            },
          );
  }

  // ----- Customer Profiles Tab -----
  Widget _buildCustomerProfiles() {
    final customers = filteredCustomers;
    return customers.isEmpty
        ? const Center(child: Text('No customers'))
        : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: customers.length,
            itemBuilder: (ctx, i) {
              final c = customers[i];
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            child: Text(c['name']?[0] ?? '?'),
                            radius: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c['name'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                Text(c['email'] ?? '',
                                    style: TextStyle(
                                        color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statColumn(
                              'Bookings', '${c['totalBookings']}'),
                          _statColumn(
                              'Spent', 'Rs. ${c['totalSpent']}'),
                          _statColumn(
                            'Last Booking',
                            c['lastBooking']
                                    ?.toString()
                                    .substring(0, 10) ??
                                'N/A',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(value,
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label,
            style:
                TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }
}