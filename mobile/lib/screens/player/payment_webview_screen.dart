import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/payment_service.dart';

class KhaltiPaymentScreen extends StatefulWidget {
  final String paymentUrl;
  final String pidx;
  final int bookingId;

  const KhaltiPaymentScreen({
    super.key,
    required this.paymentUrl,
    required this.pidx,
    required this.bookingId,
  });

  @override
  State<KhaltiPaymentScreen> createState() => _KhaltiPaymentScreenState();
}

class _KhaltiPaymentScreenState extends State<KhaltiPaymentScreen> {
  late final WebViewController _controller;
  bool _isVerifying = false;
  bool _paymentCompleted = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;
            debugPrint('🔵 NAVIGATION: $url');
            
            // Check for payment success indicators
            if (_isPaymentSuccess(url)) {
              debugPrint('🎯 PAYMENT SUCCESS DETECTED!');
              _handlePaymentSuccess();
              return NavigationDecision.prevent;
            }
            
            // Check for payment failure/cancellation
            if (_isPaymentFailure(url)) {
              debugPrint('❌ PAYMENT FAILURE DETECTED!');
              _handlePaymentFailure();
              return NavigationDecision.prevent;
            }
            
            return NavigationDecision.navigate;
          },
          onPageFinished: (url) {
            debugPrint('🟢 PAGE FINISHED: $url');
            if (_isPaymentSuccess(url) && !_paymentCompleted) {
              _handlePaymentSuccess();
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  bool _isPaymentSuccess(String url) {
    return url.contains('payment=success') ||
           url.contains('status=COMPLETED') ||
           url.contains('status=completed') ||
           url.contains('booking-history?payment=success') ||
           url.contains('payment_status=COMPLETED') ||
           url.contains('success=true') ||
           url.contains('transaction_id');
  }

  bool _isPaymentFailure(String url) {
    return url.contains('payment=failed') ||
           url.contains('status=failed') ||
           url.contains('payment=error') ||
           url.contains('status=cancelled') ||
           url.contains('error');
  }

  Future<void> _handlePaymentSuccess() async {
    if (_paymentCompleted || _isVerifying) return;
    
    setState(() {
      _paymentCompleted = true;
      _isVerifying = true;
    });

    debugPrint('🔍 Verifying payment for pidx: ${widget.pidx}');
    
    try {
      final response = await PaymentService.verifyPayment(widget.pidx);
      debugPrint('📡 Verification response: ${response['status']} - ${response['paymentStatus']}');
      
      if (!mounted) return;

      if (response['status'] == 'success' && 
          response['paymentStatus'] == 'COMPLETED') {
        debugPrint('✅ Payment verified successfully!');
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        debugPrint('❌ Payment verification failed');
        if (mounted) {
          _showErrorDialog('Payment verification failed. Please contact support if amount was deducted.');
        }
      }
    } catch (e) {
      debugPrint('❌ Verification error: $e');
      if (mounted) {
        _showErrorDialog('Error verifying payment. Please check your booking status.');
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  void _handlePaymentFailure() {
    if (_paymentCompleted) return;
    debugPrint('❌ Payment failed or cancelled');
    if (mounted) {
      Navigator.pop(context, false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Payment Status'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (mounted) {
                Navigator.pop(context, false);
              }
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khalti Payment'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_isVerifying)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: _isVerifying
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 16),
                  Text('Verifying your payment...'),
                ],
              ),
            )
          : WebViewWidget(controller: _controller),
    );
  }
}