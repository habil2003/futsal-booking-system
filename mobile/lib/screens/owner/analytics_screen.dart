import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/analytics_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  final int futsalId;
  final String futsalName;

  const AnalyticsScreen({
    super.key,
    required this.futsalId,
    required this.futsalName,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Date range filter
  DateTimeRange? _selectedDateRange;
  bool _useDateRangeFilter = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Changed to 4 tabs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AnalyticsProvider>(context, listen: false)
          .loadAllAnalytics(widget.futsalId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _useDateRangeFilter = true;
      });
      
      final provider = Provider.of<AnalyticsProvider>(context, listen: false);
      await provider.loadAnalyticsWithDateRange(
        widget.futsalId,
        _selectedDateRange!.start,
        _selectedDateRange!.end,
      );
    }
  }
  
  void _resetFilter() {
    setState(() {
      _selectedDateRange = null;
      _useDateRangeFilter = false;
    });
    
    final provider = Provider.of<AnalyticsProvider>(context, listen: false);
    provider.loadAllAnalytics(widget.futsalId);
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
        title: Text('${widget.futsalName} - Analytics'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Revenue', icon: Icon(Icons.payments)),
            Tab(text: 'Insights', icon: Icon(Icons.insights)),
            Tab(text: 'Payment', icon: Icon(Icons.payment)),
            Tab(text: 'Booking Status', icon: Icon(Icons.book_online)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _useDateRangeFilter ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _useDateRangeFilter ? Colors.amber : Colors.white,
            ),
            onPressed: _selectDateRange,
            tooltip: 'Filter by date range',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              if (_useDateRangeFilter) {
                _resetFilter();
              } else {
                Provider.of<AnalyticsProvider>(context, listen: false)
                    .loadAllAnalytics(widget.futsalId);
              }
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_useDateRangeFilter && _selectedDateRange != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.green.shade50,
              child: Row(
                children: [
                  const Icon(Icons.date_range, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _resetFilter,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.close, size: 14),
                          SizedBox(width: 4),
                          Text('Clear', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Consumer<AnalyticsProvider>(
              builder: (ctx, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: Colors.green));
                }

                if (provider.error != null) {
                  return _buildErrorView(provider);
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRevenueTab(provider),
                    _buildInsightsTab(provider),
                    _buildPaymentTab(provider),
                    _buildBookingStatusTab(provider),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // REVENUE TAB
  // ============================================
  Widget _buildRevenueTab(AnalyticsProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.loadAllAnalytics(widget.futsalId),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildRevenueSummaryCards(provider),
            const SizedBox(height: 24),
            _buildMonthlyRevenueChart(provider),
            const SizedBox(height: 24),
            _buildWeeklyRevenueChart(provider),
            const SizedBox(height: 24),
            _buildPeakHoursChart(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueSummaryCards(AnalyticsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Revenue Summary',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                label: 'Today',
                value: 'रू ${provider.todayRevenue.toStringAsFixed(0)}',
                icon: Icons.today,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                label: 'This Week',
                value: 'रू ${provider.thisWeekRevenue.toStringAsFixed(0)}',
                icon: Icons.weekend,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                label: 'This Month',
                value: 'रू ${provider.thisMonthRevenue.toStringAsFixed(0)}',
                icon: Icons.calendar_month,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                label: 'All Time',
                value: 'रू ${provider.allTimeRevenue.toStringAsFixed(0)}',
                icon: Icons.payments_outlined,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String label,
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
    );
  }

  Widget _buildMonthlyRevenueChart(AnalyticsProvider provider) {
    if (provider.monthlyRevenue.isEmpty) {
      return _buildEmptyCard('Monthly Revenue', 'No data available');
    }

    final maxRevenue = provider.monthlyRevenue
        .map((m) => m['revenue'] as double)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _buildCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Revenue',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Last 6 months',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
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
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= provider.monthlyRevenue.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            provider.monthlyRevenue[index]['month'],
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          'रू${value.toInt()}',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(provider.monthlyRevenue.length, (index) {
                  final isHighest = provider.monthlyRevenue[index]['revenue'] == maxRevenue;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: provider.monthlyRevenue[index]['revenue'],
                        color: isHighest ? Colors.green : Colors.green.shade200,
                        width: 30,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
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

  Widget _buildWeeklyRevenueChart(AnalyticsProvider provider) {
    if (provider.weeklyRevenue.isEmpty || provider.weeklyRevenue.every((v) => v == 0)) {
      return _buildEmptyCard('Weekly Revenue', 'No revenue data this week');
    }

    final maxRevenue = provider.weeklyRevenue.reduce((a, b) => a > b ? a : b);
    final labels = _dayLabels;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _buildCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Revenue',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Last 7 days',
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
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(labels[index], style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (value, meta) => Text('रू${value.toInt()}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(provider.weeklyRevenue.length, (index) {
                  final isToday = index == provider.weeklyRevenue.length - 1;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: provider.weeklyRevenue[index],
                        color: isToday ? Colors.green : Colors.green.shade200,
                        width: 24,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
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

  Widget _buildPeakHoursChart(AnalyticsProvider provider) {
    if (provider.peakHours.isEmpty) {
      return _buildEmptyCard('Peak Hours', 'No booking data available');
    }

    final sortedEntries = provider.peakHours.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final maxCount = provider.peakHours.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _buildCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Peak Hours',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Bookings by time of day',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxCount * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()} bookings',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= sortedEntries.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            sortedEntries[index].key.replaceAll(':00', ''),
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(sortedEntries.length, (index) {
                  final isPeak = sortedEntries[index].value == maxCount;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: sortedEntries[index].value.toDouble(),
                        color: isPeak ? Colors.orange : Colors.orange.shade200,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
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
  // INSIGHTS TAB
  // ============================================
  Widget _buildInsightsTab(AnalyticsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMetricCard(
            title: 'Completion Rate',
            value: '${provider.completionRate.toStringAsFixed(1)}%',
            subtitle: 'Bookings that were completed',
            icon: Icons.check_circle,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          _buildMetricCard(
            title: 'Cancellation Rate',
            value: '${provider.cancellationRate.toStringAsFixed(1)}%',
            subtitle: 'Bookings that were cancelled',
            icon: Icons.cancel,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          _buildMetricCard(
            title: 'Average Booking Value',
            value: 'रू ${provider.averageBookingValue.toStringAsFixed(0)}',
            subtitle: 'Average spend per booking',
            icon: Icons.trending_up,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildStatsGrid(provider),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _buildCardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
                ),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(AnalyticsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _buildCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Statistics',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  label: 'Total',
                  value: provider.totalBookings.toString(),
                  color: Colors.grey,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  label: 'Completed',
                  value: provider.completedBookings.toString(),
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  label: 'Confirmed',
                  value: provider.confirmedBookings.toString(),
                  color: Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  label: 'Pending',
                  value: provider.pendingBookings.toString(),
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatItem(
            label: 'Cancelled',
            value: provider.cancelledBookings.toString(),
            color: Colors.red,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  // ============================================
  // PAYMENT TAB
  // ============================================
  Widget _buildPaymentTab(AnalyticsProvider provider) {
    final codRevenue = provider.paymentBreakdown['COD']['revenue'];
    final khaltiRevenue = provider.paymentBreakdown['KHALTI']['revenue'];
    final codCount = provider.paymentBreakdown['COD']['count'];
    final khaltiCount = provider.paymentBreakdown['KHALTI']['count'];
    final codPercentage = provider.paymentBreakdown['COD']['percentage'];
    final khaltiPercentage = provider.paymentBreakdown['KHALTI']['percentage'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _buildCardDecoration(),
            child: Column(
              children: [
                const Text(
                  'Payment Method Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: codRevenue,
                          title: '${codPercentage.toStringAsFixed(1)}%',
                          color: Colors.blue,
                          radius: 80,
                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        PieChartSectionData(
                          value: khaltiRevenue,
                          title: '${khaltiPercentage.toStringAsFixed(1)}%',
                          color: Colors.purple,
                          radius: 80,
                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildPaymentMethodCard(
                        name: 'COD',
                        revenue: codRevenue,
                        count: codCount,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPaymentMethodCard(
                        name: 'KHALTI',
                        revenue: khaltiRevenue,
                        count: khaltiCount,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _buildCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Revenue by Payment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: provider.totalPaymentRevenue > 0 ? codRevenue / provider.totalPaymentRevenue : 0,
                  backgroundColor: Colors.blue.shade100,
                  color: Colors.blue,
                  minHeight: 12,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('COD', style: TextStyle(color: Colors.blue.shade700)),
                    Text('रू ${codRevenue.toStringAsFixed(0)}', style: TextStyle(color: Colors.blue.shade700)),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: provider.totalPaymentRevenue > 0 ? khaltiRevenue / provider.totalPaymentRevenue : 0,
                  backgroundColor: Colors.purple.shade100,
                  color: Colors.purple,
                  minHeight: 12,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('KHALTI', style: TextStyle(color: Colors.purple.shade700)),
                    Text('रू ${khaltiRevenue.toStringAsFixed(0)}', style: TextStyle(color: Colors.purple.shade700)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required String name,
    required double revenue,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          Text('रू ${revenue.toStringAsFixed(0)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text('$count bookings', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  // ============================================
  // BOOKING STATUS TAB (NEW)
  // ============================================
  Widget _buildBookingStatusTab(AnalyticsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildBookingStatusSummary(provider),
          const SizedBox(height: 16),
          _buildPaymentStatusBreakdown(provider),
          const SizedBox(height: 16),
          _buildBookingStatusBreakdown(provider),
          const SizedBox(height: 16),
          _buildRefundAlertCard(provider),
        ],
      ),
    );
  }

  Widget _buildBookingStatusSummary(AnalyticsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _buildCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Booking Status Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatusCard(
                  label: 'Total Bookings',
                  value: provider.totalBookings.toString(),
                  color: Colors.grey,
                  icon: Icons.book_online,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusCard(
                  label: 'Completed',
                  value: provider.completedBookings.toString(),
                  color: Colors.green,
                  icon: Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusCard(
                  label: 'Cancelled',
                  value: provider.cancelledBookings.toString(),
                  color: Colors.red,
                  icon: Icons.cancel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatusCard(
                  label: 'Confirmed',
                  value: provider.confirmedBookings.toString(),
                  color: Colors.blue,
                  icon: Icons.confirmation_number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusCard(
                  label: 'Pending',
                  value: provider.pendingBookings.toString(),
                  color: Colors.orange,
                  icon: Icons.pending_actions,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusCard(
                  label: 'Paid',
                  value: provider.paidBookings.toString(),
                  color: Colors.teal,
                  icon: Icons.payment,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatusBreakdown(AnalyticsProvider provider) {
    final paid = provider.paidBookings;
    final unpaid = provider.unpaidBookings;
    final total = provider.totalBookings;
    final paidPercentage = total > 0 ? (paid / total) * 100 : 0;
    final unpaidPercentage = total > 0 ? (unpaid / total) * 100 : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _buildCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💰 Payment Status Distribution',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildProgressBar(
            label: 'Paid',
            value: paid,
            total: total,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildProgressBar(
            label: 'Unpaid',
            value: unpaid,
            total: total,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${paidPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const Text('Collection Rate', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${unpaidPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      const Text('Outstanding', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingStatusBreakdown(AnalyticsProvider provider) {
    final completed = provider.completedBookings;
    final confirmed = provider.confirmedBookings;
    final pending = provider.pendingBookings;
    final cancelled = provider.cancelledBookings;
    final total = provider.totalBookings;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _buildCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 Booking Status Distribution',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildProgressBar(
            label: 'Completed',
            value: completed,
            total: total,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildProgressBar(
            label: 'Confirmed',
            value: confirmed,
            total: total,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildProgressBar(
            label: 'Pending',
            value: pending,
            total: total,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildProgressBar(
            label: 'Cancelled',
            value: cancelled,
            total: total,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildRefundAlertCard(AnalyticsProvider provider) {
    final paidButCancelled = provider.paidButCancelledBookings;
    
    if (paidButCancelled == 0) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠️ Refunds Required',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 4),
                Text(
                  '$paidButCancelled booking(s) were cancelled but payment was received. Please process refunds immediately.',
                  style: TextStyle(fontSize: 13, color: Colors.red.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar({
    required String label,
    required int value,
    required int total,
    required Color color,
  }) {
    final percentage = total > 0 ? (value / total) * 100 : 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Text(
              '$value (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: total > 0 ? value / total : 0,
          backgroundColor: Colors.grey.shade200,
          color: color,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  // ============================================
  // HELPER METHODS
  // ============================================
  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildEmptyCard(String title, String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _buildCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildErrorView(AnalyticsProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(provider.error ?? 'Something went wrong', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.loadAllAnalytics(widget.futsalId),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}