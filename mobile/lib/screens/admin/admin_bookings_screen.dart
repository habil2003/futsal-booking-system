import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/booking.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  String _selectedStatus = 'ALL';
  DateTime? _fromDate;
  DateTime? _toDate;
  int _currentPage = 1;

  final List<String> _statuses = [
    'ALL',
    'PENDING',
    'CONFIRMED',
    'COMPLETED',
    'CANCELLED',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookings();
    });
  }

  Future<void> _loadBookings({int page = 1}) async {
    setState(() => _currentPage = page);
    await Provider.of<AdminProvider>(context, listen: false).loadAllBookings(
      status: _selectedStatus,
      from: _fromDate?.toIso8601String(),
      to: _toDate?.toIso8601String(),
      page: page,
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.green),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _loadBookings();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = 'ALL';
      _fromDate = null;
      _toDate = null;
    });
    _loadBookings();
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Colors.green;
      case 'CONFIRMED':
        return Colors.teal;
      case 'CANCELLED':
        return Colors.red;
      case 'PENDING':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return 'Completed';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'CANCELLED':
        return 'Cancelled';
      case 'PENDING':
        return 'Pending';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Bookings'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadBookings(page: _currentPage),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Status filter chips
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _statuses.length,
                    itemBuilder: (_, index) {
                      final status = _statuses[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(status),
                          selected: _selectedStatus == status,
                          onSelected: (_) {
                            setState(() => _selectedStatus = status);
                            _loadBookings();
                          },
                          selectedColor: Colors.green.shade100,
                          checkmarkColor: Colors.green,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: _selectedStatus == status
                                ? Colors.green
                                : Colors.grey.shade700,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // Date range + clear
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.date_range,
                            size: 16, color: Colors.green),
                        label: Text(
                          _fromDate == null
                              ? 'Select Date Range'
                              : '${_fromDate!.day}/${_fromDate!.month} - ${_toDate!.day}/${_toDate!.month}',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.green),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.green.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: _selectDateRange,
                      ),
                    ),
                    if (_fromDate != null || _selectedStatus != 'ALL') ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        tooltip: 'Clear filters',
                        onPressed: _clearFilters,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Bookings list
          Expanded(
            child: Consumer<AdminProvider>(
              builder: (context, adminProvider, _) {
                if (adminProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  );
                }

                if (adminProvider.allBookings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.book_online,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No bookings found',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => _loadBookings(page: _currentPage),
                  child: Column(
                    children: [
                      // Count + total
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              '${adminProvider.totalBookingsCount} bookings',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13),
                            ),
                            const Spacer(),
                            Text(
                              'Page $_currentPage of ${adminProvider.totalPages}',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),

                      // List
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          itemCount: adminProvider.allBookings.length,
                          itemBuilder: (_, index) {
                            return _buildBookingCard(
                                adminProvider.allBookings[index]);
                          },
                        ),
                      ),

                      // Pagination
                      if (adminProvider.totalPages > 1)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: _currentPage > 1
                                    ? () =>
                                        _loadBookings(page: _currentPage - 1)
                                    : null,
                                color: _currentPage > 1
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              Text(
                                '$_currentPage / ${adminProvider.totalPages}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: _currentPage <
                                        adminProvider.totalPages
                                    ? () =>
                                        _loadBookings(page: _currentPage + 1)
                                    : null,
                                color: _currentPage < adminProvider.totalPages
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ],
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

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final bookingStatus = booking['bookingStatus'] ?? 'PENDING';
    final paymentStatus = booking['paymentStatus'] ?? 'PENDING';
    final paymentMethod = booking['paymentMethod'] ?? 'COD';
    final isPaid = paymentStatus.toUpperCase() == 'COMPLETED' || 
                   paymentStatus.toUpperCase() == 'PAID';
    final isCOD = paymentMethod == 'COD';
    final isKhalti = paymentMethod == 'KHALTI';

    final date = booking['date'] != null
        ? DateTime.parse(booking['date'])
        : DateTime.now();

    final bookingDate = booking['bookingDate'] != null
        ? DateTime.parse(booking['bookingDate'])
        : DateTime.now();

    // Determine status color and text
    final statusColor = _getStatusColor(bookingStatus);
    final statusText = _getStatusText(bookingStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(bookingStatus),
                  size: 14,
                  color: statusColor,
                ),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Payment method badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCOD ? Colors.orange.shade100 : Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isCOD ? 'COD' : 'KHALTI',
                    style: TextStyle(
                      fontSize: 8,
                      color: isCOD ? Colors.orange.shade700 : Colors.purple.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Unpaid badge (only for unpaid COD or failed Khalti)
                if (!isPaid && !_isTerminalStatus(bookingStatus))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'UNPAID',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Futsal name + court
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        booking['futsalName'] ?? 'Unknown Futsal',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Court ${booking['courtNumber']}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Player info
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      booking['playerName'] ?? 'Unknown',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.email_outlined,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        booking['playerEmail'] ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Date and time
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '${date.day}/${date.month}/${date.year}',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '${booking['startTime']} - ${booking['endTime']}',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                    if (booking['duration'] != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer,
                              size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            '${booking['duration']}h',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Price and booking date
                Row(
                  children: [
                    Icon(Icons.currency_rupee,
                        size: 14, color: Colors.green.shade600),
                    Text(
                      ' ${booking['totalPrice']}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isPaid ? Colors.green : Colors.orange,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Booked on ${bookingDate.day}/${bookingDate.month}/${bookingDate.year}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'CANCELLED':
        return Icons.cancel;
      case 'COMPLETED':
        return Icons.check_circle;
      case 'CONFIRMED':
        return Icons.login;
      case 'PENDING':
        return Icons.hourglass_empty;
      default:
        return Icons.check_circle_outline;
    }
  }

  bool _isTerminalStatus(String status) {
    final upper = status.toUpperCase();
    return upper == 'COMPLETED' || upper == 'CANCELLED';
  }
}