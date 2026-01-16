import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:system_movil/screens/home_screen.dart';
import 'package:system_movil/screens/appointments/appointments_screen.dart';

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
    if (payload == null || payload.isEmpty) {
      _pushTo(const HomeScreen());
      return;
    }

    try {
      final data = json.decode(payload) as Map<String, dynamic>;
      final type = (data['type'] ?? data['route'] ?? 'home').toString().toLowerCase();

      switch (type) {
        case 'appointment':
        case 'cita':
        case 'appointments':
        case 'citas':
          _pushTo(const AppointmentsScreen());
          break;
        default:
          _pushTo(const HomeScreen());
      }
    } catch (e) {
      _pushTo(const HomeScreen());
    }
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
