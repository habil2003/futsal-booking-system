import 'package:flutter/material.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

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
                'Help & Support',
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
                    'https://images.unsplash.com/photo-1516321497487-e288fb19713f?q=80&w=1200&auto=format&fit=crop',
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
                            Icons.support_agent_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Need Help?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'We are always here for you',
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSupportBanner(),
                  const SizedBox(height: 26),
                  const Text(
                    'Frequently Asked Questions',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const FAQCard(
                    question: 'How do I book a futsal ground?',
                    answer:
                        'Browse available grounds, choose your preferred date and time slot, select a payment method, and confirm instantly.',
                    icon: Icons.calendar_month_rounded,
                  ),
                  const SizedBox(height: 16),
                  const FAQCard(
                    question: 'Can I cancel my booking?',
                    answer:
                        'Yes. You can cancel up to 2 hours before the match starts. Refund rules depend on your payment method.',
                    icon: Icons.cancel_outlined,
                  ),
                  const SizedBox(height: 16),
                  const FAQCard(
                    question: 'Which payment methods are supported?',
                    answer:
                        'We support Khalti online payments and Cash on Delivery (COD) directly at the venue.',
                    icon: Icons.payments_rounded,
                  ),
                  const SizedBox(height: 16),
                  const FAQCard(
                    question: 'I forgot my password. What should I do?',
                    answer:
                        'Tap "Forgot Password?" on the login screen and follow the email instructions to reset it securely.',
                    icon: Icons.lock_reset_rounded,
                  ),
                  const SizedBox(height: 16),
                  const FAQCard(
                    question: 'How can I contact the futsal owner?',
                    answer:
                        'Ground details include phone, email, and messaging options for direct communication.',
                    icon: Icons.phone_in_talk_rounded,
                  ),
                  const SizedBox(height: 16),
                  const FAQCard(
                    question: 'Why is my booking still pending?',
                    answer:
                        'Pending means the owner has not confirmed the booking yet. Most bookings are approved within a few minutes.',
                    icon: Icons.hourglass_bottom_rounded,
                  ),
                  const SizedBox(height: 16),
                  const FAQCard(
                    question: 'Are prices per person or per court?',
                    answer:
                        'Prices are generally charged per court per hour unless otherwise mentioned.',
                    icon: Icons.sports_soccer_rounded,
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
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
                          Icons.headset_mic_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Our support team typically responds within 2 hours during business days.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                              'Contact Support',
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
                          icon: Icons.access_time_rounded,
                          text: '10 AM – 6 PM, Sunday – Friday',
                        ),
                      ],
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

  Widget _buildSupportBanner() {
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
      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF22C55E),
            size: 40,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Find quick answers, manage bookings, and get support anytime with Futsal Nepal.',
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FAQCard extends StatelessWidget {
  final String question;
  final String answer;
  final IconData icon;

  const FAQCard({
    super.key,
    required this.question,
    required this.answer,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
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
                  question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  answer,
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
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
