import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/futsal.dart';
import '../../models/review.dart';
import '../../models/court.dart';
import '../../providers/auth_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/court_provider.dart';
import '../../utils/date_formatter.dart';
import 'check_availability_screen.dart';  // Keep separate - booking flow

// ==================== FULLSCREEN IMAGE VIEWER ====================

class FullscreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullscreenImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => Navigator.pop(context),
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    widget.images[index],
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Loading... ${((loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)) * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white, size: 24),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== FUTSAL APP BAR (Image Carousel) ====================

class FutsalAppBar extends StatelessWidget {
  final Futsal futsal;
  final int selectedImageIndex;
  final Function(int) onPageChanged;
  final bool isProcessing;
  final VoidCallback onBack;
  final VoidCallback onFavorite;
  final VoidCallback onShare;
  final bool isFavorite;

  const FutsalAppBar({
    super.key,
    required this.futsal,
    required this.selectedImageIndex,
    required this.onPageChanged,
    required this.isProcessing,
    required this.onBack,
    required this.onFavorite,
    required this.onShare,
    this.isFavorite = false,
  });

  void _showFullScreenImage(BuildContext context, int index) {
    if (futsal.images.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenImageViewer(
          images: futsal.images,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.green,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () => _showFullScreenImage(context, selectedImageIndex),
              child: PageView.builder(
                itemCount: futsal.images.isNotEmpty ? futsal.images.length : 1,
                onPageChanged: onPageChanged,
                itemBuilder: (context, index) {
                  return futsal.images.isNotEmpty
                      ? Image.network(
                          futsal.images[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder();
                },
              ),
            ),
            _buildImageIndicators(),
            _buildGradient(),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: onBack,
      ),
      actions: [
        IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: Colors.white,
          ),
          onPressed: isProcessing ? null : onFavorite,
        ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: isProcessing ? null : onShare,
        ),
      ],
    );
  }

  Widget _placeholder() {
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
  }

  Widget _buildImageIndicators() {
    if (futsal.images.isEmpty || futsal.images.length <= 1) {
      return const SizedBox.shrink();
    }
    
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          futsal.images.length,
          (index) => Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selectedImageIndex == index
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradient() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.5),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }
}

// ==================== FUTSAL HEADER ====================

class FutsalHeader extends StatelessWidget {
  final Futsal futsal;

