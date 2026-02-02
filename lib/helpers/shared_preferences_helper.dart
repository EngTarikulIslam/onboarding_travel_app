import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static const String _onboardingKey = 'onboarding_completed';

  // Get SharedPreferences instance
  static Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // Check if onboarding is completed
  static Future<bool> isOnboardingCompleted() async {
    final prefs = await _prefs;
    return prefs.getBool(_onboardingKey) ?? false;
  }

  // Set onboarding as completed
  static Future<void> setOnboardingCompleted() async {
    final prefs = await _prefs;
    await prefs.setBool(_onboardingKey, true);
  }

  // Reset onboarding (for testing)
  static Future<void> resetOnboarding() async {
    final prefs = await _prefs;
    await prefs.remove(_onboardingKey);
  }

  // Clear all preferences (optional)
  static Future<void> clearAllPreferences() async {
    final prefs = await _prefs;
    await prefs.clear();
  }
}