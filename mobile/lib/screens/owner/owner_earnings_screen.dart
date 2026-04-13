import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/revenue_provider.dart';
import '../../providers/futsal_provider.dart';
import '../../models/futsal.dart';

class OwnerEarningsScreen extends StatefulWidget {
  const OwnerEarningsScreen({super.key});

  @override
  State<OwnerEarningsScreen> createState() => _OwnerEarningsScreenState();
}

class _OwnerEarningsScreenState extends State<OwnerEarningsScreen> {
  String _selectedPeriod = "month";
  String _selectedTab = "overview";
  Futsal? _selectedFutsal;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final revenueProvider = Provider.of<RevenueProvider>(context, listen: false);
    final futsalProvider = Provider.of<FutsalProvider>(context, listen: false);
    
    await Future.wait([
      revenueProvider.loadEarningsOverview(period: _selectedPeriod),
      revenueProvider.loadEarningsBreakdown(),
      revenueProvider.loadEarningsHistory(),
      revenueProvider.loadEarningsChart(),
      revenueProvider.loadPayoutHistory(),
      futsalProvider.fetchMyFutsals(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Earnings'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'OVERVIEW', icon: Icon(Icons.dashboard)),
              Tab(text: 'BREAKDOWN', icon: Icon(Icons.pie_chart)),
              Tab(text: 'HISTORY', icon: Icon(Icons.history)),
              Tab(text: 'PAYOUTS', icon: Icon(Icons.payments)),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
          ),
          actions: [
            // Period filter
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _selectedPeriod,
                hint: const Text('Period', style: TextStyle(color: Colors.white)),
                dropdownColor: Colors.white,
                underline: const SizedBox(),
                icon: const Icon(Icons.calendar_today, color: Colors.white),
                style: const TextStyle(color: Colors.black),
                items: const [
                  DropdownMenuItem(value: "today", child: Text("Today")),
                  DropdownMenuItem(value: "week", child: Text("This Week")),
                  DropdownMenuItem(value: "month", child: Text("This Month")),
                  DropdownMenuItem(value: "year", child: Text("This Year")),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPeriod = value);
                    Provider.of<RevenueProvider>(context, listen: false)
                        .loadEarningsOverview(period: value);
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _loadData(),
            ),
          ],
        ),
        body: Consumer<RevenueProvider>(
          builder: (context, revenueProvider, _) {
            if (revenueProvider.isLoading) {
              return const Center(child: CircularProgressIndicator(color: Colors.green));
            }

            return TabBarView(
              children: [
                _buildOverviewTab(revenueProvider),
                _buildBreakdownTab(revenueProvider),
                _buildHistoryTab(revenueProvider),
                _buildPayoutsTab(revenueProvider),
              ],
            );
          },
        ),
      ),
    );
  }

  // ============================================
  // OVERVIEW TAB
  // ============================================
