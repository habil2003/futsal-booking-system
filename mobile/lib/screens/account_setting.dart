import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../screens/login_screen.dart';

import 'player/account/account_info.dart';
import 'player/account/addresses.dart';
import 'player/account/wishlist.dart';
import 'player/account/change_password.dart';
import 'player/account/language.dart';
import 'player/account/pushnotification.dart';
import 'player/account/privacy.dart';
import 'player/account/about.dart';
import 'player/account/support.dart';

class AccountSetting extends StatelessWidget {
  const AccountSetting({super.key});

  Future<void> _pickProfileImage(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final picker = ImagePicker();

    XFile? picked;
    try {
      picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
    } catch (_) {}

    if (picked == null) return;
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Color(0xFF059669))),
    );

    final ok = await auth.updateProfileImage(picked);

    if (!context.mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Profile picture updated' : 'Could not update profile picture'),
        backgroundColor: ok ? const Color(0xFF16A34A) : Colors.red,
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    if (confirm == true) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.logout();
      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: CustomScrollView(
        slivers: [
          // ───── Modern Header ─────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF047857)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => _pickProfileImage(context),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: Colors.white,
                              foregroundImage: user.profileImage != null && user.profileImage!.isNotEmpty
                                  ? NetworkImage(user.profileImage!)
                                  : null,
                              child: user.profileImage == null || user.profileImage!.isEmpty
                                  ? Text(
                                      user.fullName[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF16A34A),
                                      ),
                                    )
                                  : null,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.camera_alt, size: 18, color: Color(0xFF059669)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          user.phoneNumber!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ───── Content ─────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ProfileStats(),
                  const SizedBox(height: 20),
                  _sectionTitle("ACCOUNT"),
                  _menuCard(
                    icon: Icons.person_outline,
                    title: "Account Information",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AccountInfoScreen(),
                      ),
                    ),
                  ),
                  _menuCard(
                    icon: Icons.location_on_outlined,
                    title: "Addresses",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddressesScreen(),
                      ),
                    ),
                  ),
                  _menuCard(
                    icon: Icons.favorite_border,
                    title: "Wishlist",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WishlistScreen(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  _sectionTitle("SETTINGS"),
                  _menuCard(
                    icon: Icons.lock_outline,
                    title: "Change Password",
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => const ChangePasswordDialog(),
                    ),
                  ),
                  _menuCard(
                    icon: Icons.language,
                    title: "Language",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LanguageScreen(),
                      ),
                    ),
                  ),
                  _menuCard(
                    icon: Icons.notifications_none,
                    title: "Notifications",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PushNotificationScreen(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  _sectionTitle("SUPPORT"),
                  _menuCard(
                    icon: Icons.privacy_tip_outlined,
                    title: "Privacy Policy",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyScreen(),
                      ),
                    ),
                  ),
                  _menuCard(
                    icon: Icons.info_outline,
                    title: "About Us",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AboutScreen(),
                      ),
                    ),
                  ),
                  _menuCard(
                    icon: Icons.help_outline,
                    title: "Help & Support",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SupportScreen(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ───── Sign out button ─────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _signOut(context),
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Sign Out",
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───── Section Title ─────
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  // ───── Modern Card Menu ─────
  Widget _menuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF16A34A).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF16A34A)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }
}

class _ProfileStats extends StatefulWidget {
  const _ProfileStats();

  @override
  State<_ProfileStats> createState() => _ProfileStatsState();
}

class _ProfileStatsState extends State<_ProfileStats> {
  int _bookings = 0;
  double _spent = 0;
  int _favorites = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final bookingsRes = await ApiService.get('bookings/my-bookings');
      final bookings = bookingsRes['bookings'] as List? ?? [];
      var count = 0;
      double spent = 0;
      for (final b in bookings) {
        final status = b['status']?.toString().toUpperCase() ?? '';
        if (status == 'CANCELLED') continue;
        count++;
        spent += (b['totalPrice'] as num?)?.toDouble() ?? 0;
      }

      final favRes = await ApiService.get('favorites');
      final favs = favRes['favorites'] as List? ?? [];

      if (!mounted) return;
      setState(() {
        _bookings = count;
        _spent = spent;
        _favorites = favs.length;
        _loaded = true;
      });
    } catch (e) {
      debugPrint('Profile stats load error: $e');
      if (!mounted) return;
      setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem(Icons.calendar_today_outlined, _bookings.toString(),
              'Bookings'),
          Container(width: 1, height: 34, color: Colors.grey.shade200),
          _statItem(Icons.payments_outlined,
              'रु${_spent.toStringAsFixed(0)}', 'Total Spent'),
          Container(width: 1, height: 34, color: Colors.grey.shade200),
          _statItem(Icons.favorite_outline, _favorites.toString(),
              'Saved'),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF16A34A)),
        const SizedBox(height: 6),
        Text(
          _loaded ? value : '…',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
