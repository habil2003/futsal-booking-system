import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final Map<String, String> _languages = {
    'English': 'English',
    'Nepali': 'नेपाली',
    'Hindi': 'हिन्दी',
  };

  String _selected = 'English';
  static const _prefKey = 'app_language';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null) setState(() => _selected = saved);
  }

  Future<void> _select(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, lang);
    setState(() => _selected = lang);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Select display language',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
          const SizedBox(height: 12),
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
            child: RadioGroup<String>(
              groupValue: _selected,
              onChanged: (val) {
                if (val != null) _select(val);
              },
              child: Column(
                children: _languages.entries.map((entry) {
                  return Column(
                    children: [
                      RadioListTile<String>(
                        title: Row(
                          children: [
                            Text(entry.key,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Text(entry.value,
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        value: entry.key,
                        activeColor: const Color(0xFF059669),
                      ),
                      if (entry.key != _languages.keys.last)
                        const Divider(height: 1, indent: 56),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF059669), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Selected preference is saved on this device.',
                    style: TextStyle(color: Color(0xFF059669), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