Widget _buildOverviewTab(RevenueProvider provider) {
  final overview = provider.earningsOverview;
  
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Total Earnings',
                value: 'रू ${(overview['totalEarnings'] ?? 0).toStringAsFixed(0)}',
                icon: Icons.money,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Pending Payout',
                value: 'रू ${(overview['pendingPayout'] ?? 0).toStringAsFixed(0)}',  // ✅ Changed from pendingEarnings
                icon: Icons.pending,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Total Bookings',
                value: '${overview['totalBookings'] ?? 0}',
                icon: Icons.book_online,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Total Paid Out',
                value: 'रू ${(overview['totalPaidOut'] ?? 0).toStringAsFixed(0)}',
                icon: Icons.payments,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Earnings Chart
        _buildEarningsChart(provider),
        const SizedBox(height: 24),

        // Request Payout Button - ✅ FIXED CONDITION
        if ((overview['pendingPayout'] ?? 0) >= (overview['minPayoutAmount'] ?? 1000))
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () => _requestPayout(provider),
              icon: const Icon(Icons.payments),
              label: Text(
                'Request Payout (Min: रू ${(overview['minPayoutAmount'] ?? 1000).toStringAsFixed(0)})',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

  Widget _buildSummaryCard({
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildEarningsChart(RevenueProvider provider) {
    final chartData = provider.earningsChart;
    
    if (chartData.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No earnings data available',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
      );
    }

    double maxEarnings = 1000.0;
    final maxVal = chartData.map<double>((d) => (d['earnings'] ?? 0).toDouble()).reduce((a, b) => a > b ? a : b);
    maxEarnings = maxVal * 1.2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Earnings Trend',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < chartData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                chartData[index]['label'] ?? '',
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 50),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: 0,
                  maxY: maxEarnings,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(chartData.length, (index) {
                        return FlSpot(
                          index.toDouble(),
                          (chartData[index]['earnings'] ?? 0).toDouble(),
                        );
                      }),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // BREAKDOWN TAB
  // ============================================
  Widget _buildBreakdownTab(RevenueProvider provider) {
    final futsalProvider = Provider.of<FutsalProvider>(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Futsal Filter
          if (futsalProvider.myFutsals.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButton<Futsal>(
                value: _selectedFutsal,
                hint: const Text('All Futsals'),
                isExpanded: true,
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem<Futsal>(value: null, child: Text('All Futsals')),
                  ...futsalProvider.myFutsals.map((f) => DropdownMenuItem(
                    value: f,
                    child: Text(f.name),
                  )),
                ],
                onChanged: (futsal) {
                  setState(() => _selectedFutsal = futsal);
                  provider.loadEarningsBreakdown(futsalId: futsal?.id);
                },
              ),
            ),

          // Totals Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTotalRow('Total Bookings', provider.earningsTotals['totalBookings'] ?? 0),
                  const Divider(),
                  _buildTotalRow('Total Revenue', 'रू ${(provider.earningsTotals['totalAmount'] ?? 0).toStringAsFixed(0)}'),
                  const Divider(),
                  _buildTotalRow('Platform Commission', 'रू ${(provider.earningsTotals['totalCommission'] ?? 0).toStringAsFixed(0)}'),
                  const Divider(),
                  _buildTotalRow('Your Earnings', 'रू ${(provider.earningsTotals['totalEarnings'] ?? 0).toStringAsFixed(0)}', isHighlight: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Breakdown List
          Card(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.earningsBreakdown.length,
              itemBuilder: (context, index) {
                final item = provider.earningsBreakdown[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item['futsalName'] ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            'रू ${(item['totalEarnings'] ?? 0).toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('${item['totalBookings']} bookings', style: const TextStyle(fontSize: 12)),
                          const Spacer(),
                          Text(
                            'Commission: रू ${(item['totalCommission'] ?? 0).toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      if (index < provider.earningsBreakdown.length - 1) const Divider(),
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

  // ============================================
  // HISTORY TAB
  // ============================================
  Widget _buildHistoryTab(RevenueProvider provider) {
    final transactions = provider.earningsHistory;
    
    if (transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No transaction history'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final booking = transaction['booking'] ?? {};
        final slot = booking['slot'] ?? {};
        final court = slot['court'] ?? {};
        final futsal = court['futsal'] ?? {};
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.sports_soccer, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        futsal['name'] ?? 'Unknown Futsal',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Court ${court['courtNumber']} • ${slot['startTime']}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _formatDate(transaction['createdAt']),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'रू ${(transaction['amount'] ?? 0).toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'You get: रू ${(transaction['ownerEarning'] ?? 0).toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12, color: Colors.green),
                    ),
                    Text(
                      'Commission: रू ${(transaction['commission'] ?? 0).toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 11, color: Colors.orange),
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

  // ============================================
  // PAYOUTS TAB
  // ============================================
  Widget _buildPayoutsTab(RevenueProvider provider) {
    final payouts = provider.payoutHistory;
    
    if (payouts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payments, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No payout history'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: payouts.length,
      itemBuilder: (context, index) {
        final payout = payouts[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'रू ${(payout['amount'] ?? 0).toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: payout['status'] == 'COMPLETED' 
                            ? Colors.green.shade100 
                            : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        payout['status'] ?? 'PENDING',
                        style: TextStyle(
                          fontSize: 10,
                          color: payout['status'] == 'COMPLETED' ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Requested: ${_formatDate(payout['requestDate'])}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (payout['processedAt'] != null)
                  Text(
                    'Processed: ${_formatDate(payout['processedAt'])}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                if (payout['transactions'] != null)
                  Text(
                    '${payout['transactions'].length} bookings included',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                if (payout['notes'] != null && payout['notes'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Note: ${payout['notes']}',
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotalRow(String label, dynamic value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal)),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            color: isHighlight ? Colors.green : Colors.black,
          ),
        ),
      ],
    );
  }

  Future<void> _requestPayout(RevenueProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Payout'),
        content: const Text('Are you sure you want to request a payout for all pending earnings?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Request'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final response = await provider.requestPayout();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Payout request submitted'),
            backgroundColor: response['status'] == 'success' ? Colors.green : Colors.red,
          ),
        );
        if (response['status'] == 'success') {
          await _loadData();
        }
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}