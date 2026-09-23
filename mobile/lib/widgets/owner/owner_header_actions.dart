import 'package:flutter/material.dart';
import '../../screens/owner/owner_notification_screen.dart';
import '../../services/api_service.dart';

class OwnerMenuButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color? color;

  const OwnerMenuButton({super.key, required this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.menu, color: color ?? Colors.white),
      tooltip: 'Menu',
      onPressed: onPressed,
    );
  }
}

class OwnerHeaderActions extends StatefulWidget {
  const OwnerHeaderActions({super.key});

  @override
  State<OwnerHeaderActions> createState() => _OwnerHeaderActionsState();
}

class _OwnerHeaderActionsState extends State<OwnerHeaderActions> {
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final response = await ApiService.get('notifications/unread-count');
      if (mounted && response['status'] == 'success') {
        setState(() => _unread = response['unreadCount'] ?? 0);
      }
    } catch (_) {
      // silently ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
              Text('OWNER',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ],
          ),
        ),
        IconButton(
          icon: _unread > 0
              ? Badge(
                  label: Text('$_unread',
                      style: const TextStyle(fontSize: 10, color: Colors.white)),
                  child: const Icon(Icons.notifications_outlined),
                )
              : const Icon(Icons.notifications_outlined),
          color: Colors.white,
          tooltip: 'Notifications',
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OwnerNotificationScreen()),
            );
            _loadUnreadCount();
          },
        ),
      ],
    );
  }
}