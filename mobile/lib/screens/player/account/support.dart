import 'package:flutter/material.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Text(
          _helpSupportText,
          style: TextStyle(fontSize: 15, height: 1.6),
        ),
      ),
    );
  }
}

const String _helpSupportText = '''
Help & Support

Frequently Asked Questions

Q: How do I book a futsal ground?
A: Browse available grounds, select a date and time slot, choose your payment method, and confirm. You'll receive a confirmation instantly.

Q: Can I cancel my booking?
A: Yes, you can cancel up to 2 hours before the start time. Refund policies depend on the payment method. COD bookings can be cancelled anytime before payment.

Q: How do I pay?
A: We support online payment via Khalti or Cash on Delivery (COD). For COD, pay directly at the venue when you arrive.

Q: I forgot my password. What do I do?
A: On the login screen, tap "Forgot Password?" and follow the instructions to reset it via email.

Q: How can I contact the futsal owner?
A: On the ground's detail page, you'll find phone and email options. You can also message the owner directly (if enabled).

Q: My booking status is still "Pending". Is it confirmed?
A: "Pending" means the venue owner hasn't confirmed yet. Most bookings are auto‑confirmed within 5 minutes. If it's still pending after an hour, contact us.

Q: Are the prices shown per person or per court?
A: Prices are per hour for the entire court, unless stated otherwise.

Need more help?
Reach out to our support team – we're happy to assist!

📧 support@futsalnepal.com
📞 +977‑980‑0000000 (10 AM – 6 PM, Sunday–Friday)

We aim to respond within 2 hours during business days.
''';