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
import 'package:url_launcher/url_launcher.dart';
import '../../screens/player/futsal_details_screen.dart';
import '../../screens/player/booking_history_screen.dart';
import '../../screens/player/search_screen.dart';
import '../../screens/player/tournament_screen.dart';   // adjust name if needed

class PlayerHomeScreen extends StatefulWidget {
  const PlayerHomeScreen({super.key});

  @override
  _PlayerHomeScreenState createState() => _PlayerHomeScreenState();
}

class _PlayerHomeScreenState extends State<PlayerHomeScreen>
    with TickerProviderStateMixin {
  final PageController _adController = PageController();
  final PageController _productAdController = PageController();
  int _currentProductAdIndex = 0;
  late Future<List<Map<String, dynamic>>> futureProductAds;

  String _selectedFilter = 'All';
  bool _showFilters = false;
  int _currentAdIndex = 0;
  int _currentNavIndex = 0;       // controls which tab is displayed

  Position? _userPosition;
  bool _isGettingLocation = false;
  double _distanceRadius = 5.0;

  late Future<List<Map<String, dynamic>>> futureAds = _fetchAds();
  late Future<List<Map<String, dynamic>>> futureTournaments = _fetchTournaments();

  List<String> _filters = ['All', 'Popular'];

  static const _filterKey = 'home_filter';
  static const _radiusKey = 'home_radius';
  static const _showFiltersKey = 'home_show_filters';

  // ─── Time‑based greeting ───
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 16) return 'Good Afternoon';
    if (hour < 20) return 'Good Evening';
    return 'Good Night';
  }

  Widget _buildGreetingRow(String greeting) {
    IconData icon;
    switch (greeting) {
      case 'Good Morning':
        icon = Icons.waving_hand;
        break;
      case 'Good Afternoon':
        icon = Icons.wb_sunny;
        break;
      case 'Good Evening':
        icon = Icons.wb_twilight;
        break;
      case 'Good Night':
        icon = Icons.bedtime;
        break;
      default:
        icon = Icons.wb_sunny;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 6),
        Text(
          greeting,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _loadFilterPreferences();
    _refreshAll();
    _startAdAutoScroll();

    futureProductAds = _fetchProductAds();
    _startProductAdAutoScroll();
  }

  @override
  void dispose() {
    _adController.dispose();
    _productAdController.dispose();
    super.dispose();
  }

  // ────────────────── Persistence ──────────────────
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

  void _startProductAdAutoScroll() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      if (_productAdController.hasClients) {
        _currentProductAdIndex = (_currentProductAdIndex + 1) % 3;
        _productAdController.animateToPage(
          _currentProductAdIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      _startProductAdAutoScroll();
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
      final courtTypes = futsal.getCourtTypes();
      filterSet.addAll(courtTypes);
    }

    setState(() {
      _filters = filterSet.toList();
    });
  }

  // ────────────────── Data fetching ──────────────────
  Future<List<Map<String, dynamic>>> _fetchAds() async {
    final ads = await ApiService.getActiveAds();
    return ads.map((ad) => {
      'image': ad['imageUrl'],
      'title': ad['title'],
      'subtitle': ad['subtitle'],
      'cta': ad['buttonText'],
      'color': Colors.deepPurple,
    }).toList().cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> _fetchTournaments() async {
    try {
      final response = await ApiService.getList('tournaments/published');
      return response.map((t) {
        final startDate = DateTime.parse(t['startDate']);
        final endDate = t['endDate'] != null ? DateTime.parse(t['endDate']) : null;
        final dateStr = endDate != null
            ? '${_monthAbbr(startDate.month)} ${startDate.day} - ${_monthAbbr(endDate.month)} ${endDate.day}'
            : '${_monthAbbr(startDate.month)} ${startDate.day}';
        return {
          'name': t['name'],
          'date': dateStr,
          'prize': t['prizePool']?.toString() ?? 'TBA',
          'image': t['imageUrl'] ?? 'https://picsum.photos/id/1005/200/200',
        };
      }).toList().cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error fetching tournaments: $e');
      return [];
    }
  }

  String _monthAbbr(int month) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[month - 1];
  }

  Future<List<Map<String, dynamic>>> _fetchProductAds() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return [
      {
        'gradientStart': Colors.blueGrey.shade800,
        'gradientEnd': Colors.black87,
        'tag': '⚡ GEAR UP!',
        'title': 'Premium Jerseys',
        'subtitle': 'Up to 40% off • Free shipping',
        'buttonText': 'SHOP NOW',
        'buttonColor': Colors.amber.shade600,
        'imageUrl':
            'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800&h=400&fit=crop',
        'externalUrl': 'https://www.example.com/jerseys',
      },
      {
        'gradientStart': Colors.deepOrange.shade700,
        'gradientEnd': Colors.brown.shade900,
        'tag': '👟 NEW ARRIVALS',
        'title': 'Pro Football Boots',
        'subtitle': 'Lightweight • 20% off first order',
        'buttonText': 'EXPLORE',
        'buttonColor': Colors.white,
        'imageUrl':
            'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800&h=400&fit=crop',
        'externalUrl': 'https://www.example.com/boots',
      },
      {
        'gradientStart': Colors.indigo.shade600,
        'gradientEnd': Colors.purple.shade900,
        'tag': '🏷️ LIMITED OFFER',
        'title': 'Complete Kit Set',
        'subtitle': 'Jersey + Shorts + Socks',
        'buttonText': 'BUY NOW',
        'buttonColor': Colors.yellow.shade600,
        'imageUrl':
            'https://images.unsplash.com/photo-1551958219-acbc608c6377?w=800&h=400&fit=crop',
        'externalUrl': 'https://www.example.com/kits',
      },
    ];
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
            const SnackBar(content: Text('Location permission denied. Enable in settings.'), backgroundColor: Colors.red),
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
          SnackBar(content: Text('Location set! Showing futsals within $_distanceRadius km'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e'), backgroundColor: Colors.red),
        );
      }
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

  List<Futsal> get _filteredFutsals {
    final futsalProvider = Provider.of<FutsalProvider>(context, listen: false);
    var futsals = futsalProvider.futsals;

    if (_selectedFilter != 'All' && _selectedFilter != 'Popular') {
      futsals = futsals.where((f) {
        final courtTypes = f.getCourtTypes();
        return courtTypes.contains(_selectedFilter);
      }).toList();
    }

    if (_userPosition != null) {
      for (var futsal in futsals) {
        if (futsal.latitude != null && futsal.longitude != null) {
          futsal.distance = _calculateDistance(
            _userPosition!.latitude, _userPosition!.longitude,
            futsal.latitude!, futsal.longitude!,
          );
        }
      }
      futsals = futsals.where((f) => f.distance == null || f.distance! <= _distanceRadius).toList();
      futsals.sort((a, b) => (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity));
    }

    if (_selectedFilter == 'Popular') {
      futsals.sort((a, b) => (b.averageRating ?? 0).compareTo(a.averageRating ?? 0));
    }

    return futsals;
  }

  void _onBookPressed(BuildContext context, Futsal futsal) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      final didLogin = await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()),
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
        builder: (context) => FutsalDetailsScreen(futsal: futsal, initialTabIndex: 1),
      ),
    );
  }

  // ────────────────── Main Build with persistent bottom nav ──────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildHomeTab(),                // 0 – Home
          const SearchScreen(),           // 1 – Search
          _buildBookingsTab(),            // 2 – Bookings
          const TournamentsScreen(),      // 3 – Tournaments
          _buildProfileTab(),             // 4 – Profile
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey.shade500,
        showUnselectedLabels: false,
        showSelectedLabels: false,
        currentIndex: _currentNavIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Tournaments'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
        onTap: (index) {
          setState(() => _currentNavIndex = index);
        },
      ),
    );
  }

  // ─────────── Tab Builders ───────────
  Widget _buildHomeTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.green.shade900, Colors.black87],
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          color: Colors.white,
          backgroundColor: Colors.green.shade700,
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
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
              SliverToBoxAdapter(child: _buildAdCarousel()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: FilterChips(
                    filters: _filters,
                    selectedFilter: _selectedFilter,
                    onFilterSelected: (filter) {
                      setState(() => _selectedFilter = filter);
                      _saveFilterPreferences();
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildFutsalListSection('Top Grounds', maxCount: 6)),
              SliverToBoxAdapter(child: _buildTournamentsSection()),
              SliverToBoxAdapter(child: _buildFutsalListSection('More Grounds', maxCount: 4, skipCount: 6)),
              SliverToBoxAdapter(child: _buildProductAdCarousel()),
              SliverToBoxAdapter(child: _buildActionButtons()),
              SliverToBoxAdapter(child: _buildFooter()),
              SliverToBoxAdapter(child: SizedBox(height: 1)),
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
            Icon(Icons.calendar_today, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Please log in to view bookings', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('Login'),
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
            Icon(Icons.person_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Please log in to view profile', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );
    }
    return AccountSetting();
  }

  // ─────────── Sliver App Bar with Greeting ───────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      floating: true,
      pinned: false,
      snap: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      title: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final name = auth.user?.fullName;
          if (name != null && name.isNotEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreetingRow(_getGreeting()),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    shadows: [Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 2))],
                  ),
                ),
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Find Your', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w400)),
                const Text(
                  'Perfect Futsal ⚽',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    shadows: [Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 2))],
                  ),
                ),
              ],
            );
          }
        },
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {},
        ),
        Consumer<AuthProvider>(
          builder: (_, auth, __) => Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: auth.isAuthenticated
                ? PopupMenuButton<String>(
                    offset: Offset(0, 50),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Colors.green.shade700),
                    ),
                    onSelected: (value) async {
                      if (value == 'logout') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('Logout'),
                            content: Text('Are you sure you want to logout?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: Text('Logout'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await auth.logout();
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Logged out successfully'), behavior: SnackBarBehavior.floating),
                          );
                        }
                      } else if (value == 'profile') {
                        setState(() => _currentNavIndex = 4); // switch to profile tab
                      } else if (value == 'dashboard') {
                        if (auth.isOwner) {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OwnerDashboard()));
                        } else if (auth.isAdmin) {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminDashboard()));
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
                            Icon(Icons.filter_list, color: Colors.grey.shade700),
                            SizedBox(width: 12),
                            Text(_showFilters ? 'Hide Filters' : 'Show Filters'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.person_outline, color: Colors.grey.shade700),
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
                              Icon(Icons.dashboard, color: Colors.grey.shade700),
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
                            Icon(Icons.logout, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Logout', style: TextStyle(color: Colors.red)),
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
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                        setState(() {});
                      },
                      customBorder: CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(Icons.login, color: Colors.green.shade700),
                      ),
                    ),
                  ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _buildSearchBar(),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () {
        setState(() => _currentNavIndex = 1);   // switch to search tab instead of push
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 4))],
          border: Border.all(color: Colors.white30, width: 1),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.search, color: Colors.green, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search by name or location...',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.w400),
              ),
            ),
            const Icon(Icons.tune, color: Colors.grey, size: 20),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  // ─────────── Futsal List Section ───────────
  Widget _buildFutsalListSection(String title, {required int maxCount, int skipCount = 0}) {
    final allFutsals = _filteredFutsals;
    final sliced = allFutsals.skip(skipCount).take(maxCount).toList();
    if (sliced.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: () => setState(() => _currentNavIndex = 1),   // go to search tab
                  child: Text('See All', style: TextStyle(color: Colors.green.shade300, fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 210,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: sliced.length,
              padding: const EdgeInsets.only(right: 16),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 190,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
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

  // ─────────── Ad Carousel ───────────
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
              height: 180,
              child: PageView.builder(
                controller: _adController,
                onPageChanged: (index) => setState(() => _currentAdIndex = index),
                itemCount: ads.length,
                itemBuilder: (context, index) => _buildAdCard(ads[index]),
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                ads.length,
                (index) => AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: _currentAdIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentAdIndex == index ? Colors.green.shade400 : Colors.white38,
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
            color: (ad['color'] as Color?)?.withOpacity(0.3) ?? Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Image.network(ad['image'], height: 180, width: double.infinity, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(ad['title'], style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text(ad['subtitle'], style: TextStyle(color: Colors.white70, fontSize: 14)),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ad['color'] ?? Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(ad['cta']),
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
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }

  // ─────────── Featured Section (inactive) ───────────
  Widget _buildFeaturedSection() {
    return Consumer<FutsalProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.futsals.isEmpty) {
          return _buildHorizontalShimmer();
        }
        if (provider.futsals.isEmpty) {
          return SizedBox.shrink();
        }
        final featured = provider.futsals.take(4).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('✨ Featured Grounds', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  TextButton(
                    onPressed: () {},
                    child: Text('See All', style: TextStyle(color: Colors.green.shade300)),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: featured.length,
                itemBuilder: (context, index) => _buildFeaturedCard(featured[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeaturedCard(Futsal futsal) {
    final imageUrl = futsal.images.isNotEmpty ? futsal.images[0] : 'https://via.placeholder.com/300x200?text=Futsal';
    return Hero(
      tag: 'featured-${futsal.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onBookPressed(context, futsal),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 200,
            margin: const EdgeInsets.only(right: 16, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  child: Stack(
                    children: [
                      Image.network(imageUrl, height: 120, width: double.infinity, fit: BoxFit.cover),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Consumer<FavoriteProvider>(
                          builder: (context, favProvider, child) {
                            final isFav = favProvider.isFavorite(futsal.id);
                            return Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: InkWell(
                                onTap: () async {
                                  final auth = Provider.of<AuthProvider>(context, listen: false);
                                  if (!auth.isAuthenticated) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please log in to save favorites'), backgroundColor: Colors.orange),
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
                                child: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.white, size: 16),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(futsal.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(futsal.address.split(',').first, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(futsal.averageRating?.toStringAsFixed(1) ?? '4.5', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Spacer(),
                          Text(
                            futsal.getMinPrice() != null ? 'Rs. ${futsal.getMinPrice()!.toStringAsFixed(0)}/hr' : '',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────── Tournaments Section ───────────
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
                  Text('🏆 Upcoming Tournaments', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  TextButton(
                    onPressed: () => setState(() => _currentNavIndex = 3),   // go to tournaments tab
                    child: Text('View All', style: TextStyle(color: Colors.green.shade300)),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: tournaments.length,
                itemBuilder: (context, index) {
                  final t = tournaments[index];
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 16, bottom: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.deepPurple.shade400, Colors.purple.shade900],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 4))
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          bottom: -20,
                          child: Icon(Icons.emoji_events, size: 100, color: Colors.white.withOpacity(0.1)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t['name'], style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                                  SizedBox(width: 6),
                                  Text(t['date'], style: TextStyle(color: Colors.white70)),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.emoji_events, size: 14, color: Colors.amber),
                                  SizedBox(width: 6),
                                  Text('Prize: ${t['prize']}', style: TextStyle(color: Colors.white70)),
                                ],
                              ),
                              Spacer(),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.purple,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                child: Text('Register'),
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
          Container(width: 150, height: 20, color: Colors.grey.shade800),
          SizedBox(height: 12),
          Row(
            children: List.generate(3, (index) => Container(
                  width: 200,
                  height: 180,
                  margin: EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(20)),
                )),
          ),
        ],
      ),
    );
  }

  // ─────────── Product Ad Carousel ───────────
  Widget _buildProductAdCarousel() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: futureProductAds,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildProductAdShimmer();
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final ads = snapshot.data!;
        final screenWidth = MediaQuery.of(context).size.width;
        final bannerHeight = screenWidth * 0.35;
        final maxHeight = 180.0;
        final minHeight = 130.0;
        final height = bannerHeight.clamp(minHeight, maxHeight);
        return Column(
          children: [
            SizedBox(
              height: height,
              child: PageView.builder(
                controller: _productAdController,
                onPageChanged: (index) => setState(() => _currentProductAdIndex = index),
                itemCount: ads.length,
                itemBuilder: (context, index) {
                  final ad = ads[index];
                  return _buildProductAdCard(ad, height);
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                ads.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentProductAdIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentProductAdIndex == index ? Colors.amber.shade400 : Colors.white38,
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

  Widget _buildProductAdCard(Map<String, dynamic> ad, double height) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ad['gradientStart'], ad['gradientEnd']],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black38, blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _launchURL(ad['externalUrl']),
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: height * 2.5,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Image.network(
                      ad['imageUrl'],
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.shopping_bag,
                        size: height * 0.5,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(height * 0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        ad['tag'],
                        style: TextStyle(
                          color: Colors.amber.shade300,
                          fontSize: height * 0.08,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ad['title'],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: height * 0.14,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black38, blurRadius: 6)],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ad['subtitle'],
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: height * 0.09,
                          shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _launchURL(ad['externalUrl']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ad['buttonColor'],
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: EdgeInsets.symmetric(
                            horizontal: height * 0.12,
                            vertical: height * 0.05,
                          ),
                        ),
                        child: Text(ad['buttonText'], style: TextStyle(fontSize: height * 0.08)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductAdShimmer() {
    final screenWidth = MediaQuery.of(context).size.width;
    final height = (screenWidth * 0.35).clamp(130.0, 180.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }

  // ─────────── Action Buttons ───────────
  Widget _buildActionButtons() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isAuthenticated) return const SizedBox.shrink();
        final isDesktop = Responsive.isDesktop(context);
        final buttonPadding = EdgeInsets.symmetric(
          horizontal: isDesktop ? 24 : 16,
          vertical: isDesktop ? 16 : 12,
        );
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              const Divider(color: Colors.white24, thickness: 1),
              const SizedBox(height: 20),
              Text('Ready to get started?',
                  style: TextStyle(color: Colors.white, fontSize: isDesktop ? 20 : 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Login to book or register your futsal',
                  style: TextStyle(color: Colors.white70, fontSize: isDesktop ? 14 : 12)),
              const SizedBox(height: 24),
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
                            arguments: LoginScreenArguments(isLogin: true, selectedRole: 'PLAYER'),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Login as Player'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: buttonPadding,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
                            arguments: LoginScreenArguments(isLogin: false, selectedRole: 'OWNER'),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_business),
                    label: const Text('Register Futsal'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: buttonPadding,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ─────────── Footer ───────────
  Widget _buildFooter() {
    final isDesktop = Responsive.isDesktop(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 24,
        vertical: isDesktop ? 40 : 30,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade900.withOpacity(0.8),
            Colors.black.withOpacity(0.6),
          ],
        ),
        border: Border(top: BorderSide(color: Colors.white24, width: 1)),
      ),
      child: isMobile ? _buildMobileFooter() : _buildDesktopFooter(isDesktop),
    );
  }

  Widget _buildDesktopFooter(bool isDesktop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.sports_soccer, color: Colors.white, size: 28),
                  const SizedBox(width: 8),
                  Text('Futsal Booking',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Your one-stop platform for booking futsal grounds, managing tournaments, and connecting with players.',
                style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildSocialIcon(Icons.facebook, 'Facebook'),
                  const SizedBox(width: 12),
                  _buildSocialIcon(Icons.camera_alt, 'Instagram'),
                  const SizedBox(width: 12),
                  _buildSocialIcon(Icons.alternate_email, 'Twitter'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 40),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quick Links', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildFooterLink('About Us'),
              _buildFooterLink('How It Works'),
              _buildFooterLink('Pricing'),
              _buildFooterLink('FAQs'),
              _buildFooterLink('Blog'),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Services', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildFooterLink('Book a Ground'),
              _buildFooterLink('Tournaments'),
              _buildFooterLink('Become an Owner'),
              _buildFooterLink('Player Community'),
              _buildFooterLink('Gift Cards'),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Contact Us', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildContactItem(Icons.email_outlined, 'support@futsalbooking.com'),
              const SizedBox(height: 8),
              _buildContactItem(Icons.phone_outlined, '+977 980-0000000'),
              const SizedBox(height: 8),
              _buildContactItem(Icons.location_on_outlined, 'Kathmandu, Nepal'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.sports_soccer, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text('Futsal Booking', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Your one-stop platform for booking futsal grounds, managing tournaments, and connecting with players.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Links', style: _footerHeadingStyle()),
                  const SizedBox(height: 12),
                  _buildFooterLink('About Us'),
                  _buildFooterLink('How It Works'),
                  _buildFooterLink('FAQs'),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Services', style: _footerHeadingStyle()),
                  const SizedBox(height: 12),
                  _buildFooterLink('Book a Ground'),
                  _buildFooterLink('Tournaments'),
                  _buildFooterLink('Become an Owner'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Contact Us', style: _footerHeadingStyle()),
        const SizedBox(height: 12),
        _buildContactItem(Icons.email_outlined, 'support@futsalbooking.com'),
        const SizedBox(height: 8),
        _buildContactItem(Icons.phone_outlined, '+977 980-0000000'),
        const SizedBox(height: 8),
        _buildContactItem(Icons.location_on_outlined, 'Kathmandu, Nepal'),
        const SizedBox(height: 24),
        Row(
          children: [
            _buildSocialIcon(Icons.facebook, 'Facebook'),
            const SizedBox(width: 16),
            _buildSocialIcon(Icons.camera_alt, 'Instagram'),
            const SizedBox(width: 16),
            _buildSocialIcon(Icons.alternate_email, 'Twitter'),
          ],
        ),
      ],
    );
  }

  TextStyle _footerHeadingStyle() =>
      TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold);

  Widget _buildFooterLink(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: InkWell(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$text page coming soon'))),
        child: Text(text, style: TextStyle(color: Colors.white70, fontSize: 14)),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.green.shade300, size: 18),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, String platform) {
    return InkWell(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$platform link coming soon'))),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }

  // ─────────── Square Futsal Card (horizontal slider) ───────────
  Widget _buildSquareFutsalCard(Futsal futsal) {
    final imageUrl = futsal.images.isNotEmpty
        ? futsal.images[0]
        : 'https://via.placeholder.com/300x200?text=Futsal';
    final rating = futsal.averageRating ?? 4.5;
    final price = futsal.getMinPrice();

    return GestureDetector(
      onTap: () => _onBookPressed(context, futsal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 110,
                  color: Colors.green.shade50,
                  child: const Icon(Icons.sports_soccer, color: Colors.green, size: 40),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(futsal.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: Colors.grey),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          futsal.address.split(',').first,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(
                        price != null ? 'Rs. ${price.toStringAsFixed(0)}/hr' : 'Price varies',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green.shade700),
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
}