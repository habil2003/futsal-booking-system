import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/payment_service.dart';

class KhaltiPaymentScreen extends StatefulWidget {
  final String paymentUrl;
  final String pidx;

  const KhaltiPaymentScreen({
    super.key,
    required this.paymentUrl,
    required this.pidx,
  });

  @override
  State<KhaltiPaymentScreen> createState() => _KhaltiPaymentScreenState();
}

class _KhaltiPaymentScreenState extends State<KhaltiPaymentScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            print('🔵 NAVIGATION: ${request.url}');
            return NavigationDecision.navigate;
          },
          onPageFinished: (url) {
            print('🟢 PAGE FINISHED: $url');
            
            // Check for payment completion indicators
            if (url.contains('payment=success') ||
                url.contains('booking-history') ||
                url.contains('status=COMPLETED')) {
              print('🎯 PAYMENT SUCCESS DETECTED!');
              _verifyPayment();
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  Future<void> _verifyPayment() async {
    print('🔍 Verifying payment for pidx: ${widget.pidx}');
    try {
      final response = await PaymentService.verifyPayment(widget.pidx);
      print('📡 Response: ${response['status']} - ${response['paymentStatus']}');
      
      if (!mounted) return;

      if (response['status'] == 'success' && 
          response['paymentStatus'] == 'COMPLETED') {
        print('✅ Payment verified!');
        Navigator.pop(context, true);
      } else {
        print('❌ Payment verification failed');
        Navigator.pop(context, false);
      }
    } catch (e) {
      print('❌ Error: $e');
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khalti Payment'),
        backgroundColor: Colors.green,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}