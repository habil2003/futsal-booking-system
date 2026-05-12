import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class RecentActivityScreen extends StatelessWidget {
  const RecentActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final activities = adminProvider.recentActivities;

        if (activities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text('No recent activity', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            final name = activity['name'] ?? activity['user']?['fullName'] ?? 'System';
            final email = activity['email'] ?? activity['user']?['email'] ?? '';
            final phone = activity['phone'] ?? activity['user']?['phoneNumber'] ?? '';
            final category = activity['category'] ?? activity['type'] ?? 'Activity';
            final status = activity['status'] ?? 'completed';
            final description = activity['description'] ?? '';
            final createdAt = activity['createdAt'] ?? '';

            final categoryColor = category == 'Booking' ? Colors.blue : category == 'User Added' ? Colors.green : category == 'User Login' ? Colors.teal : Colors.purple;
            final statusColor = status == 'completed' ? Colors.green.shade700 : status == 'pending' ? Colors.orange.shade700 : status == 'registered' ? Colors.blue.shade700 : status == 'cancelled' ? Colors.red.shade700 : Colors.grey.shade700;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                        Text(_formatRelativeTime(createdAt), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (email.isNotEmpty) Row(children: [Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade600), const SizedBox(width: 6), Text(email, style: TextStyle(fontSize: 13, color: Colors.grey.shade700))]),
                    if (phone.isNotEmpty) Row(children: [Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade600), const SizedBox(width: 6), Text(phone, style: TextStyle(fontSize: 13, color: Colors.grey.shade700))]),
                    if (description.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8, bottom: 4), child: Text(description, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: categoryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: categoryColor.withOpacity(0.3))), child: Text(category, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: categoryColor))),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withOpacity(0.3))), child: Text(status.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor))),
                    ]),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatRelativeTime(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays > 7) return '${date.day}/${date.month}/${date.year}';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (e) {
      return 'Unknown';
    }
  }
}