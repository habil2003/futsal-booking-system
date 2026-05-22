import 'package:flutter/material.dart';
import 'slot_helpers.dart';
import '../../../../utils/app_colors.dart';            

class BookingBar extends StatelessWidget {
  final Map<String, dynamic>? selectedSlot;
  final DateTime? selectedDate;                       
  final bool isProcessing;
  final VoidCallback onProceedToBooking;

  const BookingBar({
    super.key,
    required this.selectedSlot,
    required this.selectedDate,
    required this.isProcessing,
    required this.onProceedToBooking,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedSlot == null || selectedDate == null) return const SizedBox.shrink();

    final price = SlotHelpers.getSlotPrice(selectedSlot!);
    final time = selectedSlot!['startTime'] ?? '';
    final court = SlotHelpers.getCourtNumber(selectedSlot!);

    // Format the selected date, e.g. "24 Nov 2025"
    final dateStr = '${selectedDate!.day} ${_monthAbbr(selectedDate!.month)} ${selectedDate!.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Two summary boxes ──
            Row(
              children: [
                Expanded(
                  child: _buildInfoBox('Date', dateStr, Icons.calendar_today_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoBox('Court', court, Icons.sports_soccer),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ── Time & Price row ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${selectedSlot!['startTime']} – ${selectedSlot!['endTime'] ?? selectedSlot!['startTime']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'रू $price',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ── Book Now button (full width) ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isProcessing ? null : onProceedToBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isProcessing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Book Now',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.onBackground,
            ),
          ),
        ],
      ),
    );
  }

  String _monthAbbr(int month) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return months[month - 1];
  }
}