  const FutsalHeader({
    super.key,
    required this.futsal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  futsal.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildRatingBadge(context),
            ],
          ),
          const SizedBox(height: 6),
          _buildAddressRow(),
        ],
      ),
    );
  }

  Widget _buildRatingBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 18),
          const SizedBox(width: 4),
          Text(
            futsal.averageRating?.toStringAsFixed(1) ?? 'N/A',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Consumer<ReviewProvider>(
            builder: (_, rp, __) => Text(
              ' (${rp.reviews.length})',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow() {
    return Row(
      children: [
        Icon(Icons.location_on, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            futsal.address,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

// ==================== ABOUT TAB (FULL VERSION) ====================

class AboutTab extends StatelessWidget {
  final Futsal futsal;
  final bool isLoading;

  const AboutTab({
    super.key,
    required this.futsal,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final courtProvider = Provider.of<CourtProvider>(context);
    final courts = courtProvider.courts;

    if (isLoading || courtProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (futsal.description?.isNotEmpty ?? false) ...[
          const Text(
            'Description',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            futsal.description!,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
        ],
        const Text(
          'Facilities',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildFacilitiesWrap(courts),
        const SizedBox(height: 20),
        const Text(
          'Courts',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildCourtsList(courts),
        const SizedBox(height: 20),
        const Text(
          'Location',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildMapPlaceholder(context),
        const SizedBox(height: 20),
        const Text(
          'Operating Hours',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildOperatingHours(),
      ],
    );
  }

  Widget _buildFacilitiesWrap(List<Court> courts) {
    final Set<String> allAmenities = {};
    for (var court in courts) {
      allAmenities.addAll(court.amenities);
    }
    
    final facilities = <String>[];
    facilities.add('${courts.length} Courts');
    facilities.addAll(allAmenities.toList());
    
    if (facilities.isEmpty) {
      return const Text('No facilities listed');
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: facilities.map((facility) {
        return _buildFacilityChip(
          _getFacilityIcon(facility),
          facility,
        );
      }).toList(),
    );
  }

  IconData _getFacilityIcon(String facility) {
    final lower = facility.toLowerCase();
    if (lower.contains('court')) return Icons.sports_soccer;
    if (lower.contains('parking')) return Icons.local_parking;
    if (lower.contains('water')) return Icons.local_drink;
    if (lower.contains('light')) return Icons.light_mode;
    if (lower.contains('chair') || lower.contains('seating')) return Icons.chair;
    if (lower.contains('shower') || lower.contains('changing')) return Icons.shower;
    if (lower.contains('wifi')) return Icons.wifi;
    if (lower.contains('ac') || lower.contains('air')) return Icons.ac_unit;
    if (lower.contains('floodlight')) return Icons.light;
    return Icons.fitness_center;
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

  Widget _buildCourtsList(List<Court> courts) {
    if (courts.isEmpty) {
      return const Text('No courts available');
    }
    
    return Column(
      children: courts.map((court) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(
              court.courtType == 'indoor' ? Icons.sports_soccer : Icons.grass,
              color: Colors.green,
            ),
            title: Text('Court ${court.courtNumber}'),
            subtitle: Text(
              '${court.courtTypeDisplay} • रू${court.basePrice}/hr${court.hasPeakPricing ? ' (Peak: रू${court.peakPrice})' : ''}',
            ),
            trailing: court.isUnderMaintenance
                ? const Chip(
                    label: Text('Maintenance'),
                    backgroundColor: Colors.orange,
                    labelStyle: TextStyle(color: Colors.white, fontSize: 10),
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMapPlaceholder(BuildContext context) {
    if (futsal.latitude != null && futsal.longitude != null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map, size: 50, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                '${futsal.latitude}, ${futsal.longitude}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _openInMaps(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Open in Maps'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
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
            Text('Location not available', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Future<void> _openInMaps(BuildContext context) async {
    final lat = futsal.latitude;
    final lng = futsal.longitude;
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available')),
      );
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!ok) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    }
  }

  Widget _buildOperatingHours() {
    if (futsal.operatingHours == null || futsal.operatingHours!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Operating hours not set',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: List.generate(days.length, (index) {
          final day = days[index];
          final dayName = dayNames[index];
          final hours = futsal.operatingHours![day];
          
          if (hours == null) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dayName, style: const TextStyle(fontWeight: FontWeight.w500)),
                  const Text('Closed', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dayName, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text('${hours['open']} - ${hours['close']}'),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ==================== REVIEWS TAB (FULL VERSION) ====================

class ReviewsTab extends StatefulWidget {
  final Futsal futsal;

  const ReviewsTab({
    super.key,
    required this.futsal,
  });

  @override
  State<ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<ReviewsTab> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadReviewData();
  }

  void _loadReviewData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reviewProvider =
          Provider.of<ReviewProvider>(context, listen: false);
      reviewProvider.loadReviews(widget.futsal.id);
      reviewProvider.checkCanReview(widget.futsal.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, _) {
        final reviews = reviewProvider.reviews;
        final avgRating = reviewProvider.averageRating;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildRatingSummaryCard(avgRating, reviews.length),
            const SizedBox(height: 16),
            if (reviewProvider.canReview && !_isProcessing)
              _buildWriteReviewButton(reviewProvider.eligibleBookingId!),
            const SizedBox(height: 16),
            const Text(
              'Recent Reviews',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (reviewProvider.isLoading)
              const Center(child: CircularProgressIndicator(color: Colors.green))
            else if (reviews.isEmpty)
              _buildEmptyReviews()
            else
              ...reviews.map((review) => _buildReviewCard(review)),
          ],
        );
      },
    );
  }

  Widget _buildRatingSummaryCard(double avgRating, int reviewCount) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    avgRating > 0 ? avgRating.toStringAsFixed(1) : 'N/A',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 4),
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
                  const SizedBox(height: 4),
                  Text(
                    '$reviewCount ${reviewCount == 1 ? 'review' : 'reviews'}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: List.generate(5, (index) {
                  final star = 5 - index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildRatingRow(star),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(int star) {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, _) {
        final reviews = reviewProvider.reviews;
        final count = reviews.where((r) => r.rating.round() == star).length;
        final fraction = reviews.isEmpty ? 0.0 : count / reviews.length;

        return Row(
          children: [
            Text('$star', style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            const Icon(Icons.star, size: 12, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: LinearProgressIndicator(
                value: fraction,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(Colors.amber.shade700),
              ),
            ),
            const SizedBox(width: 8),
            Text('$count', style: const TextStyle(fontSize: 12)),
          ],
        );
      },
    );
  }

  Widget _buildWriteReviewButton(int bookingId) {
    return OutlinedButton.icon(
      onPressed: _isProcessing ? null : () => _showWriteReviewDialog(bookingId),
      icon: const Icon(Icons.edit),
      label: const Text('Write a Review'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.green,
        side: const BorderSide(color: Colors.green),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildEmptyReviews() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.star_border, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text('No reviews yet',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isOwnReview = authProvider.user?.id == review.userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.green.shade100,
                  child: Text(
                    review.userName.isNotEmpty
                        ? review.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              review.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Text(
                            DateFormatter.formatDateMedium(review.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < review.rating.round()
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                if (isOwnReview && !_isProcessing)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditReviewDialog(review);
                      } else if (value == 'delete') {
                        _confirmDeleteReview(review);
                      }
                    },
                    itemBuilder: (_) => [
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
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (review.comment?.isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              Text(
                review.comment!,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ],
            if (review.reply?.isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.reply, size: 14, color: Colors.green.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Owner Response',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      review.reply!,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showWriteReviewDialog(int bookingId) {
    double selectedRating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: !_isProcessing,
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
              onPressed: _isProcessing ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: _isProcessing
                  ? null
                  : () => _submitReview(
                        ctx,
                        bookingId,
                        selectedRating,
                        commentController.text.trim(),
                      ),
              child:
                  const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview(
    BuildContext dialogContext,
    int bookingId,
    double rating,
    String comment,
  ) async {
    setState(() => _isProcessing = true);
    Navigator.pop(dialogContext);

    try {
      final reviewProvider =
          Provider.of<ReviewProvider>(context, listen: false);
      final result = await reviewProvider.submitReview(
        futsalId: widget.futsal.id,
        bookingId: bookingId,
        rating: rating,
        comment: comment.isEmpty ? null : comment,
      );

      if (mounted) {
        _showSnackBar(
          result['message'],
          isError: result['status'] != 'success',
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error submitting review: ${e.toString()}',
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showEditReviewDialog(Review review) {
    double selectedRating = review.rating;
    final commentController = TextEditingController(text: review.comment ?? '');

    showDialog(
      context: context,
      barrierDismissible: !_isProcessing,
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
              onPressed: _isProcessing ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: _isProcessing
                  ? null
                  : () => _updateReview(
                        ctx,
                        review.id,
                        selectedRating,
                        commentController.text.trim(),
                      ),
              child:
                  const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateReview(
    BuildContext dialogContext,
    int reviewId,
    double rating,
    String comment,
  ) async {
    setState(() => _isProcessing = true);
    Navigator.pop(dialogContext);

    try {
      final reviewProvider =
          Provider.of<ReviewProvider>(context, listen: false);
      final result = await reviewProvider.updateReview(
        reviewId: reviewId,
        futsalId: widget.futsal.id,
        rating: rating,
        comment: comment.isEmpty ? null : comment,
      );

      if (mounted) {
        _showSnackBar(
          result['message'],
          isError: result['status'] != 'success',
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error updating review: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _confirmDeleteReview(Review review) {
    showDialog(
      context: context,
      barrierDismissible: !_isProcessing,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete your review?'),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed:
                _isProcessing ? null : () => _deleteReview(ctx, review.id),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReview(BuildContext dialogContext, int reviewId) async {
    setState(() => _isProcessing = true);
    Navigator.pop(dialogContext);

    try {
      final reviewProvider =
          Provider.of<ReviewProvider>(context, listen: false);
      final result = await reviewProvider.deleteReview(
        reviewId: reviewId,
        futsalId: widget.futsal.id,
      );

      if (mounted) {
        _showSnackBar(
          result['message'],
          isError: result['status'] != 'success',
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error deleting review: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}

// ==================== FUTSAL TABS ====================

class FutsalTabs extends StatefulWidget {
  final Futsal futsal;
  final int initialTabIndex;

  const FutsalTabs({
    super.key,
    required this.futsal,
    required this.initialTabIndex,
  });

  @override
  State<FutsalTabs> createState() => _FutsalTabsState();
}

class _FutsalTabsState extends State<FutsalTabs> with TickerProviderStateMixin {
  late TabController _tabController;
  late Future<void> _courtsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex > 1 ? 1 : widget.initialTabIndex,
    );
    _courtsFuture = _fetchCourts();
  }
  
  Future<void> _fetchCourts() async {
    final courtProvider = Provider.of<CourtProvider>(context, listen: false);
    await courtProvider.loadCourts(widget.futsal.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _courtsFuture,
      builder: (context, snapshot) {
        return Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.green,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.green,
                tabs: const [
                  Tab(text: 'About', icon: Icon(Icons.info_outline)),
                  Tab(text: 'Reviews', icon: Icon(Icons.star_border)),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  AboutTab(
                    futsal: widget.futsal,
                    isLoading: snapshot.connectionState != ConnectionState.done,
                  ),
                  ReviewsTab(futsal: widget.futsal),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckAvailabilityScreen(futsal: widget.futsal),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Check Availability',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ==================== MAIN FUTSAL DETAILS SCREEN ====================

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
    with WidgetsBindingObserver {
  int _selectedImageIndex = 0;
  final bool _isProcessing = false;
  bool _isFavorite = false;
  
  bool get isDesktop => MediaQuery.of(context).size.width >= 1100;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFavoriteStatus();
    });
  }
  
  Future<void> _checkFavoriteStatus() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isAuthenticated) {
      final favProvider = Provider.of<FavoriteProvider>(context, listen: false);
      setState(() {
        _isFavorite = favProvider.isFavorite(widget.futsal.id);
      });
    }
  }
  
  Future<void> _toggleFavorite() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      _showSnackBar('Please log in to save favorites', isError: true);
      return;
    }
    
    final favProvider = Provider.of<FavoriteProvider>(context, listen: false);
    final success = await favProvider.toggleFavorite(widget.futsal.id);
    
    if (success) {
      setState(() {
        _isFavorite = !_isFavorite;
      });
      _showSnackBar(
        _isFavorite ? 'Added to favorites' : 'Removed from favorites',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return _buildDesktopLayout();
    }
    return _buildMobileLayout();
  }

  // ==================== MOBILE LAYOUT ====================
  
  Widget _buildMobileLayout() {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          FutsalAppBar(
            futsal: widget.futsal,
            selectedImageIndex: _selectedImageIndex,
            onPageChanged: (index) {
              if (mounted) {
                setState(() => _selectedImageIndex = index);
              }
            },
            isProcessing: _isProcessing,
            onBack: () => Navigator.pop(context),
            onFavorite: _toggleFavorite,
            onShare: () => _showSnackBar('Share feature coming soon'),
            isFavorite: _isFavorite,
          ),
          SliverToBoxAdapter(
            child: FutsalHeader(futsal: widget.futsal),
          ),
          SliverFillRemaining(
            child: FutsalTabs(
              futsal: widget.futsal,
              initialTabIndex: widget.initialTabIndex,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DESKTOP LAYOUT ====================
  
  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildDesktopAppBar(),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 1400,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDesktopImageGallery(),
                            const SizedBox(height: 24),
                            FutsalHeader(futsal: widget.futsal),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        flex: 3,
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: FutsalTabs(
                              futsal: widget.futsal,
                              initialTabIndex: widget.initialTabIndex,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.futsal.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _toggleFavorite,
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => _showSnackBar('Share feature coming soon'),
              icon: const Icon(Icons.share),
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopImageGallery() {
    final images = widget.futsal.images;
    
    if (images.isEmpty) {
      return Container(
        height: 350,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
              SizedBox(height: 12),
              Text('No images available', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullscreenImageViewer(
                      images: images,
                      initialIndex: _selectedImageIndex,
                    ),
                  ),
                );
              },
              child: Container(
                height: 350,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    images[_selectedImageIndex],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, size: 50),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.photo_library, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      '${_selectedImageIndex + 1} / ${images.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.tap_and_play, size: 12, color: Colors.white70),
                    SizedBox(width: 4),
                    Text('Tap to enlarge', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedImageIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedImageIndex = index);
                },
                child: Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.green : Colors.grey[300]!,
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, size: 30),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}