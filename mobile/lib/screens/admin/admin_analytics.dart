import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final Map<String, bool> _expandedSections = {
    'Booking Analytics': true,
    'Revenue Analytics': true,
    'Ground Performance': false,
    'User Analytics': false,
    'Time Slot Analysis': false,
    'Tournament Analytics': false,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadAllAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Consumer<AdminProvider>(
        builder: (context, provider, _) {
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
                  _buildBookingAnalyticsSection(provider),
                  const SizedBox(height: 20),
                  _buildRevenueAnalyticsSection(provider),
                  const SizedBox(height: 20),
                  _buildGroundPerformanceSection(provider),
                  const SizedBox(height: 20),
                  _buildUserAnalyticsSection(provider),
                  const SizedBox(height: 20),
                  _buildTimeSlotAnalysisSection(provider),
                  const SizedBox(height: 20),
                  _buildTournamentAnalyticsSection(provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(AdminProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Advanced Analytics',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Detailed insights for data-driven decisions',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.green),
            onPressed: () => provider.loadAllAnalytics(),
            tooltip: 'Refresh all',
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {String? subtitle, required bool expanded, required VoidCallback onToggle}) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.green.shade700,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingAnalyticsSection(AdminProvider provider) {
    final expanded = _expandedSections['Booking Analytics'] ?? true;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSectionHeader(
              '📊 Booking Analytics',
              expanded: expanded,
              onToggle: () => setState(() => _expandedSections['Booking Analytics'] = !expanded),
            ),
            if (expanded) ...[
              const SizedBox(height: 16),
              if (provider.isBookingAnalyticsLoading)
                const Center(child: CircularProgressIndicator(color: Colors.green))
              else
                _buildBookingAnalyticsContent(provider.bookingAnalytics),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookingAnalyticsContent(Map<String, dynamic> data) {
    final bookingsOverTime = (data['bookingsOverTime'] as List?) ?? [];
    final peakHours = (data['peakHours'] as Map?)?.cast<String, int>() ?? {};
    final mostBookedDays = (data['mostBookedDays'] as List?) ?? [];
    final totalBookings = data['totalBookings'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total bookings card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.blue.shade100],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.book_online, color: Colors.blue.shade700, size: 32),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Bookings', style: TextStyle(color: Colors.blue.shade800, fontSize: 14)),
                  Text('$totalBookings', style: TextStyle(color: Colors.blue.shade900, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (bookingsOverTime.isNotEmpty) ...[
          Text('Bookings Over Time', style: _sectionTitleStyle()),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: bookingsOverTime.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value as num).toDouble())).toList(),
                    color: Colors.blue.shade600,
                    barWidth: 3,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: Colors.blue.shade100.withOpacity(0.5)),
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 5),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                'Peak Hours',
                peakHours.entries.map((e) => '${e.key}: ${e.value} bookings').join('\n'),
                Icons.access_time,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoCard(
                'Most Booked Days',
                mostBookedDays.map((e) => e.toString()).join('\n'),
                Icons.calendar_today,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueAnalyticsSection(AdminProvider provider) {
    final expanded = _expandedSections['Revenue Analytics'] ?? true;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSectionHeader(
              '💰 Revenue Analytics',
              expanded: expanded,
              onToggle: () => setState(() => _expandedSections['Revenue Analytics'] = !expanded),
            ),
            if (expanded) ...[
              const SizedBox(height: 16),
              if (provider.isRevenueAnalyticsLoading)
                const Center(child: CircularProgressIndicator(color: Colors.green))
              else
                _buildRevenueAnalyticsContent(provider.revenueAnalytics),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueAnalyticsContent(Map<String, dynamic> data) {
    final trends = (data['trends'] as List?) ?? [];
    final revenuePerGround = (data['revenuePerGround'] as List?) ?? [];
    final paymentMethods = (data['paymentMethods'] as Map?)?.cast<String, double>() ?? {};
    final totalRevenue = data['totalRevenue'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.green.shade50, Colors.green.shade100]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.attach_money, color: Colors.green.shade700, size: 32),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Revenue', style: TextStyle(color: Colors.green.shade800, fontSize: 14)),
                  Text('रू ${(totalRevenue as num).toStringAsFixed(0)}', style: TextStyle(color: Colors.green.shade900, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (trends.isNotEmpty) ...[
          Text('Revenue Trends', style: _sectionTitleStyle()),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barGroups: trends.asMap().entries.map((e) => BarChartGroupData(
                  x: e.key,
                  barRods: [BarChartRodData(toY: (e.value as num).toDouble(), color: Colors.green.shade600, width: 20, borderRadius: BorderRadius.circular(4))],
                )).toList(),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                'Revenue per Ground',
                revenuePerGround.map((e) => '${e['name']}: रू ${(e['revenue'] as num).toStringAsFixed(0)}').join('\n'),
                Icons.sports_soccer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoCard(
                'Payment Methods',
                paymentMethods.entries.map((e) => '${e.key}: ${e.value.toStringAsFixed(1)}%').join('\n'),
                Icons.payment,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGroundPerformanceSection(AdminProvider provider) {
    final expanded = _expandedSections['Ground Performance'] ?? false;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSectionHeader(
              '⚽ Ground Performance',
              expanded: expanded,
              onToggle: () => setState(() => _expandedSections['Ground Performance'] = !expanded),
            ),
            if (expanded) ...[
              const SizedBox(height: 16),
              if (provider.isGroundPerformanceLoading)
                const Center(child: CircularProgressIndicator(color: Colors.green))
              else
                _buildGroundPerformanceContent(provider.groundPerformance),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGroundPerformanceContent(Map<String, dynamic> data) {
    final popular = (data['popular'] as List?) ?? [];
    final leastUsed = (data['leastUsed'] as List?) ?? [];
    final occupancyRate = (data['occupancyRate'] as num?)?.toDouble() ?? 0.0;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.orange.shade50, Colors.orange.shade100]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.pie_chart, color: Colors.orange.shade700, size: 32),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Avg Occupancy Rate', style: TextStyle(color: Colors.orange.shade800, fontSize: 14)),
                  Text('${occupancyRate.toStringAsFixed(1)}%', style: TextStyle(color: Colors.orange.shade900, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildInfoCard('Most Popular', popular.map((e) => '${e['name']}: ${e['bookings']} bookings').join('\n'), Icons.trending_up)),
            const SizedBox(width: 16),
            Expanded(child: _buildInfoCard('Least Used', leastUsed.map((e) => e['name']).join('\n'), Icons.trending_down)),
          ],
        ),
      ],
    );
  }

  Widget _buildUserAnalyticsSection(AdminProvider provider) {
    final expanded = _expandedSections['User Analytics'] ?? false;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSectionHeader(
              '👥 User Analytics',
              expanded: expanded,
              onToggle: () => setState(() => _expandedSections['User Analytics'] = !expanded),
            ),
            if (expanded) ...[
              const SizedBox(height: 16),
              if (provider.isUserAnalyticsLoading)
                const Center(child: CircularProgressIndicator(color: Colors.green))
              else
                _buildUserAnalyticsContent(provider.userAnalytics),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserAnalyticsContent(Map<String, dynamic> data) {
  final newUsers = data['newUsers'] ?? 0;
  final activeVsInactive = (data['activeVsInactive'] as Map?)?.cast<String, int>() ?? {};
  final topPlayers = (data['topPlayers'] as List?) ?? [];

  return Column(
    children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.purple.shade50, Colors.purple.shade100]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.person_add, color: Colors.purple.shade700, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Users (This Month)', style: TextStyle(color: Colors.purple.shade800, fontSize: 14)),
                Text('$newUsers', style: TextStyle(color: Colors.purple.shade900, fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: _buildInfoCard(
              'Active vs Inactive',
              activeVsInactive.isNotEmpty
                  ? 'Active: ${activeVsInactive['active']}\nInactive: ${activeVsInactive['inactive']}'
                  : 'No user activity data yet',
              Icons.people,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildInfoCard(
              'Top Players',
              topPlayers.isNotEmpty
                  ? topPlayers.map((e) => '${e['name'] ?? e['fullName']}: ${e['bookings'] ?? e['totalBookings']}').join('\n')
                  : 'No player data yet',
              Icons.emoji_events,
            ),
          ),
        ],
      ),
    ],
  );
}

  Widget _buildTimeSlotAnalysisSection(AdminProvider provider) {
    final expanded = _expandedSections['Time Slot Analysis'] ?? false;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSectionHeader(
              '🕒 Time Slot Analysis',
              expanded: expanded,
              onToggle: () => setState(() => _expandedSections['Time Slot Analysis'] = !expanded),
            ),
            if (expanded) ...[
              const SizedBox(height: 16),
              if (provider.isTimeSlotAnalyticsLoading)
                const Center(child: CircularProgressIndicator(color: Colors.green))
              else
                _buildTimeSlotContent(provider.timeSlotAnalytics),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotContent(Map<String, dynamic> data) {
    final peakSlots = (data['peakSlots'] as List?) ?? [];
    final leastUsedSlots = (data['leastUsedSlots'] as List?) ?? [];

    return Row(
      children: [
        Expanded(child: _buildInfoCard('Most Booked Slots', peakSlots.join('\n'), Icons.access_time_filled, color: Colors.amber)),
        const SizedBox(width: 16),
        Expanded(child: _buildInfoCard('Least Used Slots', leastUsedSlots.join('\n'), Icons.access_time, color: Colors.blueGrey)),
      ],
    );
  }

  Widget _buildTournamentAnalyticsSection(AdminProvider provider) {
    final expanded = _expandedSections['Tournament Analytics'] ?? false;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSectionHeader(
              '🏆 Tournament Analytics',
              expanded: expanded,
              onToggle: () => setState(() => _expandedSections['Tournament Analytics'] = !expanded),
            ),
            if (expanded) ...[
              const SizedBox(height: 16),
              if (provider.isTournamentAnalyticsLoading)
                const Center(child: CircularProgressIndicator(color: Colors.green))
              else
                _buildTournamentContent(provider.tournamentAnalytics),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentContent(Map<String, dynamic> data) {
    final count = data['count'] ?? 0;
    final participation = (data['participationRate'] as num?)?.toDouble() ?? 0.0;
    final revenue = (data['revenue'] as num?)?.toDouble() ?? 0.0;

    return Row(
      children: [
        Expanded(child: _buildInfoCard('Total Tournaments', '$count', Icons.emoji_events, color: Colors.indigo)),
        const SizedBox(width: 16),
        Expanded(child: _buildInfoCard('Participation Rate', '${participation.toStringAsFixed(1)}%', Icons.people, color: Colors.teal)),
        const SizedBox(width: 16),
        Expanded(child: _buildInfoCard('Tournament Revenue', 'रू ${revenue.toStringAsFixed(0)}', Icons.attach_money, color: Colors.deepPurple)),
      ],
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon, {Color color = Colors.green}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(color: Colors.grey.shade700, height: 1.5),
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
      ],
    ),
  );
}

  TextStyle _sectionTitleStyle() => const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
}