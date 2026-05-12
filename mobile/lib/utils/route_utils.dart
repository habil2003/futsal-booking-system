import 'package:shared_preferences/shared_preferences.dart';

/// Saves the current route so it can be restored after a page refresh
Future<void> saveLastRoute(String route) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('last_route', route);
}

/// Returns the last saved route, or null if none
Future<String?> getLastRoute() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('last_route');
}