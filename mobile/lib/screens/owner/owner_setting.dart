import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class OwnerSettingsScreen extends StatefulWidget {
  const OwnerSettingsScreen({super.key});

  @override
  State<OwnerSettingsScreen> createState() => _OwnerSettingsScreenState();
}

class _OwnerSettingsScreenState extends State<OwnerSettingsScreen> {
  bool _twoFactorEnabled = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user != null) {
      _nameController.text = user.fullName ?? '';
      _emailController.text = user.email ?? '';
      // _phoneController.text = user.phone ?? '';
    }
    _fetchSecurityStatus();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    // _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchSecurityStatus() async {
    try {
      final data = await ApiService.get('auth/security-status');
      if (data != null) {
        setState(() => _twoFactorEnabled = data['two_factor_enabled'] ?? false);
      }
    } catch (_) {
      // endpoint may not exist – keep default false
    }
  }

  Future<void> _updateProfile() async {
    try {
      await ApiService.put('users/me', {
        'name': _nameController.text,
        'email': _emailController.text,
        // 'phone': _phoneController.text,
      });
      await Provider.of<AuthProvider>(context, listen: false).refreshUser();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _toggleTwoFactor(bool enable) async {
    setState(() => _twoFactorEnabled = enable);
    try {
      await ApiService.post('auth/toggle-2fa', {'enable': enable});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(enable ? '2FA Enabled' : '2FA Disabled'), backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() => _twoFactorEnabled = !enable);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to toggle 2FA: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Profile Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
                  TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
                  // TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _updateProfile,
                    child: const Text('Save Profile'),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 32),

          const Text('Ground Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Card(
            child: ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Pricing Rules'),
              subtitle: const Text('Set per‑court via Court Management'),
              trailing: const Icon(Icons.info_outline),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pricing is managed per court in the Court Manager')),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Availability'),
              subtitle: const Text('Edit opening hours in Court Manager'),
              trailing: const Icon(Icons.info_outline),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Availability is set per futsal in the Edit Ground screen')),
              ),
            ),
          ),
          const Divider(height: 32),

          const Text('Payment Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance),
              title: const Text('Bank / Khalti / eSewa'),
              subtitle: const Text('Payment gateways – coming soon'),
              trailing: const Icon(Icons.construction),
              onTap: () {},
            ),
          ),
          const Divider(height: 32),

          const Text('Security', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Change Password'),
              subtitle: const Text('Update your login password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showChangePasswordDialog(),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Two-Factor Authentication'),
            subtitle: Text(_twoFactorEnabled ? 'Enabled' : 'Disabled'),
            value: _twoFactorEnabled,
            onChanged: _toggleTwoFactor,
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
            TextField(controller: newPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
            TextField(controller: confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm New Password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (newPassCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                return;
              }
              try {
                await ApiService.post('auth/change-password', {
                  'old_password': oldPassCtrl.text,
                  'new_password': newPassCtrl.text,
                });
                Navigator.pop(ctx, true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully')));
    }
  }
}