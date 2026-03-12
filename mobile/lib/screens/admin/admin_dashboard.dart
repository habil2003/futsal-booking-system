import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/admin/futsal_details_modal.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        centerTitle: true,
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (adminProvider.error != null) {
            return Center(
              child: Text(
                adminProvider.error!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => adminProvider.loadDashboardStats(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Dashboard Statistics",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Stats Cards
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _statCard(
                          "Total Users",
                          adminProvider.totalUsers.toString(),
                          Icons.people,
                          Colors.blue),
                      _statCard(
                          "Total Futsals",
                          adminProvider.totalFutsals.toString(),
                          Icons.sports_soccer,
                          Colors.green),
                      _statCard(
                          "Pending Approvals",
                          adminProvider.pendingApprovals.toString(),
                          Icons.pending_actions,
                          Colors.orange),
                      _statCard(
                          "Today's Bookings",
                          adminProvider.todayBookings.toString(),
                          Icons.book_online,
                          Colors.purple),
                      _statCard(
                          "Total Revenue",
                          "Rs ${adminProvider.totalRevenue.toStringAsFixed(0)}",
                          Icons.attach_money,
                          Colors.teal),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Quick Actions
                  const Text("Quick Actions",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _actionButton(
                          "Pending Futsals", Icons.approval, Colors.orange, () {
                        Navigator.pushNamed(context, "/admin/futsal-approvals");
                      }),
                      const SizedBox(width: 12),
                      _actionButton(
                          "Manage Users", Icons.people_alt, Colors.blue, () {
                        Navigator.pushNamed(context, "/admin/users");
                      }),
                      const SizedBox(width: 12),
                      _actionButton(
                          "All Futsals", Icons.sports_soccer, Colors.green, () {
                        Navigator.pushNamed(context, "/admin/futsals");
                      }),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Recent Activities
                  const Text("Recent Activities",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (adminProvider.recentActivities.isEmpty)
                    const Text("No recent activities"),
                  ...adminProvider.recentActivities.map((activity) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.notifications),
                        title: Text(activity['user']?['fullName'] ?? 'User'),
                        subtitle:
                            Text("Booking on ${activity['bookingDate'] ?? ''}"),
                      ),
                    );
                  }),

                  const SizedBox(height: 30),

                  // Pending Futsals Preview
                  const Text("Pending Futsal Approvals",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: adminProvider.pendingFutsals.length,
                    itemBuilder: (_, index) {
                      final futsal = adminProvider.pendingFutsals[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        child: ListTile(
                          title: Text(futsal['name'] ?? 'Futsal'),
                          subtitle:
                              Text(futsal['owner']?['fullName'] ?? 'Owner'),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => FutsalDetailsModal(
                                futsal: futsal,
                                onApprove: () async {
                                  final result = await adminProvider
                                      .approveFutsal(futsal['id']);
                                  if (result['status'] == 'success') {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(result['message'])),
                                    );
                                  }
                                  return result; // ✅ Always return Map<String, dynamic>
                                },
                                onReject: (reason) async {
                                  final result = await adminProvider
                                      .rejectFutsal(futsal['id'], reason);
                                  if (result['status'] == 'success') {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(result['message'])),
                                    );
                                  }
                                  return result; // ✅ Always return Map<String, dynamic>
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return SizedBox(
      width: 160,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(title,
                  style: const TextStyle(fontSize: 14, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 90,
          decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, color: color))
          ]),
        ),
      ),
    );
  }
}
