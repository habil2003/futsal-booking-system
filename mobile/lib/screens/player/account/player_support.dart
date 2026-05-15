import 'package:flutter/material.dart';

class PlayerSupportScreen extends StatefulWidget {
  const PlayerSupportScreen({super.key});

  @override
  State<PlayerSupportScreen> createState() => _PlayerSupportScreenState();
}

class _PlayerSupportScreenState extends State<PlayerSupportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Support & Help'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _buildTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => _showContentPage(context, 'Privacy Policy', _privacyPolicyText),
          ),
          _buildTile(
            icon: Icons.info_outline,
            title: 'About Us',
            onTap: () => _showContentPage(context, 'About Us', _aboutUsText),
          ),
          _buildTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () => _showContentPage(context, 'Help & Support', _helpSupportText),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: Colors.green.shade700, size: 22),
            title: Text(title, style: const TextStyle(fontSize: 15)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            onTap: onTap,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          ),
          const Divider(height: 0.5, indent: 70),
        ],
      ),
    );
  }

  void _showContentPage(BuildContext context, String title, String content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(title),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0.5,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Text(
              content,
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Static content ──
const String _privacyPolicyText = '''
Privacy Policy

Effective Date: 15 May 2026

1. Information We Collect
We collect personal information such as your name, email address, phone number, and location data (only when you grant permission) to provide our services. We also collect booking details, payment transaction records, and device information for security and analytics.

2. How We Use Your Information
Your data is used to:
• Process bookings and manage court reservations.
• Communicate booking confirmations, reminders, and promotional offers (if you opt in).
• Improve our platform through analytics and user feedback.
• Comply with legal obligations and prevent fraud.

3. Sharing of Information
We do not sell or rent your personal information. We may share data with:
• Futsal venue owners (only the details necessary for your booking).
• Payment processors (Khalti, etc.) to complete transactions.
• Law enforcement, if required by law.

4. Data Security
We implement industry‑standard encryption and security measures. However, no method of electronic storage is 100% secure. We regularly review our security practices.

5. Your Rights
You can update or delete your account at any time. For data access, correction, or deletion requests, contact us at the email below.

6. Changes to This Policy
We may update this policy occasionally. Significant changes will be notified via email or in‑app notice.

7. Contact Us
For questions about this policy, please contact us at:
📧 support@futsalnepal.com
📞 +977‑980‑0000000
📍 Kathmandu, Nepal
''';

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