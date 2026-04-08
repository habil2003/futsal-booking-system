import 'package:flutter/material.dart';
import '../../../../models/booking.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onCheckIn;
  final VoidCallback onMarkPaid;
  final VoidCallback onCancel;
  final VoidCallback onBlock;
  final VoidCallback onUnblock;
  final bool isBlocked;

  const BookingCard({
    super.key,
    required this.booking,
    required this.onCheckIn,
    required this.onMarkPaid,
    required this.onCancel,
    required this.onBlock,
    required this.onUnblock,
    required this.isBlocked,
  });

  Color _getStatusColor() {
    if (booking.isCancelled) return Colors.red;
    if (booking.isCompleted) return Colors.green;
    if (booking.isCheckedIn) return Colors.blue;
    if (booking.isPending) return Colors.orange;
    return Colors.grey;
  }

  IconData _getStatusIcon() {
    if (booking.isCancelled) return Icons.cancel;
    if (booking.isCompleted) return Icons.check_circle;
    if (booking.isCheckedIn) return Icons.login;
    if (booking.isPending) return Icons.hourglass_empty;
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(),
                  size: 14,
                  color: _getStatusColor(),
                ),
                const SizedBox(width: 4),
                Text(
                  booking.statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!booking.isCheckedIn && !booking.isCancelled && booking.isToday)
                  Row(
                    children: [
                      if (!booking.isPaid)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'UNPAID',
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'NOT CHECKED IN',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                SizedBox(
                  height: 28,
                  width: 28,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert, size: 16, color: Colors.grey),
                    onSelected: (value) {
                      if (value == 'block') onBlock();
                      if (value == 'unblock') onUnblock();
                    },
                    itemBuilder: (_) => [
                      if (!isBlocked)
                        const PopupMenuItem(
                          value: 'block',
                          child: Row(
                            children: [
                              Icon(Icons.block, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text('Block Player'),
                            ],
                          ),
                        ),
                      if (isBlocked)
                        const PopupMenuItem(
                          value: 'unblock',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 18),
                              SizedBox(width: 8),
                              Text('Unblock Player'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time column
                Container(
                  width: 60,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        booking.startTime,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Text('to', style: TextStyle(fontSize: 8, color: Colors.grey)),
                      Text(
                        booking.endTime,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Customer details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.customerName ?? 'Guest Customer',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (booking.customerPhone != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              booking.customerPhone!,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Court ${booking.courtNumber}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              booking.duration,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Price and actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'रू ${booking.totalAmount}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: booking.isPaid ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Not checked in yet
                    if (!booking.isCheckedIn && !booking.isCancelled && !booking.isCompleted)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.login, color: Colors.green, size: 20),
                            onPressed: onCheckIn,
                            tooltip: 'Check In',
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                            onPressed: onCancel,
                            tooltip: 'Cancel',
                          ),
                        ],
                      ),

                    // Checked in - Show only "Mark as Paid" button (Complete removed)
                    if (booking.isCheckedIn && !booking.isCompleted && !booking.isCancelled)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.payments, color: Colors.orange, size: 20),
                            onPressed: onMarkPaid,
                            tooltip: 'Mark as Paid',
                          ),
                        ],
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