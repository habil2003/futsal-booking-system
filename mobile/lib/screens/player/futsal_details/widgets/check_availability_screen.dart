import 'package:flutter/material.dart';
import '../../../../models/futsal.dart';
import '../widgets/slots_tab.dart';

class CheckAvailabilityScreen extends StatelessWidget {
  final Futsal futsal;
  const CheckAvailabilityScreen({super.key, required this.futsal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Check Availability - ${futsal.name}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SlotsTab(futsal: futsal),
    );
  }
}