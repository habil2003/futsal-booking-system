// lib/screens/player/futsal_details/widgets/slots_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

import '../../../../models/futsal.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/booking_provider.dart';
import '../../../../providers/futsal_provider.dart';
import '../../../../utils/date_formatter.dart';
import '../../../../services/payment_service.dart';
import '../../../../services/api_service.dart';
import '../../../../utils/futsal_constants.dart';
import '../../../../screens/player/payment_webview_screen.dart';
import '../../../../widgets/futsal/booking_confirmation_dialog.dart';
import '../../../../widgets/futsal/slots_grid_widget.dart';
import 'slot_helpers.dart';
import 'booking_bar.dart';

class SlotsTab extends StatefulWidget {
  final Futsal futsal;
  const SlotsTab({super.key, required this.futsal});

  @override
  State<SlotsTab> createState() => _SlotsTabState();
}

class _SlotsTabState extends State<SlotsTab> with WidgetsBindingObserver {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _slots = [];
  bool _isLoadingSlots = false;
  String? _slotsError;
  Map<String, dynamic>? _selectedSlot;

  final Map<int, DateTime> _temporaryLocks = {};
  Map<String, dynamic>? _tempLockedSlot;
  Timer? _lockCleanupTimer;
  bool _isProcessing = false;

  int? _tempSelectedDuration;
  int? _tempBookingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startLockCleanupTimer();
    _fetchSlots();
  }

  void _startLockCleanupTimer() {
    _lockCleanupTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      _cleanupExpiredLocks();
    });
  }

  void _cleanupExpiredLocks() {
    final now = DateTime.now();
    setState(() {
      _temporaryLocks.removeWhere((_, expiry) => expiry.isBefore(now));
    });
  }

  String _formatToAmPm(String time24) {
    final parts = time24.split(':');
    if (parts.length != 2) return time24;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return time24;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    if (minute == 0) return '$hour12 $period';
    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _fetchSlots() async {
    if (!mounted) return;

    setState(() {
      _isLoadingSlots = true;
      _slotsError = null;
      _selectedSlot = null;
    });

    try {
      final futsalProvider =
          Provider.of<FutsalProvider>(context, listen: false);
      final fetchedSlots = await futsalProvider
          .fetchFutsalSlots(widget.futsal.id, _selectedDate)
          .timeout(FutsalConstants.apiTimeout,
              onTimeout: () => throw TimeoutException('Request timed out'));

      if (!mounted) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final isToday = _selectedDate.year == today.year &&
          _selectedDate.month == today.month &&
          _selectedDate.day == today.day;

      List<Map<String, dynamic>> filteredSlots = fetchedSlots;
      if (isToday) {
        final currentTime = TimeOfDay.now();
        filteredSlots = fetchedSlots.where((slot) {
          final startTimeStr = slot['startTime'] as String?;
          if (startTimeStr == null) return false;
          final parts = startTimeStr.split(':');
          if (parts.length != 2) return false;
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          if (hour == null || minute == null) return false;
          final slotTime = TimeOfDay(hour: hour, minute: minute);
          return slotTime.hour > currentTime.hour ||
              (slotTime.hour == currentTime.hour &&
                  slotTime.minute >= currentTime.minute);
        }).toList();
      }

      final List<Map<String, dynamic>> enrichedSlots =
          filteredSlots.map((slot) {
        return {
          ...slot,
          'startTime': _formatToAmPm(slot['startTime'] ?? ''),
          'endTime': _formatToAmPm(slot['endTime'] ?? ''),
        };
      }).toList();

      setState(() {
        _slots = enrichedSlots;
        _isLoadingSlots = false;
      });
    } on TimeoutException catch (_) {
      if (!mounted) return;
      setState(() {
        _slotsError = 'Connection timeout. Please try again.';
        _isLoadingSlots = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _slotsError = 'Failed to load slots: ${e.toString()}';
        _isLoadingSlots = false;
      });
    }
  }

  void _selectSlot(Map<String, dynamic> slot) {
    if (_isProcessing) return;
    setState(() {
      if (_selectedSlot != null && _selectedSlot!['id'] == slot['id']) {
        _selectedSlot = null;
      } else {
        _selectedSlot = slot;
      }
    });
  }

  Future<void> _selectDate() async {
    if (_isProcessing) return;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate && mounted) {
      setState(() => _selectedDate = picked);
      await _fetchSlots();
      _showSnackBar(
          'Showing slots for ${DateFormatter.formatDateShort(picked)}');
    }
  }

  Future<bool> _checkIfBlocked() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (!auth.isAuthenticated) return false;
      final response = await ApiService.get(
          'owner/blocks/check/${auth.user!.id}?futsalId=${widget.futsal.id}');
      if (response['isBlocked'] == true) {
        _showBlockedDialog(response['reason']);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Check block error: $e');
      return false;
    }
  }

  void _showBlockedDialog(String? reason) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('You are Blocked'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text('You have been blocked from booking at this futsal.',
                textAlign: TextAlign.center),
            if (reason != null && reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Reason: $reason',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center),
            ],
            const SizedBox(height: 8),
            const Text('Please contact the futsal owner for more information.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _proceedToBooking() async {
    if (_selectedSlot == null || _isProcessing) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      _showSnackBar('Please log in to make a booking', isError: true);
      return;
    }
    final isBlocked = await _checkIfBlocked();
    if (isBlocked) return;
    _showConfirmationDialog();
  }

  void _showConfirmationDialog() {
    if (_selectedSlot == null || _isProcessing) return;
    showDialog(
      context: context,
      barrierDismissible: !_isProcessing,
      builder: (dialogContext) => BookingConfirmationDialog(
        selectedSlot: _selectedSlot!,
        selectedDate: _selectedDate,
        groundName: widget.futsal.name,
        isProcessing: _isProcessing,
        onConfirm: (duration) {
          Navigator.pop(dialogContext);
          _tempSelectedDuration = duration;
          _lockSlotAndShowPayment();
        },
        onCancel: () => Navigator.pop(dialogContext),
      ),
    );
  }

  Future<void> _lockSlotAndShowPayment() async {
    if (_selectedSlot == null || _isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      if (!mounted) return;
      _showLoadingDialog();
      final response = await ApiService.lockSlot(_selectedSlot!['id']).timeout(
        FutsalConstants.apiTimeout,
        onTimeout: () => throw TimeoutException('Server not responding'),
      );
      if (!mounted) {
        await _safeUnlockSlot();
        return;
      }
      Navigator.pop(context);
      if (response['status'] == 'success') {
        setState(() {
          _tempLockedSlot = _selectedSlot;
          _addTemporaryLock(_selectedSlot!['id']);
        });
        _showPaymentMethodDialog();
      } else {
        await _handleBookingFailure(response['message'] ?? 'Slot unavailable');
      }
    } on TimeoutException catch (_) {
      if (!mounted) return;
      Navigator.pop(context);
      await _handleBookingFailure('Connection timeout');
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      await _handleBookingFailure('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _addTemporaryLock(int slotId) {
    setState(() {
      _temporaryLocks[slotId] = DateTime.now().add(
        Duration(minutes: FutsalConstants.lockDurationMinutes),
      );
    });
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.green),
      ),
    );
  }

  void _showPaymentMethodDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.payment, color: Colors.green),
              title: const Text('Cash on Delivery'),
              subtitle: const Text('Pay at venue'),
              onTap: () {
                Navigator.pop(ctx);
                _createBookingWithPayment('COD');
              },
            ),
            ListTile(
              leading: Image.network(
                'https://khalti.com/favicon.ico',
                height: 24,
                width: 24,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.payment, color: Colors.purple),
              ),
              title: const Text('Khalti'),
              subtitle: const Text('Pay online'),
              onTap: () {
                Navigator.pop(ctx);
                _initiateKhaltiPayment();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cancelBookingProcess();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _createBookingWithPayment(String paymentMethod) async {
    if (_tempLockedSlot == null || _isProcessing) return;
    setState(() => _isProcessing = true);
    _showLoadingDialog();
    try {
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      final response = await bookingProvider.createBooking({
        'slotId': _tempLockedSlot!['id'],
        'paymentMethod': paymentMethod,
        'duration': _tempSelectedDuration ?? 1,
      }).timeout(FutsalConstants.apiTimeout,
          onTimeout: () => throw TimeoutException('Booking timeout'));
      if (!mounted) return;
      Navigator.pop(context);
      if (response['status'] == 'success') {
        await _handleBookingSuccess();
        _showSnackBar('Booking confirmed! Please pay at venue.');
      } else {
        await _handleBookingFailure(response['message'] ?? 'Booking failed');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      await _handleBookingFailure('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

Future<void> _initiateKhaltiPayment() async {
  if (_tempLockedSlot == null || _isProcessing) return;
  setState(() => _isProcessing = true);
  _showLoadingDialog();
  try {
    final response = await PaymentService.initiateKhaltiPayment(
      _tempLockedSlot!['id'],
      _tempSelectedDuration ?? 1,
    ).timeout(
      FutsalConstants.apiTimeout,
      onTimeout: () => throw TimeoutException('Payment service timeout'),
    );
    if (!mounted) return;
    Navigator.pop(context);
    
    final paymentUrl = response['paymentUrl'];
    final pidx = response['pidx'];
    _tempBookingId = response['bookingId'];
    
    if (response['status'] == 'success' && paymentUrl != null && pidx != null) {
      // Open WebView for payment
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => KhaltiPaymentScreen(
            paymentUrl: paymentUrl,
            pidx: pidx,
          ),
        ),
      );
      
      print('🔙 Returned from WebView with result: $result');
      
      if (result == true) {
        // Double-check with backend
        final verifyResponse = await PaymentService.verifyPayment(pidx);
        if (verifyResponse['paymentStatus'] == 'COMPLETED') {
          await _handleBookingSuccess();
          _showSnackBar('Payment successful! Booking confirmed.');
        } else {
          await _cancelBookingOnPaymentFailure();
          _showSnackBar('Payment verification failed.', isError: true);
        }
      } else {
        await _cancelBookingOnPaymentFailure();
        _showSnackBar('Payment failed or was cancelled.', isError: true);
      }
      return;
    } else {
      await _handleBookingFailure(
          response['message'] ?? 'Payment initiation failed');
    }
  } catch (e) {
    if (!mounted) return;
    Navigator.pop(context);
    await _handleBookingFailure('Error: ${e.toString()}');
  } finally {
    if (mounted) setState(() => _isProcessing = false);
  }
}

  Future<void> _handleBookingSuccess() async {
    await _safeUnlockSlot();
    _clearBookingState();
    await _fetchSlots();
  }

  Future<void> _cancelBookingOnPaymentFailure() async {
    if (_tempBookingId != null) {
      try {
        await ApiService.cancelUserBooking(_tempBookingId!);
      } catch (e) {
        debugPrint('Failed to cancel booking: $e');
      }
    }
    await _safeUnlockSlot();
    _clearBookingState();
    await _fetchSlots();
    if (mounted) {
      _showSnackBar('Payment cancelled', isError: true);
    }
  }

  Future<void> _cancelBookingProcess() async {
    setState(() => _isProcessing = true);
    await _safeUnlockSlot();
    _clearBookingState();
    await _fetchSlots();
    setState(() => _isProcessing = false);
  }

  Future<void> _safeUnlockSlot() async {
    if (_tempLockedSlot == null) return;
    try {
      await ApiService.unlockSlot(_tempLockedSlot!['id']);
    } catch (e) {
      debugPrint('Failed to unlock slot: $e');
    } finally {
      setState(() => _tempLockedSlot = null);
    }
  }

  void _clearBookingState() {
    setState(() {
      _tempLockedSlot = null;
      _selectedSlot = null;
      _tempSelectedDuration = null;
      _tempBookingId = null;
    });
  }

  Future<void> _handleBookingFailure(String message) async {
    await _safeUnlockSlot();
    await _fetchSlots();
    if (mounted) {
      _showSnackBar(message, isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: FutsalConstants.snackBarDuration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDateSelector(),
        Expanded(
          child: _isLoadingSlots
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.green))
              : _slotsError != null
                  ? _buildErrorView()
                  : _slots.isEmpty
                      ? _buildEmptySlotsView()
                      : _buildSlotsContent(),
        ),
        BookingBar(
          selectedSlot: _selectedSlot,
          selectedDate: _selectedDate,
          isProcessing: _isProcessing,
          onProceedToBooking: _proceedToBooking,
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    final dates =
        List.generate(30, (i) => DateTime.now().add(Duration(days: i)));
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final selectedMonth = DateFormatter.formatMonthYear(_selectedDate);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 5,
              offset: Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Date',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              InkWell(
                onTap: _selectDate,
                child: Row(
                  children: [
                    Text(
                      selectedMonth,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade700),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 18, color: Colors.green),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: dates.length,
              itemBuilder: (context, index) {
                final date = dates[index];
                final isSelected = _selectedDate.year == date.year &&
                    _selectedDate.month == date.month &&
                    _selectedDate.day == date.day;
                final isToday = date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;
                final weekday = weekdays[date.weekday - 1];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedDate = date);
                    _fetchSlots();
                  },
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.green.shade700
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isToday ? 'Today' : weekday,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white70
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              _buildLegendDot(Colors.green.shade300, 'Available'),
              const SizedBox(width: 12),
              _buildLegendDot(Colors.red.shade300, 'Peak'),
              const SizedBox(width: 12),
              _buildLegendDot(Colors.grey.shade400, 'Booked'),
              const SizedBox(width: 12),
              _buildLegendDot(Colors.orange.shade300, 'Locked'),
            ],
          ),
        ),
        Expanded(
          child: SlotsGridWidget(
            slots: _slots,
            selectedSlot: _selectedSlot,
            isProcessing: _isProcessing,
            onSlotSelected: _selectSlot,
            isSlotPeak: (slot) => SlotHelpers.isSlotPeak(slot, _selectedDate),
            isSlotBooked: SlotHelpers.isSlotBooked,
            isSlotAvailable: SlotHelpers.isSlotAvailable,
            isSlotLockedBySystem: SlotHelpers.isSlotLockedBySystem,
            isSlotTemporarilyLocked: (slotId) =>
                SlotHelpers.isSlotTemporarilyLocked(slotId, _temporaryLocks),
            getCourtNumber: SlotHelpers.getCourtNumber,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            _slotsError ?? 'Failed to load slots',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _isProcessing ? null : _fetchSlots,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlotsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.access_time, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No slots available for this date',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text('Try selecting another date',
              style: TextStyle(color: Colors.grey.shade500)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isProcessing ? null : _selectDate,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Choose Another Date'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.black87)),
      ],
    );
  }

  @override
  void dispose() {
    _lockCleanupTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _safeUnlockSlot();
    }
  }
}
