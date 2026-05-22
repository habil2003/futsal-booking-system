import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../models/futsal.dart';
import '../../providers/auth_provider.dart';
import '../../providers/futsal_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../utils/responsive.dart';
import '../login_screen.dart' show LoginScreen, LoginScreenArguments;
import '../../screens/owner/owner_dashboard.dart';
import '../../screens/admin/admin_dashboard.dart';
import 'home/widgets/filter_chips.dart';
import 'home/widgets/filter_panel.dart';
import '../../widgets/empty_state.dart';
import '../../screens/account_setting.dart';
import '../../screens/player/futsal_details_screen.dart';
import '../../screens/player/booking_history_screen.dart';
import '../../screens/player/venue_screen.dart';
import '../../screens/player/tournament_screen.dart';
import '../../screens/player/notification_screen.dart';
import '../../screens/player/account/wishlist.dart';

// ─── Modern Colour Palette ───
class AppColors {
  static const primary = Color(0xFF059669);
  static const primaryLight = Color(0xFF34D399);
  static const primaryDark = Color(0xFF047857);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF8FAFC);
  static const onBackground = Color(0xFF1E293B);
  static const secondaryText = Color(0xFF64748B);
  static const divider = Color(0xFFE2E8F0);
  static const shadow = Color(0x1A000000);
  static const accentAmber = Color(0xFFF59E0B);
  static const accentCoral = Color(0xFFEF4444);
  static const accentPurple = Color(0xFF7C3AED);
  static const cardDark1 = Color(0xFF1E293B);
  static const cardDark2 = Color(0xFF0F172A);
}

class PlayerHomeScreen extends StatefulWidget {
  const PlayerHomeScreen({super.key});
  @override
  _PlayerHomeScreenState createState() => _PlayerHomeScreenState();
}

