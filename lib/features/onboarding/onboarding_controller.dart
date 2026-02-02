import 'package:flutter/material.dart';
import 'onboarding_model.dart';
import '../../constants/strings.dart';

class OnboardingController {
  final PageController pageController = PageController();

  List<OnboardingModel> get onboardingPages {
    return [
      OnboardingModel(
        title: AppStrings.screen1Title,
        subtitle: AppStrings.screen1Subtitle,
        imagePath: "assets/videos/screen1.mp4",
        isVideo: true,
      ),
      OnboardingModel(
        title: AppStrings.screen2Title,
        subtitle: AppStrings.screen2Subtitle,
        imagePath: "assets/videos/screen2.mp4",
        isVideo: true,
      ),
      OnboardingModel(
        title: AppStrings.screen3Title,
        subtitle: AppStrings.screen3Subtitle,
        imagePath: "assets/videos/screen3.mp4",
        isVideo: true,
      ),
    ];
  }
}