import 'package:flutter/material.dart';
import 'slot_helpers.dart';

class SlotsGridWidget extends StatelessWidget {
  final List<Map<String, dynamic>> slots;
  final Map<String, dynamic>? selectedSlot;
  final bool isProcessing;
  final Function(Map<String, dynamic>) onSlotSelected;
  final bool Function(Map<String, dynamic>) isSlotPeak;
  final bool Function(Map<String, dynamic>) isSlotBooked;
  final bool Function(Map<String, dynamic>) isSlotAvailable;
  final bool Function(Map<String, dynamic>) isSlotLockedBySystem;
  final bool Function(int) isSlotTemporarilyLocked;
  final String Function(Map<String, dynamic>) getCourtNumber;

  const SlotsGridWidget({
    super.key,
    required this.slots,
    required this.selectedSlot,
    required this.isProcessing,
    required this.onSlotSelected,
    required this.isSlotPeak,
    required this.isSlotBooked,
    required this.isSlotAvailable,
    required this.isSlotLockedBySystem,
    required this.isSlotTemporarilyLocked,
    required this.getCourtNumber,
  });

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return const Center(child: Text('No slots available'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final isSelected = selectedSlot != null && selectedSlot!['id'] == slot['id'];
        final available = isSlotAvailable(slot) && !isSlotTemporarilyLocked(slot['id'] as int);
        final peak = isSlotPeak(slot);
        final locked = isSlotLockedBySystem(slot) || isSlotTemporarilyLocked(slot['id'] as int);
        final booked = isSlotBooked(slot);

        Color cardColor;
        String statusText;
        if (booked) {
          cardColor = Colors.grey.shade300;
          statusText = 'Booked';
        } else if (locked) {
          cardColor = Colors.orange.shade100;
          statusText = 'Locked';
        } else if (peak) {
          cardColor = Colors.red.shade50;
          statusText = 'Peak';
        } else {
          cardColor = Colors.green.shade50;
          statusText = 'Available';
        }

        return GestureDetector(
          onTap: (isProcessing || !available) ? null : () => onSlotSelected(slot),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? Colors.green.shade700 : cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.green.shade800 : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 4))]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    slot['startTime'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'रू ${SlotHelpers.getSlotPrice(slot)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white70 : Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}