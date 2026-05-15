import 'package:flutter/material.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selected = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Language'), backgroundColor: Colors.white, foregroundColor: Colors.black87),
      body: ListView(
        children: ['English', 'Nepali', 'Hindi'].map((lang) => RadioListTile<String>(
              title: Text(lang),
              value: lang,
              groupValue: _selected,
              onChanged: (val) {
                setState(() => _selected = val!);
                Navigator.pop(context);
              },
            )).toList(),
      ),
    );
  }
}
