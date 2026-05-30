import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/futsal_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/court_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/admin_analytics_provider.dart';
import 'providers/tournament_provider.dart';
import 'providers/review_provider.dart';
import 'providers/favorite_provider.dart';
import 'providers/block_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/analytics_provider.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/player/home_screen.dart';
import 'screens/owner/owner_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/futsal_approval_screen.dart';
import 'screens/admin/user_management_screen.dart';
import 'screens/admin/admin_all_futsals_screen.dart';
import 'screens/admin/admin_bookings_screen.dart';
import 'screens/admin/system_settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthProvider();
  await auth.tryAutoLogin();

  runApp(MyApp(authProvider: auth));
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;
  const MyApp({required this.authProvider, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => FutsalProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => AdminAnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ChangeNotifierProvider(create: (_) => BlockProvider()),
        ChangeNotifierProvider(create: (_) => CourtProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => TournamentProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'Futsal Booking',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF059669),
  ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const SplashScreen(),
        routes: {
          '/home': (ctx) => const PlayerHomeScreen(),
          '/login': (ctx) => const LoginScreen(),
          '/player/home': (ctx) => const PlayerHomeScreen(),
          '/owner/dashboard': (ctx) => const OwnerDashboard(),
          '/admin/dashboard': (ctx) => AdminDashboard(),
          "/admin/futsal-approvals": (ctx) => const FutsalApprovalScreen(),
          "/admin/users": (ctx) => const AdminUsersScreen(),
          '/admin/futsals': (context) => const AdminAllFutsalsScreen(),
          '/admin/bookings': (context) => const AdminBookingsScreen(),
          '/admin/settings': (context) => const SystemSettingsScreen(),
        },
      ),
    );
  }
}
