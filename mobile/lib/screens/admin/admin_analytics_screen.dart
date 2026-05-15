import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_analytics_provider.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final Map<String, bool> _expandedSections = {
    'Booking Analytics': true,
    'Revenue Analytics': true,
    'Ground Performance': true,
    'User Analytics': true,
    'Time Slot Analysis': true,
    'Tournament Analytics': true,
  };

  // Separate selected ranges for each chart
  ChartRange _bookingSelectedRange = ChartRange.week;
  ChartRange _revenueSelectedRange = ChartRange.week;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<AdminAnalyticsProvider>(context, listen: false);
      provider.loadAllAnalytics();
      // Preload the initial ranges
      provider.loadBookingsForRange(ChartRange.week);
      provider.loadRevenueForRange(ChartRange.week);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Consumer<AdminAnalyticsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.revenueByRange.isEmpty) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.green));
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadAllAnalytics(),
            color: Colors.green,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(provider),
                  const SizedBox(height: 24),
                  _buildBookingSection(provider),
                  const SizedBox(height: 20),
                  _buildRevenueSection(provider),
                  const SizedBox(height: 20),
                  _buildGroundPerformanceSection(provider),
                  const SizedBox(height: 20),
                  _buildUserSection(provider),
                  const SizedBox(height: 20),
                  _buildTimeSlotSection(provider),
                  const SizedBox(height: 20),
                  _buildTournamentSection(provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(AdminAnalyticsProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Advanced Analytics',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            Text('Daily, weekly & monthly trends',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.green),
          onPressed: () => provider.loadAllAnalytics(),
        ),
      ],
    );
  }

  // ============================================================
  // Booking Analytics Section
  // ============================================================
  Widget _buildBookingSection(AdminAnalyticsProvider provider) {
    final expanded = _expandedSections['Booking Analytics']!;
    final spots = provider.bookingsByRange[_bookingSelectedRange] ?? [];
    final labels = provider.bookingLabels[_bookingSelectedRange] ?? [];

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('📊 Booking Analytics',
              expanded: expanded,
              onToggle: () => _toggleSection('Booking Analytics')),
          if (expanded) ...[
            const SizedBox(height: 16),
            _buildChartWithRangeSelector(
              title: 'Bookings Trend',
              spots: spots,
              labels: labels,
              selectedRange: _bookingSelectedRange,
              onRangeChanged: (range) async {
                setState(() => _bookingSelectedRange = range);
                await provider.loadBookingsForRange(range);
              },
              valueFormatter: (v) => v.toInt().toString(),
              color: Colors.blue,
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // Revenue Analytics Section
  // ============================================================
  Widget _buildRevenueSection(AdminAnalyticsProvider provider) {
    final expanded = _expandedSections['Revenue Analytics']!;
    final spots = provider.revenueByRange[_revenueSelectedRange] ?? [];
    final labels = provider.revenueLabels[_revenueSelectedRange] ?? [];

    return _buildCard(
      child: Column(
        children: [
          _buildSectionHeader('💰 Revenue Analytics',
              expanded: expanded,
              onToggle: () => _toggleSection('Revenue Analytics')),
          if (expanded) ...[
            const SizedBox(height: 16),
            _buildChartWithRangeSelector(
              title: 'Revenue Trend',
              spots: spots,
              labels: labels,
              selectedRange: _revenueSelectedRange,
              onRangeChanged: (range) async {
                setState(() => _revenueSelectedRange = range);
                await provider.loadRevenueForRange(range);
              },
              valueFormatter: (v) => 'रू ${v.toStringAsFixed(0)}',
              color: Colors.green,
            ),
          ],
        ],
      ),
    );
  }

  // Reusable chart with custom range buttons (replaces SegmentedButton)
  Widget _buildChartWithRangeSelector({
    required String title,
    required List<FlSpot> spots,
    required List<String> labels,
    required ChartRange selectedRange,
    required Function(ChartRange) onRangeChanged,
    required String Function(double) valueFormatter,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRangeButton('Week', ChartRange.week, selectedRange,
                      color, onRangeChanged),
                  _buildRangeButton('Month', ChartRange.month, selectedRange,
                      color, onRangeChanged),
                  _buildRangeButton('Year', ChartRange.year, selectedRange,
                      color, onRangeChanged),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (spots.isEmpty)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text('No data available')))
        else
          SizedBox(
            height: 260,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    color: color,
                    barWidth: 3,
                    isCurved: true,
                    dotData: FlDotData(show: spots.length <= 31),
                    belowBarData:
                        BarAreaData(show: true, color: color.withOpacity(0.1)),
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) => Text(
                          valueFormatter(value),
                          style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: _calculateInterval(labels.length),
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index >= labels.length)
                          return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(labels[index],
                              style: const TextStyle(fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                            valueFormatter(spot.y),
                            const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold));
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRangeButton(String label, ChartRange value, ChartRange selected,
      Color color, Function(ChartRange) onPressed) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onPressed(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

  // ============================================================
  // Ground Performance Section (Bordered tables, left aligned)
  // ============================================================
  Widget _buildGroundPerformanceSection(AdminAnalyticsProvider provider) {
    final expanded = _expandedSections['Ground Performance']!;
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('⚽ Ground Performance',
              expanded: expanded,
              onToggle: () => _toggleSection('Ground Performance')),
          if (expanded) ...[
            const SizedBox(height: 16),
            const Text('Most Booked Grounds',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildBorderedTable(provider.groundBookingRank, 'Bookings'),
            const SizedBox(height: 20),
            const Text('Highest Revenue Grounds',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildBorderedTable(provider.groundRevenueRank, 'Revenue',
                isRevenue: true),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // User Analytics Section (Bordered table, left aligned)
  // ============================================================
  Widget _buildUserSection(AdminAnalyticsProvider provider) {
    final expanded = _expandedSections['User Analytics']!;
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('👥 User Analytics',
              expanded: expanded,
              onToggle: () => _toggleSection('User Analytics')),
          if (expanded) ...[
            const SizedBox(height: 16),
            _buildStatsBox('Total Users', provider.totalUsers.toString(),
                Icons.people, Colors.purple),
            const SizedBox(height: 20),
            const Text('🏆 Top Players (by bookings)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildBorderedTable(provider.topPlayers, 'Bookings'),
          ],
        ],
      ),
    );
  }

  // Generic bordered table with left alignment
  Widget _buildBorderedTable(List<Map<String, dynamic>> data, String metric,
      {bool isRevenue = false}) {
    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No data available'),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          border: TableBorder.all(color: Colors.grey.shade300),
          columns: [
            DataColumn(
              label: Text(metric == 'Bookings' ? 'Player' : 'Ground',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text(metric,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
          rows: data.map((item) {
            final name = isRevenue
                ? (item['name'] ?? 'Unknown')
                : (item['name'] ?? item['fullName'] ?? 'Unknown');
            final value = isRevenue
                ? 'रू ${(item['revenue'] as num).toStringAsFixed(0)}'
                : '${item['bookingCount']}';
            return DataRow(cells: [
              DataCell(Text(name,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
              DataCell(Text(value, textAlign: TextAlign.left)),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // ============================================================
  // Time Slot Analysis (Peak Hours Bar Chart)
  // ============================================================
  Widget _buildTimeSlotSection(AdminAnalyticsProvider provider) {
    final expanded = _expandedSections['Time Slot Analysis']!;
    final peakData = provider.peakHoursData;
    return _buildCard(
      child: Column(
        children: [
          _buildSectionHeader('🕒 Peak Hours',
              expanded: expanded,
              onToggle: () => _toggleSection('Time Slot Analysis')),
          if (expanded && peakData.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  barGroups: peakData.entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                            toY: e.value.toDouble(),
                            color: Colors.orange,
                            width: 20)
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                        sideTitles:
                            SideTitles(showTitles: true, reservedSize: 40)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text(
                            '${value.toInt()}:00',
                            style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // Tournament Analytics Section
  // ============================================================
  Widget _buildTournamentSection(AdminAnalyticsProvider provider) {
    final expanded = _expandedSections['Tournament Analytics']!;
    return _buildCard(
      child: Column(
        children: [
          _buildSectionHeader('🏆 Tournament Rankings',
              expanded: expanded,
              onToggle: () => _toggleSection('Tournament Analytics')),
          if (expanded) ...[
            const SizedBox(height: 16),
            if (provider.tournamentRank.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No tournaments yet'))
            else
              _buildBorderedTable(provider.tournamentRank, 'Teams'),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // Helper Widgets
  // ============================================================
  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _buildSectionHeader(String title,
      {required bool expanded, required VoidCallback onToggle}) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(children: [
          Icon(expanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.green.shade700),
          const SizedBox(width: 12),
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _buildStatsBox(
      String title, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.2)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title),
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ]),
      ]),
    );
  }

  void _toggleSection(String key) =>
      setState(() => _expandedSections[key] = !_expandedSections[key]!);
}
