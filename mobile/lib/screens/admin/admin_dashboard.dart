import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/admin_analytics_provider.dart';
import 'package:table_calendar/table_calendar.dart';

// ============================================
// CALENDAR + DEFAULT DATE PICKER (year/month/day)
// ============================================
class CalendarCard extends StatefulWidget {
  const CalendarCard({super.key});

  @override
  State<CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends State<CalendarCard> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  Future<void> _openDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime.utc(2020, 1, 1),
      lastDate: DateTime.utc(2030, 12, 31),
    );
    if (picked != null) {
      setState(() {
        _selectedDay = picked;
        _focusedDay = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: () {
                    setState(() {
                      _focusedDay =
                          DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                    });
                  },
                ),
                Row(
                  children: [
                    Text(
                      '${_focusedDay.month}/${_focusedDay.year}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _openDatePicker,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.edit_calendar,
                            color: Colors.green, size: 20),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: () {
                    setState(() {
                      _focusedDay =
                          DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                    });
                  },
                ),
              ],
            ),
          ),
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            headerVisible: false,
            onFormatChanged: null,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle:
                  TextStyle(color: Colors.grey.shade600, fontSize: 12),
              weekendStyle: TextStyle(color: Colors.red.shade300, fontSize: 12),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              defaultTextStyle: const TextStyle(fontSize: 13),
              weekendTextStyle:
                  TextStyle(color: Colors.red.shade300, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// RANGE LINE CHART CARD (UPDATED: NO 'ALL' TAB)
// ============================================
class RangeLineChartCard extends StatefulWidget {
  final String title;
  final Color color;
  final String Function(double) valueFormatter;
  final Future<void> Function(ChartRange) onRangeChanged;
  final Map<ChartRange, List<FlSpot>> data;

  const RangeLineChartCard({
    super.key,
    required this.title,
    required this.color,
    required this.valueFormatter,
    required this.onRangeChanged,
    required this.data,
  });

  @override
  State<RangeLineChartCard> createState() => _RangeLineChartCardState();
}

class _RangeLineChartCardState extends State<RangeLineChartCard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ChartRange _selectedRange = ChartRange.week;
  bool _isLoading = false;

  // Only week, month, year – removed 'all'
  static const List<ChartRange> _ranges = [
    ChartRange.week,
    ChartRange.month,
    ChartRange.year,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _ranges.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final newRange = _ranges[_tabController.index];
      if (newRange != _selectedRange) {
        setState(() => _selectedRange = newRange);
        _loadRangeData(newRange);
      }
    }
  }

  Future<void> _loadRangeData(ChartRange range) async {
    setState(() => _isLoading = true);
    await widget.onRangeChanged(range);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final spots = widget.data[_selectedRange] ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                if (_isLoading)
                  const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 8),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: widget.color,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: widget.color,
              tabs: const [
                Tab(text: 'Week'),
                Tab(text: 'Month'),
                Tab(text: 'Year'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: spots.isEmpty
                  ? const Center(child: Text('No data available'))
                  : _buildScrollableChart(spots),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableChart(List<FlSpot> spots) {
    final maxX = spots.isNotEmpty ? spots.last.x : 10.0;
    final minX = spots.isNotEmpty ? spots.first.x : 0.0;

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: widget.color,
            barWidth: 3,
            isCurved: true,
            dotData: FlDotData(show: spots.length <= 30),
            belowBarData:
                BarAreaData(show: true, color: widget.color.withValues(alpha: 0.1)),
          ),
        ],
        minX: minX,
        maxX: maxX,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _calculateInterval(spots.length),
              getTitlesWidget: (value, meta) {
                if (value < 0 || value >= spots.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_getLabelForIndex(value.toInt()),
                      style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) => Text(
                  widget.valueFormatter(value),
                  style: const TextStyle(fontSize: 10)),
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                    widget.valueFormatter(spot.y),
                    const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold));
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  double _calculateInterval(int length) {
    if (length <= 10) return 1;
    if (length <= 30) return length / 7;
    return length / 10;
  }

  String _getLabelForIndex(int index) => '$index';
}

// ============================================
// ADMIN DASHBOARD WIDGET
// ============================================
class AdminDashboard extends StatelessWidget {
  final Function(String)? onMenuSelect;

