import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/revenue_provider.dart';
import '../../providers/futsal_provider.dart';
import '../../models/futsal.dart';
import '../../services/api_service.dart';

class AdminRevenueScreen extends StatefulWidget {
  const AdminRevenueScreen({super.key});

  @override
  State<AdminRevenueScreen> createState() => _AdminRevenueScreenState();
}

class _AdminRevenueScreenState extends State<AdminRevenueScreen> {
  String _selectedPeriod = "month";
  String _selectedTab = "overview";
  Futsal? _selectedFutsal;
  List<Futsal> _allFutsals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final revenueProvider = Provider.of<RevenueProvider>(context, listen: false);
    await Future.wait([
      revenueProvider.loadRevenueOverview(period: _selectedPeriod),
      revenueProvider.loadCommissionBreakdown(),
      revenueProvider.loadRevenueTrends(),
      revenueProvider.loadPayoutRequests(),
      _loadFutsals(),
    ]);
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFutsals() async {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Revenue Analytics'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'OVERVIEW', icon: Icon(Icons.dashboard)),
              Tab(text: 'COMMISSIONS', icon: Icon(Icons.percent)),
              Tab(text: 'TRENDS', icon: Icon(Icons.trending_up)),
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
                onChanged: (value) async {
                  if (value != null) {
                    setState(() => _selectedPeriod = value);
                    final revenueProvider = Provider.of<RevenueProvider>(context, listen: false);
                    await revenueProvider.loadRevenueOverview(period: value);
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
          builder: (context, revenueProvider, child) {
            if (_isLoading || revenueProvider.isLoading) {
              return const Center(child: CircularProgressIndicator(color: Colors.green));
            }

            return TabBarView(
              children: [
                _buildOverviewTab(revenueProvider),
                _buildCommissionsTab(revenueProvider),
                _buildTrendsTab(revenueProvider),
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
    final overview = provider.revenueOverview;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary Cards - First Row (Total Revenue + Total Bookings)
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Revenue',
                  value: 'रू ${(overview['totalRevenue'] ?? 0).toStringAsFixed(0)}',
                  icon: Icons.currency_rupee,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Bookings',
                  value: '${overview['totalBookings'] ?? 0}',
                  icon: Icons.book_online,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // ✅ Second Row - Revenue Breakdown (Booking Revenue + Registration Fees)
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Booking Revenue',
                  value: 'रू ${provider.bookingRevenue.toStringAsFixed(0)}',
                  icon: Icons.shopping_cart,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Registration Fees',
                  value: 'रू ${provider.registrationRevenue.toStringAsFixed(0)}',
                  icon: Icons.assignment_ind,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Third Row - Pending Commission + Avg per Booking
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Pending Commission',
                  value: 'रू ${(overview['pendingCommission'] ?? 0).toStringAsFixed(0)}',
                  icon: Icons.pending,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Avg per Booking',
                  value: 'रू ${(overview['avgBookingValue'] ?? 0).toStringAsFixed(0)}',
                  icon: Icons.trending_up,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Commission Rate Card
          _buildCommissionRateCard(provider),
          const SizedBox(height: 24),

          // Recent Commission Breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top Futsals by Commission',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._buildCommissionList(provider),
                ],
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

  Widget _buildCommissionRateCard(RevenueProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Commission Settings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Current Rate: '),
                Text(
                  '${provider.commissionRate}%',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showCommissionDialog(provider),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Update'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCommissionList(RevenueProvider provider) {
    final breakdown = provider.commissionBreakdown;
    if (breakdown.isEmpty) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('No commission data available'),
          ),
        ),
      ];
    }
    return breakdown.take(5).map((item) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.sports_soccer, color: Colors.green, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['futsalName'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${item['totalBookings']} bookings',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'रू ${(item['totalCommission'] ?? 0).toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
                Text(
                  '${(item['totalCommission'] / (item['totalAmount'] ?? 1) * 100).toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  // ============================================
  // COMMISSIONS TAB
  // ============================================
  Widget _buildCommissionsTab(RevenueProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Futsal Filter
          if (_allFutsals.isNotEmpty)
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
                  ..._allFutsals.map((f) => DropdownMenuItem(
                    value: f,
                    child: Text(f.name),
                  )),
                ],
                onChanged: (futsal) async {
                  setState(() => _selectedFutsal = futsal);
                  await provider.loadCommissionBreakdown(futsalId: futsal?.id);
                },
              ),
            ),

          // Totals Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTotalRow('Total Bookings', provider.commissionTotals['totalBookings'] ?? 0),
                  const Divider(),
                  _buildTotalRow('Total Amount', 'रू ${(provider.commissionTotals['totalAmount'] ?? 0).toStringAsFixed(0)}'),
                  const Divider(),
                  _buildTotalRow('Total Commission', 'रू ${(provider.commissionTotals['totalCommission'] ?? 0).toStringAsFixed(0)}', isHighlight: true),
                  const Divider(),
                  _buildTotalRow('Owner Earnings', 'रू ${(provider.commissionTotals['totalOwnerEarning'] ?? 0).toStringAsFixed(0)}'),
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
              itemCount: provider.commissionBreakdown.length,
              itemBuilder: (context, index) {
                final item = provider.commissionBreakdown[index];
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
                            'रू ${(item['totalCommission'] ?? 0).toStringAsFixed(0)}',
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
                            '${(item['totalCommission'] / (item['totalAmount'] ?? 1) * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      if (index < provider.commissionBreakdown.length - 1) const Divider(),
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

  // ============================================
  // TRENDS TAB
  // ============================================
  Widget _buildTrendsTab(RevenueProvider provider) {
    final trends = provider.revenueTrends;
    
    // Convert to double safely
    double maxRevenue = 1000.0;
    if (trends.isNotEmpty) {
      final maxVal = trends.map<double>((t) => (t['revenue'] ?? 0).toDouble()).reduce((a, b) => a > b ? a : b);
      maxRevenue = maxVal * 1.2;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Revenue Trend',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 250,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxRevenue,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              if (group.x.toInt() < trends.length) {
                                final trend = trends[group.x.toInt()];
                                return BarTooltipItem(
                                  'रू ${(trend['revenue'] ?? 0).toStringAsFixed(0)}\n${trend['bookings'] ?? 0} bookings',
                                  const TextStyle(color: Colors.white, fontSize: 12),
                                );
                              }
                              return null;
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < trends.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      trends[index]['label'] ?? '',
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
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(trends.length, (index) {
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: (trends[index]['revenue'] ?? 0).toDouble(),
                                color: Colors.green,
                                width: 24,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // PAYOUTS TAB
  // ============================================
  Widget _buildPayoutsTab(RevenueProvider provider) {
    final payouts = provider.payoutRequests;
    
    if (payouts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payments, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No pending payout requests'),
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
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(Icons.person, color: Colors.green, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payout['owner']?['fullName'] ?? 'Unknown Owner',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            payout['owner']?['email'] ?? '',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'रू ${(payout['amount'] ?? 0).toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: payout['status'] == 'PENDING' ? Colors.orange.shade100 : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            payout['status'] ?? 'PENDING',
                            style: TextStyle(
                              fontSize: 10,
                              color: payout['status'] == 'PENDING' ? Colors.orange : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Requested: ${_formatDate(payout['requestDate'])}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (payout['transactions'] != null)
                  Text(
                    '${payout['transactions'].length} bookings included',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                const SizedBox(height: 12),
                if (payout['status'] == 'PENDING')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _processPayout(provider, payout['id']),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.green),
                            foregroundColor: Colors.green,
                          ),
                          child: const Text('Mark as Paid'),
                        ),
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

  Future<void> _processPayout(RevenueProvider provider, int payoutId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Process Payout'),
        content: const Text('Mark this payout as paid?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final response = await provider.processPayout(payoutId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Payout processed'),
            backgroundColor: response['status'] == 'success' ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCommissionDialog(RevenueProvider provider) async {
    final controller = TextEditingController(text: provider.commissionRate.toString());
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Commission Rate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set new commission percentage:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Commission Rate (%)',
                border: OutlineInputBorder(),
                suffixText: '%',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final rate = double.tryParse(controller.text);
              if (rate != null && rate >= 0 && rate <= 100) {
                await provider.updateCommissionRate(rate);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Commission rate updated'), backgroundColor: Colors.green),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Update'),
          ),
        ],
      ),
    );
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