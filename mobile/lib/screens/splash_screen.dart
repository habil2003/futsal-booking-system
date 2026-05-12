import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/route_utils.dart';
import 'home_screen.dart';
import 'owner/owner_dashboard.dart';
import 'admin/admin_account.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateBasedOnAuth();
  }

  Future<void> _navigateBasedOnAuth() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.checkAuth();

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (auth.isAuthenticated) {
      final lastRoute = await getLastRoute();

      if (lastRoute != null) {
        switch (lastRoute) {
          case '/home':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
            return;
          case '/owner/dashboard':
            if (auth.isOwner) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const OwnerDashboard()),
              );
              return;
            }
            break;
          case '/admin/dashboard':
            if (auth.isAdmin) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminAccountScreen()),
              );
              return;
            }
            break;
        }
      }

      // Fallback to role‑based navigation
      if (auth.isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminAccountScreen()),
        );
      } else if (auth.isOwner) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OwnerDashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green, Colors.lightGreen],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sports_soccer, size: 100, color: Colors.white),
              SizedBox(height: 20),
              Text(
                'Futsal Booking',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}