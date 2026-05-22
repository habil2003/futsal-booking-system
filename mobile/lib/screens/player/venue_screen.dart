import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/futsal.dart';
import '../../providers/futsal_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/auth_provider.dart';
import '../login_screen.dart';
import 'futsal_details_screen.dart';
import 'home_screen.dart'; // for AppColors

class VenueScreen extends StatefulWidget {
  const VenueScreen({super.key});

  @override
  State<VenueScreen> createState() => _VenueScreenState();
}

class _VenueScreenState extends State<VenueScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  String _selectedFilter = 'All';
  static final List<String> _filters = [
    'All',
    'Nearby',
    'Popular',
    '5-A-Side',
    '6-A-Side',
  ]..sort((a, b) {
    if (a == 'All') return -1; 
    if (b == 'All') return 1;
    return a.compareTo(b);       
  });

  Position? _userPosition;
  bool _isGettingLocation = false;
  static const double _nearbyRadiusKm = 10.0;

  @override
  void initState() {
    super.initState();
    _getUserLocation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FutsalProvider>(context, listen: false).fetchFutsals();
    });
  }

  // ─────────── Location ───────────
  Future<void> _getUserLocation() async {
    setState(() => _isGettingLocation = true);
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
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
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

  // ─────────── Navigation ───────────
  void _onBookPressed(BuildContext context, Futsal futsal) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      final didLogin = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 100, 
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Find Futsal',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: 10),
            // Search bar
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.divider),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                style: const TextStyle(fontSize: 15, color: AppColors.onBackground),
                decoration: InputDecoration(
                  hintText: 'Search venues...',
                  hintStyle: TextStyle(color: AppColors.secondaryText.withOpacity(0.7)),
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.onBackground,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.divider,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
          // Venue list
          Expanded(
            child: _buildResultsList(filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(List<Futsal> results) {
    if (_selectedFilter == 'Nearby' && _userPosition == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off, size: 64, color: AppColors.secondaryText),
            const SizedBox(height: 12),
            Text('Location not available',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 16)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _getUserLocation,
              icon: const Icon(Icons.my_location),
              label: const Text('Enable Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
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
            Icon(Icons.search_off, size: 64, color: AppColors.secondaryText),
            const SizedBox(height: 12),
            Text('No venues found',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) => _buildResultCard(results[index]),
    );
  }

  Widget _buildResultCard(Futsal futsal) {
    final imageUrl = futsal.images.isNotEmpty
        ? futsal.images[0]
        : 'https://via.placeholder.com/300x180?text=Futsal';
    final rating = futsal.averageRating ?? 4.5;
    final price = futsal.getMinPrice();
    final distance = futsal.distance;

    return GestureDetector(
      onTap: () => _onBookPressed(context, futsal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
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
                  color: AppColors.primary.withOpacity(0.05),
                  child: const Icon(Icons.sports_soccer, color: AppColors.primary, size: 40),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(futsal.name,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.onBackground),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: AppColors.secondaryText),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(futsal.address,
                            style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentAmber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star_rounded, size: 14, color: AppColors.accentAmber),
                            const SizedBox(width: 4),
                            Text(rating.toStringAsFixed(1),
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onBackground)),
                          ],
                        ),
                      ),
                      if (distance != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.directions_walk, size: 14, color: AppColors.secondaryText),
                        const SizedBox(width: 4),
                        Text('${distance.toStringAsFixed(1)} km',
                            style: TextStyle(fontSize: 13, color: AppColors.secondaryText)),
                      ],
                      const Spacer(),
                      Text(
                        price != null ? 'Rs. ${price.toStringAsFixed(0)}/hr' : 'Price varies',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Consumer<FavoriteProvider>(
              builder: (context, favProvider, child) {
                final isFav = favProvider.isFavorite(futsal.id);
                return IconButton(
                  icon: Icon(
                    isFav ? Icons.bookmark : Icons.bookmark_border,
                    color: isFav ? AppColors.primary : AppColors.secondaryText,
                    size: 28,
                  ),
                  onPressed: () async {
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    if (!auth.isAuthenticated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please log in to save favorites'),
                            backgroundColor: Colors.orange),
                      );
                      return;
                    }
                    final success = await favProvider.toggleFavorite(futsal.id);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isFav ? 'Removed from favorites' : 'Added to favorites'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}