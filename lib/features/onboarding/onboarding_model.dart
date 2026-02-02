class OnboardingModel {
  final String title;
  final String subtitle;
  final String imagePath;
  final bool isVideo;  // নতুন প্রপার্টি যোগ করুন

  OnboardingModel({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    this.isVideo = false,  // ডিফল্ট ভ্যালু
  });
}