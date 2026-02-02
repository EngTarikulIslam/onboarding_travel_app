import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../constants/strings.dart';
import '../../constants/colors.dart';
import 'onboarding_controller.dart';
import 'onboarding_model.dart';
import '../../helpers/shared_preferences_helper.dart';
import '../home/home_screen.dart';
import '../location/location_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final OnboardingController _controller = OnboardingController();
  int _currentPage = 0;
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo(0);
  }

  void _initializeVideo(int pageIndex) {
    final page = _controller.onboardingPages[pageIndex];

    if (page.isVideo) {
      if (_isVideoInitialized) {
        _videoController.dispose();
      }

      _videoController = VideoPlayerController.asset(page.imagePath)
        ..initialize().then((_) {
          setState(() {
            _isVideoInitialized = true;
          });
          _videoController.setLooping(true);
          _videoController.play();
        });
    }
  }

  void _nextPage() {
    if (_currentPage < _controller.onboardingPages.length - 1) {
      _controller.pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    if (_isVideoInitialized) {
      _videoController.pause();
      _videoController.dispose();
    }

    await SharedPreferencesHelper.setOnboardingCompleted();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LocationScreen()),
    );
  }

  @override
  void dispose() {
    if (_isVideoInitialized) {
      _videoController.dispose();
    }
    _controller.pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // CORRECT: Use Container with gradient for entire screen
      body: Container(
        decoration: AppColors.backgroundGradient, // This should work
        child: Stack(
          children: [
            // PageView - Should have transparent background
            PageView.builder(
              controller: _controller.pageController,
              itemCount: _controller.onboardingPages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
                _initializeVideo(index);
              },
              itemBuilder: (context, index) {
                return _buildPage(_controller.onboardingPages[index]);
              },
            ),

            // Skip Button
            Positioned(
              top: 50,
              right: 20,
              child: GestureDetector(
                onTap: _skipOnboarding,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Section
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _controller.onboardingPages.length,
                          (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? const Color(0xFF5200FF)
                              : const Color(0xFF5200FF).withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Next Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Container(
                      width: 328,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(69),
                        color: const Color(0xFF5200FF),
                      ),
                      child: TextButton(
                        onPressed: _nextPage,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.only(
                            top: 18,
                            right: 112,
                            bottom: 18,
                            left: 112,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(69),
                          ),
                        ),
                        child: const Text(
                          'Next',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingModel page) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0B0024),
            Color(0xFF082257),
          ],
          stops: [0.0, 1.0],
        ),
      ),
      child: Column(
        children: [
          // Video
          Container(
            width: MediaQuery.of(context).size.width,
            height: 429,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 25,
                  spreadRadius: 3,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              child: page.isVideo && _isVideoInitialized
                  ? _buildVideoPlayerWithCoverFit()
                  : _buildLoadingIndicator(),
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    page.title,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 24,
                      height: 36 / 24,
                      letterSpacing: 0,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    page.subtitle,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      height: 1.0,
                      letterSpacing: 0,
                      color: Color(0xCCFFFFFF),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayerWithCoverFit() {
    return Container(
      width: double.infinity,
      height: 429,
      color: Colors.black,
      child: SizedBox(
        width: double.infinity,
        height: 429,
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.center,
          child: SizedBox(
            width: _videoController.value.size.width,
            height: _videoController.value.size.height,
            child: VideoPlayer(_videoController),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'Loading video...',
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }
}