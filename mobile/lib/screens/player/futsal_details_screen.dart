import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/futsal.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/futsal_provider.dart';
import '../../utils/date_formatter.dart';
import 'booking_history_screen.dart';
import '../../services/payment_service.dart';
import '../../services/api_service.dart';
import 'payment_webview_screen.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import '../../providers/review_provider.dart';
import '../../models/review.dart';

class FutsalDetailsScreen extends StatefulWidget {
  final Futsal futsal;
  final int initialTabIndex;

  const FutsalDetailsScreen({
    super.key,
    required this.futsal,
    this.initialTabIndex = 0,
  });

  @override
  State<FutsalDetailsScreen> createState() => _FutsalDetailsScreenState();
}

class _FutsalDetailsScreenState extends State<FutsalDetailsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedImageIndex = 0;
  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _slots = [];
  bool _isLoadingSlots = false;
  String? _slotsError;

  Map<String, dynamic>? _selectedSlot;
  Map<int, bool> _temporarilyLockedSlots = {};
  Timer? _lockCleanupTimer;
  Map<String, dynamic>? _tempLockedSlot;
  int? _tempBookingId;

  // ✅ Fixed: Use a dedicated variable for duration during booking flow
  int? _tempSelectedDuration;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _fetchSlots();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReviewProvider>(context, listen: false)
          .loadReviews(widget.futsal.id);
      Provider.of<ReviewProvider>(context, listen: false)
          .checkCanReview(widget.futsal.id);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🎯 _slots length: ${_slots.length}');
      debugPrint('🎯 _isLoadingSlots: $_isLoadingSlots');
      debugPrint('🎯 _slotsError: $_slotsError');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _lockCleanupTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _slotsError = null;
    });

    try {
      final futsalProvider =
          Provider.of<FutsalProvider>(context, listen: false);
      final fetchedSlots = await futsalProvider.fetchFutsalSlots(
        widget.futsal.id,
        _selectedDate,
      );

      debugPrint('🎯 Raw slots data:');
      for (var slot in fetchedSlots) {
        debugPrint(
            '  - ID: ${slot['id']}, Time: ${slot['startTime']}, Court: ${slot['courtNumber']}, Price: ${slot['price']}');
      }

      setState(() {
        _slots = fetchedSlots;
        _isLoadingSlots = false;
      });
    } catch (e) {
      setState(() {
        _slotsError = e.toString();
        _isLoadingSlots = false;
      });
    }
  }

  bool _isSlotLocked(Map<String, dynamic> slot) {
    if (slot['status'] == 'LOCKED') {
      if (slot['lockedUntil'] != null) {
        final lockedUntil = DateTime.parse(slot['lockedUntil']);
        if (lockedUntil.isBefore(DateTime.now())) {
          return false;
        }
      }
      return true;
    }

    if (_temporarilyLockedSlots.containsKey(slot['id'])) {
      return true;
    }

    return false;
  }

  void _temporarilyLockSlot(int slotId) {
    setState(() {
      _temporarilyLockedSlots[slotId] = true;
    });

    Future.delayed(const Duration(minutes: 5), () {
      if (mounted) {
        setState(() {
          _temporarilyLockedSlots.remove(slotId);
        });
      }
    });
  }

  void _cleanupExpiredLocks() {
    setState(() {
      _temporarilyLockedSlots.removeWhere((id, _) {
        return false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.green,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: widget.futsal.images.isNotEmpty
                        ? widget.futsal.images.length
                        : 1,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return widget.futsal.images.isNotEmpty
                          ? Image.network(
                              widget.futsal.images[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.green.shade200,
                                  child: Center(
                                    child: Icon(
                                      Icons.sports_soccer,
                                      size: 80,
                                      color: Colors.green.shade400,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.green.shade200,
                              child: Center(
                                child: Icon(
                                  Icons.sports_soccer,
                                  size: 80,
                                  color: Colors.green.shade400,
                                ),
                              ),
                            );
                    },
                  ),
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.futsal.images.isNotEmpty
                            ? widget.futsal.images.length
                            : 1,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _selectedImageIndex == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Added to favorites'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Share feature coming soon'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.futsal.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              widget.futsal.averageRating?.toStringAsFixed(1) ??
                                  'N/A',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Consumer<ReviewProvider>(
                              builder: (_, rp, __) => Text(
                                ' (${rp.reviews.length})', // ✅ real count
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.futsal.address,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.green,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.green,
              tabs: const [
                Tab(text: 'About', icon: Icon(Icons.info)),
                Tab(text: 'Slots', icon: Icon(Icons.access_time)),
                Tab(text: 'Reviews', icon: Icon(Icons.star)),
              ],
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAboutTab(),
                _buildSlotsTab(),
                _buildReviewsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _selectedSlot != null ? _buildBookingBar() : null,
    );
  }

  Widget _buildAboutTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (widget.futsal.description != null) ...[
          const Text(
            'Description',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            widget.futsal.description!,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
        ],
        const Text(
          'Facilities',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFacilityChip(Icons.sports_soccer, '5 Courts'),
            _buildFacilityChip(Icons.local_parking, 'Free Parking'),
            _buildFacilityChip(Icons.local_drink, 'Drinking Water'),
            _buildFacilityChip(Icons.light_mode, 'Floodlights'),
            _buildFacilityChip(Icons.chair, 'Seating Area'),
            _buildFacilityChip(Icons.shower, 'Changing Room'),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Location',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 50, color: Colors.grey),
                SizedBox(height: 8),
                Text('Map view coming soon',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Operating Hours',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Monday - Friday'),
                  Text('Saturday - Sunday'),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('6:00 AM - 10:00 PM'),
                  Text('8:00 AM - 10:00 PM'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlotsTab() {
    return Column(
      children: [
        Container(
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
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              TextButton(
                onPressed: _selectDate,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                ),
                child: const Text('Change Date'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingSlots
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.green))
              : _slotsError != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48, color: Colors.red.shade300),
                          const SizedBox(height: 16),
                          Text('Failed to load slots',
                              style: TextStyle(color: Colors.grey.shade600)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _fetchSlots,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _slots.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.access_time,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'No slots available for this date',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try selecting another date',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _selectDate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text('Choose Another Date'),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _slots.length,
                          itemBuilder: (context, index) {
                            return _buildSlotCard(_slots[index]);
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildSlotCard(Map<String, dynamic> slot) {
    final String status = slot['status'];

    bool isAvailable = status == 'AVAILABLE';
    bool isLocked = status == 'LOCKED';
    bool isBooked =
        status == 'BOOKED' || status == 'CONFIRMED' || status == 'COMPLETED';
    bool isSelected =
        _selectedSlot != null && _selectedSlot!['id'] == slot['id'];

    Color backgroundColor;
    Color textColor;
    Color borderColor;
    String statusText = '';

    if (isSelected) {
      backgroundColor = Colors.green;
      textColor = Colors.white;
      borderColor = Colors.green;
    } else if (isBooked) {
      backgroundColor = Colors.grey.shade300;
      textColor = Colors.grey.shade700;
      borderColor = Colors.grey.shade400;
      statusText = 'BOOKED';
    } else if (isLocked) {
      backgroundColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
      borderColor = Colors.orange.shade300;
      statusText = 'LOCKED';
    } else if (isAvailable) {
      backgroundColor = Colors.white;
      textColor = Colors.green.shade300;
      borderColor = Colors.green.shade300;
      statusText = 'AVAILABLE';
    } else {
      backgroundColor = Colors.grey.shade100;
      textColor = Colors.grey;
      borderColor = Colors.grey.shade300;
    }

    return GestureDetector(
      onTap: isAvailable
          ? () {
              setState(() {
                if (isSelected) {
                  _selectedSlot = null;
                } else {
                  _selectedSlot = slot;
                }
              });
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              slot['startTime'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'रू ${slot['price']}',
              style: TextStyle(
                fontSize: 11,
                color: textColor,
              ),
            ),
            if (statusText.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      isBooked ? Colors.grey.shade400 : Colors.orange.shade200,
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

  Widget _buildReviewsTab() {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, _) {
        final reviews = reviewProvider.reviews;
        final avgRating = reviewProvider.averageRating;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Rating summary card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Column(
                      children: [
                        Text(
                          avgRating > 0 ? avgRating.toStringAsFixed(1) : 'N/A',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < avgRating.round()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                        ),
                        Text(
                          '${reviews.length} reviews',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        children: List.generate(5, (index) {
                          final star = 5 - index;
                          final count = reviews
                              .where((r) => r.rating.round() == star)
                              .length;
                          final fraction =
                              reviews.isEmpty ? 0.0 : count / reviews.length;
                          return Row(
                            children: [
                              Text('$star',
                                  style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              const Icon(Icons.star,
                                  size: 12, color: Colors.amber),
                              const SizedBox(width: 8),
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: fraction,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation(
                                      Colors.amber.shade700),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('$count',
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Write review button — only if eligible
            if (reviewProvider.canReview)
              OutlinedButton.icon(
                onPressed: () => _showWriteReviewDialog(
                  reviewProvider.eligibleBookingId!,
                  reviewProvider,
                ),
                icon: const Icon(Icons.edit),
                label: const Text('Write a Review'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),

            const SizedBox(height: 16),
            const Text(
              'Recent Reviews',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (reviewProvider.isLoading)
              const Center(
                  child: CircularProgressIndicator(color: Colors.green))
            else if (reviews.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.star_border,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('No reviews yet',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              )
            else
              ...reviews.map((review) => _buildReviewCard(review)),
          ],
        );
      },
    );
  }

  Widget _buildReviewCard(Review review) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isOwnReview = authProvider.user?.id == review.userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.green.shade100,
                  child: Text(
                    review.userName.isNotEmpty
                        ? review.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        DateFormatter.formatDateMedium(review.createdAt),
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating.round()
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 14,
                    );
                  }),
                ),
                // Edit/Delete for own review
                if (isOwnReview)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 16),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditReviewDialog(review);
                      } else if (value == 'delete') {
                        _confirmDeleteReview(review);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                          value: 'delete', child: Text('Delete')),
                    ],
                  ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.comment!, style: const TextStyle(fontSize: 14)),
            ],
            // Owner reply
            if (review.reply != null && review.reply!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Owner Reply',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700)),
                    const SizedBox(height: 4),
                    Text(review.reply!, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.green),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingBar() {
    final price = num.tryParse(_selectedSlot!['price'].toString()) ?? 0;

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
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Slot',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _selectedSlot!['startTime'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'रू $price',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _proceedToBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null;
      });
      _fetchSlots();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Showing slots for ${DateFormatter.formatDateShort(picked)}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  // ============================================
  // BOOKING FLOW METHODS - FIXED VERSION
  // ============================================

  void _proceedToBooking() {
    if (_selectedSlot == null) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to make a booking'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _showConfirmationDialog();
  }

  void _showConfirmationDialog() {
    if (_selectedSlot == null) return;

    final price = num.tryParse(_selectedSlot!['price'].toString()) ?? 0;
    int selectedDuration = 1; // Local dialog state

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Confirm Booking',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.futsal.name,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(DateFormatter.formatDateFull(_selectedDate)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(_selectedSlot!['startTime']),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Duration (hours)'),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: selectedDuration > 1
                                      ? () {
                                          setDialogState(() {
                                            selectedDuration--;
                                          });
                                        }
                                      : null,
                                  color: selectedDuration > 1
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                Container(
                                  width: 40,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$selectedDuration',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: selectedDuration < 4
                                      ? () {
                                          setDialogState(() {
                                            selectedDuration++;
                                          });
                                        }
                                      : null,
                                  color: selectedDuration < 4
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Price per hour'),
                            Text('रू ${price.toStringAsFixed(0)}'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total'),
                            Text(
                              'रू ${(price * selectedDuration).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                          },
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _tempSelectedDuration = selectedDuration;
                            _lockSlotAndShowPayment();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Confirm'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

// ============================================
// COMPLETE FIXED BOOKING FLOW
// ============================================

// ✅ Always unlock before clearing state
  Future<void> _cancelBookingProcess() async {
    await _safeUnlockSlot();
    _clearBookingState();
  }

// ✅ Uses correct unlockSlot endpoint, not cancel booking
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

// ✅ _tempBookingId cleared here too
  void _clearBookingState() {
    setState(() {
      _tempLockedSlot = null;
      _selectedSlot = null;
      _tempSelectedDuration = null;
      _tempBookingId = null;
    });
  }

// ✅ Always unlock on error, refresh slots
  Future<void> _lockSlotAndShowPayment() async {
    if (_selectedSlot == null) return;

    setState(() => _tempLockedSlot = _selectedSlot);

    final duration = _tempSelectedDuration ?? 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.green),
      ),
    );

    try {
      final response = await ApiService.lockSlot(_tempLockedSlot!['id']);

      if (!mounted) return;
      Navigator.pop(context); // close loader

      if (response['status'] == 'success') {
        _showPaymentMethodDialog();
      } else {
        // ✅ unlock + clear + refresh on failure
        await _safeUnlockSlot();
        _clearBookingState();
        await _fetchSlots();
        _showError(response['message'] ?? 'Slot no longer available');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      await _safeUnlockSlot();
      _clearBookingState();
      await _fetchSlots();
      _showError('Error: $e');
    }
  }

// ✅ Clear state + refresh on success, unlock on failure
  Future<void> _createBookingWithPayment(String paymentMethod) async {
    if (_tempLockedSlot == null) return;
    final duration = _tempSelectedDuration ?? 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.green),
      ),
    );

    try {
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      final response = await bookingProvider.createBooking({
        'slotId': _tempLockedSlot!['id'],
        'paymentMethod': paymentMethod,
        'duration': duration,
      });

      if (!mounted) return;
      Navigator.pop(context);

      if (response['status'] == 'success') {
        _tempBookingId = response['bookingId'];
        _clearBookingState(); // ✅ closes booking bar
        await _fetchSlots(); // ✅ refreshes grid
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking confirmed! Please pay at venue.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await _safeUnlockSlot();
        _clearBookingState();
        await _fetchSlots();
        _showError(response['message'] ?? 'Booking failed');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      await _safeUnlockSlot();
      _clearBookingState();
      await _fetchSlots();
      _showError('Error: $e');
    }
  }

// ✅ pidx from correct key, clear state + refresh on success
  Future<void> _initiateKhaltiPayment() async {
    if (_tempLockedSlot == null) return;
    final duration = _tempSelectedDuration ?? 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.green),
      ),
    );

    try {
      final response = await PaymentService.initiateKhaltiPayment(
        _tempLockedSlot!['id'],
        duration,
      );

      if (!mounted) return;
      Navigator.pop(context);

      final paymentUrl = response['paymentUrl'];
      final pidx = response['pidx']; // ✅ now returned from backend
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
          _clearBookingState(); // ✅ closes booking bar
          await _fetchSlots(); // ✅ refreshes grid
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking confirmed!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // ✅ cancel booking with correct booking ID
          if (_tempBookingId != null) {
            await ApiService.cancelUserBooking(_tempBookingId!);
          }
          await _safeUnlockSlot();
          _clearBookingState();
          await _fetchSlots();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment cancelled'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        await _safeUnlockSlot();
        _clearBookingState();
        await _fetchSlots();
        _showError(response['message'] ?? 'Payment initiation failed');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      await _safeUnlockSlot();
      _clearBookingState();
      await _fetchSlots();
      _showError('Error: $e');
    }
  }

// ✅ Payment method dialog — cancel properly unlocks
  void _showPaymentMethodDialog() {
    showDialog(
      context: context,
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
              _cancelBookingProcess(); // ✅ unlocks slot + clears state
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showWriteReviewDialog(int bookingId, ReviewProvider reviewProvider) {
    double selectedRating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Write a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Rate your experience:'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () =>
                        setDialogState(() => selectedRating = index + 1.0),
                    child: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 36,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Share your experience (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                Navigator.pop(ctx);
                final result = await reviewProvider.submitReview(
                  futsalId: widget.futsal.id,
                  bookingId: bookingId,
                  rating: selectedRating,
                  comment: commentController.text.trim().isEmpty
                      ? null
                      : commentController.text.trim(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(result['message']),
                    backgroundColor: result['status'] == 'success'
                        ? Colors.green
                        : Colors.red,
                  ));
                }
              },
              child:
                  const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditReviewDialog(Review review) {
    double selectedRating = review.rating;
    final commentController = TextEditingController(text: review.comment ?? '');
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () =>
                        setDialogState(() => selectedRating = index + 1.0),
                    child: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 36,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Your review',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                Navigator.pop(ctx);
                final result = await reviewProvider.updateReview(
                  reviewId: review.id,
                  futsalId: widget.futsal.id,
                  rating: selectedRating,
                  comment: commentController.text.trim().isEmpty
                      ? null
                      : commentController.text.trim(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(result['message']),
                    backgroundColor: result['status'] == 'success'
                        ? Colors.green
                        : Colors.red,
                  ));
                }
              },
              child:
                  const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteReview(Review review) {
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete your review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await reviewProvider.deleteReview(
                reviewId: review.id,
                futsalId: widget.futsal.id,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result['message']),
                  backgroundColor:
                      result['status'] == 'success' ? Colors.green : Colors.red,
                ));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
