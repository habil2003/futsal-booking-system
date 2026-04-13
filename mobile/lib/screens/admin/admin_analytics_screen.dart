import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../services/api_service.dart';
import '../../models/futsal.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  Futsal? _selectedFutsal;
  List<Futsal> _allFutsals = [];
  bool _loadingFutsals = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFutsalsForFilter();
      _loadAnalytics();
    });
  }

  Future<void> _loadFutsalsForFilter() async {
    setState(() => _loadingFutsals = true);
    try {
      final response = await ApiService.get('admin/futsals');
      if (response['data'] != null) {
        setState(() {
          _allFutsals = (response['data'] as List)
              .map((json) => Futsal.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading futsals: $e');
    } finally {
      setState(() => _loadingFutsals = false);
    }
  }

  Future<void> _loadAnalytics() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    await adminProvider.loadAdminAnalytics(futsalId: _selectedFutsal?.id);
  }

  List<String> get _dayLabels {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime.now().weekday;
    return List.generate(7, (i) {
      final dayIndex = (today - 6 + i) % 7;
      return days[dayIndex];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Analytics'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          // ✅ Futsal Filter Dropdown
          if (_allFutsals.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<Futsal>(
                value: _selectedFutsal,
                hint: const Text('All', style: TextStyle(color: Colors.white)),
                dropdownColor: Colors.white,
                underline: const SizedBox(),
                icon: const Icon(Icons.filter_list, color: Colors.white),
                style: const TextStyle(color: Colors.black),
                items: [
                  const DropdownMenuItem<Futsal>(
                    value: null,
                    child: Text('All Futsals'),
                  ),
                  ..._allFutsals.map((futsal) {
                    return DropdownMenuItem<Futsal>(
                      value: futsal,
                      child: Text(
                        futsal.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ],
                onChanged: (futsal) {
                  setState(() {
                    _selectedFutsal = futsal;
                  });
                  _loadAnalytics();
                },
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadAnalytics(),
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, _) {
          if (adminProvider.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.green));
          }

          final analytics = adminProvider.adminAnalytics;

          if (analytics.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No analytics data available',
                      style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadAnalytics(),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final weeklyRevenue = List<double>.from(
            (analytics['weeklyRevenue'] as List? ?? [])
                .map((v) => (v as num).toDouble()),
          );

          final bookingsByStatus = analytics['bookingsByStatus'] as List? ?? [];
          final totalBookings = analytics['totalBookings'] ?? 0;
          final totalRevenue =
              (analytics['totalRevenue'] as num?)?.toDouble() ?? 0;
          final activeUsers = analytics['activeUsers'] ?? 0;
          
          // Get selected futsal name for display
          final filterText = _selectedFutsal != null 
              ? ' (${_selectedFutsal!.name})' 
              : '';

          return RefreshIndicator(
            onRefresh: () => _loadAnalytics(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Filter indicator
                if (_selectedFutsal != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.filter_alt, size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Showing data for: ${_selectedFutsal!.name}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            setState(() => _selectedFutsal = null);
                            _loadAnalytics();
                          },
                          child: Icon(Icons.close, size: 16, color: Colors.green.shade700),
                        ),
                      ],
                    ),
                  ),

                // Summary cards
                _buildSummaryCards(totalBookings, totalRevenue, activeUsers, filterText),

                const SizedBox(height: 24),

                // Weekly revenue chart
                _buildWeeklyRevenueChart(weeklyRevenue, filterText),

                const SizedBox(height: 24),

                // Bookings by status
                _buildBookingsByStatus(bookingsByStatus, totalBookings),

                const SizedBox(height: 24),

                // Daily breakdown
                _buildDailyBreakdown(weeklyRevenue),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================
  // SUMMARY CARDS (Updated with filter context)
  // ============================================
  Widget _buildSummaryCards(
      int totalBookings, double totalRevenue, int activeUsers, String filterText) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 24) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildSummaryCard(
              width: cardWidth,
              label: 'Total Bookings$filterText',
              value: totalBookings.toString(),
              icon: Icons.book_online,
              color: Colors.green,
            ),
            _buildSummaryCard(
              width: cardWidth,
              label: 'Total Revenue$filterText',
              value: 'रू ${totalRevenue.toStringAsFixed(0)}',
              icon: Icons.currency_rupee,
              color: Colors.blue,
            ),
            _buildSummaryCard(
              width: cardWidth,
              label: 'Active Users',
              value: activeUsers.toString(),
              icon: Icons.people,
              color: Colors.orange,
            ),
            _buildSummaryCard(
              width: cardWidth,
              label: 'Avg per Booking$filterText',
              value: totalBookings > 0
                  ? 'रू ${(totalRevenue / totalBookings).toStringAsFixed(0)}'
                  : 'रू 0',
              icon: Icons.trending_up,
              color: Colors.purple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required double width,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
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
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // WEEKLY REVENUE CHART
  // ============================================
  Widget _buildWeeklyRevenueChart(List<double> revenue, String filterText) {
    if (revenue.isEmpty || revenue.every((v) => v == 0)) {
      return _buildEmptyChart('Weekly Revenue', 'No revenue data available');
    }

    final maxRevenue = revenue.reduce((a, b) => a > b ? a : b);
    final labels = _dayLabels;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekly Revenue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            _selectedFutsal != null 
                ? 'Last 7 days for ${_selectedFutsal!.name}'
                : 'Platform-wide last 7 days',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxRevenue * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        'रू ${rod.toY.toStringAsFixed(0)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(labels[index],
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (value, meta) => Text(
                        'रू${value.toInt()}',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade500),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(revenue.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: revenue[index],
                        color: index == revenue.length - 1
                            ? Colors.green
                            : Colors.green.shade200,
                        width: 24,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // BOOKINGS BY STATUS PIE CHART
  // ============================================
  Widget _buildBookingsByStatus(
      List<dynamic> bookingsByStatus, int totalBookings) {
    if (bookingsByStatus.isEmpty) {
      return _buildEmptyChart(
          'Bookings by Status', 'No booking data available');
    }

    final statusColors = {
      'CONFIRMED': Colors.green,
      'COMPLETED': Colors.blue,
      'CANCELLED': Colors.red,
      'PENDING': Colors.orange,
    };

    final sections = bookingsByStatus.map((item) {
      final status = item['status'] as String;
      final count = (item['_count']['status'] as int).toDouble();
      final color = statusColors[status] ?? Colors.grey;
      final percent = totalBookings > 0 ? count / totalBookings * 100 : 0.0;

      return PieChartSectionData(
        value: count,
        color: color,
        title: percent >= 10 ? '${count.toInt()}' : '',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.6,
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bookings by Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Total: $totalBookings bookings',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 20),
          Row(
            children: [
              // Pie chart
              SizedBox(
                height: 140,
                width: 140,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 25,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: bookingsByStatus.map((item) {
                    final status = item['status'] as String;
                    final count = item['_count']['status'] as int;
                    final color = statusColors[status] ?? Colors.grey;
                    final percent = totalBookings > 0
                        ? (count / totalBookings * 100).toStringAsFixed(1)
                        : '0';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              status,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            '$percent%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================
  // DAILY BREAKDOWN
  // ============================================
  Widget _buildDailyBreakdown(List<double> revenue) {
    if (revenue.isEmpty) return const SizedBox.shrink();

    final labels = _dayLabels;
    final maxVal =
        revenue.isEmpty ? 1.0 : revenue.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Revenue Breakdown',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...List.generate(revenue.length, (index) {
            final isToday = index == revenue.length - 1;
            final percent = maxVal > 0 ? revenue[index] / maxVal : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? Colors.green : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isToday ? Colors.green : Colors.green.shade300,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: Text(
                      'रू ${revenue[index].toStringAsFixed(0)}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? Colors.green : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ============================================
  // EMPTY STATE
  // ============================================
  Widget _buildEmptyChart(String title, String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Icon(Icons.bar_chart, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Text(message, style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}