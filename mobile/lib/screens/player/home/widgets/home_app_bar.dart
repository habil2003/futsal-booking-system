import 'package:flutter/material.dart';
import '../../../../models/user.dart';
import '../../../../widgets/profile/profile_dialog.dart';

class HomeAppBar extends StatelessWidget {
  final User user;
  final bool isOwner;
  final bool showFilters;
  final VoidCallback onFilterToggle;
  final VoidCallback onSwitchToOwner;

  const HomeAppBar({
    super.key,
    required this.user,
    required this.isOwner,
    required this.showFilters,
    required this.onFilterToggle,
    required this.onSwitchToOwner,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: Colors.green,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green, Colors.green.shade700],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Hello, ${user.fullName.split(' ')[0]}! 👋',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ready to play today?',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        // Player Mode Indicator
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.white),
              SizedBox(width: 4),
              Text('Player', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),

        // Switch to Owner Mode
        if (isOwner)
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.business, color: Colors.white),
              onPressed: onSwitchToOwner,
              tooltip: 'Switch to Owner Mode',
            ),
          ),

        // Filter Toggle
        IconButton(
          icon: Icon(
            showFilters ? Icons.filter_list : Icons.filter_list_outlined,
            color: Colors.white,
          ),
          onPressed: onFilterToggle,
        ),

        // Notification Icon
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () {},
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),

        // Profile Icon
        GestureDetector(
          onTap: () => ProfileDialog.show(context, user),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                user.fullName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}