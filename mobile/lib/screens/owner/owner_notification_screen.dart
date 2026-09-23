import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/owner/owner_header_actions.dart';

class OwnerNotificationScreen extends StatefulWidget {
  const OwnerNotificationScreen({super.key, this.onOpenDrawer});

  final VoidCallback? onOpenDrawer;

  @override
  State<OwnerNotificationScreen> createState() => _OwnerNotificationScreenState();
}

class _OwnerNotificationScreenState extends State<OwnerNotificationScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await ApiService.getList('notifications/my');
      if (!mounted) return;
      setState(() {
        _notifications = response.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
      // 🔥 Automatically mark all as read after loading
      _markAllAsRead();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading notifications: $e')),
      );
    }
  }

  Future<void> _markAsRead(int id) async {
    try {
      await ApiService.patch('notifications/$id/read', {});
      if (!mounted) return;
      setState(() {
        final idx = _notifications.indexWhere((n) => n['id'] == id);
        if (idx != -1) {
          _notifications[idx]['isRead'] = true;
        }
      });
    } catch (e) {
      debugPrint('Mark as read error: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await ApiService.patch('notifications/read-all', {});
      if (!mounted) return;
      setState(() {
        for (var n in _notifications) {
          n['isRead'] = true;
        }
      });
    } catch (e) {
      debugPrint('Mark all read error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: widget.onOpenDrawer != null
            ? OwnerMenuButton(
                onPressed: widget.onOpenDrawer!,
                color: AppColors.onBackground,
              )
            : null,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.onBackground,
        elevation: 0.5,
        // No longer need the "Mark all read" button
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none_rounded,
                          size: 64, color: AppColors.secondaryText),
                      SizedBox(height: 12),
                      Text('No notifications yet',
                          style: TextStyle(color: AppColors.secondaryText)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      return _buildNotificationCard(n);
                    },
                  ),
                ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['isRead'] == true;
    final title = notification['title'] ?? '';
    final message = notification['message'] ?? '';
    final type = notification['type'] ?? '';
    final createdAt = notification['createdAt'] ?? '';

    IconData icon;
    Color iconColor;
    switch (type) {
      case 'owner_new_booking':
      case 'booking_confirmed':
      case 'booking_completed':
        icon = Icons.book_online_rounded;
        iconColor = AppColors.primary;
        break;
      case 'owner_booking_cancelled':
      case 'booking_cancelled':
        icon = Icons.cancel_rounded;
        iconColor = AppColors.accentCoral;
        break;
      case 'owner_blocked_player':
      case 'player_blocked':
        icon = Icons.block_rounded;
        iconColor = Colors.orange;
        break;
      case 'futsal_approved':
        icon = Icons.check_circle_rounded;
        iconColor = AppColors.primary;
        break;
      case 'futsal_rejected':
        icon = Icons.cancel_rounded;
        iconColor = AppColors.accentCoral;
        break;
      default:
        icon = Icons.notifications_rounded;
        iconColor = AppColors.secondaryText;
    }

    return GestureDetector(
      onTap: () {
        if (!isRead) _markAsRead(notification['id']);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRead ? AppColors.divider : AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                      color: AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.secondaryText.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}