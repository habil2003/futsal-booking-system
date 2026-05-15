import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Text(
          _aboutUsText,
          style: TextStyle(fontSize: 15, height: 1.6),
        ),
      ),
    );
  }
}

const String _aboutUsText = '''
About Futsal Nepal

Welcome to Futsal Nepal – the easiest way to find and book futsal grounds across Nepal.

Our mission is to connect players with quality futsal facilities, making the booking process seamless, transparent, and affordable. Whether you're a casual player looking for a quick match or a team training for a tournament, we have the perfect pitch for you.

Founded in 2024, we now partner with over 200 futsal venues from Kathmandu to Pokhara, Chitwan, and beyond. Each venue is verified for quality, safety, and reliability.

Why choose us?
• Instant booking – reserve a court in seconds.
• Transparent pricing – no hidden fees.
• Flexible payment – online (Khalti) or Cash on Delivery.
• Verified venues – only trusted grounds.
• Dedicated support – we're here to help 7 days a week.

We're a team of football lovers and tech enthusiasts who believe that finding a futsal ground should be as fun as playing on one.

Thank you for choosing Futsal Nepal. Play on! ⚽
''';