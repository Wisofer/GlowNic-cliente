import 'package:flutter/material.dart';
import 'package:system_movil/screens/home_screen.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Navigate to a specific screen
  static void navigateTo(Widget page) {
    _pushTo(page);
  }

  /// Navigate to home screen
  static void navigateToHome() {
    _pushTo(const HomeScreen());
  }

  /// Navigate from notification payload
  static void navigateFromPayload(String? payload) {
    // Por defecto, navegar al home
    _pushTo(const HomeScreen());
  }

  static Future<void> _pushTo(Widget page) async {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    await nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => page),
      (route) => route.isFirst,
    );
  }
}
