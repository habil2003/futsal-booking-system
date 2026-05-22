import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(
              color: Colors.white,
            ),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                'Privacy Policy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?q=80&w=1200&auto=format&fit=crop',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.25),
                          Colors.black.withOpacity(0.75),
                        ],
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 20,
                    bottom: 70,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Color(0xFF22C55E),
                          child: Icon(
                            Icons.privacy_tip_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Privacy Matters',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Safe • Secure • Transparent',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInfoBanner(),
                  const SizedBox(height: 24),
                  _buildPolicyCard(
                    icon: Icons.person_outline,
                    title: 'Information We Collect',
                    content:
                        'We collect your name, email, phone number, booking details, payment records, and optional location access to improve your futsal booking experience.',
                  ),
                  const SizedBox(height: 18),
                  _buildPolicyCard(
                    icon: Icons.analytics_outlined,
                    title: 'How We Use Your Data',
                    content:
                        'Your information helps us manage bookings, send confirmations, improve platform performance, personalize experiences, and maintain security.',
                  ),
                  const SizedBox(height: 18),
                  _buildPolicyCard(
                    icon: Icons.share_outlined,
                    title: 'Information Sharing',
                    content:
                        'We never sell your personal information. Data is shared only with futsal venues, trusted payment providers, or legal authorities when required.',
                  ),
                  const SizedBox(height: 18),
                  _buildPolicyCard(
                    icon: Icons.security_rounded,
                    title: 'Data Security',
                    content:
                        'We use secure technologies and encryption standards to protect your data. Our systems are regularly reviewed for safety and reliability.',
                  ),
                  const SizedBox(height: 18),
                  _buildPolicyCard(
                    icon: Icons.settings_accessibility_rounded,
                    title: 'Your Rights',
                    content:
                        'You can update, access, or request deletion of your account information anytime through app settings or customer support.',
                  ),
                  const SizedBox(height: 18),
                  _buildPolicyCard(
                    icon: Icons.update_rounded,
                    title: 'Policy Updates',
                    content:
                        'We may occasionally update this policy. Important changes will be communicated through app notifications or email alerts.',
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.contact_support_rounded,
                              color: Colors.greenAccent,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Contact Us',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 18),
                        ContactTile(
                          icon: Icons.email_outlined,
                          text: 'support@futsalnepal.com',
                        ),
                        SizedBox(height: 12),
                        ContactTile(
                          icon: Icons.phone_outlined,
                          text: '+977 9800000000',
                        ),
                        SizedBox(height: 12),
                        ContactTile(
                          icon: Icons.location_on_outlined,
                          text: 'Kathmandu, Nepal',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Effective Date: 15 May 2026',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF22C55E),
            Color(0xFF16A34A),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.lock_rounded,
            color: Colors.white,
            size: 40,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'We are committed to protecting your personal information and ensuring complete transparency.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF16A34A),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.7,
                    color: Colors.black87,
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

class ContactTile extends StatelessWidget {
  final IconData icon;
  final String text;

  const ContactTile({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
