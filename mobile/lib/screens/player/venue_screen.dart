import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/futsal.dart';
import '../../providers/futsal_provider.dart';
import '../../providers/auth_provider.dart';
import '../login_screen.dart';
import 'futsal_details_screen.dart';
import 'home_screen.dart'; // for AppColors

class VenueScreen extends StatefulWidget {
  const VenueScreen({super.key});

  @override
  State<VenueScreen> createState() => _VenueScreenState();
}

class _VenueScreenState extends State<VenueScreen> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedFilter = 'All';
  static const List<String> _actionFilters = ['All', 'Nearby', 'Popular'];

  Position? _userPosition;
  static const double _nearbyRadiusKm = 10.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FutsalProvider>(context, listen: false).fetchFutsals();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Responsive helper methods
  double _getResponsiveFontSize(double baseSize) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 375.0).clamp(0.85, 1.2);
    return baseSize * scale;
  }

  double _getResponsivePadding() {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 32.0;
    if (width > 800) return 24.0;
    return 16.0;
  }

  int _getCrossAxisCount() {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 3;
    if (width > 800) return 2;
    return 1;
  }

  // ─────────── Location ───────────
  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied. Nearby filter requires location.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );
      setState(() => _userPosition = position);
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  // ─────────── Filtering & Sorting ───────────
  List<Futsal> _getFilteredList() {
    final futsalProvider = Provider.of<FutsalProvider>(context, listen: false);
    List<Futsal> futsals = List.from(futsalProvider.futsals);

    if (_query.isNotEmpty) {
      futsals = futsals.where((f) {
        return f.name.toLowerCase().contains(_query.toLowerCase()) ||
            f.address.toLowerCase().contains(_query.toLowerCase());
      }).toList();
    }
    
    if (_selectedFilter == 'Popular') {
      futsals.sort((a, b) => (b.averageRating ?? 0).compareTo(a.averageRating ?? 0));
    } else if (_selectedFilter == 'Nearby') {
      if (_userPosition == null) {
        return [];
      }
      for (var futsal in futsals) {
        if (futsal.latitude != null && futsal.longitude != null) {
          futsal.distance = _calculateDistance(
            _userPosition!.latitude, _userPosition!.longitude,
            futsal.latitude!, futsal.longitude!,
          );
        }
      }
      futsals = futsals.where((f) => f.distance != null && f.distance! <= _nearbyRadiusKm).toList();
      futsals.sort((a, b) => (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity));
    } else if (_selectedFilter != 'All') {
      futsals = futsals.where((f) {
        final types = f.getCourtTypes().map((t) => t.toLowerCase());
        return types.contains(_selectedFilter.toLowerCase());
      }).toList();
    }

    return futsals;
  }

  // Distinct court types derived from the loaded venue data.
  List<String> get _courtTypeFilters {
    final futsalProvider = Provider.of<FutsalProvider>(context, listen: false);
    final types = <String>{};
    for (final futsal in futsalProvider.futsals) {
      types.addAll(futsal.getCourtTypes());
    }
    final sorted = types.toList()..sort();
    return sorted;
  }

  // All filter chips: base action filters + court types.
  List<String> get _filters => [..._actionFilters, ..._courtTypeFilters];

  // Human-friendly label for a court type filter, e.g. "5-a-side" -> "5-A-Side".
  String _filterLabel(String filter) {
    return filter
        .split('-')
        .map((part) => part.isEmpty
            ? part
            : part[0].toUpperCase() + part.substring(1))
        .join('-');
  }

  // ─────────── Navigation ───────────
  void _onBookPressed(BuildContext context, Futsal futsal) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      final didLogin = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (!context.mounted) return;
      if (didLogin == true) {
        _proceedToBooking(context, futsal);
      }
    } else {
      _proceedToBooking(context, futsal);
    }
  }

  void _proceedToBooking(BuildContext context, Futsal futsal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FutsalDetailsScreen(futsal: futsal, initialTabIndex: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final filtered = _getFilteredList();
    final responsivePadding = _getResponsivePadding();
    final crossAxisCount = _getCrossAxisCount();
    final isDesktop = MediaQuery.of(context).size.width > 800;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: isDesktop ? 120 : 100,
        titleSpacing: responsivePadding,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Find Futsal',
              style: TextStyle(
                fontSize: _getResponsiveFontSize(isDesktop ? 28 : 22),
                fontWeight: FontWeight.bold,
                color: AppColors.onBackground,
              ),
            ),
            SizedBox(height: isDesktop ? 16 : 10),
            // Search bar - responsive width
            Container(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 600 : double.infinity,
              ),
              height: isDesktop ? 48 : 44,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(isDesktop ? 24 : 22),
                border: Border.all(color: AppColors.divider),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(15),
                  color: AppColors.onBackground,
                ),
                decoration: InputDecoration(
                  hintText: 'Search venues...',
                  hintStyle: TextStyle(
                    fontSize: _getResponsiveFontSize(14),
                    color: AppColors.secondaryText.withValues(alpha: 0.7),
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.secondaryText),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: isDesktop ? 12 : 10),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter chips - responsive wrapping
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: responsivePadding, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: EdgeInsets.only(right: isDesktop ? 12 : 8),
                    child: ChoiceChip(
                      label: Text(
                        _filterLabel(filter),
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(isDesktop ? 14 : 13),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.onBackground,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.divider,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedFilter = filter);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Venue list - responsive grid or list
          Expanded(
            child: _buildResultsList(filtered, crossAxisCount, isDesktop),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(List<Futsal> results, int crossAxisCount, bool isDesktop) {
    if (_selectedFilter == 'Nearby' && _userPosition == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off, size: isDesktop ? 80 : 64, color: AppColors.secondaryText),
            const SizedBox(height: 12),
            Text(
              'Location not available',
              style: TextStyle(
                fontSize: _getResponsiveFontSize(isDesktop ? 18 : 16),
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _getUserLocation,
              icon: const Icon(Icons.my_location),
              label: Text(
                'Enable Location',
                style: TextStyle(fontSize: _getResponsiveFontSize(14)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24 : 16,
                  vertical: isDesktop ? 12 : 10,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: isDesktop ? 80 : 64, color: AppColors.secondaryText),
            const SizedBox(height: 12),
            Text(
              'No venues found',
              style: TextStyle(
                fontSize: _getResponsiveFontSize(isDesktop ? 18 : 16),
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filter',
              style: TextStyle(
                fontSize: _getResponsiveFontSize(14),
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      );
    }

    final responsivePadding = _getResponsivePadding();
    
    // Use GridView for desktop/tablet, ListView for mobile
    if (crossAxisCount > 1) {
      return Padding(
        padding: EdgeInsets.all(responsivePadding),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: results.length,
          itemBuilder: (context, index) => _buildResultCard(results[index], isDesktop),
        ),
      );
    } else {
      return ListView.builder(
        padding: EdgeInsets.all(responsivePadding),
        itemCount: results.length,
        itemBuilder: (context, index) => _buildResultCard(results[index], isDesktop),
      );
    }
  }

  Widget _buildResultCard(Futsal futsal, bool isDesktop) {
    final imageUrl = futsal.images.isNotEmpty
        ? futsal.images[0]
        : 'https://via.placeholder.com/300x180?text=Futsal';
    final rating = futsal.averageRating ?? 4.5;
    final price = futsal.getMinPrice();
    final distance = futsal.distance;

    return GestureDetector(
      onTap: () => _onBookPressed(context, futsal),
      child: Container(
        margin: isDesktop ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(isDesktop ? 16 : 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: isDesktop
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image on top for desktop
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 150,
                        color: AppColors.primary.withValues(alpha: 0.05),
                        child: const Icon(Icons.sports_soccer, color: AppColors.primary, size: 50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    futsal.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: _getResponsiveFontSize(16),
                      color: AppColors.onBackground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.secondaryText),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          futsal.address,
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(12),
                            color: AppColors.secondaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentAmber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: AppColors.accentAmber),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: _getResponsiveFontSize(12),
                                fontWeight: FontWeight.w600,
                                color: AppColors.onBackground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (distance != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.directions_walk, size: 14, color: AppColors.secondaryText),
                        const SizedBox(width: 4),
                        Text(
                          '${distance.toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(12),
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        price != null ? 'Rs. ${price.toStringAsFixed(0)}/hr' : 'Price varies',
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(13),
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _onBookPressed(context, futsal),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Book Now',
                        style: TextStyle(fontSize: _getResponsiveFontSize(13)),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                // Original mobile layout (image left, content right)
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 100,
                        height: 100,
                        color: AppColors.primary.withValues(alpha: 0.05),
                        child: const Icon(Icons.sports_soccer, color: AppColors.primary, size: 40),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          futsal.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: _getResponsiveFontSize(16),
                            color: AppColors.onBackground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: AppColors.secondaryText),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                futsal.address,
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(12),
                                  color: AppColors.secondaryText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accentAmber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 14, color: AppColors.accentAmber),
                                  const SizedBox(width: 4),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: _getResponsiveFontSize(12),
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onBackground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (distance != null) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.directions_walk, size: 14, color: AppColors.secondaryText),
                              const SizedBox(width: 4),
                              Text(
                                '${distance.toStringAsFixed(1)} km',
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(12),
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              price != null ? 'Rs. ${price.toStringAsFixed(0)}/hr' : 'Price varies',
                              style: TextStyle(
                                fontSize: _getResponsiveFontSize(12),
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _onBookPressed(context, futsal),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Book Now',
                              style: TextStyle(fontSize: _getResponsiveFontSize(13)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}