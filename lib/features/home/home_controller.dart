class HomeController {
  // Home screen related business logic will go here
  // For example: Fetching user data, handling button clicks, etc.

  List<HomeFeature> getFeatures() {
    return [
      HomeFeature(
        id: 1,
        title: 'Dashboard',
        icon: 'dashboard',
        route: '/dashboard',
      ),
      HomeFeature(
        id: 2,
        title: 'Profile',
        icon: 'profile',
        route: '/profile',
      ),
      HomeFeature(
        id: 3,
        title: 'Settings',
        icon: 'settings',
        route: '/settings',
      ),
      HomeFeature(
        id: 4,
        title: 'Help',
        icon: 'help',
        route: '/help',
      ),
    ];
  }
}

class HomeFeature {
  final int id;
  final String title;
  final String icon;
  final String route;

  HomeFeature({
    required this.id,
    required this.title,
    required this.icon,
    required this.route,
  });
}