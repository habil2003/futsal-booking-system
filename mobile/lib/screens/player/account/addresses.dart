import 'package:flutter/material.dart';

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Addresses'), backgroundColor: Colors.white, foregroundColor: Colors.black87),
      body: const Center(child: Text('No saved addresses yet.')),
    );
  }
}