class _PlayerHomeScreenState extends State<PlayerHomeScreen>
    with TickerProviderStateMixin {
  final PageController _adController = PageController();

  String _selectedFilter = 'All';
  bool _showFilters = false;
  int _currentAdIndex = 0;
  int _currentNavIndex = 0;

  Position? _userPosition;
  bool _isGettingLocation = false;
  double _distanceRadius = 5.0;

  late Future<List<Map<String, dynamic>>> futureAds = _fetchAds();
  late Future<List<Map<String, dynamic>>> futureTournaments =
      _fetchTournaments();

  List<String> _filters = ['All', 'Popular'];

  static const _filterKey = 'home_filter';
  static const _radiusKey = 'home_radius';
  static const _showFiltersKey = 'home_show_filters';

  double _sp(double baseSize) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 375.0).clamp(0.85, 1.2);
    return baseSize * scale;
  }

  @override
  void initState() {
    super.initState();
    _loadFilterPreferences();
    _refreshAll();
    _startAdAutoScroll();
  }

  @override
  void dispose() {
    _adController.dispose();
    super.dispose();
  }

  Future<void> _loadFilterPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedFilter = prefs.getString(_filterKey) ?? 'All';
      _distanceRadius = prefs.getDouble(_radiusKey) ?? 5.0;
      _showFilters = prefs.getBool(_showFiltersKey) ?? false;
    });
  }

  Future<void> _saveFilterPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_filterKey, _selectedFilter);
    await prefs.setDouble(_radiusKey, _distanceRadius);
    await prefs.setBool(_showFiltersKey, _showFilters);
  }

  void _startAdAutoScroll() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      if (_adController.hasClients) {
        _currentAdIndex = (_currentAdIndex + 1) % 2;
        _adController.animateToPage(
          _currentAdIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      _startAdAutoScroll();
    });
  }

  Future<void> _refreshAll() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final futsalProvider = Provider.of<FutsalProvider>(context, listen: false);
    await futsalProvider.fetchFutsals();
    if (!mounted) return;
    _updateFilters();
    if (auth.isAuthenticated) {
      final favProvider = Provider.of<FavoriteProvider>(context, listen: false);
      await favProvider.loadFavorites();
      if (!mounted) return;
    }
    setState(() {});
  }

  void _updateFilters() {
    final futsalProvider = Provider.of<FutsalProvider>(context, listen: false);
    final Set<String> filterSet = {'All', 'Popular'};
    for (var futsal in futsalProvider.futsals) {
      filterSet.addAll(futsal.getCourtTypes());
    }
    setState(() {
      _filters = filterSet.toList();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchAds() async {
    final ads = await ApiService.getActiveAds();
    return ads
        .map((ad) => {
              'image': ad['imageUrl'],
              'title': ad['title'],
              'subtitle': ad['subtitle'],
              'cta': ad['buttonText'],
              'color': AppColors.primary,
            })
        .toList()
        .cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> _fetchTournaments() async {
    try {
      final response = await ApiService.getList('tournaments/published');
      return response
          .map((t) {
            final startDate = DateTime.parse(t['startDate']);
            final endDate =
                t['endDate'] != null ? DateTime.parse(t['endDate']) : null;
            final dateStr = endDate != null
                ? '${_monthAbbr(startDate.month)} ${startDate.day} - ${_monthAbbr(endDate.month)} ${endDate.day}'
                : '${_monthAbbr(startDate.month)} ${startDate.day}';
            return {
              'name': t['name'],
              'date': dateStr,
              'prize': t['prizePool']?.toString() ?? 'TBA',
              'image': t['imageUrl'] ?? 'https://picsum.photos/id/1005/200/200',
            };
          })
          .toList()
          .cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error fetching tournaments: $e');
      return [];
    }
  }

  String _monthAbbr(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

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
                content:
                    Text('Location permission denied. Enable in settings.'),
                backgroundColor: Colors.red),
          );
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 20),
      );
      setState(() => _userPosition = position);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Location set! Showing futsals within $_distanceRadius km'),
              backgroundColor: AppColors.primary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Could not get location: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
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

  List<Futsal> get _filteredFutsals {
    final futsalProvider = Provider.of<FutsalProvider>(context, listen: false);
    var futsals = List<Futsal>.from(futsalProvider.futsals);

    // Sort by rating (highest first) – this makes Top Grounds show the best‑rated
    futsals
        .sort((a, b) => (b.averageRating ?? 0).compareTo(a.averageRating ?? 0));

    // Apply location radius filter if user has set a position
    if (_userPosition != null) {
      for (var f in futsals) {
        if (f.latitude != null && f.longitude != null) {
          f.distance = _calculateDistance(
            _userPosition!.latitude,
            _userPosition!.longitude,
            f.latitude!,
            f.longitude!,
          );
        }
      }
      futsals = futsals
          .where((f) => f.distance == null || f.distance! <= _distanceRadius)
          .toList();
    }

    return futsals;
  }

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
        builder: (context) =>
            FutsalDetailsScreen(futsal: futsal, initialTabIndex: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildHomeTab(),
          const VenueScreen(),
          _buildBookingsTab(),
          const TournamentsScreen(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.secondaryText,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        currentIndex: _currentNavIndex,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.sports_soccer), label: 'Venue'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_rounded), label: 'Bookings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_rounded), label: 'Tournaments'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
        onTap: (index) => setState(() => _currentNavIndex = index),
      ),
    );
  }

  Widget _buildHomeTab() {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          color: AppColors.primary,
          backgroundColor: Colors.white,
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _buildSearchBar(),
                ),
              ),
              if (_showFilters)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: Responsive.getScreenPadding(context),
                    child: FilterPanel(
                      userPosition: _userPosition,
                      isGettingLocation: _isGettingLocation,
                      distanceRadius: _distanceRadius,
                      onGetLocation: _getUserLocation,
                      onDistanceChanged: (value) {
                        setState(() => _distanceRadius = value);
                        _saveFilterPreferences();
                      },
                    ),
                  ),
                ),
              SliverToBoxAdapter(child: const SizedBox(height: 16)),
              SliverToBoxAdapter(child: _buildAdCarousel()),
              SliverToBoxAdapter(child: const SizedBox(height: 16)),
              SliverToBoxAdapter(child: const SizedBox(height: 16)),
              SliverToBoxAdapter(
                  child: _buildFutsalListSection('Top Grounds', maxCount: 6)),
              SliverToBoxAdapter(child: const SizedBox(height: 24)),
              SliverToBoxAdapter(child: _buildTournamentsSection()),
              SliverToBoxAdapter(child: const SizedBox(height: 24)),
              SliverToBoxAdapter(
                  child: _buildFutsalListSection('More Grounds',
                      maxCount: 4, skipCount: 6)),
              SliverToBoxAdapter(child: const SizedBox(height: 24)),
              SliverToBoxAdapter(child: _buildActionButtons()),
              SliverToBoxAdapter(child: const SizedBox(height: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsTab() {
    final auth = Provider.of<AuthProvider>(context);
    if (!auth.isAuthenticated) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_rounded,
                size: 64, color: AppColors.secondaryText),
            const SizedBox(height: 16),
            Text('Please log in to view bookings',
                style: TextStyle(
                    color: AppColors.secondaryText, fontSize: _sp(14))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
              child: Text('Login', style: TextStyle(fontSize: _sp(14))),
            ),
          ],
        ),
      );
    }
    return const BookingHistoryScreen();
  }

  Widget _buildProfileTab() {
    final auth = Provider.of<AuthProvider>(context);
    if (!auth.isAuthenticated) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline_rounded,
                size: 64, color: AppColors.secondaryText),
            const SizedBox(height: 16),
            Text('Please log in to view profile',
                style: TextStyle(
                    color: AppColors.secondaryText, fontSize: _sp(14))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
              child: Text('Login', style: TextStyle(fontSize: _sp(14))),
            ),
          ],
        ),
      );
    }
    return AccountSetting();
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: true,
      floating: false,
      snap: false,
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 80,
      centerTitle: false,
      titleSpacing: 20,
      title: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            final name = auth.user?.fullName;
            if (name != null && name.isNotEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── "Hey, Name" on the same line ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Hey, ',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: _sp(18),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        name,
                        style: TextStyle(
                          color: AppColors.onBackground,
                          fontSize: _sp(22),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // ── Current location (or “Add location” if not set) ──
                  GestureDetector(
                    onTap: _userPosition == null ? _getUserLocation : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: _userPosition != null
                              ? AppColors.primary
                              : AppColors.secondaryText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _userPosition != null
                              ? 'Current location'
                              : 'Add location',
                          style: TextStyle(
                            color: _userPosition != null
                                ? AppColors.primary
                                : AppColors.secondaryText,
                            fontSize: _sp(13),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Find Your',
                      style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: _sp(16),
                          fontWeight: FontWeight.w400)),
                  const SizedBox(height: 2),
                  Text(
                    'Perfect Futsal ⚽',
                    style: TextStyle(
                      color: AppColors.onBackground,
                      fontSize: _sp(26),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
      actions: [
        // 1. Notification bell
        IconButton(
          icon: const Icon(Icons.notifications_outlined,
              color: AppColors.onBackground),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            );
          },
        ),
        // 2. Favourite heart (only when logged in)
        Consumer<AuthProvider>(
          builder: (_, auth, __) {
            if (!auth.isAuthenticated) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.favorite_border,
                  color: AppColors.onBackground),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WishlistScreen()),
                );
              },
            );
          },
        ),
        // 3. Profile avatar (or login button)
        Consumer<AuthProvider>(
          builder: (_, auth, __) => Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: Offset(0, 2))
              ],
            ),
            child: auth.isAuthenticated
                ? PopupMenuButton<String>(
                    offset: const Offset(0, 50),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: CircleAvatar(
                      backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                      child: Icon(Icons.person, color: AppColors.primary),
                    ),
                    onSelected: (value) async {
                      if (value == 'logout') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('Logout'),
                            content: Text('Are you sure you want to logout?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text('Cancel')),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(
                                    foregroundColor: Colors.red),
                                child: Text('Logout'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await auth.logout();
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Logged out successfully'),
                                behavior: SnackBarBehavior.floating),
                          );
                        }
                      } else if (value == 'profile') {
                        setState(() => _currentNavIndex = 4);
                      } else if (value == 'dashboard') {
                        if (auth.isOwner) {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const OwnerDashboard()));
                        } else if (auth.isAdmin) {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => AdminDashboard()));
                        }
                      } else if (value == 'filters') {
                        setState(() => _showFilters = !_showFilters);
                        _saveFilterPreferences();
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem<String>(
                        value: 'filters',
                        child: Row(
                          children: [
                            Icon(Icons.filter_list,
                                color: AppColors.onBackground),
                            SizedBox(width: 12),
                            Text(
                                _showFilters ? 'Hide Filters' : 'Show Filters'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.person_outline,
                                color: AppColors.onBackground),
                            SizedBox(width: 12),
                            Text('My Profile'),
                          ],
                        ),
                      ),
                      if (auth.isOwner || auth.isAdmin)
                        PopupMenuItem<String>(
                          value: 'dashboard',
                          child: Row(
                            children: [
                              Icon(Icons.dashboard,
                                  color: AppColors.onBackground),
                              SizedBox(width: 12),
                              Text('Dashboard'),
                            ],
                          ),
                        ),
                      PopupMenuDivider(),
                      PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: AppColors.accentCoral),
                            SizedBox(width: 12),
                            Text('Logout',
                                style: TextStyle(color: AppColors.accentCoral)),
                          ],
                        ),
                      ),
                    ],
                  )
                : Material(
                    color: Colors.white,
                    shape: CircleBorder(),
                    child: InkWell(
                      onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()));
                        setState(() {});
                      },
                      customBorder: CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(Icons.login, color: AppColors.primary),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => setState(() => _currentNavIndex = 1),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: AppColors.shadow,
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.search_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search by name or location...',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: _sp(15),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildFutsalListSection(String title,
      {required int maxCount, int skipCount = 0}) {
    final allFutsals = _filteredFutsals;
    final sliced = allFutsals.skip(skipCount).take(maxCount).toList();
    if (sliced.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: TextStyle(
                        color: AppColors.onBackground,
                        fontSize: _sp(20),
                        fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => setState(() => _currentNavIndex = 1),
                  child: Text('See All',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: _sp(14),
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 230,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: sliced.length,
              padding: const EdgeInsets.only(right: 16),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 200,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _buildSquareFutsalCard(sliced[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareFutsalCard(Futsal futsal) {
    final imageUrl = futsal.images.isNotEmpty
        ? futsal.images[0]
        : 'https://via.placeholder.com/300x200?text=Futsal';
    final rating = futsal.averageRating ?? 4.5;
    final price = futsal.getMinPrice();

    return GestureDetector(
      onTap: () => _onBookPressed(context, futsal),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: AppColors.primary.withOpacity(0.05),
                    child: Icon(Icons.sports_soccer,
                        color: AppColors.primary, size: 40),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: Consumer<FavoriteProvider>(
                      builder: (context, fav, _) {
                        final isFav = fav.isFavorite(futsal.id);
                        return InkWell(
                          onTap: () async {
                            final auth = Provider.of<AuthProvider>(context,
                                listen: false);
                            if (!auth.isAuthenticated) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Please log in to save favorites'),
                                    backgroundColor: Colors.orange),
                              );
                              return;
                            }
                            final success = await fav.toggleFavorite(futsal.id);
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isFav
                                      ? 'Removed from favorites'
                                      : 'Added to favorites'),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? AppColors.accentCoral : Colors.white,
                            size: 18,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(futsal.name,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: _sp(15),
                          color: AppColors.onBackground),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.secondaryText),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          futsal.address.split(',').first,
                          style: TextStyle(
                              fontSize: _sp(12),
                              color: AppColors.secondaryText),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentAmber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star_rounded,
                                size: 14, color: AppColors.accentAmber),
                            const SizedBox(width: 4),
                            Text(rating.toStringAsFixed(1),
                                style: TextStyle(
                                    fontSize: _sp(13),
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onBackground)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        price != null
                            ? 'Rs. ${price.toStringAsFixed(0)}/hr'
                            : 'Price varies',
                        style: TextStyle(
                            fontSize: _sp(13),
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdCarousel() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: futureAds,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildAdShimmer();
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox.shrink();
        }
        final ads = snapshot.data!;
        return Column(
          children: [
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _adController,
                onPageChanged: (index) =>
                    setState(() => _currentAdIndex = index),
                itemCount: ads.length,
                itemBuilder: (context, index) => _buildAdCard(ads[index]),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                ads.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentAdIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentAdIndex == index
                        ? AppColors.primary
                        : AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdCard(Map<String, dynamic> ad) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Image.network(ad['image'],
                height: 200, width: double.infinity, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.cardDark1.withOpacity(0.85),
                    AppColors.cardDark2.withOpacity(0.5),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(ad['title'],
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: _sp(24),
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(ad['subtitle'],
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: _sp(14))),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(ad['cta'],
                        style: TextStyle(
                            fontSize: _sp(14), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdShimmer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }

  Widget _buildTournamentsSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: futureTournaments,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildHorizontalShimmer();
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox.shrink();
        }
        final tournaments = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('🏆 Upcoming Tournaments',
                      style: TextStyle(
                          color: AppColors.onBackground,
                          fontSize: _sp(20),
                          fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => setState(() => _currentNavIndex = 3),
                    child: Text('View All',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: _sp(14),
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: tournaments.length,
                itemBuilder: (context, index) {
                  final t = tournaments[index];
                  return Container(
                    width: 300,
                    margin: const EdgeInsets.only(right: 16, bottom: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          bottom: -20,
                          child: Icon(Icons.emoji_events,
                              size: 100, color: Colors.white.withOpacity(0.1)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t['name'],
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: _sp(18),
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded,
                                      size: 16, color: Colors.white70),
                                  const SizedBox(width: 6),
                                  Text(t['date'],
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: _sp(13))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.emoji_events_rounded,
                                      size: 16, color: AppColors.accentAmber),
                                  const SizedBox(width: 6),
                                  Text('Prize: ${t['prize']}',
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: _sp(13))),
                                ],
                              ),
                              const Spacer(),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.accentPurple,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  child: Text('Register',
                                      style: TextStyle(
                                          fontSize: _sp(14),
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHorizontalShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 150, height: 20, color: AppColors.divider),
          SizedBox(height: 12),
          Row(
            children: List.generate(
              3,
              (index) => Container(
                width: 200,
                height: 180,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isAuthenticated) return const SizedBox.shrink();
        final isDesktop = Responsive.isDesktop(context);
        final buttonPadding = EdgeInsets.symmetric(
          horizontal: isDesktop ? 24 : 20,
          vertical: isDesktop ? 18 : 14,
        );
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              Container(height: 1, color: AppColors.divider),
              const SizedBox(height: 24),
              Text('Ready to get started?',
                  style: TextStyle(
                      color: AppColors.onBackground,
                      fontSize: _sp(isDesktop ? 22 : 20),
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Login to book or register your futsal',
                  style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: _sp(isDesktop ? 15 : 13))),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                          settings: const RouteSettings(
                            arguments: LoginScreenArguments(
                                isLogin: true, selectedRole: 'PLAYER'),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.login_rounded, size: 20),
                    label: Text('Login',
                        style: TextStyle(
                            fontSize: _sp(15), fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: buttonPadding,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                          settings: RouteSettings(
                            arguments: LoginScreenArguments(
                                isLogin: false, selectedRole: 'OWNER'),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_business_rounded, size: 20),
                    label: Text('Register Futsal',
                        style: TextStyle(
                            fontSize: _sp(15), fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary, width: 1.5),
                      padding: buttonPadding,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
