import 'package:flutter/material.dart';
import '../../../../models/futsal.dart';

class QuickActions extends StatelessWidget {
  final Futsal currentFutsal;
  final int futsalCount;
  final VoidCallback onCourts;
  final VoidCallback onBookings;
  final VoidCallback onTournaments;
  final VoidCallback onAnalytics;
  final VoidCallback onReviews;
  final VoidCallback onBlocked;

  const QuickActions({
    super.key,
    required this.currentFutsal,
    required this.futsalCount,
    required this.onCourts,
    required this.onBookings,
    required this.onTournaments,
    required this.onAnalytics,
    required this.onReviews,
    required this.onBlocked,
  });

  @override
  Widget build(BuildContext context) {
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
              if (futsalCount > 1)
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
                  onTap: onCourts,
                  color: Colors.blue,
                  isEnabled: isActive,
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: Icons.calendar_month,
                  label: 'Bookings',
                  onTap: onBookings,
                  color: Colors.green,
                  isEnabled: isActive,
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: Icons.emoji_events,
                  label: 'Tournaments',
                  onTap: onTournaments,
                  color: Colors.purple,
                  isEnabled: true,
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: Icons.bar_chart,
                  label: 'Analytics',
                  onTap: onAnalytics,
                  color: Colors.orange,
                  isEnabled: isActive,
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: Icons.star,
                  label: 'Reviews',
                  onTap: onReviews,
                  color: Colors.amber,
                  isEnabled: isActive,
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: Icons.block,
                  label: 'Blocked',
                  onTap: onBlocked,
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
}