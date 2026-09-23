import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/admin_analytics_provider.dart';
import '../../widgets/admin/admin_edit_profile_dialog.dart';
import 'admin_ads_banner.dart';
import 'user_management_screen.dart';
import 'admin_all_futsals_screen.dart';
import 'futsal_approval_screen.dart';
import 'admin_bookings_screen.dart';
import 'system_settings_screen.dart';
import 'admin_analytics_screen.dart';
import 'manage_tournaments.dart';
import 'admin_dashboard.dart';
import '../login_screen.dart';
import '../../widgets/admin/admin_header_actions.dart';
import '../player/home_screen.dart';

class AdminAccountScreen extends StatefulWidget {
  const AdminAccountScreen({super.key});

  @override
  State<AdminAccountScreen> createState() => _AdminAccountScreenState();
}

class _AdminAccountScreenState extends State<AdminAccountScreen> {
  String _selectedMenu = 'Dashboard';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const List<Map<String, dynamic>> _menuCategories = [
    {
      'title': 'OVERVIEW',
      'items': [
        {'title': 'Dashboard', 'icon': Icons.dashboard_rounded},
        {'title': 'Analytics', 'icon': Icons.analytics_rounded},
      ]
    },
    {
      'title': 'MANAGEMENT',
      'items': [
        {'title': 'Manage Users', 'icon': Icons.people_alt_rounded},
        {'title': 'All Bookings', 'icon': Icons.book_online_rounded},
        {'title': 'All Futsals', 'icon': Icons.sports_soccer_rounded},
        {'title': 'Pending Futsals', 'icon': Icons.pending_actions_rounded},
        {'title': 'Manage Ads', 'icon': Icons.campaign_rounded},
        {'title': 'Manage Tournaments', 'icon': Icons.emoji_events_rounded},
      ]
    },
    {
      'title': 'SYSTEM',
      'items': [
        {'title': 'Settings', 'icon': Icons.settings_rounded},
        {'title': 'Recent Activity', 'icon': Icons.history_rounded},
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      final analyticsProvider =
          Provider.of<AdminAnalyticsProvider>(context, listen: false);

      // Load dashboard stats
      adminProvider.loadDashboardStats();
      // Load all analytics data (charts, rankings, etc.)
      analyticsProvider.loadAllAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width >= 600 &&
        MediaQuery.of(context).size.width < 1100;

    return Scaffold(
      key: _scaffoldKey,
      appBar: (isMobile || isTablet) && _usesShellAppBar()
          ? AppBar(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                tooltip: 'Menu',
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: Text(_selectedMenu),
              actions: [
                IconButton(
                  icon: const Icon(Icons.sports_soccer, color: Colors.white),
                  tooltip: 'Player Mode',
                  onPressed: _openPlayerMode,
                ),
                const AdminNotificationButton(),
              ],
            )
          : null,
      drawer: (isMobile || isTablet) ? _buildDrawer() : null,
      body: Row(
        children: [
          if (!isMobile && !isTablet) _buildSidebar(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.grey.shade50, Colors.grey.shade100],
                ),
              ),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------
  // SIDEBAR & DRAWER (unchanged from original)
  // --------------------------------------------------------------
  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.green.shade800, Colors.green.shade900],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSidebarHeader(),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _menuCategories.length,
              itemBuilder: (context, categoryIndex) {
                final category = _menuCategories[categoryIndex];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
                      child: Text(
                        category['title'],
                        style: TextStyle(
                          color: Colors.green.shade200,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    ...(category['items'] as List).map((item) {
                      final isSelected = _selectedMenu == item['title'];
                      return _buildSidebarItem(
                        icon: item['icon'],
                        title: item['title'],
                        isSelected: isSelected,
                        onTap: () =>
                            setState(() => _selectedMenu = item['title']),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
          _buildSidebarItem(
            icon: Icons.sports_soccer,
            title: 'Player Mode',
            isSelected: false,
            onTap: _openPlayerMode,
          ),
          _buildSidebarProfile(),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade800, Colors.green.shade900],
          ),
        ),
        child: Column(
          children: [
            _buildDrawerHeader(),
            const Divider(color: Colors.white24),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: _menuCategories.length,
                itemBuilder: (context, categoryIndex) {
                  final category = _menuCategories[categoryIndex];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
                        child: Text(
                          category['title'],
                          style: TextStyle(
                            color: Colors.green.shade200,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      ...(category['items'] as List).map((item) {
                        final isSelected = _selectedMenu == item['title'];
                        return _buildDrawerItem(
                          icon: item['icon'],
                          title: item['title'],
                          isSelected: isSelected,
                          onTap: () {
                            setState(() => _selectedMenu = item['title']);
                            Navigator.pop(context);
                          },
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
            _buildDrawerItem(
              icon: Icons.sports_soccer,
              title: 'Player Mode',
              isSelected: false,
              onTap: () {
                Navigator.pop(context);
                _openPlayerMode();
              },
            ),
            _buildDrawerProfile(),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your platform',
                  style: TextStyle(
                    color: Colors.green.shade200,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Admin Panel',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.05)
                      ],
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.white70,
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.white : Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.white.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }

  Widget _buildSidebarProfile() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.1),
            border: const Border(top: BorderSide(color: Colors.white24)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showProfileMenu(context, authProvider),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                        child: Text(
                          (user?.fullName ?? 'A')[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Admin',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Administrator',
                            style: TextStyle(
                              color: Colors.green.shade200,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Three‑dot icon – on tap opens centered menu
                    GestureDetector(
                      onTap: () {
                        final screenSize = MediaQuery.of(context).size;
                        final center = Offset(screenSize.width / 2 - 100,
                            screenSize.height / 2 - 60);
                        showMenu(
                          context: context,
                          position: RelativeRect.fromLTRB(
                              center.dx, center.dy, center.dx, center.dy),
                          items: [
                            const PopupMenuItem(
                              value: 'profile',
                              child: Row(
                                children: [
                                  Icon(Icons.person, color: Colors.green),
                                  SizedBox(width: 42),
                                  Text('Profile'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout, color: Colors.red),
                                  SizedBox(width: 42),
                                  Text('Logout',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ).then((value) {
                          if (value == 'profile') {
                            authProvider.loadAdminProfile().then((_) {
                              if (context.mounted) {
                                _showProfileDialog(context, authProvider);
                              }
                            });
                          } else if (value == 'logout') {
                            if (!context.mounted) return;
                            _showLogoutConfirmation(context, authProvider);
                          }
                        });
                      },
                      child: const Icon(Icons.more_vert,
                          color: Colors.white70, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerProfile() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.1),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (user?.fullName ?? 'A')[0].toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ),
            title: Text(
              user?.fullName ?? 'Admin',
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Administrator',
              style: TextStyle(color: Colors.green.shade200),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white70),
              onPressed: () {
                final screenSize = MediaQuery.of(context).size;
                final center = Offset(
                    screenSize.width / 2 - 100, screenSize.height / 2 - 60);
                showMenu(
                  context: context,
                  position: RelativeRect.fromLTRB(
                      center.dx, center.dy, center.dx, center.dy),
                  items: [
                    const PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person, color: Colors.green),
                          SizedBox(width: 42),
                          Text('Profile'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: 60),
                          Text('Logout', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ).then((value) {
                  if (value == 'profile') {
                    authProvider.loadAdminProfile().then((_) {
                      if (context.mounted) _showProfileDialog(context, authProvider);
                    });
                  } else if (value == 'logout') {
                    if (!context.mounted) return;
                    _showLogoutConfirmation(context, authProvider);
                  }
                });
              },
            ),
          ),
        );
      },
    );
  }

  void _showProfileMenu(BuildContext context, AuthProvider authProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.green),
              title: const Text('Profile'),
              onTap: () async {
                Navigator.pop(ctx);
                await authProvider.loadAdminProfile();
                if (context.mounted) _showProfileDialog(context, authProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.green),
              title:
                  const Text('Logout', style: TextStyle(color: Colors.green)),
              onTap: () {
                Navigator.pop(ctx);
                _showLogoutConfirmation(context, authProvider);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return _getContentWidget();
  }

  Widget _getContentWidget() {
    final isCompact = MediaQuery.of(context).size.width < 1100;
    final VoidCallback? onOpenDrawer = isCompact
        ? () => _scaffoldKey.currentState?.openDrawer()
        : null;

    switch (_selectedMenu) {
      case 'Dashboard':
        return AdminDashboard(
            onMenuSelect: (menu) => setState(() => _selectedMenu = menu));
      case 'Analytics':
        return const AdminAnalyticsScreen();
      case 'Manage Users':
        return AdminUsersScreen(onOpenDrawer: onOpenDrawer);
      case 'All Bookings':
        return AdminBookingsScreen(onOpenDrawer: onOpenDrawer);
      case 'All Futsals':
        return AdminAllFutsalsScreen(onOpenDrawer: onOpenDrawer);
      case 'Pending Futsals':
        return FutsalApprovalScreen(onOpenDrawer: onOpenDrawer);
      case 'Manage Ads':
        return AdsBannerScreen(onOpenDrawer: onOpenDrawer);
      case 'Manage Tournaments':
        return ManageTournamentsScreen(onOpenDrawer: onOpenDrawer);
      case 'Settings':
        return SystemSettingsScreen(onOpenDrawer: onOpenDrawer);
      case 'Recent Activity':
        return _buildRecentActivity();
      default:
        return AdminDashboard(
            onMenuSelect: (menu) => setState(() => _selectedMenu = menu));
    }
  }

  bool _usesShellAppBar() {
    return _selectedMenu == 'Dashboard' ||
        _selectedMenu == 'Analytics' ||
        _selectedMenu == 'Recent Activity';
  }

  void _openPlayerMode() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const PlayerHomeScreen()));
  }

  Widget _buildRecentActivity() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final activities = adminProvider.recentActivities;

        if (activities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No recent activity',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];

            final name =
                activity['name'] ?? activity['user']?['fullName'] ?? 'System';
            final email = activity['email'] ?? activity['user']?['email'] ?? '';
            final phone =
                activity['phone'] ?? activity['user']?['phoneNumber'] ?? '';
            final category =
                activity['category'] ?? activity['type'] ?? 'Activity';
            final status = activity['status'] ?? 'completed';
            final createdAt = activity['createdAt'] ?? '';

            final categoryColor = category == 'Booking'
                ? Colors.blue
                : category == 'User Added'
                    ? Colors.green
                    : category == 'User Login'
                        ? Colors.teal
                        : Colors.purple;

            final statusColor = status == 'completed'
                ? Colors.green.shade700
                : status == 'pending'
                    ? Colors.orange.shade700
                    : status == 'registered'
                        ? Colors.blue.shade700
                        : status == 'cancelled'
                            ? Colors.red.shade700
                            : Colors.grey.shade700;

            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: categoryColor.withValues(alpha: 0.1),
                      child: Icon(
                        category == 'Booking'
                            ? Icons.book_online
                            : category == 'User Added'
                                ? Icons.person_add
                                : Icons.notifications,
                        size: 16,
                        color: categoryColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatRelativeTime(createdAt),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          if (email.isNotEmpty || phone.isNotEmpty)
                            Row(
                              children: [
                                if (email.isNotEmpty)
                                  Flexible(
                                    child: Text(
                                      email,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                if (phone.isNotEmpty) ...[
                                  if (email.isNotEmpty)
                                    Text(
                                      ' • ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  Flexible(
                                    child: Text(
                                      phone,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 10,
                              color: categoryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showProfileDialog(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.user;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Admin Profile',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey.shade600),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.green.shade100,
              foregroundImage: (user?.profileImage != null &&
                      user!.profileImage!.isNotEmpty)
                  ? NetworkImage(user.profileImage!)
                  : null,
              child: (user?.profileImage == null ||
                      user!.profileImage!.isEmpty)
                  ? Text(
                      (user?.fullName ?? 'A')[0].toUpperCase(),
                      style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(user?.fullName ?? 'Admin',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20)),
              child: Text('ADMIN',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700)),
            ),
            const SizedBox(height: 24),
            _buildProfileInfoRow(
                Icons.email_outlined, user?.email ?? 'No email'),
            const SizedBox(height: 12),
            _buildProfileInfoRow(
                Icons.phone_outlined, user?.phoneNumber ?? 'No phone'),
            const SizedBox(height: 12),
            _buildProfileInfoRow(
                Icons.calendar_today, _formatDate(user?.createdAt)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      showDialog(
                          context: context,
                          builder: (_) => const AdminEditProfileDialog());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Edit Profile'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

 Future<void> _showLogoutConfirmation(BuildContext context, AuthProvider authProvider) async {
  final bool? shouldLogout = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Logout'),
      content: const Text('Are you sure you want to logout?'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text('CANCEL')),
        TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('LOGOUT')),
      ],
    ),
  );

  debugPrint('🔍 Admin shouldLogout = $shouldLogout');
  if (shouldLogout != true) return;

  if (!context.mounted) return;

  final auth = Provider.of<AuthProvider>(context, listen: false);
  debugPrint('🔍 Admin calling logout...');
  await auth.logout();
  debugPrint('🔍 Admin logout done, mounted = $mounted');

  if (!context.mounted) {
    debugPrint('🔍 Admin not mounted, aborting navigation');
    return;
  }

  debugPrint('🔍 Admin navigating to LoginScreen');
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}

  Widget _buildProfileInfoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 16),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not available';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatRelativeTime(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays > 7) return _formatDate(date);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (e) {
      return 'Unknown';
    }
  }
}