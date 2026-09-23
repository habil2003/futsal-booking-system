import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../models/futsal.dart';
import '../../providers/auth_provider.dart';
import '../../providers/futsal_provider.dart';
import '../../providers/favorite_provider.dart';
import '../login_screen.dart';
import '../../screens/owner/owner_dashboard.dart';
import '../../screens/admin/admin_account.dart';
import '../../screens/player/futsal_details_screen.dart';
import '../../screens/player/booking_history_screen.dart';
import '../../screens/player/venue_screen.dart';
import '../../screens/player/tournament_screen.dart';
import '../../screens/player/notification_screen.dart';
import '../../screens/player/account/wishlist.dart';
import '../../screens/account_setting.dart';

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
  static const white = Color(0xFFFFFFFF);
}

class PlayerHomeScreen extends StatefulWidget {
  const PlayerHomeScreen({super.key});

  @override
  State<PlayerHomeScreen> createState() => _PlayerHomeScreenState();
}

class _PlayerHomeScreenState extends State<PlayerHomeScreen>
    with TickerProviderStateMixin {
  int _currentTab = 0;
  int _unreadNotifications = 0;
  bool _showFilters = false;
  String _searchQuery = '';
  String? _selectedArea;

  // Focus node for search
  final FocusNode _searchFocusNode = FocusNode();

  // Ad carousel controllers
  late PageController _bannerController;
  late AnimationController _fadeController;
  Timer? _adScrollTimer;
  int _currentAdIndex = 0;
  List<dynamic> _ads = [];
  bool _isLoadingAds = true;

  @override
  void initState() {
    super.initState();
    _bannerController = PageController();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadData();
    _fetchAds();
    _startAdAutoScroll();
  }

  @override
  void dispose() {
    _adScrollTimer?.cancel();
    _bannerController.dispose();
    _fadeController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchAds() async {
    try {
      final ads = await ApiService.getActiveAds();
      setState(() {
        _ads = ads;
        _isLoadingAds = false;
      });
      _fadeController.forward();
    } catch (e) {
      debugPrint('Error fetching ads: $e');
      setState(() => _isLoadingAds = false);
    }
  }

  void _startAdAutoScroll() {
    _adScrollTimer?.cancel();
    _adScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!_bannerController.hasClients) return;
      if (_ads.isEmpty) {
        _fetchAds();
        return;
      }
      _currentAdIndex = (_currentAdIndex + 1) % _ads.length;
      _bannerController.animateToPage(
        _currentAdIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  Future<void> _loadData() async {
    await _loadUnreadCount();
    if (!mounted) return;
    await Provider.of<FutsalProvider>(context, listen: false).fetchFutsals();
    if (!mounted) return;

    if (Provider.of<AuthProvider>(context, listen: false).isAuthenticated) {
      await Provider.of<FavoriteProvider>(context, listen: false)
          .loadFavorites();
    }
    setState(() {});
  }

  Future<void> _loadUnreadCount() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (!auth.isAuthenticated) return;
      final response = await ApiService.get('notifications/unread-count');
      if (mounted && response['status'] == 'success') {
        setState(() => _unreadNotifications = response['unreadCount'] ?? 0);
      }
    } catch (_) {}
  }

  // ==================== AREA FILTER ====================

  // Distinct areas derived from venue addresses, e.g. "Ganesh Tole".
  List<String> get _availableAreas {
    final futsals =
        Provider.of<FutsalProvider>(context, listen: false).futsals;
    final areas = <String>{};
    for (final f in futsals) {
      final area = _areaFromAddress(f.address);
      if (area.isNotEmpty) areas.add(area);
    }
    final sorted = areas.toList()..sort();
    return sorted;
  }

  // Extract the leading area/town name from an address like
  // "Ganesh Tole, Pokhara-4 33700" -> "Ganesh Tole".
  static String _areaFromAddress(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split(',');
    if (parts.isNotEmpty && parts.first.trim().isNotEmpty) {
      return parts.first.trim();
    }
    return trimmed;
  }

  List<Futsal> get _filteredFutsals {
    var futsals =
        Provider.of<FutsalProvider>(context, listen: false).futsals.toList();

    // Filter by search query (name or address)
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      futsals = futsals
          .where((f) =>
              f.name.toLowerCase().contains(q) ||
              f.address.toLowerCase().contains(q))
          .toList();
    }

    // Filter by selected area
    if (_selectedArea != null) {
      futsals = futsals
          .where((f) => _areaFromAddress(f.address) == _selectedArea)
          .toList();
    }

    // Sort by rating
    futsals
        .sort((a, b) => (b.averageRating ?? 0).compareTo(a.averageRating ?? 0));

    return futsals;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
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
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.secondaryText,
        currentIndex: _currentTab,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.sports_soccer), label: 'Venue'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'Bookings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events), label: 'Tournaments'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) => setState(() => _currentTab = index),
      ),
    );
  }

  // ==================== HOME TAB ====================

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildSearchBar()),
          if (_showFilters) SliverToBoxAdapter(child: _buildFilterPanel()),
          SliverToBoxAdapter(child: _buildAnimatedAdCarousel()),

          // THIS IS THE PART TO CHANGE - Replace this line:
          SliverToBoxAdapter(
            child: _buildSectionHeader('Top Grounds', onSeeAll: () {
              setState(() {
                _searchQuery = ''; // Clear search query
                _selectedArea = null; // Clear area filter
                _currentTab = 1; // Switch to Venue tab
              });
            }),
          ),

          SliverToBoxAdapter(child: _buildFutsalList(maxItems: 6)),
          SliverToBoxAdapter(
              child: _buildSectionHeader('Upcoming Tournaments',
                  onSeeAll: () => setState(() => _currentTab = 3))),
          SliverToBoxAdapter(child: _buildTournamentsList()),
          SliverToBoxAdapter(child: _buildLoginPrompt()),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.white,
      elevation: 0,
      titleSpacing: 20,
      title: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final name = auth.user?.fullName;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name != null ? 'Hey, $name' : 'Find Your Perfect Futsal ⚽',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onBackground,
                ),
              ),
              if (name != null) const SizedBox(height: 4),
              GestureDetector(
                onTap: _showAreaPicker,
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: _selectedArea != null
                          ? AppColors.primary
                          : AppColors.secondaryText,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _selectedArea ?? 'Filter by area',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: _selectedArea != null
                              ? AppColors.primary
                              : AppColors.secondaryText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_drop_down,
                      size: 16,
                      color: AppColors.secondaryText,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationScreen()));
                _loadUnreadCount();
              },
            ),
            if (_unreadNotifications > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
        IconButton(
          icon: Icon(
              _showFilters ? Icons.filter_list : Icons.filter_list_outlined),
          onPressed: () => setState(() => _showFilters = !_showFilters),
        ),
        Consumer<AuthProvider>(
          builder: (context, auth, _) => PopupMenuButton<String>(
            offset: const Offset(0, 50),
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'logout') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Logout',
                              style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) {
                  await auth.logout();
                  setState(() {});
                  _showSnackBar('Logged out successfully');
                }
              } else if (value == 'profile') {
                setState(() => _currentTab = 4);
              } else if (value == 'dashboard' &&
                  (auth.isOwner || auth.isAdmin)) {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => auth.isOwner
                            ? const OwnerDashboard()
                            : const AdminAccountScreen()));
              } else if (value == 'wishlist') {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const WishlistScreen()));
              } else if (value == 'login') {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
                setState(() {});
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'profile', child: Text('My Profile')),
              const PopupMenuItem(value: 'wishlist', child: Text('Wishlist')),
              if (auth.isOwner || auth.isAdmin)
                const PopupMenuItem(
                    value: 'dashboard', child: Text('Dashboard')),
              if (auth.isAuthenticated) const PopupMenuDivider(),
              if (auth.isAuthenticated)
                const PopupMenuItem(
                    value: 'logout',
                    child: Text('Logout', style: TextStyle(color: Colors.red))),
              if (!auth.isAuthenticated)
                const PopupMenuItem(value: 'login', child: Text('Login')),
            ],
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        focusNode: _searchFocusNode,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search venues by name or area...',
          hintStyle: const TextStyle(color: AppColors.secondaryText),
          prefixIcon:
              const Icon(Icons.search, color: AppColors.secondaryText),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear,
                      color: AppColors.secondaryText),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1),
          ),
        ),
      ),
    );
  }

  Future<void> _showAreaPicker() async {
    final areas = _availableAreas;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Filter by area',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onBackground,
                ),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: const Icon(Icons.location_city,
                        color: AppColors.primary),
                    title: const Text('All areas'),
                    selected: _selectedArea == null,
                    onTap: () => Navigator.pop(ctx, null),
                  ),
                  for (final area in areas)
                    ListTile(
                      leading: const Icon(Icons.place,
                          color: AppColors.primary),
                      title: Text(area),
                      selected: _selectedArea == area,
                      onTap: () => Navigator.pop(ctx, area),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _selectedArea = selected);
    if (selected != null) {
      _showSnackBar('Showing venues in $selected');
    }
  }

  Widget _buildFilterPanel() {
    final areas = _availableAreas;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.place, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Filter by area',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.onBackground),
                ),
              ),
              if (_selectedArea != null)
                TextButton(
                  onPressed: () => setState(() => _selectedArea = null),
                  child: const Text('Clear',
                      style: TextStyle(color: AppColors.primary)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All areas'),
                selected: _selectedArea == null,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: _selectedArea == null
                      ? Colors.white
                      : AppColors.onBackground,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: _selectedArea == null
                      ? AppColors.primary
                      : AppColors.divider,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onSelected: (_) => setState(() => _selectedArea = null),
              ),
              for (final area in areas)
                ChoiceChip(
                  label: Text(
                    area,
                    style: const TextStyle(fontSize: 12),
                  ),
                  selected: _selectedArea == area,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _selectedArea == area
                        ? Colors.white
                        : AppColors.onBackground,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: _selectedArea == area
                        ? AppColors.primary
                        : AppColors.divider,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onSelected: (_) => setState(() => _selectedArea = area),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== ANIMATED DYNAMIC AD CAROUSEL ====================

  Widget _buildAnimatedAdCarousel() {
    if (_isLoadingAds) {
      return _buildAdShimmer();
    }

    if (_ads.isEmpty) {
      return const SizedBox(height: 0);
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) {
              setState(() => _currentAdIndex = index);
              _fadeController.reset();
              _fadeController.forward();
            },
            itemCount: _ads.length,
            itemBuilder: (context, index) {
              final ad = _ads[index];
              return AnimatedBuilder(
                animation: _fadeController,
                builder: (context, child) {
                  final isCurrent = _currentAdIndex == index;
                  final scale = isCurrent ? 1.0 : 0.95;
                  final opacity = isCurrent ? 1.0 : 0.7;

                  return Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: child,
                    ),
                  );
                },
                child: _buildDynamicAdCard(ad, index),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: _fadeController,
          builder: (context, _) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _ads.length,
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
        ),
      ],
    );
  }

  Widget _buildDynamicAdCard(dynamic ad, int index) {
    final title = ad['title']?.toString() ?? 'Special Offer';
    final subtitle =
        ad['subtitle']?.toString() ?? 'Book now and get exclusive deals';
    final buttonText = ad['buttonText']?.toString() ?? 'Learn More';
    final imageUrl = ad['imageUrl']?.toString();

    final List<List<Color>> gradientOptions = [
      [const Color(0xFF059669), const Color(0xFF047857)],
      [const Color(0xFF7C3AED), const Color(0xFF6D28D9)],
      [const Color(0xFFEF4444), const Color(0xFFDC2626)],
      [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
    ];

    final gradientColors = gradientOptions[index % gradientOptions.length];

    return GestureDetector(
      onTap: () {
        final action = ad['action'] ?? ad['buttonLink'];
        if (action != null && action.toString().isNotEmpty) {
          _handleAdAction(action.toString());
        } else {
          _showSnackBar('Opening offer: $title');
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              bottom: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              right: -60,
              top: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: TweenAnimationBuilder(
                          tween: Tween<double>(begin: 1.0, end: 1.05),
                          duration: const Duration(seconds: 2),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: child,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  buttonText,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: gradientColors[0],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: gradientColors[0],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    ],
                  ),
                ),
                if (imageUrl != null && imageUrl.isNotEmpty)
                  Expanded(
                    flex: 1,
                    child: Hero(
                      tag: 'ad_image_$index',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          imageUrl,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.sports_soccer,
                            size: 60,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
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

  void _handleAdAction(String action) {
    switch (action) {
      case 'tournaments':
        setState(() => _currentTab = 3);
        break;
      case 'venues':
      case 'futsals':
        setState(() => _currentTab = 1);
        break;
      case 'offer':
        _showSnackBar('Special offer applied!');
        break;
      case 'home':
        _showSnackBar('Welcome to Futsal Booking');
        break;
      default:
        _showSnackBar('Opening promotion');
    }
  }

  Widget _buildAdShimmer() {
    return Column(
      children: [
        Container(
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== FUTSAL LIST ====================

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text(
                'See All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFutsalList({required int maxItems}) {
    final futsals = _filteredFutsals.take(maxItems).toList();
    if (futsals.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 48, color: AppColors.secondaryText),
              SizedBox(height: 8),
              Text('No futsals found',
                  style: TextStyle(color: AppColors.secondaryText)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: futsals.length,
      itemBuilder: (context, index) => _buildFutsalCard(futsals[index]),
    );
  }

  Widget _buildFutsalCard(Futsal futsal) {
    final imageUrl = futsal.images.isNotEmpty
        ? futsal.images.first
        : 'https://via.placeholder.com/400x200';

    final minPrice = futsal.getMinPrice();
    final priceText =
        minPrice != null ? '₹${minPrice.toInt()}/hr' : 'Contact for price';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToBooking(futsal),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported,
                        size: 40, color: AppColors.secondaryText),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.onBackground,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 12, color: AppColors.secondaryText),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            futsal.address,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.secondaryText),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (futsal.distance != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.directions_walk,
                              size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${futsal.distance!.toStringAsFixed(1)} km away',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star,
                                  size: 12, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(
                                futsal.averageRating?.toStringAsFixed(1) ??
                                    'New',
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          priceText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _navigateToBooking(futsal),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Book Now',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTournamentsList() {
    return FutureBuilder<List<dynamic>>(
      future: ApiService.getList('tournaments/published'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(height: 0);
        }

        final tournaments = snapshot.data!.take(3).toList();
        return Column(
          children: tournaments.map((t) => _buildTournamentCard(t)).toList(),
        );
      },
    );
  }

  Widget _buildTournamentCard(dynamic tournament) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.emoji_events, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tournament['name']?.toString() ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onBackground,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 12, color: AppColors.secondaryText),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(tournament['startDate']),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.secondaryText),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.emoji_events,
                          size: 12, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        tournament['prizePool']?.toString() ?? 'TBA',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.secondaryText),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () {
                setState(() => _currentTab = 3);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4F46E5),
                side: const BorderSide(color: Color(0xFF4F46E5)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('View',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'TBA';
    try {
      final date = DateTime.parse(dateStr.toString());
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
      return '${months[date.month - 1]} ${date.day}';
    } catch (_) {
      return 'TBA';
    }
  }

  Widget _buildLoginPrompt() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isAuthenticated) return const SizedBox(height: 0);

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Ready to get started?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Login to book futsals and join tournaments',
                style: TextStyle(color: AppColors.secondaryText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()));
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          const Text('Login', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()));
                        setState(() {});
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Register',
                          style: TextStyle(fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== OTHER TABS ====================

  Widget _buildBookingsTab() {
    final auth = Provider.of<AuthProvider>(context);
    if (!auth.isAuthenticated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_month,
                size: 64, color: AppColors.secondaryText),
            const SizedBox(height: 16),
            const Text(
              'Please login to view bookings',
              style: TextStyle(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
                setState(() {});
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 64, color: AppColors.secondaryText),
            const SizedBox(height: 16),
            const Text(
              'Please login to view profile',
              style: TextStyle(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
                setState(() {});
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Login'),
            ),
          ],
        ),
      );
    }
    return const AccountSetting();
  }

  void _navigateToBooking(Futsal futsal) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      Navigator.push(
              context, MaterialPageRoute(builder: (_) => const LoginScreen()))
          .then((_) {
        if (auth.isAuthenticated) {
          _proceedToBooking(futsal);
        }
      });
    } else {
      _proceedToBooking(futsal);
    }
  }

  void _proceedToBooking(Futsal futsal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FutsalDetailsScreen(futsal: futsal, initialTabIndex: 1),
      ),
    );
  }
}
