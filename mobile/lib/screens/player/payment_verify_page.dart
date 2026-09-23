import 'package:flutter/material.dart';
import '../../services/payment_service.dart';

class PaymentVerifyPage extends StatefulWidget {
  final String pidx;
  final int bookingId;
  
  const PaymentVerifyPage({super.key, required this.pidx, required this.bookingId});

  @override
  State<PaymentVerifyPage> createState() => _PaymentVerifyPageState();
}

class _PaymentVerifyPageState extends State<PaymentVerifyPage> {
  bool _isVerifying = true;
  bool _success = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _verifyPayment();
  }

  Future<void> _verifyPayment() async {
    try {
      final response = await PaymentService.verifyPayment(widget.pidx);

      if (!mounted) return;

      if (response['status'] == 'success' && response['paymentStatus'] == 'COMPLETED') {
        setState(() {
          _isVerifying = false;
          _success = true;
          _message = 'Payment successful! Your booking is confirmed.';
        });
        
        // Wait 2 seconds then go to home
        Future.delayed(const Duration(seconds: 2), () {
          _goToHome();
        });
      } else {
        setState(() {
          _isVerifying = false;
          _success = false;
          _message = response['message'] ?? 'Payment verification failed.';
        });
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _success = false;
        _message = 'Error verifying payment: $e';
      });
    }
  }

  void _goToHome() {
    Navigator.pushNamedAndRemoveUntil(context, '/player/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Status'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: _isVerifying
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 16),
                  Text('Verifying your payment...'),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _success ? Icons.check_circle_outline : Icons.error_outline,
                    color: _success ? Colors.green : Colors.red,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _goToHome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
      ),
    );
  }
}