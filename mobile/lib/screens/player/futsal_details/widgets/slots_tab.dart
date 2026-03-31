// lib/screens/player/futsal_details/widgets/slots_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

import '../../../../models/futsal.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/booking_provider.dart';
import '../../../../providers/futsal_provider.dart';
import '../../../../utils/date_formatter.dart';
import '../../../../services/payment_service.dart';
import '../../../../services/api_service.dart';
import '../../../../utils/futsal_constants.dart';
import '../../../../widgets/futsal/booking_confirmation_dialog.dart';
import '../../../../widgets/futsal/slots_grid_widget.dart';
import '../../payment_webview_screen.dart';  // Fixed import path
import 'slot_helpers.dart';
import 'booking_bar.dart';

class SlotsTab extends StatefulWidget {
  final Futsal futsal;

  const SlotsTab({
    super.key,
    required this.futsal,
  });

  @override
  State<SlotsTab> createState() => _SlotsTabState();
}

class _SlotsTabState extends State<SlotsTab> with WidgetsBindingObserver {
  // Slots State
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _slots = [];
  bool _isLoadingSlots = false;
  String? _slotsError;
  Map<String, dynamic>? _selectedSlot;

  // Lock State
  final Map<int, DateTime> _temporaryLocks = {};
  Map<String, dynamic>? _tempLockedSlot;
  Timer? _lockCleanupTimer;
  bool _isProcessing = false;

  // Booking State
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
          .fetchFutsalSlots(
            widget.futsal.id,
            _selectedDate,
          )
          .timeout(
            FutsalConstants.apiTimeout,
            onTimeout: () => throw TimeoutException('Request timed out'),
          );

      if (!mounted) return;

      setState(() {
        _slots = fetchedSlots;
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
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null;
      });
      await _fetchSlots();
      _showSnackBar(
          'Showing slots for ${DateFormatter.formatDateShort(picked)}');
    }
  }

  void _proceedToBooking() async {
    if (_selectedSlot == null || _isProcessing) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      _showSnackBar('Please log in to make a booking', isError: true);
      return;
    }

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
      if (mounted) {
        setState(() => _isProcessing = false);
      }
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
      }).timeout(
        FutsalConstants.apiTimeout,
        onTimeout: () => throw TimeoutException('Booking timeout'),
      );

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
      if (mounted) {
        setState(() => _isProcessing = false);
      }
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

      if (response['status'] == 'success' &&
          paymentUrl != null &&
          pidx != null) {
        if (kIsWeb) {
          html.window.location.href = paymentUrl;
          return;
        }

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => KhaltiPaymentScreen(
              paymentUrl: paymentUrl,
              pidx: pidx,
            ),
          ),
        );

        if (result == true) {
          await _handleBookingSuccess();
          _showSnackBar('Booking confirmed!');
        } else {
          await _cancelBookingOnPaymentFailure();
        }
      } else {
        await _handleBookingFailure(
            response['message'] ?? 'Payment initiation failed');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      await _handleBookingFailure('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
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
              ? const Center(child: CircularProgressIndicator(color: Colors.green))
              : _slotsError != null
                  ? _buildErrorView()
                  : _slots.isEmpty
                      ? _buildEmptySlotsView()
                      : _buildSlotsContent(),
        ),
        BookingBar(
          selectedSlot: _selectedSlot,
          isProcessing: _isProcessing,
          onProceedToBooking: _proceedToBooking,
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              DateFormatter.formatDateFull(_selectedDate),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: _isProcessing ? null : _selectDate,
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
            ),
            child: const Text('Change Date'),
          ),
        ],
      ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
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
          Text(
            'Try selecting another date',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isProcessing ? null : _selectDate,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Choose Another Date'),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsContent() {
    return Column(
      children: [
        _buildLegend(),
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

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _buildLegendDot(Colors.green.shade300, 'Available'),
          const SizedBox(width: 12),
          _buildLegendDot(Colors.red.shade300, '🔥 Peak'),
          const SizedBox(width: 12),
          _buildLegendDot(Colors.grey.shade400, 'Booked'),
          const SizedBox(width: 12),
          _buildLegendDot(Colors.orange.shade300, 'Locked'),
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
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
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
