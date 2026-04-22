import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/futsal_provider.dart';
import '../../services/api_service.dart';

class RegistrationPaymentScreen extends StatefulWidget {
  final int futsalId;
  final String futsalName;
  final double amount;

  const RegistrationPaymentScreen({
    super.key,
    required this.futsalId,
    required this.futsalName,
    required this.amount,
  });

  @override
  State<RegistrationPaymentScreen> createState() =>
      _RegistrationPaymentScreenState();
}

class _RegistrationPaymentScreenState extends State<RegistrationPaymentScreen> {
  bool _isLoading = true;
  String? _paymentUrl;
  String? _pidx;

  @override
  void initState() {
    super.initState();
    _initiatePayment();
  }

  Future<void> _initiatePayment() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.initiateRegistrationPayment(
        widget.futsalId,
      );

      if (response['status'] == 'error') {
        throw Exception(response['message'] ?? 'Failed to initiate payment');
      }

      final paymentUrl = response['paymentUrl'];
      final pidx = response['pidx'];

      if (paymentUrl == null || pidx == null) {
        throw Exception('Invalid payment response');
      }

      setState(() {
        _paymentUrl = paymentUrl;
        _pidx = pidx;
        _isLoading = false;
      });

      // Automatically open the payment URL in browser
      await _launchPaymentUrl(paymentUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initiate payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context, false);
      }
    }
  }

  Future<void> _launchPaymentUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch payment page');
    }
  }

  // This method is called when user returns from browser
  Future<void> _checkPaymentStatus() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await ApiService.verifyRegistrationPayment(
        _pidx!,
        widget.futsalId,
      );
      
      if (response['success'] == true) {
        // Refresh futsal list
        final futsalProvider =
            Provider.of<FutsalProvider>(context, listen: false);
        await futsalProvider.fetchMyFutsals();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration fee paid successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment not completed. Please try again.'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context, false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment verification failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context, false);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pay Registration Fee'),
            Text(
              '₹${widget.amount.toStringAsFixed(0)} - ${widget.futsalName}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.payment,
                size: 80,
                color: Colors.green.shade700,
              ),
              const SizedBox(height: 24),
              const Text(
                'Redirecting to Khalti...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              const Text(
                'You will be redirected to the payment page.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _checkPaymentStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('I have completed payment'),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}