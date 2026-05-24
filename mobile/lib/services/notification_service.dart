import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String _lastSeenKey = 'last_notification_seen';
  
  // Get last time admin checked notifications
  static Future<DateTime?> getLastSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeenStr = prefs.getString(_lastSeenKey);
    if (lastSeenStr == null) return null;
    return DateTime.parse(lastSeenStr);
  }
  
  // Update last seen time to now
  static Future<void> markAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSeenKey, DateTime.now().toIso8601String());
  }
  
  // Check if there are new activities since last seen
  static Future<bool> hasNewActivities(List<dynamic> activities) async {
    if (activities.isEmpty) return false;
    
    final lastSeen = await getLastSeen();
    if (lastSeen == null) return activities.isNotEmpty;
    
    // Check if any activity is newer than last seen
    for (var activity in activities) {
      final createdAt = activity['createdAt'];
      if (createdAt != null) {
        try {
          final activityDate = DateTime.parse(createdAt);
          if (activityDate.isAfter(lastSeen)) {
            return true;
          }
        } catch (e) {
          // Skip invalid dates
        }
      }
    }
    return false;
  }
}