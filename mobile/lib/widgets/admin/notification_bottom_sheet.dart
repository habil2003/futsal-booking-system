import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class NotificationBottomSheet extends StatefulWidget {
  const NotificationBottomSheet({super.key});

  @override
  State<NotificationBottomSheet> createState() => _NotificationBottomSheetState();
}

class _NotificationBottomSheetState extends State<NotificationBottomSheet> {
  @override
  void initState() {
    super.initState();
    // Mark notifications as read when opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      adminProvider.markNotificationsAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, _) {
        final activities = adminProvider.recentActivities;
        
        return Container(
          height: 500,
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              
              // Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active, color: Colors.green),
                    SizedBox(width: 12),
                    Text(
                      'Notifications',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(),
              
              // Notifications list
              Expanded(
                child: activities.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: activities.length,
                        itemBuilder: (ctx, index) {
                          final activity = activities[index];
                          return _buildNotificationItem(activity, index, activities.length);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> activity, int index, int totalCount) {
    final name = activity['name'] ?? 
                 activity['user']?['fullName'] ?? 
                 'System';
    final category = activity['category'] ?? activity['type'] ?? 'Activity';
    final description = activity['description'] ?? '';
    final createdAt = activity['createdAt'] ?? '';
    
    IconData icon;
    Color color;
    
    switch (category) {
      case 'Booking':
        icon = Icons.book_online;
        color = Colors.blue;
        break;
      case 'User Added':
        icon = Icons.person_add;
        color = Colors.green;
        break;
      case 'User Login':
        icon = Icons.login;
        color = Colors.teal;
        break;
      case 'User Register':
        icon = Icons.app_registration;
        color = Colors.purple;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }
    
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            description.isNotEmpty ? description : '$category: $name',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
          subtitle: Text(
            _formatRelativeTime(createdAt),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          trailing: index < 3
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: () {
            // Handle notification tap
            Navigator.pop(context);
          },
        ),
        if (index != totalCount - 1)
          Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
      ],
    );
  }

  String _formatRelativeTime(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays > 7) {
        return '${date.day}/${date.month}/${date.year}';
      }
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (e) {
      return 'Unknown';
    }
  }
}