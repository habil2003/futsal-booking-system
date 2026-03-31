import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/futsal_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/futsal.dart';
import '../../models/booking.dart';
import 'add_futsal_screen.dart';
import 'court_management_screen.dart';
import 'bookings_screen.dart';
import '../owner/tournament_list_screen.dart';
import 'owner_reviews_screen.dart';
import 'analytics_screen.dart';
import 'blocked_players_screen.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  Futsal? _selectedFutsal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  Future<void> _loadAllData() async {
    debugPrint('📍 Dashboard: Loading all data');
    final futsalProvider = Provider.of<FutsalProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);

    await futsalProvider.fetchMyFutsals();

    if (futsalProvider.myFutsals.isNotEmpty) {
      // If no selected futsal, select first
      if (_selectedFutsal == null) {
        setState(() {
          _selectedFutsal = futsalProvider.myFutsals.first;
        });
      } else {
        // Find the selected futsal in the updated list
        final updated = futsalProvider.myFutsals.firstWhere(
          (f) => f.id == _selectedFutsal!.id,
          orElse: () => futsalProvider.myFutsals.first,
        );
        setState(() {
          _selectedFutsal = updated;
        });
      }
      await dashboardProvider.loadStatistics(_selectedFutsal!.id);
    }
  }

  Future<void> _showLogoutConfirmation() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await auth.logout();

      if (mounted) {
        Navigator.pop(context);
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Future<void> _navigateToAddFutsal([Futsal? futsalToEdit]) async {
    final shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddFutsalScreen(
          futsalToEdit: futsalToEdit?.toJson(),
        ),
      ),
    );

    if (shouldRefresh == true) {
      _loadAllData();
    }
  }

  void _navigateToCourtManagement(Futsal futsal) {
    if (futsal.status != 'ACTIVE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Courts can only be managed for active futsals'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourtManagementScreen(
          futsalId: futsal.id,
          futsalName: futsal.name,
        ),
      ),
    );
  }

  void _navigateToBookings(Futsal futsal) {
    if (futsal.status != 'ACTIVE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bookings are only available for active futsals'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingsScreen(
          futsalId: futsal.id,
          futsalName: futsal.name,
        ),
      ),
    );
  }

  void _navigateToReviews(Futsal futsal) {
    if (futsal.status != 'ACTIVE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reviews are only available for active futsals'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerReviewsScreen(
          futsalId: futsal.id,
          futsalName: futsal.name,
        ),
      ),
    );
  }

  void _navigateToAnalytics(Futsal futsal) {
    if (futsal.status != 'ACTIVE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Analytics available for active futsals only'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnalyticsScreen(
          futsalId: futsal.id,
          futsalName: futsal.name,
        ),
      ),
    );
  }

  void _navigateToBlockedPlayers(Futsal futsal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlockedPlayersScreen(
          futsalId: futsal.id,
          futsalName: futsal.name,
        ),
      ),
    );
  }

  Future<void> _deleteFutsal(Futsal futsal) async {
    final futsalProvider = Provider.of<FutsalProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final response = await futsalProvider.deleteFutsal(futsal.id);

    if (mounted) Navigator.pop(context);

    if (response['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      _loadAllData();
    } else {
      String errorMessage = response['message'];
      if (errorMessage.contains('bookings') || errorMessage.contains('favorites')) {
        errorMessage = 'Cannot delete this futsal.\n\nIt has existing bookings or favorites.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showDeleteDialog(Futsal futsal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Futsal'),
        content: Text('Are you sure you want to delete "${futsal.name}"?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteFutsal(futsal);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(Futsal futsal) async {
    final futsalProvider = Provider.of<FutsalProvider>(context, listen: false);
    
    final response = await futsalProvider.updateFutsal(futsal.id, {
      'toggleActive': true,
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['message']),
        backgroundColor: response['status'] == 'success' ? Colors.green : Colors.red,
      ),
    );
    
    if (response['status'] == 'success') {
      _loadAllData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final futsalProvider = Provider.of<FutsalProvider>(context);
    final dashboardProvider = Provider.of<DashboardProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Exit Dashboard'),
            content: const Text('Do you want to logout?'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey,
                ),
                child: const Text('STAY'),
              ),
              TextButton(
                onPressed: () async {
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  await auth.logout();
                  if (mounted) {
                    Navigator.pop(ctx, true);
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('LOGOUT'),
              ),
            ],
          ),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Text('My Futsals'),
              if (futsalProvider.myFutsals.length > 1 && _selectedFutsal != null)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _selectedFutsal!.name.length > 15 
                        ? '${_selectedFutsal!.name.substring(0, 12)}...' 
                        : _selectedFutsal!.name,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: Container(),
          flexibleSpace: Container(),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade700,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.business, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text('OWNER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.sports_soccer, color: Colors.white, size: 24),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/player/home');
                },
                tooltip: 'Switch to Player Mode',
              ),
            ),
            if (futsalProvider.myFutsals.length > 1)
              PopupMenuButton<Futsal>(
                icon: const Icon(Icons.swap_vert, color: Colors.white),
                tooltip: 'Switch Futsal',
                onSelected: (futsal) {
                  setState(() {
                    _selectedFutsal = futsal;
                  });
                  dashboardProvider.loadStatistics(futsal.id);
                },
                itemBuilder: (ctx) => futsalProvider.myFutsals.map((futsal) {
                  return PopupMenuItem(
                    value: futsal,
                    child: Text(futsal.name),
                  );
                }).toList(),
              ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadAllData,
              tooltip: 'Refresh all data',
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _showLogoutConfirmation,
              tooltip: 'Logout',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadAllData,
          child: _buildBody(futsalProvider, dashboardProvider),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _navigateToAddFutsal(),
          icon: const Icon(Icons.add),
          label: const Text('Add Futsal'),
          backgroundColor: Colors.green,
          tooltip: 'Add new futsal',
        ),
      ),
    );
  }

  Widget _buildBody(FutsalProvider futsalProvider, DashboardProvider dashboardProvider) {
    if (futsalProvider.isLoading && futsalProvider.myFutsals.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your futsals...'),
          ],
        ),
      );
    }

    if (futsalProvider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                futsalProvider.error!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAllData,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (futsalProvider.myFutsals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No futsals yet',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first futsal',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    if (_selectedFutsal == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatsSection(dashboardProvider),
        const SizedBox(height: 16),
        _buildQuickActions(_selectedFutsal!, futsalProvider),
        const SizedBox(height: 16),
        _buildTodaySchedule(dashboardProvider, futsalProvider),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'My Futsals',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        ...futsalProvider.myFutsals
            .map((futsal) => _buildFutsalCard(futsal))
            .toList(),
      ],
    );
  }

  Widget _buildQuickActions(Futsal currentFutsal, FutsalProvider futsalProvider) {
    final isActive = currentFutsal.status == 'ACTIVE';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (futsalProvider.myFutsals.length > 1)
                Text(
                  'Current: ${currentFutsal.name}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: Icons.sports_soccer,
                  label: 'Courts',
                  onTap: () => _navigateToCourtManagement(currentFutsal),
                  color: Colors.blue,
                  isEnabled: isActive,
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: Icons.calendar_month,
                  label: 'Bookings',
                  onTap: () => _navigateToBookings(currentFutsal),
                  color: Colors.green,
                  isEnabled: isActive,
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: Icons.emoji_events,
                  label: 'Tournaments',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TournamentListScreen(),
                      ),
                    );
                  },
                  color: Colors.purple,
                  isEnabled: true,
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: Icons.bar_chart,
                  label: 'Analytics',
                  onTap: () => _navigateToAnalytics(currentFutsal),
                  color: Colors.orange,
                  isEnabled: isActive,
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: Icons.star,
                  label: 'Reviews',
                  onTap: () => _navigateToReviews(currentFutsal),
                  color: Colors.amber,
                  isEnabled: isActive,
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: Icons.block,
                  label: 'Blocked',
                  onTap: () => _navigateToBlockedPlayers(currentFutsal),
                  color: Colors.red,
                  isEnabled: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required bool isEnabled,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(DashboardProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (provider.error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Could not load stats',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
            TextButton(
              onPressed: () => _loadAllData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.sports_soccer,
                  value: provider.totalCourts.toString(),
                  label: 'Total Courts',
                  color: Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.calendar_today,
                  value: provider.todayBookings.toString(),
                  label: 'Today\'s Bookings',
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.currency_rupee,
                  value: 'रू ${provider.todayRevenue}',
                  label: 'Today\'s Revenue',
                  color: Colors.orange,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.hourglass_empty,
                  value: provider.pendingApprovals.toString(),
                  label: 'Pending Approval',
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySchedule(DashboardProvider provider, FutsalProvider futsalProvider) {
    if (provider.todayBookingsList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.event_busy, color: Colors.grey, size: 32),
              SizedBox(height: 8),
              Text('No bookings today', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Schedule',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  if (_selectedFutsal != null) {
                    _navigateToBookings(_selectedFutsal!);
                  }
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...provider.todayBookingsList.take(3).map((booking) {
            return _buildBookingItem(booking);
          }).toList(),
          if (provider.todayBookingsList.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  '+${provider.todayBookingsList.length - 3} more bookings',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingItem(dynamic booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person, color: Colors.green, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.customerName ?? 'Customer',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Court ${booking.courtNumber} • ${booking.startTime}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: booking.paymentStatus == 'paid' ? Colors.green.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              booking.paymentStatus ?? 'Pending',
              style: TextStyle(
                fontSize: 10,
                color: booking.paymentStatus == 'paid' ? Colors.green.shade700 : Colors.orange.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFutsalCard(Futsal futsal) {
    final isPending = futsal.status == 'PENDING';
    final isDeactivated = futsal.status == 'DEACTIVATED';
    final hasCourts = futsal.courts != null && futsal.courts!.isNotEmpty;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (isPending)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: const BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_empty, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Pending Approval',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
          if (isDeactivated)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.block, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Deactivated',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.sports_soccer, color: Colors.green, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        futsal.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              futsal.address,
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Price varies by court',
                        style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.normal, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _navigateToAddFutsal(futsal);
                    } else if (value == 'delete') {
                      _showDeleteDialog(futsal);
                    } else if (value == 'manage_courts') {
                      _navigateToCourtManagement(futsal);
                    } else if (value == 'view_bookings') {
                      _navigateToBookings(futsal);
                    } else if (value == 'view_reviews') {
                      _navigateToReviews(futsal);
                    } else if (value == 'toggle_active') {
                      _toggleActive(futsal);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'manage_courts',
                      enabled: futsal.status == 'ACTIVE',
                      child: Row(
                        children: [
                          Icon(Icons.sports_soccer, size: 18, color: futsal.status == 'ACTIVE' ? Colors.blue : Colors.grey),
                          SizedBox(width: 8),
                          Text('Manage Courts', style: TextStyle(color: futsal.status == 'ACTIVE' ? Colors.black : Colors.grey)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'view_bookings',
                      enabled: futsal.status == 'ACTIVE',
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month, size: 18, color: futsal.status == 'ACTIVE' ? Colors.green : Colors.grey),
                          SizedBox(width: 8),
                          Text('View Bookings', style: TextStyle(color: futsal.status == 'ACTIVE' ? Colors.black : Colors.grey)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'view_reviews',
                      enabled: futsal.status == 'ACTIVE',
                      child: Row(
                        children: [
                          Icon(Icons.star, size: 18, color: futsal.status == 'ACTIVE' ? Colors.amber : Colors.grey),
                          SizedBox(width: 8),
                          Text('View Reviews', style: TextStyle(color: futsal.status == 'ACTIVE' ? Colors.black : Colors.grey)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      enabled: futsal.status == 'PENDING' && !hasCourts,
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: futsal.status == 'PENDING' && !hasCourts ? Colors.red : Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: futsal.status == 'PENDING' && !hasCourts ? Colors.red : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle_active',
                      enabled: futsal.status == 'ACTIVE' || futsal.status == 'DEACTIVATED',
                      child: Row(
                        children: [
                          Icon(
                            futsal.status == 'ACTIVE' ? Icons.visibility_off : Icons.visibility,
                            size: 18,
                            color: futsal.status == 'ACTIVE' ? Colors.orange : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(futsal.status == 'ACTIVE' ? 'Deactivate' : 'Activate'),
                        ],
                      ),
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
}