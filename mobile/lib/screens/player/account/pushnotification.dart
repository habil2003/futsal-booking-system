import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PushNotificationScreen extends StatefulWidget {
  const PushNotificationScreen({super.key});

  @override
  State<PushNotificationScreen> createState() => _PushNotificationScreenState();
}

class _PushNotificationScreenState extends State<PushNotificationScreen> {
  bool _bookingsEnabled = true;
  bool _promotionsEnabled = true;
  bool _tournamentsEnabled = true;
  bool _allEnabled = true;

  static const _prefAll = 'push_all';
  static const _prefBookings = 'push_bookings';
  static const _prefPromotions = 'push_promotions';
  static const _prefTournaments = 'push_tournaments';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _allEnabled = prefs.getBool(_prefAll) ?? true;
      _bookingsEnabled = prefs.getBool(_prefBookings) ?? true;
      _promotionsEnabled = prefs.getBool(_prefPromotions) ?? true;
      _tournamentsEnabled = prefs.getBool(_prefTournaments) ?? true;
    });
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    setState(() {});
  }

  Future<void> _toggleAll(bool value) async {
    _allEnabled = value;
    _bookingsEnabled = value;
    _promotionsEnabled = value;
    _tournamentsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefAll, value);
    await prefs.setBool(_prefBookings, value);
    await prefs.setBool(_prefPromotions, value);
    await prefs.setBool(_prefTournaments, value);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionCard(
            children: [
              SwitchListTile(
                title: const Text('Enable Notifications',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Receive booking, promotion and tournament alerts'),
                value: _allEnabled,
                activeTrackColor: const Color(0xFF059669),
                onChanged: _toggleAll,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'NOTIFICATION TYPES',
            children: [
              SwitchListTile(
                title: const Text('Booking Updates'),
                subtitle: const Text('Booking confirmation, reminders and cancellations'),
                value: _bookingsEnabled,
                activeTrackColor: const Color(0xFF059669),
                onChanged: (v) {
                  setState(() => _bookingsEnabled = v);
                  _save(_prefBookings, v);
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Promotions & Offers'),
                subtitle: const Text('Discounts, deals and special offers'),
                value: _promotionsEnabled,
                activeTrackColor: const Color(0xFF059669),
                onChanged: (v) {
                  setState(() => _promotionsEnabled = v);
                  _save(_prefPromotions, v);
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Tournament Alerts'),
                subtitle: const Text('Registrations, fixtures and match results'),
                value: _tournamentsEnabled,
                activeTrackColor: const Color(0xFF059669),
                onChanged: (v) {
                  setState(() => _tournamentsEnabled = v);
                  _save(_prefTournaments, v);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({String? title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
        Container(
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
          child: Column(children: children),
        ),
      ],
    );
  }
}
