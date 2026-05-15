import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Text(
          _privacyPolicyText,
          style: TextStyle(fontSize: 15, height: 1.6),
        ),
      ),
    );
  }
}

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