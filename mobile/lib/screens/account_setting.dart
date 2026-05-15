import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import 'player/account/account_info.dart';
import 'player/account/addresses.dart';
import 'player/account/wishlist.dart';
import 'player/account/payment_methods.dart';
import 'player/account/change_password.dart';
import 'player/account/language.dart';
import 'player/account/privacy.dart';
import 'player/account/about.dart';
import 'player/account/support.dart';

class AccountSetting extends StatelessWidget {
  const AccountSetting({super.key});

  String _memberSince(DateTime? date) {
    if (date == null) return 'Recently joined';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.logout();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // ── Profile Header ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.green.shade50,
                  child: Text(
                    (user.fullName ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.fullName ?? 'User',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Member since: ${_memberSince(user.createdAt)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Account Card ──
          _buildMenuCard(
            icon: Icons.person,
            title: 'Account',
            subtitle: 'Edit profile, addresses, wishlist',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountSectionScreen()),
            ),
          ),
          // ── Settings Card ──
          _buildMenuCard(
            icon: Icons.settings,
            title: 'Settings',
            subtitle: 'Notifications, password, language',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsSectionScreen()),
            ),
          ),
          // ── Support Card ──
          _buildMenuCard(
            icon: Icons.help,
            title: 'Support & Help',
            subtitle: 'Privacy, about, FAQs',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupportSectionScreen()),
            ),
          ),

          const SizedBox(height: 40),

          // ── Sign Out Button ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: () => _signOut(context),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.red.shade50,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, size: 32, color: Colors.green.shade700),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}

class AccountSectionScreen extends StatelessWidget {
  const AccountSectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: ListView(
        children: [
          _sectionHeader('Profile'),
          _tile(context, icon: Icons.person_outline, title: 'Account Information', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountInfoScreen()))),
          _sectionHeader('Saved'),
          _tile(context, icon: Icons.location_on_outlined, title: 'Saved Addresses', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressesScreen()))),
          _tile(context, icon: Icons.favorite_border, title: 'Wishlist', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen()))),   // ← add this line
          _tile(context, icon: Icons.payment, title: 'Payment Methods', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()))),
        ],
      ),
    );
  }
}
class SettingsSectionScreen extends StatelessWidget {
  const SettingsSectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: ListView(
        children: [
          // Notifications toggle handled inline (or you can create a dedicated screen)
          _switchTile(context, icon: Icons.notifications_outlined, title: 'Push Notifications', subtitle: 'Receive booking and offer alerts', value: true, onChanged: (val) {}),
          _tile(context, icon: Icons.lock_outline, title: 'Change Password', onTap: () => showDialog(context: context, builder: (_) => const ChangePasswordDialog())),
          _tile(context, icon: Icons.language, title: 'Language', subtitle: 'English', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageScreen()))),
        ],
      ),
    );
  }
}

class SupportSectionScreen extends StatelessWidget {
  const SupportSectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support & Help'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: ListView(
        children: [
          _tile(context, icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen()))),
          _tile(context, icon: Icons.info_outline, title: 'About Us', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()))),
          _tile(context, icon: Icons.help_outline, title: 'Help & Support', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()))),
        ],
      ),
    );
  }
}

// ─────────── Reusable tile/header helpers ───────────
Widget _sectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
    child: Text(
      title,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 0.5),
    ),
  );
}

Widget _tile(BuildContext context, {required IconData icon, required String title, String? subtitle, required VoidCallback onTap}) {
  return Container(
    color: Colors.white,
    child: Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.green.shade700, size: 22),
          title: Text(title, style: const TextStyle(fontSize: 15)),
          subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
          trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        ),
        const Divider(height: 0.5, indent: 70),
      ],
    ),
  );
}

Widget _switchTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
  return Container(
    color: Colors.white,
    child: Column(
      children: [
        SwitchListTile(
          secondary: Icon(icon, color: Colors.green.shade700, size: 22),
          title: Text(title, style: const TextStyle(fontSize: 15)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
          value: value,
          onChanged: onChanged,
          activeColor: Colors.green,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        const Divider(height: 0.5, indent: 70),
      ],
    ),
  );
}