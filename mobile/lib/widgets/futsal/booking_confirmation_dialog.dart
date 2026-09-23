import 'package:flutter/material.dart';
import '../../utils/date_formatter.dart';
import '../../utils/futsal_constants.dart';
import '../../utils/app_colors.dart';

class BookingConfirmationDialog extends StatefulWidget {
  final Map<String, dynamic> selectedSlot;
  final DateTime selectedDate;
  final String groundName;
  final bool isProcessing;
  final Function(int) onConfirm;
  final VoidCallback onCancel;

  const BookingConfirmationDialog({
    super.key,
    required this.selectedSlot,
    required this.selectedDate,
    required this.groundName,
    required this.isProcessing,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<BookingConfirmationDialog> createState() =>
      _BookingConfirmationDialogState();
}

class _BookingConfirmationDialogState extends State<BookingConfirmationDialog> {
  int _selectedDuration = 1;

  String _getCourtNumber() {
    final slot = widget.selectedSlot;
    if (slot.containsKey('court')) {
      return 'Court ${slot['court']}';
    } else if (slot.containsKey('courtNumber')) {
      return 'Court ${slot['courtNumber']}';
    } else if (slot.containsKey('court_no')) {
      return 'Court ${slot['court_no']}';
    } else {
      return 'Court 1';
    }
  }

  bool _isSlotPeak() {
    try {
      final timeStr = widget.selectedSlot['startTime'] as String? ?? '00:00';
      final hour = int.tryParse(timeStr.split(':').first) ?? 0;
      return FutsalConstants.isPeakHour(hour, widget.selectedDate.weekday);
    } catch (e) {
      return false;
    }
  }

  num _getSlotPrice() {
    return num.tryParse(widget.selectedSlot['price']?.toString() ?? '0') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final price = _getSlotPrice();
    final isPeak = _isSlotPeak();
    final total = price * _selectedDuration;
    final dateStr = DateFormatter.formatDateFull(widget.selectedDate);
    final timeStr = widget.selectedSlot['startTime'] ?? '';
    final courtStr = _getCourtNumber();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 24), 
      title: const Padding(
        padding: EdgeInsets.only(bottom: 8.0),
        child: Text(
        'Confirm Booking',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.onBackground,
          fontSize: 22, 
        ),
      ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Ground Summary Box ──
            Container(
              padding: const EdgeInsets.all(18), // increased from 14
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(Icons.sports_soccer_rounded, widget.groundName,
                      fontWeight: FontWeight.bold, fontSize: 16),
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.calendar_today_rounded, dateStr,
                      fontSize: 16),
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.access_time_rounded, timeStr,
                      fontSize: 16),
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.grid_view_rounded, courtStr,
                      fontSize: 16),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // ── Pricing Box ──
            Container(
              padding: const EdgeInsets.all(18), // increased from 14
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price per hour row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          children: [
                            const Flexible(
                              child: Text('Price per hour',
                                  style: TextStyle(
                                      color: AppColors.secondaryText,
                                      fontSize: 16)),
                            ),
                            if (isPeak) ...[
                              const SizedBox(width: 8),
                              _buildPeakChip(),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'रू ${price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isPeak
                              ? AppColors.accentCoral
                              : AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Duration selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text('Duration (hours)',
                            style: TextStyle(
                                color: AppColors.secondaryText, fontSize: 16)),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildDurationButton(
                            icon: Icons.remove,
                            size: 40,
                            onTap: _selectedDuration > 1
                                ? () => setState(() => _selectedDuration--)
                                : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '$_selectedDuration',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onBackground,
                              ),
                            ),
                          ),
                          _buildDurationButton(
                            icon: Icons.add,
                            size: 40,
                            onTap: _selectedDuration <
                                    FutsalConstants.maxBookingHours
                                ? () => setState(() => _selectedDuration++)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 16),
                  // Total row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: AppColors.onBackground,
                        ),
                      ),
                      Text(
                        'रू ${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.isProcessing ? null : widget.onCancel,
          child: const Text('Cancel',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 16)),
        ),
        ElevatedButton(
          onPressed: widget.isProcessing
              ? null
              : () => widget.onConfirm(_selectedDuration),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          ),
          child: const Text('Confirm Booking', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }

// Updated helpers
  Widget _buildInfoRow(IconData icon, String text,
      {FontWeight fontWeight = FontWeight.normal, double fontSize = 16}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary), // larger icon
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: AppColors.onBackground,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeakChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accentCoral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.accentCoral.withValues(alpha: 0.3)),
      ),
      child: const Text(
        '🔥 Peak',
        style: TextStyle(
            fontSize: 12,
            color: AppColors.accentCoral,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDurationButton(
      {required IconData icon, double size = 32, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.divider,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: size * 0.55,
            color: onTap != null ? AppColors.primary : AppColors.secondaryText),
      ),
    );
  }
}
