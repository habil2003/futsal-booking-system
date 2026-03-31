// lib/widgets/futsal/slots_grid_widget.dart
import 'package:flutter/material.dart';
import '../../utils/futsal_constants.dart';

class SlotsGridWidget extends StatelessWidget {
  final List<Map<String, dynamic>> slots;
  final Map<String, dynamic>? selectedSlot;
  final bool isProcessing;
  final Function(Map<String, dynamic>) onSlotSelected;
  final Function(Map<String, dynamic>) isSlotPeak;
  final Function(Map<String, dynamic>) isSlotBooked;
  final Function(Map<String, dynamic>) isSlotAvailable;
  final Function(Map<String, dynamic>) isSlotLockedBySystem;
  final Function(int) isSlotTemporarilyLocked;
  final Function(Map<String, dynamic>) getCourtNumber;

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
    if (slots.isEmpty) return const SizedBox.shrink();

    // Group slots by court number
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final slot in slots) {
      dynamic courtValue;

      if (slot.containsKey('court')) {
        courtValue = slot['court'];
      } else if (slot.containsKey('courtNumber')) {
        courtValue = slot['courtNumber'];
      } else if (slot.containsKey('court_no')) {
        courtValue = slot['court_no'];
      } else if (slot.containsKey('courtId')) {
        courtValue = slot['courtId'];
      } else if (slot.containsKey('court_id')) {
        courtValue = slot['court_id'];
      } else {
        courtValue = '1';
      }

      final court = 'Court $courtValue';
      grouped.putIfAbsent(court, () => []);
      grouped[court]!.add(slot);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCourtHeader(entry.key, entry.value.length),
            const SizedBox(height: 8),
            _buildCourtSlotsGrid(entry.value),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCourtHeader(String courtName, int slotCount) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade700,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            courtName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$slotCount slots',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildCourtSlotsGrid(List<Map<String, dynamic>> slots) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: FutsalConstants.slotGridCrossAxisCount,
        childAspectRatio: FutsalConstants.slotAspectRatio,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) => _buildSlotCard(slots[index]),
    );
  }

  Widget _buildSlotCard(Map<String, dynamic> slot) {
    final slotId = slot['id'] as int? ?? 0;
    final isAvailable = isSlotAvailable(slot);
    final isBooked = isSlotBooked(slot);
    final isSystemLocked = isSlotLockedBySystem(slot);
    final isTemporarilyLocked = isSlotTemporarilyLocked(slotId);
    final isPeak = isSlotPeak(slot);
    final isSelected = selectedSlot != null && selectedSlot!['id'] == slotId;
    final canSelect = isAvailable && !isTemporarilyLocked && !isSystemLocked;

    Color backgroundColor;
    Color textColor;
    Color borderColor;
    String? statusText;

    if (isSelected) {
      backgroundColor = Colors.green;
      textColor = Colors.white;
      borderColor = Colors.green;
    } else if (isBooked) {
      backgroundColor = Colors.grey.shade300;
      textColor = Colors.grey.shade700;
      borderColor = Colors.grey.shade400;
      statusText = 'BOOKED';
    } else if (isSystemLocked || isTemporarilyLocked) {
      backgroundColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
      borderColor = Colors.orange.shade300;
      statusText = 'LOCKED';
    } else if (isAvailable && isPeak) {
      backgroundColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      borderColor = Colors.red.shade300;
    } else if (isAvailable) {
      backgroundColor = Colors.white;
      textColor = Colors.green.shade700;
      borderColor = Colors.green.shade300;
    } else {
      backgroundColor = Colors.grey.shade100;
      textColor = Colors.grey;
      borderColor = Colors.grey.shade300;
    }

    return GestureDetector(
      onTap: canSelect && !isProcessing ? () => onSlotSelected(slot) : null,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isPeak && isAvailable && !isSelected)
              const Text('🔥', style: TextStyle(fontSize: 10)),
            Text(
              slot['startTime'] ?? '00:00',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              getCourtNumber(slot),
              style: TextStyle(
                fontSize: 10,
                color: textColor.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'रू ${slot['price'] ?? 0}',
              style: TextStyle(
                fontSize: 11,
                color: textColor,
              ),
            ),
            if (statusText != null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: isBooked ? Colors.grey.shade400 : Colors.orange.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 8,
                    color: isBooked ? Colors.white : Colors.orange.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}