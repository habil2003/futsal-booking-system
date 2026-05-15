import 'package:flutter/material.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods'), backgroundColor: Colors.white, foregroundColor: Colors.black87),
      body: const Center(child: Text('No payment methods saved.')),
    );
  }
}