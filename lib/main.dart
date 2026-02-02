import 'package:flutter/material.dart';
import 'helpers/shared_preferences_helper.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/location/location_screen.dart';
import 'features/home/home_screen.dart';
import 'constants/colors.dart';
import 'helpers/notification_service.dart';  // ← এটা অবশ্যই helpers থেকে

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Notification initialize করা খুব জরুরি — এটা প্রথমে হতে হবে
  try {
    await NotificationService().initialize();
    print("NotificationService initialized successfully");
  } catch (e) {
    print("NotificationService initialization failed: $e");
  }

  // Onboarding চেক
  final bool isOnboardingCompleted = await SharedPreferencesHelper.isOnboardingCompleted();

  print("Onboarding completed: $isOnboardingCompleted");

  runApp(
    MyApp(
      isOnboardingCompleted: isOnboardingCompleted,
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isOnboardingCompleted;

  const MyApp({super.key, required this.isOnboardingCompleted});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Onboarding',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryPurple,
        ),
        useMaterial3: true,
      ),
      initialRoute: _getInitialRoute(),
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/location': (context) => const LocationScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }

  String _getInitialRoute() {
    if (!isOnboardingCompleted) {
      return '/onboarding';
    }
    // Onboarding শেষ হলে সরাসরি LocationScreen-এ যাবে (notification permission চাওয়ার জন্য)
    return '/location';
    // যদি location skip করতে চাও তাহলে '/home' করতে পারো, কিন্তু recommendation হচ্ছে location আগে
  }
}