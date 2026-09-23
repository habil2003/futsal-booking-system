import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../utils/route_utils.dart';
// import 'home_screen.dart';
import 'owner/owner_dashboard.dart';
import 'admin/admin_account.dart';
// import 'login_screen.dart';
import './player/home_screen.dart';
import './onboarding_screen.dart';   

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    // 1. Check if onboarding has been completed
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_complete') ?? false;

    // Minimum splash display time
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 2. If onboarding not done, go there first (regardless of auth)
    if (!onboardingDone) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      return;
    }

    // 3. Onboarding already done – proceed with normal auth flow
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.checkAuth();
    if (!mounted) return;

    if (auth.isAuthenticated) {
      // Restore last route if available
      final lastRoute = await getLastRoute();
      if (!mounted) return;
      if (lastRoute != null) {
        switch (lastRoute) {
          case '/player/home':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const PlayerHomeScreen()),
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

      // Fallback role‑based navigation
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
          MaterialPageRoute(builder: (_) => const PlayerHomeScreen()),
        );
      }
    } else {
      // Not logged in → go to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
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