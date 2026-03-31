import 'package:flutter/material.dart';
import '../../../../models/futsal.dart';

class DashboardFutsalCard extends StatelessWidget {
  final Futsal futsal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onManageCourts;
  final VoidCallback onViewBookings;
  final VoidCallback onViewReviews;
  final VoidCallback onToggleActive;

  const DashboardFutsalCard({
    super.key,
    required this.futsal,
    required this.onEdit,
    required this.onDelete,
    required this.onManageCourts,
    required this.onViewBookings,
    required this.onViewReviews,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
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
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                      case 'manage_courts':
                        onManageCourts();
                        break;
                      case 'view_bookings':
                        onViewBookings();
                        break;
                      case 'view_reviews':
                        onViewReviews();
                        break;
                      case 'toggle_active':
                        onToggleActive();
                        break;
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