  const AdminDashboard({super.key, this.onMenuSelect});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AdminProvider, AdminAnalyticsProvider>(
      builder: (context, adminProvider, analyticsProvider, child) {
        if (adminProvider.isLoading && adminProvider.totalUsers == 0) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.green));
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 1100;

        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              adminProvider.loadDashboardStats(),
              analyticsProvider.loadAllAnalytics(),
            ]);
          },
          color: Colors.green,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, adminProvider, isMobile),
                const SizedBox(height: 24),
                _buildStatsAndCalendarSection(context, adminProvider,
                    analyticsProvider, isMobile, isTablet),
                const SizedBox(height: 24),

                // Revenue & Booking trend charts
                if (screenWidth >= 900)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: RangeLineChartCard(
                          title: 'Revenue Trend',
                          color: Colors.green,
                          valueFormatter: (v) => 'Rs ${v.toStringAsFixed(0)}',
                          onRangeChanged: (range) =>
                              analyticsProvider.loadRevenueForRange(range),
                          data: analyticsProvider.revenueByRange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: RangeLineChartCard(
                          title: 'Bookings Trend',
                          color: Colors.blue,
                          valueFormatter: (v) => v.toInt().toString(),
                          onRangeChanged: (range) =>
                              analyticsProvider.loadBookingsForRange(range),
                          data: analyticsProvider.bookingsByRange,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      RangeLineChartCard(
                        title: 'Revenue Trend',
                        color: Colors.green,
                        valueFormatter: (v) => 'Rs ${v.toStringAsFixed(0)}',
                        onRangeChanged: (range) =>
                            analyticsProvider.loadRevenueForRange(range),
                        data: analyticsProvider.revenueByRange,
                      ),
                      const SizedBox(height: 20),
                      RangeLineChartCard(
                        title: 'Bookings Trend',
                        color: Colors.blue,
                        valueFormatter: (v) => v.toInt().toString(),
                        onRangeChanged: (range) =>
                            analyticsProvider.loadBookingsForRange(range),
                        data: analyticsProvider.bookingsByRange,
                      ),
                    ],
                  ),

                const SizedBox(height: 20),
                _buildDashboardBottomSection(
                    context, adminProvider, analyticsProvider, isMobile),
              ],
            ),
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------
  // HEADER
  // --------------------------------------------------------------
  Widget _buildHeader(
      BuildContext context, AdminProvider adminProvider, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back, 👋',
                style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            if (MediaQuery.of(context).size.width >= 1100)
              Text('Dashboard Overview',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800)),
          ],
        ),
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2))
              ]),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.green),
            onPressed: () async {
              await Future.wait([
                adminProvider.loadDashboardStats(),
                Provider.of<AdminAnalyticsProvider>(context, listen: false)
                    .loadAllAnalytics(),
              ]);
            },
            tooltip: 'Refresh',
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------
  // UNIFIED SECTION: Stats cards + Pie chart + Calendar
  // --------------------------------------------------------------
  Widget _buildStatsAndCalendarSection(
      BuildContext context,
      AdminProvider adminProvider,
      AdminAnalyticsProvider analyticsProvider,
      bool isMobile,
      bool isTablet) {
    final stats = [
      {
        'title': 'Total Users',
        'value': adminProvider.totalUsers.toString(),
        'icon': Icons.people_alt_rounded,
        'color': Colors.blue
      },
      {
        'title': 'Total Futsals',
        'value': adminProvider.totalFutsals.toString(),
        'icon': Icons.sports_soccer_rounded,
        'color': Colors.green
      },
      {
        'title': 'Total Owners',
        'value': adminProvider.totalOwners.toString(),
        'icon': Icons.business_rounded,
        'color': Colors.orange
      },
      {
        'title': 'Total Players',
        'value': adminProvider.totalPlayers.toString(),
        'icon': Icons.person_rounded,
        'color': Colors.purple
      },
      {
        'title': 'Total Bookings',
        'value': adminProvider.totalBookings.toString(),
        'icon': Icons.book_online_rounded,
        'color': Colors.teal
      },
      {
        'title': 'Total Revenue',
        'value': 'Rs ${adminProvider.totalRevenue.toStringAsFixed(0)}',
        'icon': Icons.payments_outlined,
        'color': Colors.red
      },
    ];

    if (isMobile) {
      return Column(
        children: [
          ...stats.map((stat) => _buildStatCardMobile(stat)),
          if (analyticsProvider.bookingStatusBreakdown.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildPieChartCard(analyticsProvider),
          ],
          const SizedBox(height: 16),
          const CalendarCard(),
        ],
      );
    }

    // Desktop / Tablet: two‑column row
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side: stats + pie chart
        Expanded(
          flex: 3,
          child: Column(
            children: [
              // First row of stats
              Row(
                children: List.generate(
                    3,
                    (i) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                right: i < 2 ? 8 : 0, bottom: 8),
                            child: _buildCompactStatCard(stats[i]),
                          ),
                        )),
              ),
              // Second row of stats
              Row(
                children: List.generate(
                    3,
                    (i) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                            child: _buildCompactStatCard(stats[i + 3]),
                          ),
                        )),
              ),
              // Pie chart inside the same left container
              if (analyticsProvider.bookingStatusBreakdown.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildPieChartCard(analyticsProvider),
              ],
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Right side: calendar
        const Expanded(
          flex: 2,
          child: CalendarCard(),
        ),
      ],
    );
  }

  // --------------------------------------------------------------
  // COMPACT STAT CARD (desktop/tablet)
  // --------------------------------------------------------------
  Widget _buildCompactStatCard(Map<String, dynamic> stat) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: (stat['color'] as Color).withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(stat['icon'] as IconData,
                    color: stat['color'] as Color, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(stat['title']!,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(stat['value']!,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: stat['color'] as Color)),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------
  // MOBILE STAT CARD
  // --------------------------------------------------------------
  Widget _buildStatCardMobile(Map<String, dynamic> stat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: (stat['color'] as Color).withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ]),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: (stat['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(stat['icon'] as IconData,
                  color: stat['color'] as Color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(stat['title'],
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(stat['value'],
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: stat['color'] as Color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------
  // PIE CHART (uses bookingStatusBreakdown from analytics provider)
  // --------------------------------------------------------------
  Widget _buildPieChartCard(AdminAnalyticsProvider analyticsProvider) {
    final data = analyticsProvider.bookingStatusBreakdown;
    if (data.isEmpty) return const SizedBox.shrink();
    final total = data.values.fold(0, (sum, v) => sum + v);
    final colors = {
      'CONFIRMED': Colors.green,
      'COMPLETED': Colors.blue,
      'CANCELLED': Colors.red,
      'PENDING': Colors.orange
    };

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Booking Status Breakdown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  height: 150,
                  width: 150,
                  child: PieChart(PieChartData(
                      sections: data.entries
                          .map((e) => PieChartSectionData(
                              value: e.value.toDouble(),
                              color: colors[e.key] ?? Colors.grey,
                              title: total > 0
                                  ? '${((e.value / total) * 100).toStringAsFixed(0)}%'
                                  : '',
                              radius: 50,
                              titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)))
                          .toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 30)),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: data.entries
                        .map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(children: [
                              Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                      color: colors[e.key],
                                      shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text(e.key, style: const TextStyle(fontSize: 13)),
                              const Spacer(),
                              Text('${e.value}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold))
                            ])))
                        .toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------
  // BOTTOM SECTION (PENDING APPROVALS + RECENT ACTIVITY)
  // --------------------------------------------------------------
  Widget _buildDashboardBottomSection(
      BuildContext context,
      AdminProvider adminProvider,
      AdminAnalyticsProvider analyticsProvider,
      bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildPendingApprovalsCard(context, adminProvider, compact: true),
          const SizedBox(height: 24),
          _buildRecentActivityCard(context, adminProvider, compact: true),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        return isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child:
                          _buildPendingApprovalsCard(context, adminProvider)),
                  const SizedBox(width: 24),
                  Expanded(
                      child: _buildRecentActivityCard(context, adminProvider)),
                ],
              )
            : Column(
                children: [
                  _buildPendingApprovalsCard(context, adminProvider),
                  const SizedBox(height: 24),
                  _buildRecentActivityCard(context, adminProvider),
                ],
              );
      },
    );
  }

  Widget _buildPendingApprovalsCard(
      BuildContext context, AdminProvider adminProvider,
      {bool compact = false}) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 4))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(compact ? 16 : 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('⏳ Pending Approvals',
                    style: TextStyle(
                        fontSize: compact ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800)),
                TextButton(
                    onPressed: () => onMenuSelect?.call('Pending Futsals'),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 8)),
                    child: const Text('View All')),
              ],
            ),
          ),
          if (adminProvider.pendingFutsals.isEmpty)
            Padding(
              padding: EdgeInsets.all(compact ? 20 : 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: compact ? 40 : 48, color: Colors.green.shade300),
                    const SizedBox(height: 12),
                    Text('All caught up!',
                        style: TextStyle(
                            fontSize: compact ? 14 : 16,
                            color: Colors.grey.shade600)),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
              itemCount: adminProvider.pendingFutsals.length.clamp(0, 3),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final futsal = adminProvider.pendingFutsals[index];
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(
                      vertical: compact ? 4 : 8, horizontal: 4),
                  leading: Container(
                    width: compact ? 40 : 48,
                    height: compact ? 40 : 48,
                    decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.sports_soccer_rounded,
                        color: Colors.green.shade700, size: compact ? 20 : 24),
                  ),
                  title: Text(futsal['name'] ?? 'Futsal',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: compact ? 14 : 16)),
                  subtitle: Text(
                      'Owner: ${futsal['owner']?['fullName'] ?? 'Unknown'}',
                      style: TextStyle(fontSize: compact ? 12 : 14)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: Icon(Icons.check_circle_outline_rounded,
                              color: Colors.green, size: compact ? 20 : 22),
                          onPressed: () => _approveFutsal(
                              context, adminProvider, futsal['id']),
                          tooltip: 'Approve'),
                      IconButton(
                          icon: Icon(Icons.cancel_outlined,
                              color: Colors.red, size: compact ? 20 : 22),
                          onPressed: () => _rejectFutsalDialog(
                              context, adminProvider, futsal),
                          tooltip: 'Reject'),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard(
      BuildContext context, AdminProvider adminProvider,
      {bool compact = false}) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 4))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(compact ? 16 : 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('📋 Recent Activity',
                    style: TextStyle(
                        fontSize: compact ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800)),
                TextButton(
                    onPressed: () => onMenuSelect?.call('Recent Activity'),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 8)),
                    child: const Text('View All')),
              ],
            ),
          ),
          if (adminProvider.recentActivities.isEmpty)
            Padding(
              padding: EdgeInsets.all(compact ? 20 : 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.history_rounded,
                        size: compact ? 40 : 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text('No recent activity',
                        style: TextStyle(
                            fontSize: compact ? 14 : 16,
                            color: Colors.grey.shade600)),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
              itemCount: adminProvider.recentActivities.length.clamp(0, 5),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final activity = adminProvider.recentActivities[index];

                final name = activity['name'] ??
                    activity['user']?['fullName'] ??
                    'System';
                final email =
                    activity['email'] ?? activity['user']?['email'] ?? '';
                final phone =
                    activity['phone'] ?? activity['user']?['phoneNumber'] ?? '';
                final category =
                    activity['category'] ?? activity['type'] ?? 'Activity';
                final status = activity['status'] ?? 'completed';
                final createdAt = activity['createdAt'] ?? '';

                final categoryColor = category == 'Booking'
                    ? Colors.blue
                    : category == 'User Added'
                        ? Colors.green
                        : Colors.purple;
                final statusColor = status == 'completed'
                    ? Colors.green.shade700
                    : status == 'pending'
                        ? Colors.orange.shade700
                        : status == 'registered'
                            ? Colors.blue.shade700
                            : Colors.grey.shade700;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: compact ? 14 : 15)),
                      const SizedBox(height: 2),
                      if (email.isNotEmpty)
                        Text(email,
                            style: TextStyle(
                                fontSize: compact ? 11 : 12,
                                color: Colors.grey.shade600)),
                      if (phone.isNotEmpty)
                        Text(phone,
                            style: TextStyle(
                                fontSize: compact ? 11 : 12,
                                color: Colors.grey.shade600)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: categoryColor.withValues(alpha: 0.3),
                                  width: 1),
                            ),
                            child: Text(category,
                                style: TextStyle(
                                    fontSize: compact ? 10 : 11,
                                    fontWeight: FontWeight.w600,
                                    color: categoryColor)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: statusColor.withValues(alpha: 0.3),
                                  width: 1),
                            ),
                            child: Text(status.toUpperCase(),
                                style: TextStyle(
                                    fontSize: compact ? 10 : 11,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor)),
                          ),
                          const Spacer(),
                          Text(_formatRelativeTime(createdAt),
                              style: TextStyle(
                                  fontSize: compact ? 10 : 11,
                                  color: Colors.grey.shade500)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // --------------------------------------------------------------
  // HELPER ACTIONS
  // --------------------------------------------------------------
  Future<void> _approveFutsal(
      BuildContext context, AdminProvider adminProvider, int id) async {
    final result = await adminProvider.approveFutsal(id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor:
              result['status'] == 'success' ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      if (result['status'] == 'success') adminProvider.loadDashboardStats();
    }
  }

  void _rejectFutsalDialog(BuildContext context, AdminProvider adminProvider,
      Map<String, dynamic> futsal) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Futsal'),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
              labelText: 'Reason for rejection',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          maxLines: 2,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30))),
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await adminProvider.rejectFutsal(
                  futsal['id'], reasonController.text);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: result['status'] == 'success'
                        ? Colors.green
                        : Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                if (result['status'] == 'success') {
                  adminProvider.loadDashboardStats();
                }
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) =>
      date == null ? 'Not available' : '${date.day}/${date.month}/${date.year}';

  String _formatRelativeTime(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays > 7) return _formatDate(date);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (e) {
      return 'Unknown';
    }
  }
}
